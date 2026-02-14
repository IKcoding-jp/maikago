const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');

admin.initializeApp();

// Google Cloud Vision APIクライアントを初期化
const visionClient = new vision.ImageAnnotatorClient();

// Cloud Function to analyze image using OCR and ChatGPT (シンプル版)
exports.analyzeImage = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }

  const { imageUrl, timestamp } = data;
  if (!imageUrl) {
    throw new functions.https.HttpsError('invalid-argument', '画像データが必要です');
  }

  try {
    console.log('🖼️ 画像解析開始（シンプル版）:', { userId: context.auth.uid, timestamp });
    
    // base64エンコードされた画像データを処理
    const imageBuffer = Buffer.from(imageUrl, 'base64');
    console.log('📊 画像バッファサイズ(byte):', imageBuffer.length);
    
    // 1. Google Cloud Vision APIでOCR実行（シンプル版）
    console.log('🔍 Vision APIでOCR実行中...');
    const [visionResult] = await Promise.race([
      visionClient.documentTextDetection({
        image: { content: imageBuffer },
        imageContext: { languageHints: ['ja', 'en'] }
      }),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Vision APIタイムアウト')), 10000) // 10秒に短縮
      )
    ]);

    const fullTextAnnotation = visionResult.fullTextAnnotation;
    const textAnnotations = visionResult.textAnnotations;
    
    if (!fullTextAnnotation && (!textAnnotations || textAnnotations.length === 0)) {
      console.log('⚠️ テキストが検出されませんでした');
      return {
        success: false,
        error: 'テキストが検出されませんでした',
        timestamp: timestamp || new Date().toISOString()
      };
    }

    // OCRテキストを取得
    const ocrText = (fullTextAnnotation && fullTextAnnotation.text) || 
                   (textAnnotations && textAnnotations[0] && textAnnotations[0].description) || '';
    
    if (!ocrText.trim()) {
      console.log('⚠️ OCRテキストが空でした');
      return {
        success: false,
        error: 'OCRテキストが空でした',
        timestamp: timestamp || new Date().toISOString()
      };
    }

    console.log('📝 OCRテキスト取得完了:', ocrText.slice(0, 100) + '...');

    // 2. ChatGPTで商品情報を抽出
    console.log('🤖 ChatGPTで商品情報を抽出中...');
    const openai = require('openai');
    const client = new openai.OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const chatResponse = await Promise.race([
      client.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: `あなたは商品の値札を解析する専門家です。OCRで読み取ったテキストから商品名と税込価格を抽出してください。

出力形式（JSON）:
{
  "name": "商品名",
  "price": 税込価格（数値のみ）
}

注意事項:
- 商品名は簡潔に（例：「やわらかパイ」）
- 価格は税込価格のみを抽出（例：138）
- 価格が複数ある場合は最も目立つ価格を選択
- 商品名や価格が不明確な場合はnullを返す`
          },
          {
            role: 'user',
            content: `以下のOCRテキストから商品名と税込価格を抽出してください:\n\n${ocrText}`
          }
        ],
        temperature: 0.1,
        max_tokens: 200
      }),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('ChatGPTタイムアウト')), 15000) // 15秒
      )
    ]);

    const chatContent = chatResponse.choices[0]?.message?.content;
    if (!chatContent) {
      throw new Error('ChatGPTからの応答が空でした');
    }

    console.log('🤖 ChatGPT応答:', chatContent);

    // JSONパース
    let productInfo;
    try {
      // JSON部分のみを抽出
      const jsonMatch = chatContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        productInfo = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('JSON形式が見つかりません');
      }
    } catch (parseError) {
      console.error('❌ JSONパースエラー:', parseError);
      throw new Error('ChatGPTの応答を解析できませんでした');
    }

    // 結果の検証
    if (!productInfo.name || !productInfo.price) {
      console.log('⚠️ 商品情報が不完全:', productInfo);
      return {
        success: false,
        error: '商品名または価格を抽出できませんでした',
        ocrText: ocrText,
        timestamp: timestamp || new Date().toISOString()
      };
    }

    const result = {
      success: true,
      name: productInfo.name,
      price: parseInt(productInfo.price),
      ocrText: ocrText,
      timestamp: timestamp || new Date().toISOString(),
      userId: context.auth.uid
    };

    console.log('✅ 解析完了:', { name: result.name, price: result.price });
    return result;

  } catch (error) {
    console.error('❌ 画像解析エラー:', error);
    
    if (error.message.includes('タイムアウト')) {
      throw new functions.https.HttpsError('deadline-exceeded', '解析がタイムアウトしました。画像サイズを小さくして再試行してください。');
    }
    
    throw new functions.https.HttpsError('internal', '画像解析に失敗しました: ' + error.message);
  }
});

