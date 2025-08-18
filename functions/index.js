const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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


