// 買い切り型アプリ内課金による機能制御システム
import 'package:flutter/material.dart';
import 'package:maikago/services/one_time_purchase_service.dart';

/// 機能制限の種類
enum FeatureType {
  themeCustomization, // テーマカスタマイズ
  fontCustomization, // フォントカスタマイズ
  adRemoval, // 広告削除
}

/// 制限に達した際の案内タイプ
enum LimitReachedType {
  themeLimit, // テーマ制限
  fontLimit, // フォント制限
  featureLocked, // 機能ロック
}

/// 買い切り型アプリ内課金による機能制御システム
/// - 買い切り型アプリ内課金に基づく機能制御
/// - 制限に達した際の優しい案内機能
/// - アップグレード促進機能
/// - 使用状況の可視化機能
class FeatureAccessControl extends ChangeNotifier {
  factory FeatureAccessControl() => _instance;
  FeatureAccessControl._internal();

  static final FeatureAccessControl _instance =
      FeatureAccessControl._internal();

  late OneTimePurchaseService _purchaseService;

  /// 初期化
  void initialize(OneTimePurchaseService purchaseService) {
    _purchaseService = purchaseService;
    _purchaseService.addListener(_onPurchaseChanged);
  }

  /// 購入状態変更時の処理
  void _onPurchaseChanged() {
    notifyListeners();
  }

  /// 現在のプラン情報を取得
  Map<String, dynamic> get currentPlanInfo => {
        'isPremium': _purchaseService.isPremiumUnlocked,
        'isTrialActive': _purchaseService.isTrialActive,
        'trialRemainingDuration':
            _purchaseService.trialRemainingDuration?.toString(),
      };

  /// プレミアム機能が利用可能かどうか
  bool get isPremiumUnlocked => _purchaseService.isPremiumUnlocked;

  /// テーマカスタマイズが利用可能かどうか
  bool canCustomizeTheme() {
    return _purchaseService.isPremiumUnlocked;
  }

  /// フォントカスタマイズが利用可能かどうか
  bool canCustomizeFont() {
    return _purchaseService.isPremiumUnlocked;
  }

  /// 広告が表示されるかどうか
  bool shouldShowAds() {
    return !_purchaseService.isPremiumUnlocked;
  }

  /// 機能が利用可能かどうかをチェック
  bool isFeatureAvailable(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.themeCustomization:
        return canCustomizeTheme();
      case FeatureType.fontCustomization:
        return canCustomizeFont();
      case FeatureType.adRemoval:
        return !shouldShowAds();
    }
  }

  /// 機能がロックされているかどうかをチェック
  bool isFeatureLocked(FeatureType featureType) {
    return !isFeatureAvailable(featureType);
  }

  /// 機能制限に達したかどうかをチェック
  bool hasReachedLimit(LimitReachedType limitType) {
    switch (limitType) {
      case LimitReachedType.themeLimit:
        return !canCustomizeTheme();
      case LimitReachedType.fontLimit:
        return !canCustomizeFont();
      case LimitReachedType.featureLocked:
        return false; // 基本的に機能ロックなし
    }
  }

  /// 推奨アップグレードプランを取得
  Map<String, dynamic> getRecommendedUpgradePlan([FeatureType? featureType]) {
    if (isPremiumUnlocked) {
      // すでにプレミアム機能を利用中
      return {
        'type': 'premium',
        'name': 'まいかごプレミアム',
        'description': 'すべてのプレミアム機能を利用可能',
        'price': 280,
        'isAlreadyOwned': true,
      };
    } else {
      // プレミアム機能を推奨
      return {
        'type': 'premium',
        'name': 'まいかごプレミアム',
        'description': 'すべてのプレミアム機能を利用可能',
        'price': 280,
        'isAlreadyOwned': false,
        'trialDays': 7,
        'trialDescription': '7日間無料でお試し！いつでも解約OK',
        'features': [
          '全テーマ利用可能',
          '全フォント利用可能',
          '広告完全非表示',
        ],
      };
    }
  }

  /// 機能の説明を取得
  String getFeatureDescription(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.themeCustomization:
        return 'テーマカスタマイズ';
      case FeatureType.fontCustomization:
        return 'フォントカスタマイズ';
      case FeatureType.adRemoval:
        return '広告非表示';
    }
  }

  /// 制限タイプの説明を取得
  String getLimitDescription(LimitReachedType limitType) {
    switch (limitType) {
      case LimitReachedType.themeLimit:
        return 'テーマ制限';
      case LimitReachedType.fontLimit:
        return 'フォント制限';
      case LimitReachedType.featureLocked:
        return '機能ロック';
    }
  }

  /// 使用状況の統計を取得
  Map<String, dynamic> getUsageStats() {
    return {
      'currentPlan': currentPlanInfo,
      'features': {
        'themeCustomization': {
          'available': canCustomizeTheme(),
          'description': getFeatureDescription(FeatureType.themeCustomization),
        },
        'fontCustomization': {
          'available': canCustomizeFont(),
          'description': getFeatureDescription(FeatureType.fontCustomization),
        },
        'adRemoval': {
          'available': !shouldShowAds(),
          'description': getFeatureDescription(FeatureType.adRemoval),
        },
      },
      'recommendedUpgrade': getRecommendedUpgradePlan(),
    };
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isPremiumUnlocked': isPremiumUnlocked,
      'isTrialActive': _purchaseService.isTrialActive,
      'trialRemainingDuration':
          _purchaseService.trialRemainingDuration?.toString(),
      'isStoreAvailable': _purchaseService.isStoreAvailable,
      'error': _purchaseService.error,
      'isLoading': _purchaseService.isLoading,
      'currentPlanInfo': currentPlanInfo,
      'usageStats': getUsageStats(),
    };
  }

  @override
  void dispose() {
    _purchaseService.removeListener(_onPurchaseChanged);
    super.dispose();
  }
}
