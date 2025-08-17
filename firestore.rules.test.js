const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');

const TEST_PROJECT_ID = 'test-project-id';

describe('Firestore Security Rules', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: TEST_PROJECT_ID,
      firestore: {
        rules: readFileSync('firestore.rules', 'utf8'),
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  // ユーザー認証テスト
  describe('User Authentication', () => {
    it('should allow authenticated users to access their own data', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const userDoc = db.collection('users').doc('user1');
      
      await firebase.assertSucceeds(userDoc.set({
        name: 'Test User',
        email: 'test@example.com'
      }));
      
      await firebase.assertSucceeds(userDoc.get());
    });

    it('should deny access to other users data', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const otherUserDoc = db.collection('users').doc('user2');
      
      await firebase.assertFails(otherUserDoc.get());
      await firebase.assertFails(otherUserDoc.set({
        name: 'Other User'
      }));
    });
  });

  // ファミリー共有機能テスト
  describe('Family Sharing', () => {
    it('should allow family members to access family data', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const familyDoc = db.collection('families').doc('family1');
      
      // ファミリーメンバーとして設定
      await familyDoc.set({
        id: 'family1',
        members: {
          user1: { id: 'user1', role: 'owner' },
          user2: { id: 'user2', role: 'member' }
        }
      });
      
      await firebase.assertSucceeds(familyDoc.get());
    });

    it('should deny access to non-family members', async () => {
      const db = testEnv.authenticatedContext('user3').firestore();
      const familyDoc = db.collection('families').doc('family1');
      
      await firebase.assertFails(familyDoc.get());
    });
  });

  // 送信型共有機能テスト
  describe('Transmission Sharing', () => {
    it('should allow sender to create transmission', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const transmissionDoc = db.collection('transmissions').doc('transmission1');
      
      await firebase.assertSucceeds(transmissionDoc.set({
        sharedBy: 'user1',
        sharedWith: ['user2', 'user3'],
        title: 'Test Transmission',
        isActive: true
      }));
    });

    it('should allow recipients to read transmission', async () => {
      const db = testEnv.authenticatedContext('user2').firestore();
      const transmissionDoc = db.collection('transmissions').doc('transmission1');
      
      await firebase.assertSucceeds(transmissionDoc.get());
    });

    it('should deny access to non-recipients', async () => {
      const db = testEnv.authenticatedContext('user4').firestore();
      const transmissionDoc = db.collection('transmissions').doc('transmission1');
      
      await firebase.assertFails(transmissionDoc.get());
    });
  });

  // リアルタイム共有機能テスト
  describe('Realtime Sharing', () => {
    it('should allow creator to create sync data', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const syncDoc = db.collection('syncData').doc('sync1');
      
      await firebase.assertSucceeds(syncDoc.set({
        userId: 'user1',
        sharedWith: ['user2', 'user3'],
        title: 'Test Sync',
        isActive: true
      }));
    });

    it('should allow shared users to read sync data', async () => {
      const db = testEnv.authenticatedContext('user2').firestore();
      const syncDoc = db.collection('syncData').doc('sync1');
      
      await firebase.assertSucceeds(syncDoc.get());
    });

    it('should deny access to non-shared users', async () => {
      const db = testEnv.authenticatedContext('user4').firestore();
      const syncDoc = db.collection('syncData').doc('sync1');
      
      await firebase.assertFails(syncDoc.get());
    });
  });

  // 通知機能テスト
  describe('Notifications', () => {
    it('should allow user to create their own notifications', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const notificationDoc = db.collection('notifications').doc('user1').collection('items').doc('notification1');
      
      await firebase.assertSucceeds(notificationDoc.set({
        type: 'new_content',
        title: 'Test Notification',
        isRead: false
      }));
    });

    it('should allow user to read their own notifications', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const notificationDoc = db.collection('notifications').doc('user1').collection('items').doc('notification1');
      
      await firebase.assertSucceeds(notificationDoc.get());
    });

    it('should deny access to other users notifications', async () => {
      const db = testEnv.authenticatedContext('user2').firestore();
      const notificationDoc = db.collection('notifications').doc('user1').collection('items').doc('notification1');
      
      await firebase.assertFails(notificationDoc.get());
    });
  });

  // 送信履歴テスト
  describe('Transmission History', () => {
    it('should allow sender to create transmission history', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const historyDoc = db.collection('transmissionHistory').doc('history1');
      
      await firebase.assertSucceeds(historyDoc.set({
        senderId: 'user1',
        receiverIds: ['user2', 'user3'],
        contentTitle: 'Test History'
      }));
    });

    it('should allow sender to read their transmission history', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const historyDoc = db.collection('transmissionHistory').doc('history1');
      
      await firebase.assertSucceeds(historyDoc.get());
    });

    it('should deny access to non-senders', async () => {
      const db = testEnv.authenticatedContext('user2').firestore();
      const historyDoc = db.collection('transmissionHistory').doc('history1');
      
      await firebase.assertFails(historyDoc.get());
    });
  });

  // 匿名ユーザーテスト
  describe('Anonymous Users', () => {
    it('should allow anonymous users to access anonymous data', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      const anonymousDoc = db.collection('anonymous').doc('session1');
      
      await firebase.assertSucceeds(anonymousDoc.set({
        sessionId: 'session1',
        data: 'test data'
      }));
      
      await firebase.assertSucceeds(anonymousDoc.get());
    });
  });

  // エラーテスト
  describe('Error Cases', () => {
    it('should deny unauthenticated access to protected collections', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      const userDoc = db.collection('users').doc('user1');
      
      await firebase.assertFails(userDoc.get());
      await firebase.assertFails(userDoc.set({ name: 'Test' }));
    });

    it('should deny access to unknown collections', async () => {
      const db = testEnv.authenticatedContext('user1').firestore();
      const unknownDoc = db.collection('unknown').doc('doc1');
      
      await firebase.assertFails(unknownDoc.get());
      await firebase.assertFails(unknownDoc.set({ data: 'test' }));
    });
  });
});
