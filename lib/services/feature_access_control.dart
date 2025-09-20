// 買い切り型アプリ内課金による機能制御システム
import 'package:flutter/material.dart';
import 'subscription_integration_service.dart';

/// 機能制限の種類
enum FeatureType {
  listCreation, // タブ作成
  themeCustomization, // テーマカスタマイズ
  fontCustomization, // フォントカスタマイズ
  adRemoval, // 広告削除
  familySharing, // 家族共有
  analytics, // 分析・レポート
  export, // エクスポート機能
  backup, // バックアップ機能
}

/// 制限に達した際の案内タイプ
enum LimitReachedType {
  listLimit, // タブ数制限
  itemLimit, // リストアイテム数制限
  themeLimit, // テーマ制限
  fontLimit, // フォント制限
  familyLimit, // 家族メンバー制限
  featureLocked, // 機能ロック
}

/// 買い切り型アプリ内課金による機能制御システム
/// - 買い切り型アプリ内課金に基づく機能制御
/// - 制限に達した際の優しい案内機能
/// - アップグレード促進機能
/// - 使用状況の可視化機能
class FeatureAccessControl extends ChangeNotifier {
  static final FeatureAccessControl _instance =
      FeatureAccessControl._internal();
  factory FeatureAccessControl() => _instance;
  FeatureAccessControl._internal();

  late SubscriptionIntegrationService _subscriptionService;

  /// 初期化
  void initialize(SubscriptionIntegrationService subscriptionService) {
    _subscriptionService = subscriptionService;
    _subscriptionService.addListener(_onSubscriptionChanged);
  }

  /// サブスクリプション変更時の処理
  void _onSubscriptionChanged() {
    notifyListeners();
  }

  /// 現在のプラン情報を取得
  Map<String, dynamic> get currentPlanInfo =>
      _subscriptionService.getCurrentPlanInfo();

  /// プレミアム機能が利用可能かどうか
  bool get isPremiumUnlocked => _subscriptionService.isPremiumUnlocked;

  /// テーマカスタマイズが利用可能かどうか
  bool canCustomizeTheme() {
    return _subscriptionService.canCustomizeTheme();
  }

  /// フォントカスタマイズが利用可能かどうか
  bool canCustomizeFont() {
    return _subscriptionService.canCustomizeFont();
  }

  /// 広告が表示されるかどうか
  bool shouldShowAds() {
    return _subscriptionService.shouldShowAds();
  }

  /// リスト作成が可能かどうか
  bool canCreateList() {
    return _subscriptionService.canCreateList();
  }

  /// タブ作成が可能かどうか
  bool canCreateTab() {
    return _subscriptionService.canCreateTab();
  }

  /// 家族共有機能が利用可能かどうか
  bool canUseFamilySharing() {
    return _subscriptionService.canUseFamilySharing();
  }

  /// 分析・レポート機能が利用可能かどうか
  bool canUseAnalytics() {
    return _subscriptionService.canUseAnalytics();
  }

  /// エクスポート機能が利用可能かどうか
  bool canUseExport() {
    return _subscriptionService.canUseExport();
  }

  /// バックアップ機能が利用可能かどうか
  bool canUseBackup() {
    return _subscriptionService.canUseBackup();
  }

  /// 機能が利用可能かどうかをチェック
  bool isFeatureAvailable(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.listCreation:
        return canCreateList();
      case FeatureType.themeCustomization:
        return canCustomizeTheme();
      case FeatureType.fontCustomization:
        return canCustomizeFont();
      case FeatureType.adRemoval:
        return !shouldShowAds();
      case FeatureType.familySharing:
        return canUseFamilySharing();
      case FeatureType.analytics:
        return canUseAnalytics();
      case FeatureType.export:
        return canUseExport();
      case FeatureType.backup:
        return canUseBackup();
    }
  }

  /// 機能がロックされているかどうかをチェック
  bool isFeatureLocked(FeatureType featureType) {
    return !isFeatureAvailable(featureType);
  }

  /// 機能制限に達したかどうかをチェック
  bool hasReachedLimit(LimitReachedType limitType) {
    // 買い切り型では基本的に制限なし
    switch (limitType) {
      case LimitReachedType.listLimit:
        return !canCreateList();
      case LimitReachedType.itemLimit:
        return false; // アイテム数制限なし
      case LimitReachedType.themeLimit:
        return !canCustomizeTheme();
      case LimitReachedType.fontLimit:
        return !canCustomizeFont();
      case LimitReachedType.familyLimit:
        return !canUseFamilySharing();
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
      case FeatureType.listCreation:
        return 'リスト作成';
      case FeatureType.themeCustomization:
        return 'テーマカスタマイズ';
      case FeatureType.fontCustomization:
        return 'フォントカスタマイズ';
      case FeatureType.adRemoval:
        return '広告非表示';
      case FeatureType.familySharing:
        return '家族共有';
      case FeatureType.analytics:
        return '分析・レポート';
      case FeatureType.export:
        return 'エクスポート機能';
      case FeatureType.backup:
        return 'バックアップ機能';
    }
  }

  /// 制限タイプの説明を取得
  String getLimitDescription(LimitReachedType limitType) {
    switch (limitType) {
      case LimitReachedType.listLimit:
        return 'リスト作成制限';
      case LimitReachedType.itemLimit:
        return 'アイテム数制限';
      case LimitReachedType.themeLimit:
        return 'テーマ制限';
      case LimitReachedType.fontLimit:
        return 'フォント制限';
      case LimitReachedType.familyLimit:
        return '家族メンバー制限';
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
        'familySharing': {
          'available': canUseFamilySharing(),
          'description': getFeatureDescription(FeatureType.familySharing),
        },
        'analytics': {
          'available': canUseAnalytics(),
          'description': getFeatureDescription(FeatureType.analytics),
        },
        'export': {
          'available': canUseExport(),
          'description': getFeatureDescription(FeatureType.export),
        },
        'backup': {
          'available': canUseBackup(),
          'description': getFeatureDescription(FeatureType.backup),
        },
      },
      'recommendedUpgrade': getRecommendedUpgradePlan(),
    };
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isPremiumUnlocked': isPremiumUnlocked,
      'isTrialActive': _subscriptionService.isTrialActive,
      'trialRemainingDuration':
          _subscriptionService.trialRemainingDuration?.toString(),
      'isStoreAvailable': _subscriptionService.isStoreAvailable,
      'error': _subscriptionService.error,
      'isLoading': _subscriptionService.isLoading,
      'currentPlanInfo': currentPlanInfo,
      'usageStats': getUsageStats(),
    };
  }

  @override
  void dispose() {
    _subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
}
