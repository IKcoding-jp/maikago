// 買い切り型アプリ内課金の統合サービス
import 'dart:async';
import 'package:flutter/material.dart';
import 'one_time_purchase_service.dart';
import '../models/one_time_purchase.dart';
import 'debug_service.dart';

/// 買い切り型アプリ内課金機能を統合するサービス。
/// - 買い切り型アプリ内課金機能を提供
/// - 機能制限の管理
class SubscriptionIntegrationService extends ChangeNotifier {
  static final SubscriptionIntegrationService _instance =
      SubscriptionIntegrationService._internal();
  factory SubscriptionIntegrationService() => _instance;
  SubscriptionIntegrationService._internal() {
    _initialize();
  }

  late final OneTimePurchaseService _oneTimePurchaseService;
  bool _isInitialized = false;
  String? _currentUserId;

  /// 初期化完了フラグ
  bool get isInitialized => _isInitialized;

  /// 初期化処理
  void _initialize() {
    _oneTimePurchaseService = OneTimePurchaseService();
    _isInitialized = true;

    if (DebugService().enableDebugMode) {
      debugPrint('買い切り型統合サービス: 初期化完了');
    }
  }

  /// プレミアム機能が利用可能かどうか
  bool get isPremiumUnlocked => _oneTimePurchaseService.isPremiumUnlocked;

  /// プレミアム機能が購入済みかどうか
  bool get isPremiumPurchased => _oneTimePurchaseService.isPremiumPurchased;

  /// 体験期間がアクティブかどうか
  bool get isTrialActive => _oneTimePurchaseService.isTrialActive;

  /// 体験期間の残り時間
  Duration? get trialRemainingDuration =>
      _oneTimePurchaseService.trialRemainingDuration;

  /// ストアが利用可能かどうか
  bool get isStoreAvailable => _oneTimePurchaseService.isStoreAvailable;

  /// エラーメッセージ
  String? get error => _oneTimePurchaseService.error;

  /// ローディング状態
  bool get isLoading => _oneTimePurchaseService.isLoading;

  /// プレミアム機能の購入
  Future<bool> purchasePremium() async {
    return await _oneTimePurchaseService
        .purchaseProduct(OneTimePurchase.premium);
  }

  /// 購入状態の復元
  Future<void> restorePurchases() async {
    await _oneTimePurchaseService.restorePurchases();
  }

  /// 体験期間の開始
  void startTrial(int trialDays) {
    _oneTimePurchaseService.startTrial(trialDays);
  }

  /// 体験期間の終了
  void endTrial() {
    _oneTimePurchaseService.endTrial();
  }

  /// テーマカスタマイズが利用可能かどうか
  bool canCustomizeTheme() {
    return isPremiumUnlocked;
  }

  /// フォントカスタマイズが利用可能かどうか
  bool canCustomizeFont() {
    return isPremiumUnlocked;
  }

  /// 広告が表示されるかどうか
  bool shouldShowAds() {
    return !isPremiumUnlocked;
  }

  /// リスト作成制限をチェック
  bool canCreateList() {
    // 買い切り型では制限なし
    return true;
  }

  /// タブ作成制限をチェック
  bool canCreateTab() {
    // 買い切り型では制限なし
    return true;
  }

  /// 家族共有機能が利用可能かどうか
  bool canUseFamilySharing() {
    // 買い切り型では制限なし
    return true;
  }

  /// 分析・レポート機能が利用可能かどうか
  bool canUseAnalytics() {
    // 買い切り型では制限なし
    return true;
  }

  /// エクスポート機能が利用可能かどうか
  bool canUseExport() {
    // 買い切り型では制限なし
    return true;
  }

  /// バックアップ機能が利用可能かどうか
  bool canUseBackup() {
    // 買い切り型では制限なし
    return true;
  }

