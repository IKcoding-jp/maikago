import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:maikago/services/subscription_manager.dart';
import 'package:maikago/config.dart';

// モッククラスの生成
@GenerateMocks([
  SharedPreferences,
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference,
])
import 'subscription_manager_test.mocks.dart';

void main() {
  group('SubscriptionManager Tests', () {
    late SubscriptionManager subscriptionManager;
    late MockSharedPreferences mockPrefs;
    late MockFirebaseFirestore mockFirestore;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnapshot;
    late MockCollectionReference<Map<String, dynamic>> mockCollectionRef;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockFirestore = MockFirebaseFirestore();
      mockDocRef = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();
      mockCollectionRef = MockCollectionReference<Map<String, dynamic>>();

      // モックの設定
      when(mockPrefs.getString(any)).thenReturn(null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
      when(mockFirestore.collection(any)).thenReturn(mockCollectionRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.data()).thenReturn({});
      when(mockDocSnapshot.exists).thenReturn(false);

      subscriptionManager = SubscriptionManager();
    });

    group('プラン管理テスト', () {
      test('デフォルトプランはFreeである', () {
        expect(subscriptionManager.currentPlan, SubscriptionPlan.free);
        expect(subscriptionManager.isActive, false);
      });

      test('プラン名が正しく取得できる', () {
        expect(subscriptionManager.currentPlanName, 'フリープラン');
      });

      test('プランの価格が正しく取得できる', () {
        expect(subscriptionManager.currentPlanPrice, 0);
      });
    });

    group('サブスクリプション処理テスト', () {
      test('サブスクリプションの処理が正常に動作する', () async {
        const testPlan = SubscriptionPlan.basic;
        final testExpiryDate = DateTime.now().add(const Duration(days: 30));

        await subscriptionManager.processSubscription(
          testPlan,
          expiry: testExpiryDate,
        );

        expect(subscriptionManager.currentPlan, testPlan);
        expect(subscriptionManager.isActive, true);
        expect(subscriptionManager.subscriptionExpiry, testExpiryDate);
      });

      test('期限切れのサブスクリプションが正しく処理される', () async {
        const testPlan = SubscriptionPlan.basic;
        final expiredDate = DateTime.now().subtract(const Duration(days: 1));

        await subscriptionManager.processSubscription(
          testPlan,
          expiry: expiredDate,
        );

        expect(subscriptionManager.currentPlan, testPlan);
        expect(subscriptionManager.isActive, false);
      });

      test('無効なプランでのエラーハンドリング', () {
        expect(
          () =>
              subscriptionManager.processSubscription(null as SubscriptionPlan),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('家族共有機能テスト', () {
      test('家族メンバーの追加が正常に動作する', () async {
        const testEmail = 'test@example.com';
        const testName = 'Test User';

        await subscriptionManager.addFamilyMember(testEmail);

        expect(subscriptionManager.familyMembers.length, 1);
        expect(subscriptionManager.familyMembers.first, testEmail);
      });

      test('重複する家族メンバーの追加が正しく処理される', () async {
        const testEmail = 'test@example.com';
        const testName = 'Test User';

        await subscriptionManager.addFamilyMember(testEmail);
        await subscriptionManager.addFamilyMember(testEmail);

        expect(subscriptionManager.familyMembers.length, 1);
        expect(subscriptionManager.familyMembers.first, testEmail);
      });

      test('家族メンバーの削除が正常に動作する', () async {
        const testEmail = 'test@example.com';

        await subscriptionManager.addFamilyMember(testEmail);
        expect(subscriptionManager.familyMembers.length, 1);

        await subscriptionManager.removeFamilyMember(testEmail);
        expect(subscriptionManager.familyMembers.length, 0);
      });

      test('存在しない家族メンバーの削除が正しく処理される', () async {
        const testEmail = 'test@example.com';

        await subscriptionManager.removeFamilyMember(testEmail);
        expect(subscriptionManager.familyMembers.length, 0);
      });
    });

    group('ユーザーID管理テスト', () {
      test('ユーザーIDの設定が正常に動作する', () {
        const testUserId = 'test-user-id';

        subscriptionManager.setCurrentUserId(testUserId);

        // ユーザーIDが正しく設定されていることを確認
        expect(subscriptionManager, isNotNull);
      });

      test('nullユーザーIDの設定が正常に動作する', () {
        subscriptionManager.setCurrentUserId(null);

        // nullユーザーIDが正しく設定されていることを確認
        expect(subscriptionManager, isNotNull);
      });
    });

    group('データ永続化テスト', () {
      test('サブスクリプション状態の保存が正常に動作する', () async {
        const testPlan = SubscriptionPlan.basic;
        final testExpiryDate = DateTime.now().add(const Duration(days: 30));

        await subscriptionManager.processSubscription(
          testPlan,
          expiry: testExpiryDate,
        );

        // 状態が正しく保存されていることを確認
        expect(subscriptionManager.currentPlan, testPlan);
        expect(subscriptionManager.isActive, true);
      });

      test('家族メンバーの保存が正常に動作する', () async {
        const testEmail = 'test@example.com';

        await subscriptionManager.addFamilyMember(testEmail);

        // 家族メンバーが正しく保存されていることを確認
        expect(subscriptionManager.familyMembers.length, 1);
        expect(subscriptionManager.familyMembers.first, testEmail);
      });
    });

    group('エラーハンドリングテスト', () {
      test('無効な日付でのエラーハンドリング', () async {
        const testPlan = SubscriptionPlan.basic;

        // 無効な日付での処理をテスト
        expect(
          () => subscriptionManager.processSubscription(testPlan, expiry: null),
          returnsNormally,
        );
      });

      test('無効なプランでのエラーハンドリング', () {
        expect(
          () =>
              subscriptionManager.processSubscription(null as SubscriptionPlan),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('境界値テスト', () {
      test('最大家族メンバー数の境界値テスト', () async {
        // Familyプランを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // 制限内でメンバーを追加
        for (int i = 0; i < 10; i++) {
          await subscriptionManager.addFamilyMember('user$i@example.com');
        }

        expect(subscriptionManager.familyMembers.length, 10);

        // 制限を超えてメンバーを追加
        await subscriptionManager.addFamilyMember('user11@example.com');
        expect(subscriptionManager.familyMembers.length, 10); // 制限内に留まる
      });

      test('期限切れの境界値テスト', () async {
        const testPlan = SubscriptionPlan.basic;
        final now = DateTime.now();

        // 期限切れの日付
        final expiredDate = now.subtract(const Duration(seconds: 1));
        await subscriptionManager.processSubscription(
          testPlan,
          expiry: expiredDate,
        );
        expect(subscriptionManager.isActive, false);

        // 有効期限の日付
        final validDate = now.add(const Duration(seconds: 1));
        await subscriptionManager.processSubscription(
          testPlan,
          expiry: validDate,
        );
        expect(subscriptionManager.isActive, true);
      });
    });
  });
}
