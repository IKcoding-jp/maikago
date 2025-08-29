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
    // 全メンバーを非アクティブ化
    const updatedMembers = members.map(member => ({
      ...member,
      isActive: false
    }));
    
    batch.update(db.collection('families').doc(familyId), {
      'dissolvedAt': admin.firestore.FieldValue.serverTimestamp(),
      'isActive': false,
      'members': updatedMembers,
      'memberIds': []
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

// Cloud Function to handle family member removal
exports.removeFamilyMember = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '認証が必要です');
  }

  const { familyId, memberId } = data;
  if (!familyId || !memberId) {
    throw new functions.https.HttpsError('invalid-argument', 'ファミリーIDとメンバーIDが必要です');
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
      throw new functions.https.HttpsError('permission-denied', 'ファミリーオーナーのみメンバーを削除できます');
    }

    // 削除対象がメンバーに存在するかチェック
    const members = familyData.members || [];
    const targetMember = members.find(member => member.id === memberId);
    if (!targetMember) {
      throw new functions.https.HttpsError('not-found', '削除対象のメンバーが見つかりません');
    }

    const batch = db.batch();

    // ファミリードキュメントから対象メンバーを非アクティブ化
    const updatedMembers = members.map(member => {
      if (member.id === memberId) {
        return { ...member, isActive: false };
      }
      return member;
    });

    batch.update(db.collection('families').doc(familyId), {
      'members': updatedMembers,
      'memberIds': admin.firestore.FieldValue.arrayRemove([memberId])
    });

    // 対象メンバーのユーザー情報からファミリーIDを削除
    batch.update(db.collection('users').doc(memberId), {
      'familyId': null
    });

    // 対象メンバーのサブスクリプションを元のプランへ復元
    try {
      const subRef = db.collection('users').doc(memberId).collection('subscription').doc('current');
      const currentSubDoc = await subRef.get();
      
      if (currentSubDoc.exists) {
        const subData = currentSubDoc.data();
        const currentPlanType = subData.planType;
        const autoUpgradedFrom = subData.autoUpgradedFrom;

        if (currentPlanType === 'family' && autoUpgradedFrom) {
          batch.set(subRef, {
            'planType': autoUpgradedFrom,
            'isActive': autoUpgradedFrom !== 'free',
            'familyMembers': [],
            'autoUpgradedFrom': admin.firestore.FieldValue.delete(),
            'upgradedAt': admin.firestore.FieldValue.delete(),
            'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        } else if (currentPlanType === 'family') {
          batch.set(subRef, {
            'planType': 'free',
            'isActive': false,
            'familyMembers': [],
            'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        }
      }
    } catch (e) {
      console.warn('メンバー削除時のサブスクリプション復元に失敗:', e);
    }

    await batch.commit();
    console.log(`Member ${memberId} removed from family ${familyId} by ${context.auth.uid}`);
    
    return { success: true };
  } catch (error) {
    console.error('removeFamilyMember error:', error);
    throw new functions.https.HttpsError('internal', 'メンバー削除に失敗しました');
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