  /// 現在のプラン情報を取得（互換性のため）
  Map<String, dynamic> getCurrentPlanInfo() {
    return {
      'type': isPremiumUnlocked ? 'premium' : 'free',
      'name': isPremiumUnlocked ? 'まいかごプレミアム' : 'まいカゴフリー',
      'description': isPremiumUnlocked ? 'すべてのプレミアム機能を利用可能' : '基本的な機能を無料で利用',
      'isPremium': isPremiumUnlocked,
      'isTrialActive': isTrialActive,
      'trialRemainingDuration': trialRemainingDuration,
    };
  }

  /// 推奨アップグレードプランを取得（互換性のため）
  Map<String, dynamic> getRecommendedUpgradePlan() {
    if (isPremiumUnlocked) {
      return {
        'type': 'premium',
        'name': 'まいかごプレミアム',
        'description': 'すべてのプレミアム機能を利用可能',
        'price': 280,
        'isAlreadyOwned': true,
      };
    } else {
      return {
        'type': 'premium',
        'name': 'まいかごプレミアム',
        'description': 'すべてのプレミアム機能を利用可能',
        'price': 280,
        'isAlreadyOwned': false,
        'trialDays': 7,
        'trialDescription': '7日間無料でお試し！いつでも解約OK',
      };
    }
  }

  /// プラン情報を取得（互換性のため）
  Map<String, dynamic> getPlanInfo() {
    return {
      'currentPlan': getCurrentPlanInfo(),
      'recommendedPlan': getRecommendedUpgradePlan(),
      'features': {
        'themeCustomization': canCustomizeTheme(),
        'fontCustomization': canCustomizeFont(),
        'adRemoval': !shouldShowAds(),
        'listCreation': canCreateList(),
        'tabCreation': canCreateTab(),
        'familySharing': canUseFamilySharing(),
        'analytics': canUseAnalytics(),
        'export': canUseExport(),
        'backup': canUseBackup(),
      },
    };
  }

  /// 広告を非表示にするかどうか（互換性のため）
  bool get shouldHideAds => !shouldShowAds();

  /// テーマを変更できるかどうか（互換性のため）
  bool get canChangeTheme => canCustomizeTheme();

  /// フォントを変更できるかどうか（互換性のため）
  bool get canChangeFont => canCustomizeFont();

  /// リストにアイテムを追加できるかどうか（互換性のため）
  bool canAddItemToList() {
    return true; // 買い切り型では制限なし
  }

  /// 現在のユーザーIDを設定（互換性のため）
  void setCurrentUserId(String userId) {
    if (_currentUserId == userId) {
      return;
    }

    _currentUserId = userId;

    _oneTimePurchaseService.initialize(userId: userId).then((_) {
      notifyListeners();
    }).catchError((error, stackTrace) {
      debugPrint('買い切り型統合サービス: ユーザー切り替え時の初期化エラー: $error');
      if (DebugService().enableDebugMode) {
        debugPrint('スタックトレース: $stackTrace');
      }
    });
  }

  /// 体験期間の残り日数（互換性のため）
  int? get trialRemainingDays {
    final duration = trialRemainingDuration;
    if (duration == null) return null;
    return duration.inDays;
  }

  /// ファミリーメンバーかどうか（互換性のため）
  bool get isFamilyMember => false; // 買い切り型ではファミリー機能なし

  /// ファミリー特典がアクティブかどうか（互換性のため）
  bool get isFamilyBenefitsActive => false; // 買い切り型ではファミリー機能なし

  /// ファミリーメンバー一覧（互換性のため）
  List<String> get familyMembers => []; // 買い切り型ではファミリー機能なし

  /// 最大ファミリーメンバー数（互換性のため）
  int getMaxFamilyMembers() => 0; // 買い切り型ではファミリー機能なし

  /// 現在のプラン（互換性のため）
  Map<String, dynamic>? get currentPlan => getCurrentPlanInfo();

  /// サブスクリプションがアクティブかどうか（互換性のため）
  bool get isSubscriptionActive => isPremiumUnlocked;

  /// 元のプラン（互換性のため）
  Map<String, dynamic>? get originalPlan => null; // 買い切り型では不要
}
