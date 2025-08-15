import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:matcher/matcher.dart';

import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/subscription_integration_service.dart';
import 'package:maikago/services/subscription_manager.dart';

// モッククラスの生成
@GenerateMocks([SubscriptionIntegrationService])
import 'feature_access_control_test.mocks.dart';

void main() {
  group('FeatureAccessControl Tests', () {
    late FeatureAccessControl featureControl;
    late MockSubscriptionIntegrationService mockSubscriptionService;

    setUp(() {
      mockSubscriptionService = MockSubscriptionIntegrationService();
      featureControl = FeatureAccessControl();
      featureControl.initialize(mockSubscriptionService);
    });

    group('機能アクセス制御テスト', () {
      test('Freeプランでの機能制限が正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.free);
        when(mockSubscriptionService.maxLists).thenReturn(3);
        when(mockSubscriptionService.maxFamilyMembers).thenReturn(0);
        when(mockSubscriptionService.canCreateList(any)).thenReturn(true);
        when(mockSubscriptionService.canChangeTheme).thenReturn(false);
        when(mockSubscriptionService.canChangeFont).thenReturn(false);
        when(mockSubscriptionService.shouldHideAds).thenReturn(false);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(false);
        when(mockSubscriptionService.currentPlanName).thenReturn('フリープラン');

        expect(featureControl.canCreateList(2), true);
        expect(featureControl.canCustomizeTheme(), false);
        expect(featureControl.canCustomizeFont(), false);
        expect(featureControl.isAdRemoved(), false);
        expect(featureControl.canUseFamilySharing(), false);
        expect(featureControl.canUseAnalytics(), false);
      });

      test('Basicプランでの機能制限が正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.basic);
        when(mockSubscriptionService.maxLists).thenReturn(10);
        when(mockSubscriptionService.maxFamilyMembers).thenReturn(0);
        when(mockSubscriptionService.canCreateList(any)).thenReturn(true);
        when(mockSubscriptionService.canChangeTheme).thenReturn(true);
        when(mockSubscriptionService.canChangeFont).thenReturn(true);
        when(mockSubscriptionService.shouldHideAds).thenReturn(true);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(false);
        when(mockSubscriptionService.currentPlanName).thenReturn('ベーシックプラン');

        expect(featureControl.canCreateList(9), true);
        expect(featureControl.canCustomizeTheme(), true);
        expect(featureControl.canCustomizeFont(), true);
        expect(featureControl.isAdRemoved(), true);
        expect(featureControl.canUseFamilySharing(), false);
        expect(featureControl.canUseAnalytics(), false);
      });

      test('Premiumプランでの機能制限が正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.premium);
        when(mockSubscriptionService.maxLists).thenReturn(50);
        when(mockSubscriptionService.maxFamilyMembers).thenReturn(0);
        when(mockSubscriptionService.canCreateList(any)).thenReturn(true);
        when(mockSubscriptionService.canChangeTheme).thenReturn(true);
        when(mockSubscriptionService.canChangeFont).thenReturn(true);
        when(mockSubscriptionService.shouldHideAds).thenReturn(true);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(false);
        when(mockSubscriptionService.currentPlanName).thenReturn('プレミアムプラン');

        expect(featureControl.canCreateList(49), true);
        expect(featureControl.canCustomizeTheme(), true);
        expect(featureControl.canCustomizeFont(), true);
        expect(featureControl.isAdRemoved(), true);
        expect(featureControl.canUseFamilySharing(), false);
        expect(featureControl.canUseAnalytics(), true);
      });

      test('Familyプランでの機能制限が正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.family);
        when(mockSubscriptionService.maxLists).thenReturn(100);
        when(mockSubscriptionService.maxFamilyMembers).thenReturn(5);
        when(mockSubscriptionService.canCreateList(any)).thenReturn(true);
        when(mockSubscriptionService.canChangeTheme).thenReturn(true);
        when(mockSubscriptionService.canChangeFont).thenReturn(true);
        when(mockSubscriptionService.shouldHideAds).thenReturn(true);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(true);
        when(mockSubscriptionService.currentPlanName).thenReturn('ファミリープラン');

        expect(featureControl.canCreateList(99), true);
        expect(featureControl.canCustomizeTheme(), true);
        expect(featureControl.canCustomizeFont(), true);
        expect(featureControl.isAdRemoved(), true);
        expect(featureControl.canUseFamilySharing(), true);
        expect(featureControl.canUseAnalytics(), true);
      });
    });

    group('制限チェックテスト', () {
      test('リスト数制限のチェックが正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.basic);
        when(mockSubscriptionService.maxLists).thenReturn(10);
        when(mockSubscriptionService.canCreateList(5)).thenReturn(true);
        when(mockSubscriptionService.canCreateList(10)).thenReturn(false);
        when(mockSubscriptionService.canCreateList(15)).thenReturn(false);

        expect(featureControl.canCreateList(5), true);
        expect(featureControl.canCreateList(10), false);
        expect(featureControl.canCreateList(15), false);
      });

      test('家族メンバー数制限のチェックが正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.family);
        when(mockSubscriptionService.maxFamilyMembers).thenReturn(5);
        when(mockSubscriptionService.familyMembers).thenReturn([]);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(true);

        // 家族共有機能の利用可能性をチェック
        expect(featureControl.canUseFamilySharing(), true);
      });

      test('機能ロックのチェックが正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.free);
        when(mockSubscriptionService.canChangeTheme).thenReturn(false);
        when(mockSubscriptionService.canChangeFont).thenReturn(false);
        when(mockSubscriptionService.shouldHideAds).thenReturn(false);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(false);
        when(mockSubscriptionService.currentPlanName).thenReturn('フリープラン');

        expect(featureControl.canCustomizeTheme(), false);
        expect(featureControl.canCustomizeFont(), false);
        expect(featureControl.isAdRemoved(), false);
        expect(featureControl.canUseFamilySharing(), false);
        expect(featureControl.canUseAnalytics(), false);
      });
    });

    group('使用状況サマリーテスト', () {
      test('使用状況サマリーの取得が正しく動作する', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.basic);
        when(mockSubscriptionService.maxLists).thenReturn(10);
        when(mockSubscriptionService.currentPlanName).thenReturn('ベーシックプラン');
        when(mockSubscriptionService.canCreateList(5)).thenReturn(true);
        when(mockSubscriptionService.availableThemes).thenReturn(5);
        when(mockSubscriptionService.availableFonts).thenReturn(3);

        final usageSummary = featureControl.getUsageSummary(5);
        expect(usageSummary['currentLists'], 5);
        expect(usageSummary['maxLists'], 10);
        expect(usageSummary['usagePercentage'], 50.0);
        expect(usageSummary['remainingLists'], 5);
      });

      test('使用率の境界値テスト', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.basic);
        when(mockSubscriptionService.maxLists).thenReturn(10);
        when(mockSubscriptionService.currentPlanName).thenReturn('ベーシックプラン');
        when(mockSubscriptionService.canCreateList(0)).thenReturn(true);
        when(mockSubscriptionService.canCreateList(5)).thenReturn(true);
        when(mockSubscriptionService.canCreateList(10)).thenReturn(false);
        when(mockSubscriptionService.availableThemes).thenReturn(5);
        when(mockSubscriptionService.availableFonts).thenReturn(3);

        // 0%の使用率
        final usage0 = featureControl.getUsageSummary(0);
        expect(usage0['usagePercentage'], 0.0);
        expect(usage0['remainingLists'], 10);

        // 100%の使用率
        final usage100 = featureControl.getUsageSummary(10);
        expect(usage100['usagePercentage'], 100.0);
        expect(usage100['remainingLists'], 0);

        // 50%の使用率
        final usage50 = featureControl.getUsageSummary(5);
        expect(usage50['usagePercentage'], 50.0);
        expect(usage50['remainingLists'], 5);
      });
    });

    group('エラーハンドリングテスト', () {
      test('未初期化状態でのエラーハンドリング', () {
        final uninitializedControl = FeatureAccessControl();

        expect(
          () => uninitializedControl.canCreateList(1),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('統合テスト', () {
      test('完全な機能制御フローのテスト', () {
        when(
          mockSubscriptionService.currentPlan,
        ).thenReturn(SubscriptionPlan.free);
        when(mockSubscriptionService.maxLists).thenReturn(5);
        when(mockSubscriptionService.maxFamilyMembers).thenReturn(0);
        when(mockSubscriptionService.canCreateList(2)).thenReturn(true);
        when(mockSubscriptionService.canCreateList(3)).thenReturn(false);
        when(mockSubscriptionService.canCreateList(5)).thenReturn(false);
        when(mockSubscriptionService.canChangeTheme).thenReturn(false);
        when(mockSubscriptionService.canChangeFont).thenReturn(false);
        when(mockSubscriptionService.shouldHideAds).thenReturn(false);
        when(mockSubscriptionService.hasFamilySharing).thenReturn(false);
        when(mockSubscriptionService.currentPlanName).thenReturn('フリープラン');
        when(mockSubscriptionService.availableThemes).thenReturn(1);
        when(mockSubscriptionService.availableFonts).thenReturn(1);

        // リスト作成制限のチェック
        expect(featureControl.canCreateList(2), true);
        expect(featureControl.canCreateList(3), false);

        // 機能ロックのチェック
        expect(featureControl.canCustomizeTheme(), false);

        // 使用状況サマリー
        final usageSummary = featureControl.getUsageSummary(2);
        expect(usageSummary['currentLists'], 2);
        expect(usageSummary['maxLists'], 5);
        expect(usageSummary['remainingLists'], 3);
      });
    });
  });
}
