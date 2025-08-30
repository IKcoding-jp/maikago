const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');

admin.initializeApp();

// Google Cloud Vision APIクライアントを初期化
const visionClient = new vision.ImageAnnotatorClient();

// Cloud Function to analyze image using OCR (高速化版)
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
    console.log('🖼️ 画像解析開始（ドキュメントOCR）:', { userId: context.auth.uid, timestamp });
    console.log('📊 受信データ概要:', { 
      hasImageUrl: !!imageUrl, 
      imageUrlLength: imageUrl ? imageUrl.length : 0,
      imageUrlPreview: imageUrl ? imageUrl.substring(0, 50) + '...' : 'null'
    });
    
    // base64エンコードされた画像データを処理
    const imageBuffer = Buffer.from(imageUrl, 'base64');
    console.log('📊 画像バッファサイズ(byte):', imageBuffer.length);
    
    // Google Cloud Vision APIを使用してOCR実行（ドキュメントOCR + タイムアウト）
    const [visionResult] = await Promise.race([
      visionClient.documentTextDetection({
        image: { content: imageBuffer },
        imageContext: { languageHints: ['ja', 'en'] }
      }),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Vision APIタイムアウト')), 10000)
      )
    ]);

    const fullTextAnnotation = visionResult.fullTextAnnotation;
    const textAnnotations = visionResult.textAnnotations;
    
    if (!fullTextAnnotation && (!textAnnotations || textAnnotations.length === 0)) {
      console.log('⚠️ テキストが検出されませんでした');
      return {
        success: true,
        ocrText: '',
        confidence: 0.0,
        timestamp: timestamp || new Date().toISOString(),
        userId: context.auth.uid
      };
    }

    // ドキュメントOCRの結果を優先
    const fullText = (fullTextAnnotation && fullTextAnnotation.text) || (textAnnotations && textAnnotations[0] && textAnnotations[0].description) || '';
    console.log('📝 検出テキスト（先頭200文字）:', fullText.slice(0, 200));

    // 簡易信頼度算出（段落・ブロックの平均confidence）
    function computeConfidence(annotation) {
      try {
        if (!annotation || !annotation.pages) return 0.0;
        let sum = 0;
        let count = 0;
        for (const page of annotation.pages) {
          if (!page.blocks) continue;
          for (const block of page.blocks) {
            if (typeof block.confidence === 'number') {
              sum += block.confidence;
              count += 1;
            }
          }
        }
        return count > 0 ? Number((sum / count).toFixed(3)) : 0.0;
      } catch (_) {
        return 0.0;
      }
    }
    const confidence = computeConfidence(fullTextAnnotation);

    const result = {
      success: true,
      ocrText: fullText,
      confidence,
      timestamp: timestamp || new Date().toISOString(),
      userId: context.auth.uid,
      textRegions: (textAnnotations || []).slice(1).map(detection => ({
        text: detection.description,
        bounds: detection.boundingPoly
      }))
    };

    console.log('✅ 画像解析完了:', { textLength: fullText.length, confidence: result.confidence });
    return result;
  } catch (error) {
    console.error('❌ 画像解析エラー:', error);
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