// Cloud Function to set family plan for invitee and owner when owner creates family
exports.applyFamilyPlanToGroup = functions.firestore
  .document('families/{familyId}')
  .onCreate(async (snap, context) => {
    const familyData = snap.data();
    if (!familyData) return null;

    const members = familyData.members || [];
    const batch = admin.firestore().batch();

    try {
      // For each member, update their subscription/current doc to family
      for (const m of members) {
        const uid = m.id;
        if (!uid) continue;
        const subRef = admin.firestore().collection('users').doc(uid).collection('subscription').doc('current');
        batch.set(subRef, {
          planType: 'family',
          isActive: true,
          expiryDate: null,
          familyMembers: members.map(x => x.id),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      await batch.commit();
      console.log('applyFamilyPlanToGroup: Updated subscriptions for members');
      return null;
    } catch (e) {
      console.error('applyFamilyPlanToGroup error:', e);
      return null;
    }
  });

// Cloud Function to handle family dissolution
exports.dissolveFamily = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }

  const { familyId } = data;
  if (!familyId) {
    throw new functions.https.HttpsError('invalid-argument', 'ファミリーIDが必要です');
  }

  try {
    const db = admin.firestore();
    
    // ファミリードキュメントを取得
    const familyDoc = await db.collection('families').doc(familyId).get();
    if (!familyDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'ファミリーが見つかりません');
    }

    const familyData = familyDoc.data();
    
    // オーナー権限チェック
    if (familyData.ownerId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'ファミリーオーナーのみ解散できます');
    }

    const batch = db.batch();

    // ファミリードキュメントを更新（解散マーク）
    batch.update(db.collection('families').doc(familyId), {
      'dissolvedAt': admin.firestore.FieldValue.serverTimestamp(),
      'isActive': false
    });

    // 全メンバーのユーザー情報からファミリーIDを削除
    const members = familyData.members || [];
    for (const member of members) {
      if (member.id) {
        const userRef = db.collection('users').doc(member.id);
        batch.update(userRef, {
          'familyId': null
        });
      }
    }

    await batch.commit();
    console.log(`Family ${familyId} dissolved successfully by ${context.auth.uid}`);
    
    return { success: true };
  } catch (error) {
    console.error('dissolveFamily error:', error);
    throw new functions.https.HttpsError('internal', 'ファミリー解散に失敗しました');
  }
});

