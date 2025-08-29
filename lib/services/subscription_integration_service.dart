// サブスクリプション機能の統合サービス
import 'package:flutter/material.dart';
import 'subscription_service.dart';
import '../config.dart';
import '../models/subscription_plan.dart';
import '../providers/transmission_provider.dart';

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
  TransmissionProvider? _transmissionProvider;
  bool _isInitialized = false;
  bool _notifyScheduled = false;

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
    _scheduleNotify();
  }

  /// 現在のユーザーIDを設定
  void setCurrentUserId(String? userId) {
    // SubscriptionServiceは自動でユーザー認証状態を監視するため不要
  }

  /// TransmissionProviderを設定
  void setTransmissionProvider(TransmissionProvider provider) {
    // 既に同じProviderが設定されている場合は何もしない
    if (_transmissionProvider == provider) {
      return;
    }

    // 以前のリスナーを解除
    _transmissionProvider?.removeListener(_onTransmissionChanged);

    _transmissionProvider = provider;
    // TransmissionProviderの変更を監視
    _transmissionProvider!.addListener(_onTransmissionChanged);
    _scheduleNotify();
  }

  /// TransmissionProvider変更時の処理
  void _onTransmissionChanged() {
    _scheduleNotify();
  }

  /// ビルド中の更新例外を避けるため、次フレームで通知を行う
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      // リスナーがいない場合は何もしない
      if (!hasListeners) return;
      notifyListeners();
    });
  }

  // === 基本プロパティ ===

  /// 特典が有効かどうか（サブスクリプション + ファミリー参加）
  bool get hasBenefits {
    // ファミリーグループに参加している場合は特典有効
    if (_transmissionProvider?.isFamilyMember == true) {
      return true;
    }
    // サブスクリプションが有効な場合も特典有効
    return _subscriptionService.isSubscriptionActive;
  }

  /// 広告を非表示にするかどうか（サブスクリプション + ファミリー参加）
  bool get shouldHideAds {
    // ファミリーグループに参加している場合は広告非表示
    if (_transmissionProvider?.isFamilyMember == true) {
      if (enableDebugMode) {
        debugPrint('=== 広告制御デバッグ情報 ===');
        debugPrint('ファミリー参加による広告非表示: true');
        debugPrint('最終的な広告非表示判定: true');
        debugPrint('========================');
      }
      return true;
    }

    final subscriptionHideAds = !_subscriptionService.shouldShowAds();

    if (enableDebugMode) {
      debugPrint('=== 広告制御デバッグ情報 ===');
      debugPrint('サブスクリプションによる広告非表示: $subscriptionHideAds');
      debugPrint('ファミリー参加: ${_transmissionProvider?.isFamilyMember ?? false}');
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
    if (plan == null) return 15; // フリープランのデフォルト制限
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
    // ファミリーグループに参加している場合は利用可能
    if (_transmissionProvider?.isFamilyMember == true) {
      return true;
    }
    // ファミリープランのサブスクリプションが有効な場合も利用可能
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
    if (plan == null) return currentListCount < 15; // フリープランのデフォルト制限

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

  /// ファミリー共有機能が利用可能かどうか（グループ作成権限）
  bool canUseFamilySharing() {
    // ファミリーグループに参加している場合は利用可能（ただしグループ作成はオーナーのみ）
    if (_transmissionProvider?.isFamilyMember == true) {
      return true;
    }
    // ファミリープランのみがグループ作成可能
    final plan = _subscriptionService.currentPlan;
    return plan?.isFamilyPlan == true &&
        _subscriptionService.isSubscriptionActive;
  }

  /// ファミリー共有機能の制限メッセージを取得
  String getFamilySharingLimitMessage() {
    final plan = _subscriptionService.currentPlan;
    if (plan == null || plan.type == SubscriptionPlanType.free) {
      return 'ファミリー共有機能はフリープランでは利用できません。\nファミリープランに加入している人のグループに参加するか、ファミリープランにアップグレードしてください。';
    }
    if (!plan.isFamilyPlan) {
      return 'ファミリー共有機能はファミリープランのみで利用できます。\nファミリープランに加入している人のグループに参加するか、ファミリープランにアップグレードしてください。';
    }
    return '';
  }

  /// ファミリーグループに参加可能かどうか
  bool canJoinFamilyGroup() {
    // どのプランでもファミリーグループに参加可能
    return true;
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
    _transmissionProvider?.removeListener(_onTransmissionChanged);
    super.dispose();
  }
}
