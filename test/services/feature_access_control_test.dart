import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/one_time_purchase_service.dart';

/// テスト用のFake OneTimePurchaseService
///
/// OneTimePurchaseServiceはFirebase/InAppPurchaseに強く依存するため、
/// Mockitoではなく手動Fakeを使用する。
class FakeOneTimePurchaseService extends ChangeNotifier
    implements OneTimePurchaseService {
  bool _isPremiumUnlocked = false;
  bool _isTrialActive = false;
  Duration? _trialRemainingDuration;
  final bool _isStoreAvailable = true;
  final String? _error = null;
  final bool _isLoading = false;

  void setPremiumUnlocked(bool value) {
    _isPremiumUnlocked = value;
    notifyListeners();
  }

  void setTrialActive(bool value) {
    _isTrialActive = value;
    notifyListeners();
  }

  @override
  bool get isPremiumUnlocked => _isPremiumUnlocked;

  @override
  bool get isPremiumPurchased => _isPremiumUnlocked;

  @override
  bool get isTrialActive => _isTrialActive;

  @override
  Duration? get trialRemainingDuration => _trialRemainingDuration;

  @override
  bool get isStoreAvailable => _isStoreAvailable;

  @override
  String? get error => _error;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isInitialized => true;

  @override
  Future<void> get initialized => Future.value();

  @override
  DateTime? get trialStartDate => null;

  @override
  DateTime? get trialEndDate => null;

  @override
  bool get isTrialEverStarted => false;

  // 未使用のメソッドは空実装
  @override
  Future<void> initialize({String? userId}) async {}

  @override
  Future<bool> purchaseProduct(product) async => false;

  @override
  Future<bool> restorePurchases() async => false;

  @override
  void startTrial(int trialDays) {}

  @override
  void endTrial() {}

  @override
  void clearError() {}
}

