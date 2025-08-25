const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');

admin.initializeApp();

// Google Cloud Vision APIクライアントを初期化
const visionClient = new vision.ImageAnnotatorClient();

// Cloud Function to analyze image using OCR
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
    console.log('🖼️ 画像解析開始:', { userId: context.auth.uid, timestamp });
    console.log('📊 受信データ:', { 
      hasImageUrl: !!imageUrl, 
      imageUrlLength: imageUrl ? imageUrl.length : 0,
      imageUrlPreview: imageUrl ? imageUrl.substring(0, 50) + '...' : 'null'
    });
    
    // base64エンコードされた画像データを処理
    const imageBuffer = Buffer.from(imageUrl, 'base64');
    console.log('📊 画像バッファサイズ:', imageBuffer.length);
    
    // Google Cloud Vision APIを使用してOCR実行
    const [visionResult] = await visionClient.textDetection({
      content: imageBuffer
    });
    const detections = visionResult.textAnnotations;
    
    if (!detections || detections.length === 0) {
      console.log('⚠️ テキストが検出されませんでした');
      return {
        success: true,
        ocrText: '',
        confidence: 0.0,
        timestamp: timestamp || new Date().toISOString(),
        userId: context.auth.uid
      };
    }

    // 最初の要素は全体のテキスト、残りは個別の文字領域
    const fullText = detections[0].description;
    console.log('📝 検出されたテキスト:', fullText);

    const result = {
      success: true,
      ocrText: fullText,
      confidence: 0.85, // 実際の信頼度計算は複雑なので固定値
      timestamp: timestamp || new Date().toISOString(),
      userId: context.auth.uid,
      textRegions: detections.slice(1).map(detection => ({
        text: detection.description,
        bounds: detection.boundingPoly
      }))
    };

    console.log('✅ 画像解析完了:', { ocrText: fullText, confidence: result.confidence });
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


