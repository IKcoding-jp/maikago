import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maikago/services/subscription_service.dart';
import 'package:maikago/models/subscription_plan.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/subscription_integration_service.dart';
import 'package:maikago/services/donation_manager.dart';

void main() {
  group('Subscription Integration Tests', () {
    late SubscriptionService subscriptionService;
    late FeatureAccessControl featureControl;
    late SubscriptionIntegrationService integrationService;
    late DonationManager donationManager;

    setUp(() async {
      // SharedPreferencesのモックを設定
      SharedPreferences.setMockInitialValues({});
      
      // サービスを初期化
      subscriptionService = SubscriptionService();
      featureControl = FeatureAccessControl();
      integrationService = SubscriptionIntegrationService();
      donationManager = DonationManager();
    });

    group('Basic Integration', () {
      test('初期状態でフリープランが設定されている', () async {
        final currentPlan = integrationService.currentPlan;
        expect(currentPlan, equals(SubscriptionPlan.free));
      });

      test('サブスクリプションが非アクティブの状態', () async {
        expect(integrationService.isSubscriptionActive, isFalse);
      });

      test('広告が表示される状態', () async {
        expect(integrationService.shouldShowAds, isTrue);
      });
    });

    group('Plan Upgrades', () {
      test('ベーシックプランへのアップグレード', () async {
        await integrationService.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(integrationService.currentPlan, equals(SubscriptionPlan.basic));
        expect(integrationService.isSubscriptionActive, isTrue);
        expect(integrationService.shouldShowAds, isFalse);
      });

      test('プレミアムプランへのアップグレード', () async {
        await integrationService.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(integrationService.currentPlan, equals(SubscriptionPlan.premium));
        expect(integrationService.canChangeTheme, isTrue);
        expect(integrationService.canChangeFont, isTrue);
      });

      test('ファミリープランへのアップグレード', () async {
        await integrationService.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(integrationService.currentPlan, equals(SubscriptionPlan.family));
        expect(integrationService.hasFamilySharing, isTrue);
        expect(integrationService.maxFamilyMembers, equals(6));
      });
    });

    group('Feature Access', () {
      test('フリープランでの制限確認', () async {
        expect(featureControl.canCustomizeTheme(), isFalse);
        expect(featureControl.canCustomizeFont(), isFalse);
        expect(featureControl.canUseFamilySharing(), isFalse);
      });

      test('プレミアムプランでの機能アクセス', () async {
        await integrationService.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(featureControl.canCustomizeTheme(), isTrue);
        expect(featureControl.canCustomizeFont(), isTrue);
        expect(featureControl.canUseAnalytics(), isTrue);
        expect(featureControl.canUseExport(), isTrue);
        expect(featureControl.canUseBackup(), isTrue);
      });
    });

    group('Donation Integration', () {
      test('寄付とサブスクリプションの共存', () async {
        // 寄付を処理
        await donationManager.processDonation(1000);
        
        // サブスクリプションも追加
        await integrationService.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );

        expect(integrationService.hasBenefits, isTrue);
        expect(integrationService.isDonated, isTrue);
        expect(integrationService.isSubscriptionActive, isTrue);
      });
    });

    group('Edge Cases', () {
      test('期限切れサブスクリプション', () async {
        // 過去の日付で期限を設定
        await integrationService.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(integrationService.isSubscriptionExpired, isTrue);
        expect(integrationService.isSubscriptionActive, isFalse);
      });

      test('不正なプラン処理', () async {
        // テスト: 無効なプランでもエラーが発生しないことを確認
        expect(() async {
          await integrationService.processSubscription(
            SubscriptionPlan.free,
            expiry: DateTime.now().add(const Duration(days: 30)),
          );
        }, returnsNormally);
      });
    });

    tearDown(() async {
      // クリーンアップは自動で行われる
    });
  });
}