void main() {
  late FeatureAccessControl featureAccessControl;
  late FakeOneTimePurchaseService fakePurchaseService;

  setUp(() {
    fakePurchaseService = FakeOneTimePurchaseService();
    featureAccessControl = FeatureAccessControl();
    featureAccessControl.initialize(fakePurchaseService);
  });

  tearDown(() {
    featureAccessControl.dispose();
    fakePurchaseService.dispose();
  });

  group('初期化', () {
    test('initialize()でOneTimePurchaseServiceのリスナーが登録される', () {
      // fakePurchaseServiceの変更がfeatureAccessControlに伝播することを確認
      var notified = false;
      featureAccessControl.addListener(() => notified = true);

      fakePurchaseService.setPremiumUnlocked(true);

      expect(notified, true);
    });

    test('dispose()後はリスナーが解除される', () {
      // 新しいインスタンスを作成してdispose
      final fac = FeatureAccessControl();
      final fps = FakeOneTimePurchaseService();
      fac.initialize(fps);
      fac.dispose();

      // dispose後の変更通知でエラーが出ないことを確認
      // （リスナーが解除されていれば問題なし）
      fps.setPremiumUnlocked(true);
      fps.dispose();
    });
  });

  group('プレミアム判定', () {
    test('プレミアム時にisPremiumUnlocked=true', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(featureAccessControl.isPremiumUnlocked, true);
    });

    test('非プレミアム時にisPremiumUnlocked=false', () {
      expect(featureAccessControl.isPremiumUnlocked, false);
    });
  });

  group('canCustomizeTheme', () {
    test('プレミアム時にtrue', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(featureAccessControl.canCustomizeTheme(), true);
    });

    test('非プレミアム時にfalse', () {
      expect(featureAccessControl.canCustomizeTheme(), false);
    });
  });

  group('canCustomizeFont', () {
    test('プレミアム時にtrue', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(featureAccessControl.canCustomizeFont(), true);
    });

    test('非プレミアム時にfalse', () {
      expect(featureAccessControl.canCustomizeFont(), false);
    });
  });

  group('shouldShowAds', () {
    test('プレミアム時にfalse（広告非表示）', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(featureAccessControl.shouldShowAds(), false);
    });

    test('非プレミアム時にtrue（広告表示）', () {
      expect(featureAccessControl.shouldShowAds(), true);
    });
  });

  group('isFeatureAvailable', () {
    test('プレミアム時にthemeCustomizationが利用可能', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(
        featureAccessControl.isFeatureAvailable(FeatureType.themeCustomization),
        true,
      );
    });

    test('プレミアム時にfontCustomizationが利用可能', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(
        featureAccessControl.isFeatureAvailable(FeatureType.fontCustomization),
        true,
      );
    });

    test('プレミアム時にadRemovalが利用可能', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(
        featureAccessControl.isFeatureAvailable(FeatureType.adRemoval),
        true,
      );
    });

    test('非プレミアム時にすべての機能が利用不可', () {
      for (final featureType in FeatureType.values) {
        expect(
          featureAccessControl.isFeatureAvailable(featureType),
          false,
        );
      }
    });
  });

  group('isFeatureLocked', () {
    test('非プレミアム時にすべての機能がロック', () {
      for (final featureType in FeatureType.values) {
        expect(
          featureAccessControl.isFeatureLocked(featureType),
          true,
        );
      }
    });

    test('プレミアム時にすべての機能がアンロック', () {
      fakePurchaseService.setPremiumUnlocked(true);

      for (final featureType in FeatureType.values) {
        expect(
          featureAccessControl.isFeatureLocked(featureType),
          false,
        );
      }
    });
  });

  group('hasReachedLimit', () {
    test('非プレミアム時にthemeLimitに達している', () {
      expect(
        featureAccessControl.hasReachedLimit(LimitReachedType.themeLimit),
        true,
      );
    });

    test('非プレミアム時にfontLimitに達している', () {
      expect(
        featureAccessControl.hasReachedLimit(LimitReachedType.fontLimit),
        true,
      );
    });

    test('featureLockedは常にfalse', () {
      expect(
        featureAccessControl.hasReachedLimit(LimitReachedType.featureLocked),
        false,
      );
    });

    test('プレミアム時にはthemeLimit/fontLimitに達していない', () {
      fakePurchaseService.setPremiumUnlocked(true);

      expect(
        featureAccessControl.hasReachedLimit(LimitReachedType.themeLimit),
        false,
      );
      expect(
        featureAccessControl.hasReachedLimit(LimitReachedType.fontLimit),
        false,
      );
    });
  });

  group('getRecommendedUpgradePlan', () {
    test('プレミアム時はisAlreadyOwned=true', () {
      fakePurchaseService.setPremiumUnlocked(true);

      final plan = featureAccessControl.getRecommendedUpgradePlan();

      expect(plan['isAlreadyOwned'], true);
      expect(plan['type'], 'premium');
      expect(plan['price'], 280);
    });

    test('非プレミアム時はisAlreadyOwned=false', () {
      final plan = featureAccessControl.getRecommendedUpgradePlan();

      expect(plan['isAlreadyOwned'], false);
      expect(plan['type'], 'premium');
      expect(plan['price'], 280);
      expect(plan['trialDays'], 7);
      expect(plan['features'], isA<List>());
    });
  });

  group('getFeatureDescription', () {
    test('各FeatureTypeの説明が取得できる', () {
      expect(
        featureAccessControl
            .getFeatureDescription(FeatureType.themeCustomization),
        'テーマカスタマイズ',
      );
      expect(
        featureAccessControl
            .getFeatureDescription(FeatureType.fontCustomization),
        'フォントカスタマイズ',
      );
      expect(
        featureAccessControl.getFeatureDescription(FeatureType.adRemoval),
        '広告非表示',
      );
    });
  });

  group('getLimitDescription', () {
    test('各LimitReachedTypeの説明が取得できる', () {
      expect(
        featureAccessControl.getLimitDescription(LimitReachedType.themeLimit),
        'テーマ制限',
      );
      expect(
        featureAccessControl.getLimitDescription(LimitReachedType.fontLimit),
        'フォント制限',
      );
      expect(
        featureAccessControl
            .getLimitDescription(LimitReachedType.featureLocked),
        '機能ロック',
      );
    });
  });

  group('getUsageStats', () {
    test('非プレミアム時の使用状況統計', () {
      final stats = featureAccessControl.getUsageStats();

      expect(stats['currentPlan'], isA<Map>());
      expect(stats['features'], isA<Map>());
      expect(stats['recommendedUpgrade'], isA<Map>());

      final features = stats['features'] as Map<String, dynamic>;
      final theme = features['themeCustomization'] as Map<String, dynamic>;
      final font = features['fontCustomization'] as Map<String, dynamic>;
      final ad = features['adRemoval'] as Map<String, dynamic>;
      expect(theme['available'], false);
      expect(font['available'], false);
      expect(ad['available'], false);
    });

    test('プレミアム時の使用状況統計', () {
      fakePurchaseService.setPremiumUnlocked(true);

      final stats = featureAccessControl.getUsageStats();
      final features = stats['features'] as Map<String, dynamic>;
      final theme = features['themeCustomization'] as Map<String, dynamic>;
      final font = features['fontCustomization'] as Map<String, dynamic>;
      final ad = features['adRemoval'] as Map<String, dynamic>;

      expect(theme['available'], true);
      expect(font['available'], true);
      expect(ad['available'], true);
    });
  });

  group('currentPlanInfo', () {
    test('プラン情報にisPremiumが含まれる', () {
      final info = featureAccessControl.currentPlanInfo;

      expect(info['isPremium'], false);
      expect(info['isTrialActive'], false);
    });

    test('プレミアム時のプラン情報', () {
      fakePurchaseService.setPremiumUnlocked(true);

      final info = featureAccessControl.currentPlanInfo;

      expect(info['isPremium'], true);
    });
  });
}
