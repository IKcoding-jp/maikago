// サブスクリプションと寄付機能の統合サービス
import 'package:flutter/material.dart';
import 'donation_manager.dart';
import 'subscription_manager.dart';
import '../config.dart';

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
  late final SubscriptionManager _subscriptionManager;
  bool _isInitialized = false;

  /// 初期化完了フラグ
  bool get isInitialized => _isInitialized;

  /// 初期化処理
  void _initialize() {
    _donationManager = DonationManager();
    _subscriptionManager = SubscriptionManager();

    // 両方のマネージャーの変更を監視
    _donationManager.addListener(_onStateChanged);
    _subscriptionManager.addListener(_onStateChanged);

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
    _subscriptionManager.setCurrentUserId(userId);
  }

  // === 互換性プロパティ（DonationManagerとの互換性を保持） ===

  /// 特典が有効かどうか（寄付またはサブスクリプション）
  bool get hasBenefits =>
      _donationManager.hasBenefits || _subscriptionManager.hasBenefits;

  /// 広告を非表示にするかどうか
  bool get shouldHideAds =>
      _donationManager.shouldHideAds || _subscriptionManager.shouldHideAds;

  /// 広告を表示するかどうか
  bool get shouldShowAds => !shouldHideAds;

  /// テーマ変更機能が利用可能かどうか
  bool get canChangeTheme =>
      _donationManager.canChangeTheme || _subscriptionManager.canChangeTheme;

  /// フォント変更機能が利用可能かどうか
  bool get canChangeFont =>
      _donationManager.canChangeFont || _subscriptionManager.canChangeFont;

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
  SubscriptionPlan get currentPlan => _subscriptionManager.currentPlan;

  /// 現在のプラン名
  String get currentPlanName => _subscriptionManager.currentPlanName;

  /// 現在のプラン価格
  int get currentPlanPrice => _subscriptionManager.currentPlanPrice;

  /// サブスクリプションが有効かどうか
  bool get isSubscriptionActive => _subscriptionManager.isActive;

  /// サブスクリプションの期限
  DateTime? get subscriptionExpiry => _subscriptionManager.subscriptionExpiry;

  /// サブスクリプションが期限切れかどうか
  bool get isSubscriptionExpired {
    final expiry = _subscriptionManager.subscriptionExpiry;
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  // === 無料トライアル関連プロパティ ===

  /// 無料トライアルが利用可能かどうか
  bool get canUseTrial => _subscriptionManager.canUseTrial;

  /// 無料トライアルが有効かどうか
  bool get isTrialActive => _subscriptionManager.isTrialActive;

  /// 無料トライアルの残り日数
  int get trialRemainingDays => _subscriptionManager.trialRemainingDays;

  /// 無料トライアルの開始日
  DateTime? get trialStartDate => _subscriptionManager.trialStartDate;

  /// 無料トライアルの終了日
  DateTime? get trialEndDate => _subscriptionManager.trialEndDate;

  /// 無料トライアルが使用済みかどうか
  bool get trialUsed => _subscriptionManager.trialUsed;

  /// 最大リスト数
  int get maxLists => _subscriptionManager.maxLists;

  /// 各リスト内の最大商品アイテム数
  int get maxItemsPerList => _subscriptionManager.maxItemsPerList;

  /// 家族メンバーリスト
  List<String> get familyMembers => _subscriptionManager.familyMembers;

  /// 家族共有が有効かどうか
  bool get hasFamilySharing => _subscriptionManager.familySharing;

  /// 最大家族メンバー数
  int get maxFamilyMembers => _subscriptionManager.maxFamilyMembers;

  /// 利用可能なテーマ数
  int get availableThemes => _subscriptionManager.themes;

  /// 利用可能なフォント数
  int get availableFonts => _subscriptionManager.fonts;

  /// 復元処理中かどうか
  bool get isRestoring =>
      _donationManager.isRestoring || _subscriptionManager.isRestoring;

  // === 機能判定メソッド ===

  /// リスト作成が可能かどうか
  bool canCreateList(int currentListCount) {
    if (_subscriptionManager.maxLists == -1) return true; // 無制限
    return currentListCount < _subscriptionManager.maxLists;
  }

  /// 商品アイテム追加が可能かどうか
  bool canAddItemToList(int currentItemCount) {
    if (_subscriptionManager.maxItemsPerList == -1) return true; // 無制限
    return currentItemCount < _subscriptionManager.maxItemsPerList;
  }

  /// テーマが利用可能かどうか
  bool isThemeAvailable(int themeIndex) {
    if (_subscriptionManager.themes == -1) {
      return true; // サブスクリプションで全テーマ利用可能
    }
    return themeIndex < _subscriptionManager.themes;
  }

  /// フォントが利用可能かどうか
  bool isFontAvailable(int fontIndex) {
    if (_subscriptionManager.fonts == -1) {
      return true; // サブスクリプションで全フォント利用可能
    }
    return fontIndex < _subscriptionManager.fonts;
  }

  /// 家族メンバーを追加可能かどうか
  bool canAddFamilyMember() {
    return _subscriptionManager.familySharing &&
        _subscriptionManager.familyMembers.length <
            _subscriptionManager.maxFamilyMembers;
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
    await _subscriptionManager.processSubscription(plan, expiry: expiry);
  }

  /// 無料トライアルを開始
  Future<void> startFreeTrial() async {
    await _subscriptionManager.startFreeTrial();
  }

  /// サブスクリプション状態を復元（未実装）
  Future<void> restoreSubscriptionStatus() async {
    // TODO: 実装予定
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: サブスクリプション状態復元は未実装です');
    }
  }

  /// サブスクリプション状態をリセット（未実装）
  Future<void> resetSubscriptionStatus() async {
    // TODO: 実装予定
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: サブスクリプション状態リセットは未実装です');
    }
  }

  /// 家族メンバーを追加
  Future<void> addFamilyMember(String memberEmail) async {
    await _subscriptionManager.addFamilyMember(memberEmail);
  }

  /// 家族メンバーを削除
  Future<void> removeFamilyMember(String memberEmail) async {
    await _subscriptionManager.removeFamilyMember(memberEmail);
  }

  /// プラン情報を取得（未実装）
  Map<String, dynamic> getPlanInfo(SubscriptionPlan plan) {
    // TODO: 実装予定
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: プラン情報取得は未実装です');
    }
    return {};
  }

  /// 全プラン情報を取得（未実装）
  Map<SubscriptionPlan, Map<String, dynamic>> getAllPlans() {
    // TODO: 実装予定
    if (enableDebugMode) {
      debugPrint('SubscriptionIntegrationService: 全プラン情報取得は未実装です');
    }
    return {};
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
      'shouldRecommendSubscription':
          _donationManager.shouldRecommendSubscription,
      'currentPlan': _subscriptionManager.currentPlan.toString(),
      'hasSubscription': _subscriptionManager.isActive,
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
    if (_subscriptionManager.currentPlan == SubscriptionPlan.free) {
      return SubscriptionPlan.basic;
    } else if (_subscriptionManager.currentPlan == SubscriptionPlan.basic) {
      return SubscriptionPlan.premium;
    } else if (_subscriptionManager.currentPlan == SubscriptionPlan.premium) {
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
      debugPrint('現在のプラン: $currentPlanName');
      debugPrint('最大リスト数: $maxLists');
      debugPrint('--- 移行関連 ---');
      debugPrint('既存寄付者: $isLegacyDonor');
      debugPrint('移行完了: $migrationCompleted');
      debugPrint('新規ユーザー: $isNewUser');
      debugPrint('サブスクリプション推奨: $shouldRecommendSubscription');
      debugPrint('========================');

      _donationManager.debugPrintDonationStatus();
      // _subscriptionManager.debugPrintSubscriptionStatus(); // 未実装のためコメントアウト
    }
  }

  /// サービスを破棄
  @override
  void dispose() {
    _donationManager.removeListener(_onStateChanged);
    _subscriptionManager.removeListener(_onStateChanged);
    super.dispose();
  }
}
