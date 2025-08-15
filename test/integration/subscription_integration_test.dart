import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maikago/services/subscription_manager.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/subscription_integration_service.dart';
import 'package:maikago/services/donation_manager.dart';

void main() {
  group('Subscription Integration Tests', () {
    late SubscriptionManager subscriptionManager;
    late FeatureAccessControl featureControl;
    late SubscriptionIntegrationService integrationService;
    late DonationManager donationManager;

    setUp(() async {
      // SharedPreferencesをテスト用に初期化
      SharedPreferences.setMockInitialValues({});

      subscriptionManager = SubscriptionManager();
      featureControl = FeatureAccessControl();
      donationManager = DonationManager();
      integrationService = SubscriptionIntegrationService();

      // サービスを初期化
      featureControl.initialize(integrationService);
    });

    group('サービス連携テスト', () {
      test('SubscriptionManagerとFeatureAccessControlの連携が正しく動作する', () async {
        // サブスクリプションを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // FeatureAccessControlが正しく動作することを確認
        expect(featureControl.canCreateList(5), true);
        expect(featureControl.canCreateList(15), false); // 制限を超える
        expect(featureControl.canCustomizeTheme(), true);
        expect(featureControl.canCustomizeFont(), true);
        expect(featureControl.isAdRemoved(), true);
        expect(featureControl.canUseFamilySharing(), false);
        expect(featureControl.canUseAnalytics(), false);
      });

      test('SubscriptionIntegrationServiceが正しく統合される', () async {
        // サブスクリプションを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // 統合サービスが正しく動作することを確認
        expect(integrationService.currentPlan, SubscriptionPlan.premium);
        expect(integrationService.isSubscriptionActive, true);
        expect(integrationService.maxLists, 50);
        expect(integrationService.canCreateList(25), true);
        expect(integrationService.canCreateList(60), false);
        expect(integrationService.canChangeTheme, true);
        expect(integrationService.canChangeFont, true);
        expect(integrationService.shouldHideAds, true);
        expect(integrationService.hasFamilySharing, false);
      });

      test('寄付とサブスクリプションの統合が正しく動作する', () async {
        // 寄付を処理
        await donationManager.processDonation(500);

        // 既存寄付者の状態を確認
        expect(donationManager.isLegacyDonor, true);
        expect(donationManager.hasBenefits, true);

        // 統合サービスが正しく動作することを確認
        expect(integrationService.hasBenefits, true);
        expect(integrationService.shouldHideAds, true);
        expect(integrationService.canChangeTheme, true);
        expect(integrationService.canChangeFont, true);
      });
    });

    group('プラン変更テスト', () {
      test('プラン変更時にFeatureAccessControlが正しく更新される', () async {
        // Freeプランから開始
        expect(featureControl.canCreateList(3), false);
        expect(featureControl.canCustomizeTheme(), false);

        // Basicプランに変更
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(featureControl.canCreateList(5), true);
        expect(featureControl.canCustomizeTheme(), true);

        // Premiumプランに変更
        await subscriptionManager.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(featureControl.canCreateList(25), true);
        expect(featureControl.canUseAnalytics(), true);
      });

      test('プラン期限切れ時に正しく制限が適用される', () async {
        // 有効なサブスクリプションを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(featureControl.canCreateList(5), true);

        // 期限切れのサブスクリプションに変更
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(featureControl.canCreateList(5), false);
        expect(featureControl.canCustomizeTheme(), false);
      });
    });

    group('家族共有機能テスト', () {
      test('Familyプランでの家族共有機能が正しく動作する', () async {
        // Familyプランを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(featureControl.canUseFamilySharing(), true);
        expect(integrationService.hasFamilySharing, true);
        expect(integrationService.maxFamilyMembers, 5);

        // 家族メンバーを追加
        await subscriptionManager.addFamilyMember('test@example.com');
        expect(subscriptionManager.familyMembers.length, 1);
        expect(subscriptionManager.familyMembers.first, 'test@example.com');

        // 家族メンバーを削除
        await subscriptionManager.removeFamilyMember('test@example.com');
        expect(subscriptionManager.familyMembers.length, 0);
      });

      test('家族メンバー数の制限が正しく動作する', () async {
        // Familyプランを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // 制限内でメンバーを追加
        for (int i = 0; i < 5; i++) {
          await subscriptionManager.addFamilyMember('user$i@example.com');
        }
        expect(subscriptionManager.familyMembers.length, 5);

        // 制限を超えてメンバーを追加
        await subscriptionManager.addFamilyMember('user6@example.com');
        expect(subscriptionManager.familyMembers.length, 5); // 制限内に留まる
      });
    });

    group('移行機能テスト', () {
      test('既存寄付者からサブスクリプションへの移行が正しく動作する', () async {
        // 寄付を処理
        await donationManager.processDonation(1000);

        // 移行状態を確認
        expect(donationManager.isLegacyDonor, true);
        expect(integrationService.isLegacyDonor, true);
        expect(integrationService.shouldRecommendSubscription, false);

        // 移行完了処理
        await integrationService.completeMigration();
        expect(donationManager.migrationCompleted, true);
      });

      test('新規ユーザーの移行推奨が正しく動作する', () async {
        // 新規ユーザーの状態を確認
        expect(donationManager.isNewUser, true);
        expect(integrationService.isNewUser, true);
        expect(integrationService.shouldRecommendSubscription, true);

        // 推奨プランを確認
        final recommendedPlan = integrationService.getRecommendedPlan();
        expect(recommendedPlan, SubscriptionPlan.basic);
      });
    });

    group('データ永続化テスト', () {
      test('サブスクリプション状態が正しく永続化される', () async {
        // サブスクリプションを設定
        await subscriptionManager.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // 新しいインスタンスを作成
        final newSubscriptionManager = SubscriptionManager();
        newSubscriptionManager.setCurrentUserId('test-user-id');

        // 状態が正しく復元されることを確認
        expect(newSubscriptionManager.currentPlan, SubscriptionPlan.premium);
        expect(newSubscriptionManager.isActive, true);
      });

      test('寄付状態が正しく永続化される', () async {
        // 寄付を処理
        await donationManager.processDonation(500);

        // 新しいインスタンスを作成
        final newDonationManager = DonationManager();
        newDonationManager.setCurrentUserId('test-user-id');

        // 状態が正しく復元されることを確認
        expect(newDonationManager.isLegacyDonor, true);
        expect(newDonationManager.hasBenefits, true);
        expect(newDonationManager.totalDonationAmount, 500);
      });
    });

    group('エラーハンドリングテスト', () {
      test('重複する家族メンバーの追加エラーハンドリング', () async {
        await subscriptionManager.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        await subscriptionManager.addFamilyMember('test@example.com');
        await subscriptionManager.addFamilyMember('test@example.com');

        expect(subscriptionManager.familyMembers.length, 1);
        expect(subscriptionManager.familyMembers.first, 'test@example.com');
      });
    });

    group('パフォーマンステスト', () {
      test('大量の家族メンバー追加のパフォーマンス', () async {
        await subscriptionManager.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        final stopwatch = Stopwatch()..start();

        // 制限内でメンバーを追加
        for (int i = 0; i < 5; i++) {
          await subscriptionManager.addFamilyMember('user$i@example.com');
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒以内
        expect(subscriptionManager.familyMembers.length, 5);
      });

      test('プラン変更のパフォーマンス', () async {
        final stopwatch = Stopwatch()..start();

        // 複数のプラン変更を実行
        for (int i = 0; i < 10; i++) {
          await subscriptionManager.processSubscription(
            SubscriptionPlan.basic,
            expiry: DateTime.now().add(const Duration(days: 30)),
          );
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 2秒以内
      });
    });

    group('境界値テスト', () {
      test('リスト数の境界値テスト', () async {
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // 境界値でのテスト
        expect(integrationService.canCreateList(9), true);
        expect(integrationService.canCreateList(10), false);
        expect(integrationService.canCreateList(11), false);
      });

      test('家族メンバー数の境界値テスト', () async {
        await subscriptionManager.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        // 制限内でメンバーを追加
        for (int i = 0; i < 4; i++) {
          await subscriptionManager.addFamilyMember('user$i@example.com');
        }
        expect(subscriptionManager.familyMembers.length, 4);

        // 境界値でメンバーを追加
        await subscriptionManager.addFamilyMember('user4@example.com');
        expect(subscriptionManager.familyMembers.length, 5);

        // 制限を超えてメンバーを追加
        await subscriptionManager.addFamilyMember('user5@example.com');
        expect(subscriptionManager.familyMembers.length, 5); // 制限内に留まる
      });

      test('期限切れの境界値テスト', () async {
        final now = DateTime.now();

        // 期限切れの日付
        final expiredDate = now.subtract(const Duration(seconds: 1));
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: expiredDate,
        );
        expect(subscriptionManager.isActive, false);

        // 有効期限の日付
        final validDate = now.add(const Duration(seconds: 1));
        await subscriptionManager.processSubscription(
          SubscriptionPlan.basic,
          expiry: validDate,
        );
        expect(subscriptionManager.isActive, true);
      });
    });
  });
}
