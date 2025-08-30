// サブスクリプション機能の統合サービス
import 'package:flutter/material.dart';
import 'subscription_service.dart';
import '../config.dart';
import '../models/subscription_plan.dart';

/// サブスクリプション機能を統合するサービス。
/// - サブスクリプション機能を提供
/// - 機能制限の管理
class SubscriptionIntegrationService extends ChangeNotifier {
  static final SubscriptionIntegrationService _instance =
      SubscriptionIntegrationService._internal();
  factory SubscriptionIntegrationService() => _instance;
  SubscriptionIntegrationService._internal() {
    _initialize();
  }

  late final SubscriptionService _subscriptionService;
  bool _isInitialized = false;

  /// 初期化完了フラグ
  bool get isInitialized => _isInitialized;

  /// 初期化処理
  void _initialize() {
    _subscriptionService = SubscriptionService();

    // サブスクリプションサービスの変更を監視
    _subscriptionService.addListener(_onStateChanged);

    _isInitialized = true;
    if (enableDebugMode) {
      debugPrint('サブスクリプション統合サービス: 初期化完了');
    }
  }

  /// 状態変更時の処理
  void _onStateChanged() {
    notifyListeners();
  }

  /// 現在のユーザーIDを設定
  void setCurrentUserId(String? userId) {
    // SubscriptionServiceは自動でユーザー認証状態を監視するため不要
  }

  // === 基本プロパティ ===

  /// 特典が有効かどうか（サブスクリプション）
  bool get hasBenefits => _subscriptionService.isSubscriptionActive;

  /// 広告を非表示にするかどうか（サブスクリプションのみ）
  bool get shouldHideAds {
    final subscriptionHideAds = !_subscriptionService.shouldShowAds();

    if (enableDebugMode) {
      debugPrint('=== 広告制御デバッグ情報 ===');
      debugPrint('サブスクリプションによる広告非表示: $subscriptionHideAds');
      debugPrint('最終的な広告非表示判定: $subscriptionHideAds');
      debugPrint(
        '現在のプラン: ${_subscriptionService.currentPlan?.name ?? 'フリープラン'}',
      );
      debugPrint('サブスクリプション有効: ${_subscriptionService.isSubscriptionActive}');
      debugPrint('プランのshowAds設定: ${_subscriptionService.currentPlan?.showAds}');
      debugPrint(
        'SubscriptionService.shouldShowAds(): ${_subscriptionService.shouldShowAds()}',
      );
      debugPrint('========================');
    }

    return subscriptionHideAds;
  }

  /// 広告を表示するかどうか
  bool get shouldShowAds => !shouldHideAds;

  /// テーマ変更機能が利用可能かどうか
  bool get canChangeTheme {
    final plan = _subscriptionService.currentPlan;
    // フリープランとベーシックプランでは制限
    if (plan == null ||
        plan.type == SubscriptionPlanType.free ||
        plan.type == SubscriptionPlanType.basic) {
      return false;
    }
    // プレミアムとファミリープランのみ利用可能
    return plan.canCustomizeTheme;
  }

  /// フォント変更機能が利用可能かどうか
  bool get canChangeFont {
    final plan = _subscriptionService.currentPlan;
    // フリープランとベーシックプランでは制限
    if (plan == null ||
        plan.type == SubscriptionPlanType.free ||
        plan.type == SubscriptionPlanType.basic) {
      return false;
    }
    // プレミアムとファミリープランのみ利用可能
    return plan.canCustomizeFont;
  }

  // === サブスクリプション固有プロパティ ===

  /// 現在のサブスクリプションプラン
  SubscriptionPlan? get currentPlan => _subscriptionService.currentPlan;

  /// サブスクリプションが有効かどうか
  bool get isSubscriptionActive => _subscriptionService.isSubscriptionActive;

  /// サブスクリプションの期限
  DateTime? get subscriptionExpiry =>
      _subscriptionService.subscriptionExpiryDate;

  /// サブスクリプションが期限切れかどうか
  bool get isSubscriptionExpired {
    final expiry = _subscriptionService.subscriptionExpiryDate;
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// ファミリーメンバーリスト
  List<String> get familyMembers => _subscriptionService.familyMembers;

  /// 復元処理中かどうか
  bool get isRestoring => _subscriptionService.isLoading;

  /// 最大タブ数
  int get maxLists {
    final plan = _subscriptionService.currentPlan;
    if (plan == null) return 10; // フリープランのデフォルト制限
    return plan.maxLists;
  }

  /// 最大アイテム数（リストアイテム制限）
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
    return plan?.isFamilyPlan == true &&
        _subscriptionService.isSubscriptionActive;
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

  /// タブ作成が可能かどうか
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

  // === サブスクリプション機能メソッド ===

  /// サブスクリプション処理を実行
  Future<void> processSubscription(
    SubscriptionPlan plan, {
    DateTime? expiry,
  }) async {
    await _subscriptionService.updatePlan(plan, expiry);
  }

  /// サブスクリプション状態を復元（無効化）
  Future<void> restoreSubscriptionStatus() async {
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: サブスクリプション状態復元は無効化されています');
    }
  }

  // === プラン情報取得 ===

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
      debugPrint('サブスクリプション有効: $isSubscriptionActive');
      debugPrint('現在のプラン: ${currentPlan?.name ?? 'free'}');
      debugPrint('========================');

      _subscriptionService.debugPrintStatus();
    }
  }

  /// サービスを破棄
  @override
  void dispose() {
    _subscriptionService.removeListener(_onStateChanged);
    super.dispose();
  }
}