// ファミリープランの期限切れ時にメンバーを元のプランに戻すCloud Function
exports.handleFamilyPlanExpiration = functions.firestore
  .document('users/{userId}/subscription/current')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const userId = context.params.userId;

    // ファミリープランの期限切れを検知
    if (beforeData && afterData) {
      const beforePlanType = beforeData.planType;
      const afterPlanType = afterData.planType;
      const beforeIsActive = beforeData.isActive;
      const afterIsActive = afterData.isActive;
      const beforeFamilyMembers = beforeData.familyMembers || [];
      const afterFamilyMembers = afterData.familyMembers || [];

      // ファミリープランが期限切れになった場合
      if (beforePlanType === 'family' && beforeIsActive && !afterIsActive) {
        console.log(`🔍 ファミリープラン期限切れ検知: userId=${userId}`);
        
        try {
          const db = admin.firestore();
          const batch = db.batch();

          // 各メンバーを元のプランに戻す
          for (const memberId of beforeFamilyMembers) {
            if (memberId === userId) continue; // オーナー自身はスキップ

            console.log(`🔄 メンバーを元のプランに戻す処理開始: memberId=${memberId}`);

            // メンバーの現在のサブスクリプション情報を取得
            const memberSubRef = db.collection('users').doc(memberId).collection('subscription').doc('current');
            const memberSubDoc = await memberSubRef.get();

            if (memberSubDoc.exists) {
              const memberData = memberSubDoc.data();
              const originalPlanType = memberData.originalPlanType || 'free';
              const originalPlan = memberData.originalPlan || null;

              console.log(`📋 メンバー情報: memberId=${memberId}, originalPlanType=${originalPlanType}`);

              // 元のプランに戻す
              const restoreData = {
                planType: originalPlanType,
                isActive: originalPlanType !== 'free',
                familyOwnerId: null,
                familyOwnerActive: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              };

              // 元のプランが有料プランの場合、30日間の期限を設定
              if (originalPlanType !== 'free') {
                const expiryDate = new Date();
                expiryDate.setDate(expiryDate.getDate() + 30);
                restoreData.expiryDate = admin.firestore.Timestamp.fromDate(expiryDate);
                console.log(`⏰ 有料プラン復元: 期限を30日後に設定: ${expiryDate.toISOString()}`);
              } else {
                restoreData.expiryDate = null;
                console.log(`🆓 フリープラン復元`);
              }

              // 元のプラン情報があれば保存
              if (originalPlan) {
                restoreData.originalPlan = originalPlan;
              }

              // ファミリー関連の情報をクリア
              restoreData.familyMembers = [];

              batch.set(memberSubRef, restoreData, { merge: true });

              // メンバーに通知を送信（オプション）
              await sendFamilyExpirationNotification(memberId, userId);

              console.log(`✅ メンバー復元完了: memberId=${memberId}, planType=${originalPlanType}`);
            } else {
              console.log(`⚠️ メンバーのサブスクリプション情報が見つかりません: memberId=${memberId}`);
            }
          }

          // オーナー自身もフリープランに戻す
          const ownerSubRef = db.collection('users').doc(userId).collection('subscription').doc('current');
          batch.set(ownerSubRef, {
            planType: 'free',
            isActive: false,
            expiryDate: null,
            familyMembers: [],
            familyOwnerId: null,
            familyOwnerActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          await batch.commit();
          console.log(`✅ ファミリープラン期限切れ処理完了: userId=${userId}, メンバー数=${beforeFamilyMembers.length}`);

        } catch (error) {
          console.error(`❌ ファミリープラン期限切れ処理エラー: userId=${userId}`, error);
        }
      }
    }

    return null;
  });

// ファミリープラン期限切れ通知を送信する関数
async function sendFamilyExpirationNotification(memberId, ownerId) {
  try {
    const db = admin.firestore();
    
    // 通知ドキュメントを作成
    const notificationRef = db.collection('users').doc(memberId).collection('notifications').doc();
    await notificationRef.set({
      type: 'family_plan_expired',
      title: 'ファミリープランの期限が切れました',
      message: '参加していたファミリープランの期限が切れたため、元のプランに戻りました。',
      ownerId: ownerId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });

    console.log(`📧 ファミリープラン期限切れ通知送信: memberId=${memberId}`);
  } catch (error) {
    console.error(`❌ 通知送信エラー: memberId=${memberId}`, error);
  }
}

// 定期的にファミリープランの期限をチェックするCloud Function（毎日実行）
exports.checkFamilyPlanExpirations = functions.pubsub
  .schedule('0 2 * * *') // 毎日午前2時に実行
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    try {
      console.log('🔍 ファミリープラン期限チェック開始');
      
      const db = admin.firestore();
      const now = new Date();

      // 期限切れのファミリープランを検索
      const expiredFamilyPlans = await db
        .collectionGroup('subscription')
        .where('planType', '==', 'family')
        .where('isActive', '==', true)
        .where('expiryDate', '<', admin.firestore.Timestamp.fromDate(now))
        .get();

      console.log(`📊 期限切れファミリープラン数: ${expiredFamilyPlans.docs.length}`);

      for (const doc of expiredFamilyPlans.docs) {
        const data = doc.data();
        const userId = doc.ref.parent.parent.id; // users/{userId}/subscription/current
        const familyMembers = data.familyMembers || [];

        console.log(`🔄 期限切れファミリープラン処理: userId=${userId}, メンバー数=${familyMembers.length}`);

        // 期限切れとしてマーク
        await doc.ref.update({
          isActive: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // メンバーを元のプランに戻す処理を実行
        await handleFamilyPlanExpirationForMembers(userId, familyMembers);
      }

      console.log('✅ ファミリープラン期限チェック完了');
      return null;
    } catch (error) {
      console.error('❌ ファミリープラン期限チェックエラー:', error);
      return null;
    }
  });

