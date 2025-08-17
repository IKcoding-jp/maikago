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


