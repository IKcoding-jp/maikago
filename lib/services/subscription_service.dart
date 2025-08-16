import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';

/// サブスクリプション管理サービス
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  SubscriptionPlan? _currentPlan = SubscriptionPlan.free;
  bool _isSubscriptionActive = false;
  DateTime? _subscriptionExpiryDate;
  String? _error;
  List<String> _familyMembers = [];
  bool _isLoading = false;

  /// 現在のプラン
  SubscriptionPlan? get currentPlan => _currentPlan;

  /// サブスクリプションが有効かどうか
  bool get isSubscriptionActive => _isSubscriptionActive;

  /// サブスクリプション有効期限
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;

  /// エラーメッセージ
  String? get error => _error;

  /// ファミリーメンバー一覧
  List<String> get familyMembers => List.unmodifiable(_familyMembers);

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// 初期化
  Future<void> initialize() async {
    await loadFromFirestore(skipNotify: true);
    await _loadFromLocalStorage();
  }

  /// Firestoreからサブスクリプション情報を読み込み
  Future<void> loadFromFirestore({bool skipNotify = false}) async {
    try {
      _setLoading(true, skipNotify: skipNotify);
      clearError(skipNotify: skipNotify);

      // 実際の実装では、ユーザーIDを取得してFirestoreからデータを読み込む
      // ここでは簡略化のため、デフォルト値を設定
      _currentPlan = SubscriptionPlan.free;
      _isSubscriptionActive = false;
      _subscriptionExpiryDate = null;
      _familyMembers = [];

      if (!skipNotify) {
        notifyListeners();
      }
    } catch (e) {
      _setError('サブスクリプション情報の読み込みに失敗しました: $e', skipNotify: skipNotify);
    } finally {
      _setLoading(false, skipNotify: skipNotify);
    }
  }

  /// ローカルストレージからサブスクリプション情報を読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      // SharedPreferencesを使用してローカルデータを読み込む
      // 実際の実装では、SharedPreferencesからデータを取得
    } catch (e) {
      debugPrint('ローカルストレージからの読み込みに失敗: $e');
    }
  }

  /// フリープランに設定
  Future<bool> setFreePlan() async {
    try {
      _setLoading(true);
      clearError();

      _currentPlan = SubscriptionPlan.free;
      _isSubscriptionActive = true;
      _subscriptionExpiryDate = null;
      _familyMembers = [];

      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('フリープランの設定に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// プランを更新
  Future<bool> updatePlan(SubscriptionPlan plan, DateTime? expiryDate) async {
    try {
      _setLoading(true);
      clearError();

      _currentPlan = plan;
      _isSubscriptionActive = true;
      _subscriptionExpiryDate = expiryDate;

      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('プランの更新に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// サブスクリプションをキャンセル
  Future<bool> cancelSubscription() async {
    try {
      _setLoading(true);
      clearError();

      // フリープランに戻す
      _currentPlan = SubscriptionPlan.free;
      _isSubscriptionActive = false;
      _subscriptionExpiryDate = null;
      _familyMembers = [];

      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('サブスクリプションのキャンセルに失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーメンバーを追加
  Future<bool> addFamilyMember(String memberId) async {
    try {
      _setLoading(true);
      clearError();

      if (_currentPlan?.isFamilyPlan != true) {
        _setError('ファミリープランではありません');
        return false;
      }

      if (_familyMembers.length >= (_currentPlan?.maxFamilyMembers ?? 0)) {
        _setError('ファミリーメンバーの上限に達しています');
        return false;
      }

      if (_familyMembers.contains(memberId)) {
        _setError('既に追加されているメンバーです');
        return false;
      }

      _familyMembers.add(memberId);
      await _saveToFirestore();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('ファミリーメンバーの追加に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーメンバーを削除
  Future<bool> removeFamilyMember(String memberId) async {
    try {
      _setLoading(true);
      clearError();

      if (_currentPlan?.isFamilyPlan != true) {
        _setError('ファミリープランではありません');
        return false;
      }

      final removed = _familyMembers.remove(memberId);
      if (!removed) {
        _setError('メンバーが見つかりません');
        return false;
      }

      await _saveToFirestore();

      notifyListeners();
      return true;
    } catch (e) {
      _setError('ファミリーメンバーの削除に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーメンバー一覧を取得
  List<String> getFamilyMembers() {
    return List.unmodifiable(_familyMembers);
  }

  /// ファミリーメンバー数を取得
  int getFamilyMemberCount() {
    return _familyMembers.length;
  }

  /// ファミリーメンバーの上限数を取得
  int getMaxFamilyMembers() {
    return _currentPlan?.maxFamilyMembers ?? 0;
  }

  /// ファミリーメンバーを追加できるかどうか
  bool canAddFamilyMember() {
    return _currentPlan?.isFamilyPlan == true &&
        _familyMembers.length < (_currentPlan?.maxFamilyMembers ?? 0);
  }

  /// リスト作成制限をチェック
  bool canCreateList(int currentListCount) {
    if (_currentPlan?.hasListLimit != true) return true;
    return currentListCount < (_currentPlan?.maxLists ?? 0);
  }

  /// タブ作成制限をチェック
  bool canCreateTab(int currentTabCount) {
    if (_currentPlan?.hasTabLimit != true) return true;
    return currentTabCount < (_currentPlan?.maxTabs ?? 0);
  }

  /// テーマカスタマイズが可能かどうか
  bool canCustomizeTheme() {
    return _currentPlan?.canCustomizeTheme == true;
  }

  /// フォントカスタマイズが可能かどうか
  bool canCustomizeFont() {
    return _currentPlan?.canCustomizeFont == true;
  }

  /// 広告を表示するかどうか
  bool shouldShowAds() {
    return _currentPlan?.showAds == true;
  }

  /// 新機能早期アクセスが可能かどうか
  bool hasEarlyAccess() {
    return _currentPlan?.hasEarlyAccess == true;
  }

  /// 購入処理（新しいUI用）
  Future<bool> purchasePlan(
    SubscriptionPlan plan, {
    DateTime? expiryDate,
  }) async {
    try {
      _setLoading(true);
      clearError();

      // プランを更新
      final success = await updatePlan(plan, expiryDate);
      if (success) {
        debugPrint('プラン購入が完了しました: ${plan.name}');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _setError('プラン購入に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 購入履歴を復元
  Future<bool> restorePurchases() async {
    try {
      _setLoading(true);
      clearError();

      // 実際の実装では、ストアから購入履歴を復元
      // ここでは簡略化のため、成功を返す
      debugPrint('購入履歴の復元を開始しました');

      // 復元処理が完了したら、現在のプランを再読み込み
      await loadFromFirestore();

      return true;
    } catch (e) {
      _setError('購入履歴の復元に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Firestoreに保存
  Future<void> _saveToFirestore() async {
    try {
      // 実際の実装では、ユーザーIDを取得してFirestoreに保存
      // ここでは簡略化のため、保存処理をスキップ
      debugPrint('Firestoreに保存: ${_currentPlan?.name ?? 'Unknown'}');
    } catch (e) {
      debugPrint('Firestoreへの保存に失敗: $e');
    }
  }

  /// ローカルストレージに保存
  Future<void> _saveToLocalStorage() async {
    try {
      // SharedPreferencesを使用してローカルデータを保存
      // 実際の実装では、SharedPreferencesにデータを保存
      debugPrint('ローカルストレージに保存: ${_currentPlan?.name ?? 'Unknown'}');
    } catch (e) {
      debugPrint('ローカルストレージへの保存に失敗: $e');
    }
  }

  /// エラーを設定
  void _setError(String error, {bool skipNotify = false}) {
    _error = error;
    if (!skipNotify) {
      notifyListeners();
    }
  }

  /// エラーをクリア
  void clearError({bool skipNotify = false}) {
    _error = null;
    if (!skipNotify) {
      notifyListeners();
    }
  }

  /// ローディング状態を設定
  void _setLoading(bool loading, {bool skipNotify = false}) {
    _isLoading = loading;
    if (!skipNotify) {
      notifyListeners();
    }
  }

  /// サブスクリプション状態をリセット
  void reset() {
    _currentPlan = SubscriptionPlan.free;
    _isSubscriptionActive = false;
    _subscriptionExpiryDate = null;
    _familyMembers = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
