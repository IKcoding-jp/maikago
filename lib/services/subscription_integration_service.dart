// サブスクリプション機能の統合サービス
import 'dart:async';
import 'package:flutter/material.dart';
import 'subscription_service.dart';
import '../models/subscription_plan.dart';
import 'debug_service.dart';

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

    // 期限切れチェックを開始
    _startExpiryCheck();

    _isInitialized = true;
    if (DebugService().enableDebugMode) {
      debugPrint('サブスクリプション統合サービス: 初期化完了');
    }
  }

  /// 期限切れチェックを開始
  void _startExpiryCheck() {
    // 1分ごとに期限切れをチェック
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkExpiry();
    });
  }

  /// 期限切れをチェック
  void _checkExpiry() {
    final expiryDate = _subscriptionService.subscriptionExpiryDate;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
      // 期限切れの場合、フリープランに変更
      if (_subscriptionService.currentPlan?.type != SubscriptionPlanType.free) {
        debugPrint('期限切れ検出: フリープランに変更');
        _subscriptionService.setFreePlan();
      }
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

  /// 特典が有効かどうか（サブスクリプション + ファミリーメンバー特典 + 解約後有効期限内）
  bool get hasBenefits {
    // ファミリーメンバー特典
    if (_subscriptionService.isFamilyBenefitsActive) {
      return true;
    }

    // 通常のサブスクリプション
    if (_subscriptionService.isSubscriptionActive) {
      return true;
    }

    // 解約後でも有効期限内の場合は特典を提供
    final expiryDate = _subscriptionService.subscriptionExpiryDate;
    if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
      final currentPlan = _subscriptionService.currentPlan;
      if (currentPlan != null &&
          currentPlan.type != SubscriptionPlanType.free) {
        return true;
      }
    }

    return false;
  }

  /// ファミリーメンバーとして特典を享受しているかどうか
  bool get isFamilyMemberWithBenefits =>
      _subscriptionService.isFamilyBenefitsActive;

  /// ファミリーオーナーかどうか
  bool get isFamilyOwner =>
      _subscriptionService.currentPlan?.isFamilyPlan == true &&
      _subscriptionService.isSubscriptionActive;

  /// 広告を非表示にするかどうか（サブスクリプションのみ）
  bool get shouldHideAds {
    final subscriptionHideAds = !_subscriptionService.shouldShowAds();

    if (DebugService().enableDebugMode) {
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

    // ファミリーメンバー特典があれば有効化（YouTubeファミリープランと同様）
    if (_subscriptionService.isFamilyBenefitsActive) {
      return true;
    }

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

    // ファミリーメンバー特典があれば有効化（YouTubeファミリープランと同様）
    if (_subscriptionService.isFamilyBenefitsActive) {
      return true;
    }

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

  /// ファミリーオーナーID
  String? get familyOwnerId => _subscriptionService.familyOwnerId;

  /// ファミリーメンバーとして参加しているかどうか
  bool get isFamilyMember => _subscriptionService.isFamilyMember;

  /// ファミリー特典が有効かどうか
  bool get isFamilyBenefitsActive =>
      _subscriptionService.isFamilyBenefitsActive;

  /// 元のプラン（ファミリー参加前のプラン）
  SubscriptionPlan? get originalPlan => _subscriptionService.originalPlan;

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
    final allow = (plan?.canCustomizeTheme == true) ||
        _subscriptionService.isFamilyBenefitsActive;
    return allow ? 10 : 1; // 暫定的に10個として設定
  }

  /// 利用可能なフォント数
  int get availableFonts {
    final plan = _subscriptionService.currentPlan;
    final allow = (plan?.canCustomizeFont == true) ||
        _subscriptionService.isFamilyBenefitsActive;
    return allow ? 5 : 1; // 暫定的に5個として設定
  }

  // === 機能判定メソッド ===

  /// タブ作成が可能かどうか
  bool canCreateList(int currentListCount) {
    final plan = _subscriptionService.currentPlan;

    // ファミリーメンバー特典があれば無制限（YouTubeファミリープランと同様）
    if (_subscriptionService.isFamilyBenefitsActive) {
      return true;
    }

    if (plan == null) return currentListCount < 10; // フリープランのデフォルト制限

    return _subscriptionService.canCreateList(currentListCount);
  }

  /// タブ作成が可能かどうか
  bool canCreateTab(int currentTabCount) {
    final plan = _subscriptionService.currentPlan;

    // ファミリーメンバー特典があれば無制限（YouTubeファミリープランと同様）
    if (_subscriptionService.isFamilyBenefitsActive) {
      return true;
    }

    if (plan == null) return currentTabCount < 3; // フリープランのデフォルト制限

    return _subscriptionService.canCreateTab(currentTabCount);
  }

  /// アイテム追加が可能かどうか
  bool canAddItemToList(int currentItemCount) {
    final plan = _subscriptionService.currentPlan;

    // ファミリーメンバー特典があれば無制限（YouTubeファミリープランと同様）
    if (_subscriptionService.isFamilyBenefitsActive) {
      return true;
    }

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
    if (DebugService().enableDebugMode) {
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
    if (DebugService().enableDebugMode) {
      debugPrint('=== SubscriptionIntegrationService デバッグ情報 ===');
      debugPrint('初期化完了: $_isInitialized');
      debugPrint('特典有効: $hasBenefits');
      debugPrint('広告非表示: $shouldHideAds');
      debugPrint('テーマ変更可能: $canChangeTheme');
      debugPrint('フォント変更可能: $canChangeFont');
      debugPrint('サブスクリプション有効: $isSubscriptionActive');
      debugPrint('現在のプラン: ${currentPlan?.name ?? 'free'}');
      debugPrint('ファミリーメンバー: $isFamilyMember');
      debugPrint('ファミリー特典有効: $isFamilyBenefitsActive');
      debugPrint('ファミリーオーナー: $isFamilyOwner');
      debugPrint('ファミリーオーナーID: $familyOwnerId');
      debugPrint('ファミリーメンバー数: ${familyMembers.length}');
      debugPrint('元のプラン: ${originalPlan?.name ?? 'なし'}');
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