// メンバーを元のプランに戻す処理（定期チェック用）
async function handleFamilyPlanExpirationForMembers(ownerId, familyMembers) {
  try {
    const db = admin.firestore();
    const batch = db.batch();

    for (const memberId of familyMembers) {
      if (memberId === ownerId) continue;

      console.log(`🔄 メンバー復元処理: memberId=${memberId}`);

      const memberSubRef = db.collection('users').doc(memberId).collection('subscription').doc('current');
      const memberSubDoc = await memberSubRef.get();

      if (memberSubDoc.exists) {
        const memberData = memberSubDoc.data();
        const originalPlanType = memberData.originalPlanType || 'free';

        const restoreData = {
          planType: originalPlanType,
          isActive: originalPlanType !== 'free',
          familyOwnerId: null,
          familyOwnerActive: false,
          familyMembers: [],
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (originalPlanType !== 'free') {
          const expiryDate = new Date();
          expiryDate.setDate(expiryDate.getDate() + 30);
          restoreData.expiryDate = admin.firestore.Timestamp.fromDate(expiryDate);
        } else {
          restoreData.expiryDate = null;
        }

        batch.set(memberSubRef, restoreData, { merge: true });
        await sendFamilyExpirationNotification(memberId, ownerId);
      }
    }

    // オーナー自身もフリープランに戻す
    const ownerSubRef = db.collection('users').doc(ownerId).collection('subscription').doc('current');
    batch.set(ownerSubRef, {
      planType: 'free',
      isActive: false,
      expiryDate: null,
      familyMembers: [],
      familyOwnerId: null,
      familyOwnerActive: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    await batch.commit();
    console.log(`✅ メンバー復元処理完了: ownerId=${ownerId}`);

  } catch (error) {
    console.error(`❌ メンバー復元処理エラー: ownerId=${ownerId}`, error);
  }
}

// デバッグ用のテスト関数
exports.testConnection = functions.https.onCall(async (data, context) => {
  try {
    console.log('🔧 テスト接続確認:', { userId: context.auth?.uid || 'anonymous', timestamp: new Date().toISOString() });

    return {
      success: true,
      message: 'Cloud Functions接続正常',
      timestamp: new Date().toISOString(),
      userId: context.auth?.uid || 'anonymous'
    };
  } catch (error) {
    console.error('❌ テスト接続エラー:', error);
    throw new functions.https.HttpsError('internal', 'テスト接続に失敗しました');
  }
});

// Cloud Function to parse recipe text and extract ingredients
exports.parseRecipe = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }

  const { recipeText } = data;
  if (!recipeText) {
    throw new functions.https.HttpsError('invalid-argument', 'レシピテキストが必要です');
  }

  try {
    console.log('🍳 レシピ解析開始:', { userId: context.auth.uid });

    const openai = require('openai');
    const client = new openai.OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const chatResponse = await Promise.race([
      client.chat.completions.create({
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content: `あなたはレシピから材料を抽出する専門家です。
レシピテキストから「料理名（レシピ名）」と「材料リスト」を抽出し、JSONで返してください。

抽出ルール:
1. title: レシピの料理名を簡潔に抽出する。不明な場合は「レシピから取り込み」とする。
2. ingredients: 材料名と分量を正確に抽出する。
3. 曖昧な分量（「適量」「少々」「ひとつまみ」等）は quantity を null にする。
4. 材料を正規化する（全角半角の統一、余分な空白削除、一般的な表記への統一）。
5. 買い物に不要そうなもの（水、油、塩、胡椒などの基本調味料）は isExcluded を true にする。

出力形式 (JSON):
{
  "title": "肉じゃが",
  "ingredients": [
    {
      "name": "玉ねぎ",
      "quantity": "1個",
      "normalizedName": "玉ねぎ",
      "isExcluded": false,
      "confidence": 1.0,
      "notes": null
    }
  ]
}`
          },
          {
            role: 'user',
            content: `以下のレシピテキストから材料を抽出してください:\n\n${recipeText}`
          }
        ],
        temperature: 0.1,
      }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('ChatGPTタイムアウト')), 15000)
      )
    ]);

    const content = chatResponse.choices[0]?.message?.content;
    if (!content) {
      throw new Error('ChatGPTからの応答が空でした');
    }

    const result = JSON.parse(content);
    console.log('✅ レシピ解析完了:', { title: result.title, ingredientCount: result.ingredients?.length || 0 });

    return {
      success: true,
      title: result.title || 'レシピから取り込み',
      ingredients: result.ingredients || [],
    };
  } catch (error) {
    console.error('❌ レシピ解析エラー:', error);
    if (error.message.includes('タイムアウト')) {
      throw new functions.https.HttpsError('deadline-exceeded', 'レシピ解析がタイムアウトしました');
    }
    throw new functions.https.HttpsError('internal', 'レシピ解析に失敗しました: ' + error.message);
  }
});

