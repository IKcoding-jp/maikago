import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/subscription_plan.dart';
import '../models/one_time_purchase.dart';
import '../services/one_time_purchase_service.dart';

/// 非消耗型アプリ内課金管理サービス（旧サブスクリプション管理サービス）
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Firebase 依存は遅延取得にして、Firebase.initializeApp() 失敗時の
  // クラッシュを防止（オフライン/ローカルモードで継続可能にする）
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // 非消耗型アプリ内課金サービス
  late final OneTimePurchaseService _oneTimePurchaseService;

  // 旧サブスクリプション関連の変数（互換性のため保持）
  SubscriptionPlan? _currentPlan = SubscriptionPlan.free;
  bool _isSubscriptionActive = false;
  DateTime? _subscriptionExpiryDate;
  String? _error;
  List<String> _familyMembers = [];
  final bool _isLoading = false;
  bool _isCancelled = false; // 解約済みフラグ
  // 加入側（メンバー）としての参加状態
  String? _familyOwnerId; // 参加しているファミリーオーナーのユーザーID
  StreamSubscription<DocumentSnapshot>? _familyOwnerListener;
  bool _isFamilyOwnerActive = false; // オーナー側のプランが有効かどうか
  SubscriptionPlan? _originalPlan; // ファミリー参加前の元のプラン
  bool _isInitialized = false; // 追加

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

  /// 解約済みかどうか
  bool get isCancelled => _isCancelled;

  /// 加入側（メンバー）識別
  String? get familyOwnerId => _familyOwnerId;
  bool get isFamilyMember => _familyOwnerId != null;
  bool get isFamilyBenefitsActive =>
      _familyOwnerId != null && _isFamilyOwnerActive;

  /// 元のプラン（ファミリー参加前のプラン）
  SubscriptionPlan? get originalPlan => _originalPlan;

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
  DocumentReference get _userSubscriptionDoc {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('subscription')
        .doc('current');
  }

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('非消耗型アプリ内課金サービスは既に初期化済みです。');
      return;
    }
    debugPrint('非消耗型アプリ内課金サービス初期化開始');

    try {
      // 非消耗型アプリ内課金サービスを初期化
      _oneTimePurchaseService = OneTimePurchaseService();
      await _oneTimePurchaseService.initialize();

      // 非消耗型サービスの変更を監視
      _oneTimePurchaseService.addListener(_onOneTimePurchaseChanged);

      // 認証状態の変更を監視
      _auth.authStateChanges().listen((User? user) async {
        debugPrint('認証状態変更: ${user?.uid ?? 'ログアウト'}');
        if (user != null) {
          // ログイン時はFirestoreから最新の状態を読み込み
          await loadFromFirestore();
        } else {
          // ログアウト時はローカル状態をクリア
          _clearLocalState();
        }
      });

      debugPrint('初期データ読み込み開始');
      await _loadFromLocalStorage();
      await loadFromFirestore(skipNotify: true);
      // 自分が他ユーザーのファミリーに参加しているか確認
      await _checkFamilyMembership();
      debugPrint('非消耗型アプリ内課金サービス初期化完了: ${_currentPlan?.name}');
      _isInitialized = true; // 初期化完了後にフラグを設定
    } catch (e) {
      debugPrint('非消耗型アプリ内課金サービス初期化エラー: $e');
      // エラーが発生してもアプリの動作を継続
    }
  }

  /// 非消耗型購入状態変更時の処理
  void _onOneTimePurchaseChanged() {
    notifyListeners();
  }

  /// ローカル状態をクリア
  void _clearLocalState() {
    _currentPlan = SubscriptionPlan.free;
    _isSubscriptionActive = false;
    _subscriptionExpiryDate = null;
    _familyMembers.clear();
    _isCancelled = false;
    _familyOwnerId = null;
    _isFamilyOwnerActive = false;
    _originalPlan = null;
    _familyOwnerListener?.cancel();
    _familyOwnerListener = null;
    notifyListeners();
  }

  /// ローカルストレージから読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planTypeString = prefs.getString('subscription_plan');
      if (planTypeString != null) {
        _currentPlan = SubscriptionPlan.availablePlans.firstWhere(
          (plan) => plan.type.toString() == planTypeString,
          orElse: () => SubscriptionPlan.free,
        );
      }
      _isSubscriptionActive = prefs.getBool('subscription_active') ?? false;
      final expiryTimestamp = prefs.getInt('subscription_expiry');
      if (expiryTimestamp != null) {
        _subscriptionExpiryDate =
            DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      }
      _isCancelled = prefs.getBool('subscription_cancelled') ?? false;
      _familyOwnerId = prefs.getString('family_owner_id');
      _isFamilyOwnerActive = prefs.getBool('family_owner_active') ?? false;
      final originalPlanString = prefs.getString('original_plan');
      if (originalPlanString != null) {
        _originalPlan = SubscriptionPlan.availablePlans.firstWhere(
          (plan) => plan.type.toString() == originalPlanString,
          orElse: () => SubscriptionPlan.free,
        );
      }

      debugPrint('非消耗型アプリ内課金状態をローカルストレージから読み込み完了');
    } catch (e) {
      debugPrint('非消耗型ローカルストレージ読み込みエラー: $e');
    }
  }

  /// Firestoreから読み込み
  Future<void> loadFromFirestore({bool skipNotify = false}) async {
    if (!_isFirebaseAvailable) return;

    try {
      final doc = await _userSubscriptionDoc.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _currentPlan = SubscriptionPlan.availablePlans.firstWhere(
          (plan) => plan.type.toString() == data['plan_type'],
          orElse: () => SubscriptionPlan.free,
        );
        _isSubscriptionActive = data['is_active'] ?? false;
        final expiryTimestamp = data['expiry_date'] as Timestamp?;
        if (expiryTimestamp != null) {
          _subscriptionExpiryDate = expiryTimestamp.toDate();
        }
        _isCancelled = data['is_cancelled'] ?? false;
        _familyMembers = List<String>.from(data['family_members'] ?? []);

        debugPrint('非消耗型アプリ内課金状態をFirestoreから読み込み完了');
      }
    } catch (e) {
      debugPrint('非消耗型Firestore読み込みエラー: $e');
    }

    if (!skipNotify) {
      notifyListeners();
    }
  }

  /// 家族参加状況の確認
  Future<void> _checkFamilyMembership() async {
    if (!_isFirebaseAvailable) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 自分が他のユーザーのファミリーメンバーとして登録されているか確認
      final membershipQuery = await _firestore
          .collectionGroup('subscription')
          .where('family_members', arrayContains: user.uid)
          .get();

      if (membershipQuery.docs.isNotEmpty) {
        final membershipDoc = membershipQuery.docs.first;
        final ownerId = membershipDoc.reference.parent.parent?.id;

        if (ownerId != null && ownerId != user.uid) {
          _familyOwnerId = ownerId;
          _isFamilyOwnerActive = membershipDoc.data()['is_active'] ?? false;
          _originalPlan = _currentPlan;

          debugPrint(
              '家族メンバーとして参加中: オーナー=$ownerId, アクティブ=$_isFamilyOwnerActive');

          // オーナーの状態変更を監視
          _familyOwnerListener = _firestore
              .collection('users')
              .doc(ownerId)
              .collection('subscription')
              .doc('current')
              .snapshots()
              .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              _isFamilyOwnerActive = data['is_active'] ?? false;
              notifyListeners();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('家族参加状況の確認に失敗: $e');
    }
  }

  // === 非消耗型アプリ内課金の機能判定メソッド ===

  /// テーマカスタマイズが可能かどうか
  bool canCustomizeTheme() {
    return _oneTimePurchaseService.isPremiumUnlocked;
  }

  /// フォントカスタマイズが可能かどうか
  bool canCustomizeFont() {
    return _oneTimePurchaseService.isPremiumUnlocked;
  }

  /// 広告を表示するかどうか
  bool shouldShowAds() {
    return !_oneTimePurchaseService.isPremiumUnlocked;
  }

  /// リスト作成制限をチェック（制限なし）
  bool canCreateList(int currentListCount) {
    return true; // 制限なし - 非課金・課金関係なく無制限
  }

  /// タブ作成制限をチェック（制限なし）
  bool canCreateTab(int currentTabCount) {
    return true; // 制限なし - 非課金・課金関係なく無制限
  }

  /// 非消耗型商品を購入
  Future<bool> purchaseOneTimeProduct(OneTimePurchase purchase) async {
    return await _oneTimePurchaseService.purchaseProduct(purchase);
  }

  /// 購入を復元
  Future<bool> restorePurchases() async {
    return await _oneTimePurchaseService.restorePurchases();
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ファミリーメンバー数の最大値を取得
  int getMaxFamilyMembers() {
    return 5; // デフォルト値
  }

  /// ファミリーオーナーIDで参加
  Future<bool> joinFamilyByOwnerId(String ownerId) async {
    // 非消耗型アプリ内課金では家族機能は不要
    return false;
  }

  /// ファミリーから離脱
  Future<bool> leaveFamily() async {
    // 非消耗型アプリ内課金では家族機能は不要
    return false;
  }

  /// フリープランに設定
  void setFreePlan() {
    _currentPlan = SubscriptionPlan.free;
    _isSubscriptionActive = false;
    _subscriptionExpiryDate = null;
    _isCancelled = false;
    notifyListeners();
  }

  /// プランを更新
  Future<void> updatePlan(SubscriptionPlan plan, DateTime? expiry) async {
    _currentPlan = plan;
    _subscriptionExpiryDate = expiry;
    _isSubscriptionActive = plan.type != SubscriptionPlanType.free;
    _isCancelled = false;
    notifyListeners();
  }

  /// デバッグ用の状態出力
  void debugPrintStatus() {
    debugPrint('=== SubscriptionService Status ===');
    debugPrint('現在のプラン: ${_currentPlan?.name ?? 'なし'}');
    debugPrint('サブスクリプション有効: $_isSubscriptionActive');
    debugPrint('期限: ${_subscriptionExpiryDate?.toString() ?? 'なし'}');
    debugPrint('キャンセル済み: $_isCancelled');
    debugPrint('===============================');
  }

  /// リソースを解放
  @override
  void dispose() {
    _familyOwnerListener?.cancel();
    super.dispose();
  }
}
