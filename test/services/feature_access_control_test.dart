import 'package:flutter_test/flutter_test.dart';

import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/subscription_integration_service.dart';
import 'package:maikago/models/subscription_plan.dart';

void main() {
  group('FeatureAccessControl Tests', () {
    late FeatureAccessControl featureControl;
    late SubscriptionIntegrationService subscriptionService;

    setUp(() {
      subscriptionService = SubscriptionIntegrationService();
      featureControl = FeatureAccessControl();
    });

    group('Ad Removal Tests', () {
      test('フリープランでは広告が表示される', () {
        expect(featureControl.isAdRemoved(), isFalse);
      });

      test('ベーシックプラン以上では広告が非表示', () async {
        await subscriptionService.processSubscription(
          SubscriptionPlan.basic,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );
        expect(featureControl.isAdRemoved(), isTrue);
      });
    });

    group('Theme Customization Tests', () {
      test('フリープランではテーマ変更不可', () {
        expect(featureControl.canCustomizeTheme(), isFalse);
      });

      test('プレミアムプラン以上ではテーマ変更可能', () async {
        await subscriptionService.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );
        expect(featureControl.canCustomizeTheme(), isTrue);
      });
    });

    group('Font Customization Tests', () {
      test('フリープランではフォント変更不可', () {
        expect(featureControl.canCustomizeFont(), isFalse);
      });

      test('プレミアムプラン以上ではフォント変更可能', () async {
        await subscriptionService.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );
        expect(featureControl.canCustomizeFont(), isTrue);
      });
    });

    group('Family Sharing Tests', () {
      test('ファミリープランでのみ利用可能', () async {
        await subscriptionService.processSubscription(
          SubscriptionPlan.family,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );
        expect(featureControl.canUseFamilySharing(), isTrue);
      });
    });

    group('Premium Features Tests', () {
      test('プレミアム機能群のテスト', () async {
        await subscriptionService.processSubscription(
          SubscriptionPlan.premium,
          expiry: DateTime.now().add(const Duration(days: 30)),
        );
        
        expect(featureControl.canUseAnalytics(), isTrue);
        expect(featureControl.canUseExport(), isTrue);
        expect(featureControl.canUseBackup(), isTrue);
      });
    });

    group('Recommendation Tests', () {
      test('推奨プランの取得', () {
        final recommendedPlan = featureControl.getRecommendedUpgradePlan(null);
        expect(recommendedPlan, isA<SubscriptionPlan>());
      });

      test('機能別推奨プランの取得', () {
        final recommendedPlan = featureControl.getRecommendedUpgradePlan(
          FeatureType.themeCustomization
        );
        expect(recommendedPlan, equals(SubscriptionPlan.premium));
      });
    });
  });
}