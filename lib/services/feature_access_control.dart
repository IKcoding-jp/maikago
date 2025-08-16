// プラン別機能制御システム
import 'package:flutter/material.dart';
import 'subscription_integration_service.dart';
import 'subscription_service.dart';
import '../models/subscription_plan.dart';
import '../config.dart';

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

/// プラン別機能制御システム
/// - サブスクリプションプランに基づく機能制御
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

  // === 機能アクセスチェック ===

  /// タブ作成が可能かどうか
  bool canCreateList(int currentListCount) {
    return _subscriptionService.canCreateList(currentListCount);
  }

  /// 商品アイテム追加が可能かどうか
  bool canAddItemToList(int currentItemCount) {
    return _subscriptionService.canAddItemToList(currentItemCount);
  }

  /// テーマカスタマイズが可能かどうか
  bool canCustomizeTheme() {
    return _subscriptionService.canChangeTheme;
  }

  /// フォントカスタマイズが可能かどうか
  bool canCustomizeFont() {
    return _subscriptionService.canChangeFont;
  }

  /// 広告が非表示かどうか
  bool isAdRemoved() {
    return _subscriptionService.shouldHideAds;
  }

  /// 家族共有が可能かどうか
  bool canUseFamilySharing() {
    return _subscriptionService.hasFamilySharing;
  }

  /// 分析・レポート機能が利用可能かどうか
  bool canUseAnalytics() {
    final plan = _subscriptionService.currentPlan;
    return plan == SubscriptionPlan.premium || plan == SubscriptionPlan.family;
  }

  /// エクスポート機能が利用可能かどうか
  bool canUseExport() {
    final plan = _subscriptionService.currentPlan;
    return plan == SubscriptionPlan.premium || plan == SubscriptionPlan.family;
  }

  /// バックアップ機能が利用可能かどうか
  bool canUseBackup() {
    final plan = _subscriptionService.currentPlan;
    return plan == SubscriptionPlan.premium || plan == SubscriptionPlan.family;
  }

  // === 制限チェック ===

  /// タブ数制限に達しているかどうか
  bool isListLimitReached(int currentListCount) {
    return !canCreateList(currentListCount);
  }

  /// 家族メンバー制限に達しているかどうか
  bool isFamilyLimitReached() {
    return _subscriptionService.familyMembers.length >=
        _subscriptionService.maxFamilyMembers;
  }

  /// 特定の機能がロックされているかどうか
  bool isFeatureLocked(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.listCreation:
        return false; // タブ作成は常に可能（制限は別途チェック）
      case FeatureType.themeCustomization:
        return !canCustomizeTheme();
      case FeatureType.fontCustomization:
        return !canCustomizeFont();
      case FeatureType.adRemoval:
        return !isAdRemoved();
      case FeatureType.familySharing:
        return !canUseFamilySharing();
      case FeatureType.analytics:
        return !canUseAnalytics();
      case FeatureType.export:
        return !canUseExport();
      case FeatureType.backup:
        return !canUseBackup();
    }
  }

  // === 制限情報取得 ===

  /// 現在のリスト使用状況を取得
  Map<String, dynamic> getListUsageInfo(int currentListCount) {
    final maxLists = _subscriptionService.maxLists;
    final isUnlimited = maxLists == -1;

    return {
      'current': currentListCount,
      'max': isUnlimited ? null : maxLists,
      'isUnlimited': isUnlimited,
      'remaining': isUnlimited ? null : maxLists - currentListCount,
      'usagePercentage': isUnlimited
          ? null
          : (currentListCount / maxLists * 100).round(),
      'isLimitReached': isListLimitReached(currentListCount),
    };
  }

  /// 家族共有使用状況を取得
  Map<String, dynamic> getFamilySharingInfo() {
    if (!canUseFamilySharing()) {
      return {
        'available': false,
        'current': 0,
        'max': 0,
        'remaining': 0,
        'usagePercentage': 0,
        'isLimitReached': false,
      };
    }

    final current = _subscriptionService.familyMembers.length;
    final max = _subscriptionService.maxFamilyMembers;

    return {
      'available': true,
      'current': current,
      'max': max,
      'remaining': max - current,
      'usagePercentage': (current / max * 100).round(),
      'isLimitReached': isFamilyLimitReached(),
    };
  }

  /// テーマ使用状況を取得
  Map<String, dynamic> getThemeUsageInfo() {
    final availableThemes = _subscriptionService.availableThemes;
    final isUnlimited = availableThemes == -1;

    return {
      'available': canCustomizeTheme(),
      'count': isUnlimited ? '無制限' : availableThemes.toString(),
      'isUnlimited': isUnlimited,
      'locked': !canCustomizeTheme(),
    };
  }

  /// フォント使用状況を取得
  Map<String, dynamic> getFontUsageInfo() {
    final availableFonts = _subscriptionService.availableFonts;
    final isUnlimited = availableFonts == -1;

    return {
      'available': canCustomizeFont(),
      'count': isUnlimited ? '無制限' : availableFonts.toString(),
      'isUnlimited': isUnlimited,
      'locked': !canCustomizeFont(),
    };
  }

  // === 制限案内メッセージ ===

  /// 制限に達した際の案内メッセージを取得
  String getLimitReachedMessage(
    LimitReachedType type, {
    Map<String, dynamic>? context,
  }) {
    switch (type) {
      case LimitReachedType.listLimit:
        final usageInfo = getListUsageInfo(context?['currentListCount'] ?? 0);
        return 'タブ数の上限（${usageInfo['max']}個）に達しました。\nより多くのタブを作成するには、ベーシックプラン以上にアップグレードしてください。';

      case LimitReachedType.itemLimit:
        final maxItems = _subscriptionService.maxItemsPerList;
        return '商品アイテム数の上限（${maxItems}個）に達しました。\nより多くの商品を追加するには、ベーシックプラン以上にアップグレードしてください。';

      case LimitReachedType.themeLimit:
        return 'テーマカスタマイズ機能は現在のプランでは利用できません。\nプレミアムプラン以上で利用可能になります。';

      case LimitReachedType.fontLimit:
        return 'フォント変更機能は現在のプランでは利用できません。\nプレミアムプラン以上で利用可能になります。';

      case LimitReachedType.familyLimit:
        final familyInfo = getFamilySharingInfo();
        return '家族メンバーの上限（${familyInfo['max']}人）に達しました。\nより多くの家族メンバーを追加するには、ファミリープランにアップグレードしてください。';

      case LimitReachedType.featureLocked:
        return 'この機能は現在のプランでは利用できません。\nベーシックプラン以上で利用可能になります。';
    }
  }

  /// 機能ロック時の案内メッセージを取得
  String getFeatureLockedMessage(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.themeCustomization:
        return 'テーマカスタマイズ機能はプレミアムプラン以上で利用できます';
      case FeatureType.fontCustomization:
        return 'フォント変更機能はプレミアムプラン以上で利用できます';
      case FeatureType.adRemoval:
        return '広告非表示機能はベーシックプラン以上で利用できます';
      case FeatureType.familySharing:
        return '家族共有機能はプレミアムプラン以上で利用できます';
      case FeatureType.analytics:
        return '分析・レポート機能はプレミアムプラン以上で利用できます';
      case FeatureType.export:
        return 'エクスポート機能はプレミアムプラン以上で利用できます';
      case FeatureType.backup:
        return 'バックアップ機能はプレミアムプラン以上で利用できます';
      case FeatureType.listCreation:
        return 'タブ作成制限に達しています。ベーシックプラン以上にアップグレードしてください。';
    }
  }

  // === アップグレード推奨 ===

  /// 推奨アップグレードプランを取得
  SubscriptionPlan getRecommendedUpgradePlan(FeatureType? featureType) {
    if (featureType == null) {
      // 現在のプランに基づいて推奨
      final currentPlan = _subscriptionService.currentPlan;
      if (currentPlan == null || currentPlan == SubscriptionPlan.free) {
        return SubscriptionPlan.basic;
      } else if (currentPlan == SubscriptionPlan.basic) {
        return SubscriptionPlan.premium;
      } else if (currentPlan == SubscriptionPlan.premium) {
        return SubscriptionPlan.family;
      } else {
        return SubscriptionPlan.family; // 最高プラン
      }
    }

    // 特定機能に基づいて推奨
    switch (featureType) {
      case FeatureType.themeCustomization:
      case FeatureType.fontCustomization:
        return SubscriptionPlan.premium;
      case FeatureType.adRemoval:
        return SubscriptionPlan.basic;
      case FeatureType.familySharing:
      case FeatureType.analytics:
      case FeatureType.export:
      case FeatureType.backup:
        return SubscriptionPlan.premium;
      case FeatureType.listCreation:
        return SubscriptionPlan.basic;
    }
  }

  /// アップグレード推奨メッセージを取得
  String getUpgradeRecommendationMessage(FeatureType? featureType) {
    final recommendedPlan = getRecommendedUpgradePlan(featureType);
    final planInfo = _subscriptionService.getPlanInfo(recommendedPlan);

    if (featureType == null) {
      return '${planInfo['name']}にアップグレードして、より多くの機能をお楽しみください。';
    }

    switch (featureType) {
      case FeatureType.themeCustomization:
      case FeatureType.fontCustomization:
        return '${planInfo['name']}にアップグレードして、テーマ・フォントカスタマイズ機能を利用できます。';
      case FeatureType.adRemoval:
        return '${planInfo['name']}にアップグレードして、広告非表示機能を利用できます。';
      case FeatureType.familySharing:
        return '${planInfo['name']}にアップグレードして、家族共有機能を利用できます。';
      case FeatureType.analytics:
      case FeatureType.export:
      case FeatureType.backup:
        return '${planInfo['name']}にアップグレードして、分析・レポート機能を利用できます。';
      case FeatureType.listCreation:
        return '${planInfo['name']}にアップグレードして、より多くのタブを作成できます。';
    }
  }

  // === 使用状況サマリー ===

  /// 現在の使用状況サマリーを取得
  Map<String, dynamic> getUsageSummary(int currentListCount) {
    return {
      'currentPlan': _subscriptionService.currentPlanName,
      'listUsage': getListUsageInfo(currentListCount),
      'familySharing': getFamilySharingInfo(),
      'themeUsage': getThemeUsageInfo(),
      'fontUsage': getFontUsageInfo(),
      'features': {
        'adRemoval': isAdRemoved(),
        'analytics': canUseAnalytics(),
        'export': canUseExport(),
        'backup': canUseBackup(),
      },
    };
  }

  /// 制限に達している機能のリストを取得
  List<FeatureType> getLimitedFeatures(int currentListCount) {
    final limitedFeatures = <FeatureType>[];

    if (isListLimitReached(currentListCount)) {
      limitedFeatures.add(FeatureType.listCreation);
    }
    if (!canCustomizeTheme()) {
      limitedFeatures.add(FeatureType.themeCustomization);
    }
    if (!canCustomizeFont()) {
      limitedFeatures.add(FeatureType.fontCustomization);
    }
    if (!isAdRemoved()) {
      limitedFeatures.add(FeatureType.adRemoval);
    }
    if (!canUseFamilySharing()) {
      limitedFeatures.add(FeatureType.familySharing);
    }
    if (!canUseAnalytics()) {
      limitedFeatures.add(FeatureType.analytics);
    }
    if (!canUseExport()) {
      limitedFeatures.add(FeatureType.export);
    }
    if (!canUseBackup()) {
      limitedFeatures.add(FeatureType.backup);
    }

    return limitedFeatures;
  }

  // === デバッグ機能 ===

  /// 現在の制御状態をデバッグ出力
  void debugPrintStatus(int currentListCount) {
    if (enableDebugMode) {
      debugPrint('=== FeatureAccessControl デバッグ情報 ===');
      debugPrint('現在のプラン: ${_subscriptionService.currentPlanName}');
      debugPrint('タブ作成可能: ${canCreateList(currentListCount)}');
      debugPrint('テーマカスタマイズ可能: ${canCustomizeTheme()}');
      debugPrint('フォントカスタマイズ可能: ${canCustomizeFont()}');
      debugPrint('広告非表示: ${isAdRemoved()}');
      debugPrint('家族共有可能: ${canUseFamilySharing()}');
      debugPrint('分析機能利用可能: ${canUseAnalytics()}');
      debugPrint('エクスポート機能利用可能: ${canUseExport()}');
      debugPrint('バックアップ機能利用可能: ${canUseBackup()}');

      final usageInfo = getListUsageInfo(currentListCount);
      debugPrint(
        'タブ使用状況: ${usageInfo['current']}/${usageInfo['max'] ?? '無制限'}',
      );

      final familyInfo = getFamilySharingInfo();
      debugPrint('家族共有状況: ${familyInfo['current']}/${familyInfo['max']}');
      debugPrint('========================');
    }
  }

  /// サービスを破棄
  @override
  void dispose() {
    _subscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
}