// Cloud Function to summarize product name
exports.summarizeProductName = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }

  const { originalName } = data;
  if (!originalName) {
    throw new functions.https.HttpsError('invalid-argument', '商品名が必要です');
  }

  try {
    const openai = require('openai');
    const client = new openai.OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const chatResponse = await Promise.race([
      client.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: `あなたは商品名を簡潔に要約する専門家です。
以下のルールに従って商品名を要約してください：

1. メーカー名、商品名のみを抽出
2. 不要な説明文・キーワードを削除（内容量、用途説明、キャッチフレーズ、包装説明、配送関連など）
3. 商品名の一部として必要なキーワードは保持（味の種類、形状、種類など）
4. 最大20文字以内に収める
5. 日本語で回答`
          },
          {
            role: 'user',
            content: `以下の商品名を要約してください：\n${originalName}`
          }
        ],
        max_tokens: 50,
      }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('ChatGPTタイムアウト')), 10000)
      )
    ]);

    const content = chatResponse.choices[0]?.message?.content?.trim();
    if (!content) {
      return { success: false, summarizedName: '' };
    }

    return { success: true, summarizedName: content };
  } catch (error) {
    console.error('❌ 商品名要約エラー:', error);
    throw new functions.https.HttpsError('internal', '商品名要約に失敗しました');
  }
});

// Cloud Function to check if two ingredients are the same
exports.checkIngredientSimilarity = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }

  const { name1, name2 } = data;
  if (!name1 || !name2) {
    throw new functions.https.HttpsError('invalid-argument', '2つの材料名が必要です');
  }

  // 完全一致チェック
  if (name1.trim() === name2.trim()) {
    return { success: true, isSame: true };
  }

  try {
    const openai = require('openai');
    const client = new openai.OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const chatResponse = await Promise.race([
      client.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'あなたは買い物リストの整理ヘルパーです。2つの材料が同じ食材を指しているかどうかを判定してください。判定は "true" または "false" のみで返答してください。'
          },
          {
            role: 'user',
            content: `「${name1}」と「${name2}」は同じ食材ですか？`
          }
        ],
        temperature: 0,
        max_tokens: 10,
      }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('ChatGPTタイムアウト')), 5000)
      )
    ]);

    const content = chatResponse.choices[0]?.message?.content || '';
    const isSame = content.toLowerCase().includes('true');

    return { success: true, isSame };
  } catch (error) {
    console.error('❌ 材料同一性判定エラー:', error);
    throw new functions.https.HttpsError('internal', '材料同一性判定に失敗しました');
  }
});
