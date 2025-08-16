// サブスクリプションと寄付機能の統合サービス
import 'package:flutter/material.dart';
import 'donation_manager.dart';
import 'subscription_service.dart';
import 'in_app_purchase_service.dart';
import '../config.dart';
import '../models/subscription_plan.dart';

/// サブスクリプションと寄付機能を統合するサービス。
/// - 既存のDonationManagerとの互換性を保持
/// - 新しいサブスクリプション機能を提供
/// - 段階的な移行を可能にする設計
class SubscriptionIntegrationService extends ChangeNotifier {
  static final SubscriptionIntegrationService _instance =
      SubscriptionIntegrationService._internal();
  factory SubscriptionIntegrationService() => _instance;
  SubscriptionIntegrationService._internal() {
    _initialize();
  }

  late final DonationManager _donationManager;
  late final SubscriptionService _subscriptionService;
  bool _isInitialized = false;

  /// 初期化完了フラグ
  bool get isInitialized => _isInitialized;

  /// 初期化処理
  void _initialize() {
    _donationManager = DonationManager();
    _subscriptionService = SubscriptionService();

    // 両方のマネージャーの変更を監視
    _donationManager.addListener(_onStateChanged);
    _subscriptionService.addListener(_onStateChanged);

    _isInitialized = true;
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: 初期化完了');
    }
  }

  /// 状態変更時の処理
  void _onStateChanged() {
    notifyListeners();
  }

  /// 現在のユーザーIDを設定
  void setCurrentUserId(String? userId) {
    _donationManager.setCurrentUserId(userId);
    // SubscriptionServiceは自動でユーザー認証状態を監視するため不要
  }

  // === 互換性プロパティ（DonationManagerとの互換性を保持） ===

  /// 特典が有効かどうか（寄付またはサブスクリプション）
  bool get hasBenefits =>
      _donationManager.hasBenefits || _subscriptionService.isSubscriptionActive;

  /// 広告を非表示にするかどうか
  bool get shouldHideAds =>
      _donationManager.shouldHideAds || !_subscriptionService.shouldShowAds();

  /// 広告を表示するかどうか
  bool get shouldShowAds => !shouldHideAds;

  /// テーマ変更機能が利用可能かどうか
  bool get canChangeTheme =>
      _donationManager.canChangeTheme || _subscriptionService.canCustomizeTheme();

  /// フォント変更機能が利用可能かどうか
  bool get canChangeFont =>
      _donationManager.canChangeFont || _subscriptionService.canCustomizeFont();

  /// 寄付済みかどうか（既存機能との互換性）
  bool get isDonated => _donationManager.isDonated;

  /// 総寄付金額（既存機能との互換性）
  int get totalDonationAmount => _donationManager.totalDonationAmount;

  /// 寄付者称号を取得（既存機能との互換性）
  String get donorTitle => _donationManager.donorTitle;

  /// 称号の色を取得（既存機能との互換性）
  Color get donorTitleColor => _donationManager.donorTitleColor;

  /// 称号アイコンを取得（既存機能との互換性）
  IconData get donorTitleIcon => _donationManager.donorTitleIcon;

  // === サブスクリプション固有プロパティ ===

  /// 現在のサブスクリプションプラン
  SubscriptionPlan? get currentPlan => _subscriptionService.currentPlan;

  /// サブスクリプションが有効かどうか
  bool get isSubscriptionActive => _subscriptionService.isSubscriptionActive;

  /// サブスクリプションの期限
  DateTime? get subscriptionExpiry => _subscriptionService.subscriptionExpiryDate;

  /// サブスクリプションが期限切れかどうか
  bool get isSubscriptionExpired {
    final expiry = _subscriptionService.subscriptionExpiryDate;
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// ファミリーメンバーリスト
  List<String> get familyMembers => _subscriptionService.familyMembers;

  /// 復元処理中かどうか
  bool get isRestoring => _donationManager.isRestoring || _subscriptionService.isLoading;

  /// 最大リスト数
  int get maxLists {
    final plan = _subscriptionService.currentPlan;
    if (plan == null) return 10; // フリープランのデフォルト制限
    return plan.maxLists;
  }

  /// 最大アイテム数（商品アイテム制限）
  int get maxItemsPerList {
    final plan = _subscriptionService.currentPlan;
    if (plan == null) return 50; // フリープランのデフォルト制限
    return plan.maxLists; // 暫定的にmaxListsと同じ値を使用
  }

  /// 現在のプラン名
  String get currentPlanName {
    final plan = _subscriptionService.currentPlan;
    return plan?.name ?? 'フリープラン';
  }

  /// 無料トライアルが有効かどうか
  bool get isTrialActive => false; // SubscriptionServiceにはトライアル機能がないため暫定的にfalse

  /// 無料トライアルの残り日数
  int get trialRemainingDays => 0; // SubscriptionServiceにはトライアル機能がないため0

  /// ファミリー共有が有効かどうか
  bool get hasFamilySharing {
    final plan = _subscriptionService.currentPlan;
    return plan?.isFamilyPlan == true && _subscriptionService.isSubscriptionActive;
  }

  /// 最大ファミリーメンバー数
  int get maxFamilyMembers {
    final plan = _subscriptionService.currentPlan;
    return plan?.maxFamilyMembers ?? 0;
  }

  /// 利用可能なテーマ数
  int get availableThemes {
    final plan = _subscriptionService.currentPlan;
    return plan?.canCustomizeTheme == true ? 10 : 1; // 暫定的に10個として設定
  }

  /// 利用可能なフォント数
  int get availableFonts {
    final plan = _subscriptionService.currentPlan;
    return plan?.canCustomizeFont == true ? 5 : 1; // 暫定的に5個として設定
  }

  // === 機能判定メソッド ===

  /// リスト作成が可能かどうか
  bool canCreateList(int currentListCount) {
    final plan = _subscriptionService.currentPlan;
    if (plan == null) return currentListCount < 10; // フリープランのデフォルト制限
    
    return _subscriptionService.canCreateList(currentListCount);
  }

  /// タブ作成が可能かどうか
  bool canCreateTab(int currentTabCount) {
    final plan = _subscriptionService.currentPlan;
    if (plan == null) return currentTabCount < 3; // フリープランのデフォルト制限
    
    return _subscriptionService.canCreateTab(currentTabCount);
  }

  /// アイテム追加が可能かどうか
  bool canAddItemToList(int currentItemCount) {
    final plan = _subscriptionService.currentPlan;
    if (plan == null) return currentItemCount < 50; // フリープランのデフォルト制限
    
    // 無制限の場合は常にtrue
    if (plan.maxLists == -1) return true;
    
    return currentItemCount < maxItemsPerList;
  }

  /// 指定したテーマが利用可能かどうか
  bool isThemeAvailable(int themeIndex) {
    return themeIndex < availableThemes;
  }

  /// 指定したフォントが利用可能かどうか
  bool isFontAvailable(int fontIndex) {
    return fontIndex < availableFonts;
  }

  /// 無料トライアルを開始
  Future<void> startFreeTrial() async {
    // SubscriptionServiceには無料トライアル機能がないため、暫定的にベーシックプランを30日間設定
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _subscriptionService.updatePlan(SubscriptionPlan.basic, expiry);
  }

  // === 既存機能との互換性メソッド ===

  /// 寄付処理を実行（既存機能との互換性）
  Future<void> processDonation(int amount) async {
    await _donationManager.processDonation(amount);
  }

  /// 寄付状態を復元（既存機能との互換性）
  Future<void> restoreDonationStatus() async {
    await _donationManager.restoreDonationStatus();
  }

  /// 寄付状態をリセット（既存機能との互換性）
  Future<void> resetDonationStatus() async {
    await _donationManager.resetDonationStatus();
  }

  // === サブスクリプション機能メソッド ===

  /// サブスクリプション処理を実行
  Future<void> processSubscription(
    SubscriptionPlan plan, {
    DateTime? expiry,
  }) async {
    await _subscriptionService.updatePlan(plan, expiry);
  }

  /// サブスクリプション状態を復元
  Future<void> restoreSubscriptionStatus() async {
    try {
      if (enableDebugMode) {
        debugPrint('SubscriptionIntegrationService: サブスクリプション状態復元を開始');
      }

      // InAppPurchaseServiceを使用して購入履歴を復元
      final purchaseService = InAppPurchaseService();
      await purchaseService.restorePurchases();

      // SubscriptionServiceの状態を再読み込み
      await _subscriptionService.loadFromFirestore();

      if (enableDebugMode) {
        debugPrint('SubscriptionIntegrationService: サブスクリプション状態復元が完了');
      }
    } catch (e) {
      if (enableDebugMode) {
        debugPrint('SubscriptionIntegrationService: サブスクリプション状態復元エラー: $e');
      }
    }
  }

  // === 移行関連機能 ===

  /// 既存寄付者かどうか
  bool get isLegacyDonor => _donationManager.isLegacyDonor;

  /// 移行完了フラグ
  bool get migrationCompleted => _donationManager.migrationCompleted;

  /// 新規ユーザーかどうか
  bool get isNewUser => _donationManager.isNewUser;

  /// サブスクリプション移行を推奨するかどうか
  bool get shouldRecommendSubscription =>
      _donationManager.shouldRecommendSubscription;

  /// 移行状態を取得
  Map<String, dynamic> getMigrationStatus() {
    return {
      'isLegacyDonor': _donationManager.isLegacyDonor,
      'migrationCompleted': _donationManager.migrationCompleted,
      'isNewUser': _donationManager.isNewUser,
      'shouldRecommendSubscription': _donationManager.shouldRecommendSubscription,
      'currentPlan': _subscriptionService.currentPlan?.toString() ?? 'free',
      'hasSubscription': _subscriptionService.isSubscriptionActive,
      'hasDonationBenefits': _donationManager.hasBenefits,
    };
  }

  /// 移行推奨メッセージを取得
  String getMigrationRecommendationMessage() {
    if (_donationManager.isNewUser) {
      return 'サブスクリプションでより多くの機能をお楽しみください';
    } else if (_donationManager.shouldRecommendSubscription) {
      return 'サブスクリプションに移行して特典を継続しましょう';
    } else if (_donationManager.isLegacyDonor) {
      return '既存の寄付特典が引き続き有効です';
    } else {
      return '現在のプランでアプリをお楽しみください';
    }
  }

  /// 推奨プランを取得
  SubscriptionPlan getRecommendedPlan() {
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

  /// 移行完了処理
  Future<void> completeMigration() async {
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: 移行完了処理を実行');
    }

    // 移行完了フラグを設定
    await _donationManager.setAsLegacyDonor();

    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: 移行完了処理が完了しました');
    }
  }

  /// プラン情報を取得
  Map<String, dynamic> getPlanInfo(SubscriptionPlan plan) {
    return {
      'name': plan.name,
      'description': plan.description,
      'monthlyPrice': plan.monthlyPrice,
      'yearlyPrice': plan.yearlyPrice,
      'maxLists': plan.maxLists,
      'maxTabs': plan.maxTabs,
      'showAds': plan.showAds,
      'canCustomizeTheme': plan.canCustomizeTheme,
      'canCustomizeFont': plan.canCustomizeFont,
      'isFamilyPlan': plan.isFamilyPlan,
      'maxFamilyMembers': plan.maxFamilyMembers,
    };
  }

  /// 新規ユーザー設定
  Future<void> setAsNewUser() async {
    await _donationManager.setAsNewUser();
  }

  /// 既存寄付者設定
  Future<void> setAsLegacyDonor() async {
    await _donationManager.setAsLegacyDonor();
  }

  // === デバッグ機能 ===

  /// 現在の状態をデバッグ出力
  void debugPrintStatus() {
    if (enableDebugMode) {
      debugPrint('=== SubscriptionIntegrationService デバッグ情報 ===');
      debugPrint('初期化完了: $_isInitialized');
      debugPrint('特典有効: $hasBenefits');
      debugPrint('広告非表示: $shouldHideAds');
      debugPrint('テーマ変更可能: $canChangeTheme');
      debugPrint('フォント変更可能: $canChangeFont');
      debugPrint('寄付済み: $isDonated');
      debugPrint('サブスクリプション有効: $isSubscriptionActive');
      debugPrint('現在のプラン: ${currentPlan?.name ?? 'free'}');
      debugPrint('--- 移行関連 ---');
      debugPrint('既存寄付者: $isLegacyDonor');
      debugPrint('移行完了: $migrationCompleted');
      debugPrint('新規ユーザー: $isNewUser');
      debugPrint('サブスクリプション推奨: $shouldRecommendSubscription');
      debugPrint('========================');

      _donationManager.debugPrintDonationStatus();
      _subscriptionService.debugPrintStatus();
    }
  }

  /// サービスを破棄
  @override
  void dispose() {
    _donationManager.removeListener(_onStateChanged);
    _subscriptionService.removeListener(_onStateChanged);
    super.dispose();
  }
}