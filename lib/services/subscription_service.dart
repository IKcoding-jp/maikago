import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/subscription_plan.dart';

/// サブスクリプション管理サービス
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _subscriptionListener;

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

  /// Firebaseが利用可能かチェック
  bool get _isFirebaseAvailable {
    try {
      return _auth.currentUser != null;
    } catch (e) {
      debugPrint('Firebase利用不可: $e');
      return false;
    }
  }

  /// ユーザーのサブスクリプション情報ドキュメント参照
  DocumentReference<Map<String, dynamic>>? get _subscriptionDoc {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('subscription')
        .doc('current');
  }

  /// 初期化
  Future<void> initialize() async {
    debugPrint('SubscriptionService初期化開始');

    // 認証状態の変更を監視
    _auth.authStateChanges().listen((User? user) async {
      debugPrint('認証状態変更: ${user?.uid ?? 'ログアウト'}');
      if (user != null) {
        // ユーザーがログインした場合、Firestoreからデータを読み込み
        await loadFromFirestore();
        // リアルタイムリスナーを開始
        _startSubscriptionListener();
      } else {
        // ユーザーがログアウトした場合、リスナーを停止してローカルストレージから読み込み
        _stopSubscriptionListener();
        await _loadFromLocalStorage();
        notifyListeners();
      }
    });

    // 初期データ読み込み
    debugPrint('初期データ読み込み開始');
    await _loadFromLocalStorage();
    await loadFromFirestore(skipNotify: true);
    debugPrint('SubscriptionService初期化完了: ${_currentPlan?.name}');
  }

  /// サブスクリプション情報のリアルタイムリスナーを開始
  void _startSubscriptionListener() {
    if (!_isFirebaseAvailable) return;

    final docRef = _subscriptionDoc;
    if (docRef == null) return;

    _stopSubscriptionListener(); // 既存のリスナーを停止

    _subscriptionListener = docRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          _currentPlan = _parseSubscriptionPlan(data['planType'] as String?);
          _isSubscriptionActive = data['isActive'] as bool? ?? false;
          _subscriptionExpiryDate = data['expiryDate'] != null
              ? (data['expiryDate'] as Timestamp).toDate()
              : null;
          _familyMembers = List<String>.from(data['familyMembers'] ?? []);

          debugPrint('リアルタイム更新: ${_currentPlan?.name}');
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('サブスクリプションリスナーエラー: $error');
      },
    );
  }

  /// サブスクリプション情報のリアルタイムリスナーを停止
  void _stopSubscriptionListener() {
    _subscriptionListener?.cancel();
    _subscriptionListener = null;
  }

  /// Firestoreからサブスクリプション情報を読み込み
  Future<void> loadFromFirestore({bool skipNotify = false}) async {
    try {
      debugPrint('loadFromFirestore開始: Firebase利用可能=${_isFirebaseAvailable}');
      _setLoading(true, skipNotify: skipNotify);
      clearError(skipNotify: skipNotify);

      if (!_isFirebaseAvailable) {
        debugPrint('Firebase利用不可のためローカルデータを保持');
        if (!skipNotify) {
          notifyListeners();
        }
        return;
      }

      final docRef = _subscriptionDoc;
      if (docRef == null) {
        debugPrint('ユーザーがログインしていないためローカルデータを保持');
        if (!skipNotify) {
          notifyListeners();
        }
        return;
      }

      final doc = await docRef.get();
      debugPrint('Firestoreドキュメント取得: 存在=${doc.exists}');
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('Firestoreデータ: $data');
        _currentPlan = _parseSubscriptionPlan(data['planType'] as String?);
        _isSubscriptionActive = data['isActive'] as bool? ?? false;
        _subscriptionExpiryDate = data['expiryDate'] != null
            ? (data['expiryDate'] as Timestamp).toDate()
            : null;
        _familyMembers = List<String>.from(data['familyMembers'] ?? []);

        debugPrint('Firestoreから読み込み完了: ${_currentPlan?.name}');
      } else {
        // ドキュメントが存在しない場合は、現在のローカルデータを保持
        // フリープランにリセットしない
        debugPrint('Firestoreにドキュメントが存在しないが、ローカルデータを保持');
      }

      if (!skipNotify) {
        notifyListeners();
      }
    } catch (e) {
      _setError('サブスクリプション情報の読み込みに失敗しました: $e', skipNotify: skipNotify);
      // エラー時はローカルデータを保持
      debugPrint('Firestore読み込みエラー時はローカルデータを保持');
      if (!skipNotify) {
        notifyListeners();
      }
    } finally {
      _setLoading(false, skipNotify: skipNotify);
    }
  }

  /// ローカルストレージからサブスクリプション情報を読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      debugPrint('ローカルストレージ読み込み開始');
      final prefs = await SharedPreferences.getInstance();
      final planType = prefs.getString('subscription_plan_type');
      final isActive = prefs.getBool('subscription_is_active') ?? false;
      final expiryDateMs = prefs.getInt('subscription_expiry_date');
      final familyMembers =
          prefs.getStringList('subscription_family_members') ?? [];

      debugPrint(
        'ローカルストレージデータ: planType=$planType, isActive=$isActive, expiryDateMs=$expiryDateMs, familyMembers=$familyMembers',
      );

      if (planType != null) {
        _currentPlan = _parseSubscriptionPlan(planType);
        _isSubscriptionActive = isActive;
        _subscriptionExpiryDate = expiryDateMs != null
            ? DateTime.fromMillisecondsSinceEpoch(expiryDateMs)
            : null;
        _familyMembers = familyMembers;
        debugPrint('ローカルストレージから読み込み完了: ${_currentPlan?.name}');
      } else {
        debugPrint('ローカルストレージにプラン情報が存在しない');
      }
    } catch (e) {
      debugPrint('ローカルストレージからの読み込みに失敗: $e');
    }
  }

  /// 文字列からSubscriptionPlanを解析
  SubscriptionPlan _parseSubscriptionPlan(String? planType) {
    switch (planType) {
      case 'free':
        return SubscriptionPlan.free;
      case 'basic':
        return SubscriptionPlan.basic;
      case 'premium':
        return SubscriptionPlan.premium;
      case 'family':
        return SubscriptionPlan.family;
      default:
        return SubscriptionPlan.free;
    }
  }

  /// SubscriptionPlanから文字列を取得
  String _getPlanTypeString(SubscriptionPlan plan) {
    switch (plan.type) {
      case SubscriptionPlanType.free:
        return 'free';
      case SubscriptionPlanType.basic:
        return 'basic';
      case SubscriptionPlanType.premium:
        return 'premium';
      case SubscriptionPlanType.family:
        return 'family';
    }
  }

  /// フリープランに設定
  Future<bool> setFreePlan() async {
    try {
      debugPrint('setFreePlan開始');
      _setLoading(true);
      clearError();

      _currentPlan = SubscriptionPlan.free;
      _isSubscriptionActive = true;
      _subscriptionExpiryDate = null;
      _familyMembers = [];

      debugPrint('フリープランに設定');
      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      debugPrint('setFreePlan完了');
      return true;
    } catch (e) {
      debugPrint('setFreePlanでエラーが発生: $e');
      _setError('フリープランの設定に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// プランを更新
  Future<bool> updatePlan(SubscriptionPlan plan, DateTime? expiryDate) async {
    try {
      debugPrint('updatePlan開始: ${plan.name}, expiryDate=$expiryDate');
      _setLoading(true);
      clearError();

      _currentPlan = plan;
      _isSubscriptionActive = true;
      _subscriptionExpiryDate = expiryDate;

      debugPrint('プラン更新: ${plan.name}に変更');
      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      debugPrint('updatePlan完了: ${plan.name}');
      return true;
    } catch (e) {
      debugPrint('updatePlanでエラーが発生: $e');
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
    // フリープランの場合のみ広告を表示
    // ベーシック、プレミアム、ファミリープランでは広告を非表示
    final shouldShow = _currentPlan?.showAds == true;

    debugPrint('=== 広告表示判定デバッグ ===');
    debugPrint('現在のプラン: ${_currentPlan?.name ?? 'フリープラン'}');
    debugPrint('プランのshowAds設定: ${_currentPlan?.showAds}');
    debugPrint('最終的な広告表示判定: $shouldShow');
    debugPrint('========================');

    return shouldShow;
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
      debugPrint('purchasePlan開始: ${plan.name}, expiryDate=$expiryDate');
      _setLoading(true);
      clearError();

      // プランを更新
      final success = await updatePlan(plan, expiryDate);
      if (success) {
        debugPrint('プラン購入が完了しました: ${plan.name}');
        return true;
      } else {
        debugPrint('プラン購入に失敗しました: ${plan.name}');
        return false;
      }
    } catch (e) {
      debugPrint('プラン購入でエラーが発生: $e');
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
      debugPrint('_saveToFirestore開始: Firebase利用可能=${_isFirebaseAvailable}');
      if (!_isFirebaseAvailable) {
        debugPrint('Firebase利用不可のため保存をスキップ');
        return;
      }

      final docRef = _subscriptionDoc;
      if (docRef == null) {
        debugPrint('ユーザーがログインしていないため保存をスキップ');
        return;
      }

      final data = {
        'planType': _getPlanTypeString(_currentPlan!),
        'isActive': _isSubscriptionActive,
        'expiryDate': _subscriptionExpiryDate != null
            ? Timestamp.fromDate(_subscriptionExpiryDate!)
            : null,
        'familyMembers': _familyMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('Firestoreに保存するデータ: $data');
      await docRef.set(data, SetOptions(merge: true));
      debugPrint('Firestoreに保存完了: ${_currentPlan?.name ?? 'Unknown'}');
    } catch (e) {
      debugPrint('Firestoreへの保存に失敗: $e');
      throw Exception('Firestoreへの保存に失敗しました: $e');
    }
  }

  /// ローカルストレージに保存
  Future<void> _saveToLocalStorage() async {
    try {
      debugPrint('_saveToLocalStorage開始');
      final prefs = await SharedPreferences.getInstance();
      final planTypeString = _getPlanTypeString(_currentPlan!);
      await prefs.setString('subscription_plan_type', planTypeString);
      await prefs.setBool('subscription_is_active', _isSubscriptionActive);
      if (_subscriptionExpiryDate != null) {
        await prefs.setInt(
          'subscription_expiry_date',
          _subscriptionExpiryDate!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove('subscription_expiry_date');
      }
      await prefs.setStringList('subscription_family_members', _familyMembers);
      debugPrint(
        'ローカルストレージに保存完了: planType=$planTypeString, isActive=$_isSubscriptionActive, expiryDate=$_subscriptionExpiryDate, familyMembers=$_familyMembers',
      );
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

  /// デバッグ用：現在の状態をログ出力
  void debugPrintStatus() {
    debugPrint('=== SubscriptionService Status ===');
    debugPrint('Current Plan: ${_currentPlan?.name}');
    debugPrint('Is Active: $_isSubscriptionActive');
    debugPrint('Expiry Date: $_subscriptionExpiryDate');
    debugPrint('Family Members: $_familyMembers');
    debugPrint('Is Loading: $_isLoading');
    debugPrint('Error: $_error');
    debugPrint('Firebase Available: $_isFirebaseAvailable');
    debugPrint('Listener Active: ${_subscriptionListener != null}');
    debugPrint('================================');
  }

  /// リソース解放
  void dispose() {
    _stopSubscriptionListener();
    super.dispose();
  }
}
