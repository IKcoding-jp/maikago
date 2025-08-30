import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import '../models/subscription_plan.dart';
import '../config.dart';

/// サブスクリプション管理サービス
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Firebase 依存は遅延取得にして、Firebase.initializeApp() 失敗時の
  // クラッシュを防止（オフライン/ローカルモードで継続可能にする）
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _subscriptionListener;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isStoreAvailable = false;
  final Set<String> _androidProductIds = {
    // 新しい商品ID
    'maikago_basic',
    'maikago_basic_yearly',
    'maikago_family',
    'maikago_family_yearly',
    'maikago_premium',
    'maikago_premium_yearly',
  };
  final Map<String, ProductDetails> _productIdToDetails = {};
  // 正規化した商品ID（_yearlyを除去）ごとに、期間別ProductDetailsを保持
  final Map<String, Map<SubscriptionPeriod, ProductDetails>>
      _normalizedIdToPeriodDetails = {};
  final List<ProductDetails> _lastQueriedProductDetails = [];
  Completer<bool>? _restoreCompleter;

  SubscriptionPlan? _currentPlan = SubscriptionPlan.free;
  bool _isSubscriptionActive = false;
  DateTime? _subscriptionExpiryDate;
  String? _error;
  List<String> _familyMembers = [];
  bool _isLoading = false;
  // 加入側（メンバー）としての参加状態
  String? _familyOwnerId; // 参加しているファミリーオーナーのユーザーID
  StreamSubscription<DocumentSnapshot>? _familyOwnerListener;
  bool _isFamilyOwnerActive = false; // オーナー側のプランが有効かどうか

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

  /// 加入側（メンバー）識別
  String? get familyOwnerId => _familyOwnerId;
  bool get isFamilyMember => _familyOwnerId != null;
  bool get isFamilyBenefitsActive =>
      _familyOwnerId != null && _isFamilyOwnerActive;

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
    debugPrint('サブスクリプションサービス初期化開始');

    try {
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
      // 自分が他ユーザーのファミリーに参加しているか確認
      await _checkFamilyMembership();
      debugPrint('サブスクリプションサービス初期化完了: ${_currentPlan?.name}');

      // ストア初期化（非同期で実行、エラーが発生してもアプリは起動する）
      _initializeStore().catchError((error) {
        debugPrint('ストア初期化エラー（非致命的）: $error');
      });
    } catch (e) {
      debugPrint('SubscriptionService初期化エラー: $e');
      // エラーが発生してもアプリの動作を継続
    }
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

  /// ファミリーオーナーの状態リスナーを設定
  void _attachFamilyOwnerListener(String ownerUserId) {
    // 既存を解除
    _familyOwnerListener?.cancel();
    _familyOwnerListener = null;

    try {
      final DocumentReference<Map<String, dynamic>> docRef = _firestore
          .collection('users')
          .doc(ownerUserId)
          .collection('subscription')
          .doc('current');

      _familyOwnerListener = docRef.snapshots().listen(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.exists) {
          _isFamilyOwnerActive = false;
          notifyListeners();
          return;
        }
        final data = snapshot.data();
        final planType = data?['planType'] as String?;
        final isActive = data?['isActive'] as bool? ?? false;
        final isFamily = planType == 'family';
        _isFamilyOwnerActive = isFamily && isActive;
        if (enableDebugMode) {
          debugPrint(
              'ファミリーオーナー状態更新: owner=$ownerUserId, family=$isFamily, active=$isActive');
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('ファミリーオーナー状態監視エラー: $e');
      });
    } catch (e) {
      debugPrint('ファミリーオーナー状態監視設定エラー: $e');
    }
  }

  /// 自分が他ユーザーのファミリーに参加しているか確認
  Future<void> _checkFamilyMembership() async {
    if (!_isFirebaseAvailable) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // collectionGroupでfamilyMembersに自分が含まれるドキュメントを検索
      final query = await _firestore
          .collectionGroup('subscription')
          .where('familyMembers', arrayContains: user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (query.docs.isNotEmpty) {
        // ドキュメントのパス: users/{owner}/subscription/current
        final doc = query.docs.first;
        final pathSegments = doc.reference.path.split('/');
        // ['users', ownerId, 'subscription', 'current']
        final ownerId = pathSegments.length >= 2 ? pathSegments[1] : null;
        if (ownerId != null) {
          _familyOwnerId = ownerId;
          // オーナー状態リスナーを貼る
          _attachFamilyOwnerListener(ownerId);
        }
      } else {
        _familyOwnerId = null;
        _isFamilyOwnerActive = false;
        _familyOwnerListener?.cancel();
        _familyOwnerListener = null;
      }
      await _saveToLocalStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('家族参加状況の確認に失敗: $e');
    }
  }

  /// ストア初期化（In-App Purchase）
  Future<void> _initializeStore() async {
    try {
      debugPrint('アプリ内課金初期化開始');

      // プラットフォームチェック
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('IAP: サポートされていないプラットフォーム');
        return;
      }

      _isStoreAvailable = await _inAppPurchase.isAvailable();
      debugPrint('アプリ内課金利用可能: $_isStoreAvailable');
      if (!_isStoreAvailable) {
        debugPrint('アプリ内課金: ストアが利用できません');
        return;
      }

      // 購入ストリーム購読
      _purchaseSubscription ??= _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () {
          debugPrint('購入ストリームが終了しました');
        },
        onError: (Object error) {
          debugPrint('購入ストリームエラー: $error');
        },
      );

      // 商品情報取得
      await _queryProductDetails();
    } catch (e) {
      debugPrint('IAP初期化エラー: $e');
      // エラーが発生してもアプリの動作を継続
      _isStoreAvailable = false;
    }
  }

  /// 商品情報を取得
  Future<void> _queryProductDetails() async {
    try {
      final response = await _inAppPurchase.queryProductDetails(
        _androidProductIds,
      );
      if (response.error != null) {
        debugPrint('商品情報取得エラー: ${response.error}');
      }
      if (response.productDetails.isEmpty) {
        debugPrint('商品情報が見つかりませんでした。Play Consoleの設定を確認してください');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('見つからなかった商品ID: ${response.notFoundIDs}');
      }
      _productIdToDetails.clear();
      _lastQueriedProductDetails
        ..clear()
        ..addAll(response.productDetails);
      for (final p in response.productDetails) {
        _productIdToDetails[p.id] = p;
        debugPrint('商品取得: id=${p.id}, title=${p.title}, price=${p.price}');

        // Androidの場合、詳細情報を確認
        if (p is GooglePlayProductDetails) {
          debugPrint('Google Play商品詳細情報: ${p.id}');
          debugPrint('  価格: ${p.price}');
          debugPrint('  通貨: ${p.currencyCode}');
        }
      }
      // 期間別のディテールを構築
      _normalizedIdToPeriodDetails.clear();
      for (final entry in _productIdToDetails.entries) {
        final id = entry.key;
        final details = entry.value;
        final normalized = _normalizeProductId(id);
        final isYearly = id.endsWith('_yearly');
        final period =
            isYearly ? SubscriptionPeriod.yearly : SubscriptionPeriod.monthly;
        _normalizedIdToPeriodDetails.putIfAbsent(normalized, () => {});
        _normalizedIdToPeriodDetails[normalized]![period] = details;
      }
      // 年額/月額のIDが同一IDで返るケースに備えてエイリアスを補完
      void ensureAlias(String baseId, String yearlyId) {
        final base = _productIdToDetails[baseId];
        final yearly = _productIdToDetails[yearlyId];
        if (base != null && yearly == null) {
          _productIdToDetails[yearlyId] = base;
          debugPrint('エイリアス補完: $yearlyId -> $baseId');
        } else if (yearly != null && base == null) {
          _productIdToDetails[baseId] = yearly;
          debugPrint('エイリアス補完: $baseId -> $yearlyId');
        }
      }

      ensureAlias('maikago_basic', 'maikago_basic_yearly');
      ensureAlias('maikago_family', 'maikago_family_yearly');
      ensureAlias('maikago_premium', 'maikago_premium_yearly');
      debugPrint('取得された商品数: ${response.productDetails.length}');
      debugPrint('利用可能な商品ID: ${_productIdToDetails.keys.toList()}');
    } catch (e) {
      debugPrint('商品情報取得時に例外: $e');
    }
  }

  /// 年額IDをベースIDに正規化（例: maikago_basic_yearly -> maikago_basic）
  String _normalizeProductId(String productId) {
    if (productId.endsWith('_yearly')) {
      return productId.replaceAll('_yearly', '');
    }
    return productId;
  }

  /// 価格文字列（例: ￥2,200）を整数（2200）に変換
  int? _parsePriceToInt(String priceString) {
    try {
      final digits = priceString.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;
      return int.parse(digits);
    } catch (_) {
      return null;
    }
  }

  /// 購入更新イベント
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      try {
        debugPrint(
          '購入更新: productID=${purchase.productID}, status=${purchase.status}',
        );
        switch (purchase.status) {
          case PurchaseStatus.pending:
            _setLoading(true);
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final plan = _mapProductIdToPlan(purchase.productID);
            if (plan != null) {
              // 有効化（期限はストア検証を省略し未設定）
              await updatePlan(plan, null);
            }
            // Androidでは購入のackが必要
            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
            }
            break;
          case PurchaseStatus.error:
            _setError('購入処理でエラーが発生しました: ${purchase.error}');
            break;
          case PurchaseStatus.canceled:
            debugPrint('購入がキャンセルされました');
            break;
        }
      } catch (e) {
        debugPrint('購入更新処理中の例外: $e');
      } finally {
        _setLoading(false);
      }
    }

    // 復元呼び出し中であれば完了を通知
    _restoreCompleter?.complete(_isSubscriptionActive);
    _restoreCompleter = null;
  }

  /// Firestoreからサブスクリプション情報を読み込み
  Future<void> loadFromFirestore({bool skipNotify = false}) async {
    try {
      debugPrint('loadFromFirestore開始: Firebase利用可能=$_isFirebaseAvailable');
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
      final joinedOwnerId = prefs.getString('subscription_family_owner_id');
      final joinedOwnerActive =
          prefs.getBool('subscription_family_owner_active') ?? false;

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
        _familyOwnerId = joinedOwnerId;
        _isFamilyOwnerActive = joinedOwnerActive;
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
      debugPrint('フリープラン設定開始');
      _setLoading(true);
      clearError();

      _currentPlan = SubscriptionPlan.free;
      // フリープランはサブスクリプションではないため有効フラグは false にする
      _isSubscriptionActive = false;
      _subscriptionExpiryDate = null;
      _familyMembers = [];

      debugPrint('フリープランに設定');
      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      debugPrint('フリープラン設定完了');
      return true;
    } catch (e) {
      debugPrint('setFreePlanでエラーが発生: $e');
      _setError('フリープランの設定に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// テスト用プラン設定（デバッグモード時のみ）
  Future<bool> setTestPlan(SubscriptionPlan plan) async {
    if (!kDebugMode) {
      debugPrint('setTestPlan: デバッグモードでのみ使用可能です');
      return false;
    }

    try {
      debugPrint('テストプラン設定開始: ${plan.name}');
      _setLoading(true);
      clearError();

      _currentPlan = plan;
      // テスト用は有効なサブスクリプションとして扱う
      _isSubscriptionActive = true;
      // テスト用は1年後に期限切れ
      _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 365));
      _familyMembers = [];

      debugPrint('テストプラン設定: ${plan.name}');
      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      debugPrint('テストプラン設定完了: ${plan.name}');
      return true;
    } catch (e) {
      debugPrint('setTestPlanでエラーが発生: $e');
      _setError('テストプランの設定に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// プランを更新
  Future<bool> updatePlan(SubscriptionPlan plan, DateTime? expiryDate) async {
    try {
      debugPrint('プラン更新開始: ${plan.name}, 有効期限=$expiryDate');
      _setLoading(true);
      clearError();

      _currentPlan = plan;
      _isSubscriptionActive = true;
      _subscriptionExpiryDate = expiryDate;

      debugPrint('プラン更新: ${plan.name}に変更');
      await _saveToFirestore();
      await _saveToLocalStorage();

      notifyListeners();
      debugPrint('プラン更新完了: ${plan.name}');
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
    // 自分がファミリーメンバーとして特典を享受している場合は広告非表示
    if (isFamilyBenefitsActive) {
      debugPrint('広告表示判定: ファミリーメンバー特典により広告非表示');
      return false;
    }

    // フリープランの場合のみ広告を表示
    final shouldShow = _currentPlan?.showAds == true;

    debugPrint('=== 広告表示判定デバッグ ===');
    debugPrint('現在のプラン: ${_currentPlan?.name ?? 'フリープラン'}');
    debugPrint(
        'ファミリー参加: ${_familyOwnerId != null} / オーナー有効: $_isFamilyOwnerActive');
    debugPrint('プランのshowAds設定: ${_currentPlan?.showAds}');
    debugPrint('最終的な広告表示判定: $shouldShow');
    debugPrint('========================');

    return shouldShow;
  }

  /// 新機能早期アクセスが可能かどうか
  bool hasEarlyAccess() {
    return _currentPlan?.hasEarlyAccess == true;
  }

  /// 購入処理（Android: in_app_purchase）
  Future<bool> purchasePlan(
    SubscriptionPlan plan, {
    SubscriptionPeriod period = SubscriptionPeriod.monthly,
  }) async {
    try {
      _setLoading(true);
      clearError();

      if (!_isStoreAvailable) {
        _setError('ストアが利用できません。ネットワークやGoogle Playの状態を確認してください。');
        return false;
      }

      // プランから期間を考慮した商品IDを取得
      final productId = plan.getProductId(period);
      if (productId == null) {
        _setError('フリープランは購入できません。');
        return false;
      }

      debugPrint(
        '購入処理開始: plan=${plan.name}, period=$period, productId=$productId',
      );
      debugPrint(
        '選択された期間: ${period == SubscriptionPeriod.monthly ? "月額" : "年額"}',
      );
      debugPrint('取得された商品ID: $productId');

      // 商品情報を再取得して最新の状態を確認
      await _queryProductDetails();

      // 期間でProductDetailsを選択（年額IDが個別で返らない場合にも価格から推定）
      final normalizedId = _normalizeProductId(productId);
      ProductDetails? details = _productIdToDetails[productId];
      final candidatesList = _lastQueriedProductDetails
          .where((pd) => _normalizeProductId(pd.id) == normalizedId)
          .toList();

      // 期待価格
      final expectedPriceInt = plan.getPrice(period);
      int? selectedPriceInt =
          details != null ? _parsePriceToInt(details.price) : null;
      if (details == null ||
          (selectedPriceInt != null && selectedPriceInt != expectedPriceInt)) {
        // 価格一致の候補を探す
        for (final candidate in candidatesList) {
          final candPrice = _parsePriceToInt(candidate.price);
          if (candPrice == expectedPriceInt) {
            debugPrint('価格一致の候補に差し替え: id=${candidate.id}, price=$candPrice');
            details = candidate;
            selectedPriceInt = candPrice;
            break;
          }
        }
      }

      // それでも未決定なら、期間からのヒューリスティック（年額は高価格、月額は低価格）
      if (details == null && candidatesList.isNotEmpty) {
        candidatesList.sort((a, b) {
          final ap = _parsePriceToInt(a.price) ?? 0;
          final bp = _parsePriceToInt(b.price) ?? 0;
          return ap.compareTo(bp);
        });
        details = (period == SubscriptionPeriod.yearly)
            ? candidatesList.last
            : candidatesList.first;
        debugPrint('ヒューリスティックで候補選択: id=${details.id}, price=${details.price}');
      }

      if (details == null) {
        debugPrint('商品情報が見つからない: $productId (normalized=$normalizedId)');
        debugPrint('利用可能な商品ID: ${_productIdToDetails.keys.toList()}');
        _setError('商品情報を取得できませんでした（$productId）。Play Consoleの設定を確認してください。');
        return false;
      }

      // 非null確定
      var nonNullDetails = details;
      debugPrint(
        '商品情報取得成功: ${nonNullDetails.title}, 価格=${nonNullDetails.price}',
      );

      debugPrint(
        '商品情報取得成功: ${nonNullDetails.title}, 価格=${nonNullDetails.price}',
      );
      debugPrint(
        '商品ID: $productId, 期間: ${period == SubscriptionPeriod.monthly ? "月額" : "年額"}',
      );

      PurchaseParam purchaseParam;

      // Androidのベースプラン/オファーに対応
      if (nonNullDetails is GooglePlayProductDetails) {
        // 期間別商品IDを使用することで、適切なオファーが選択される
        purchaseParam = GooglePlayPurchaseParam(productDetails: nonNullDetails);
      } else {
        // 他プラットフォーム用のフォールバック（基本的に到達しない想定）
        purchaseParam = PurchaseParam(productDetails: nonNullDetails);
      }

      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      debugPrint('購入開始: productId=$productId, 期間=$period, 成功フラグ=$success');
      return success;
    } catch (e) {
      debugPrint('購入エラー: $e');
      _setError('購入開始に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// QRコードで読み取ったオーナーIDに参加
  Future<bool> joinFamilyByOwnerId(String ownerUserId) async {
    try {
      _setLoading(true);
      clearError();

      final user = _auth.currentUser;
      if (user == null) {
        _setError('ログインが必要です');
        return false;
      }

      // オーナーのドキュメントを取得
      final ownerDoc = _firestore
          .collection('users')
          .doc(ownerUserId)
          .collection('subscription')
          .doc('current');

      final snap = await ownerDoc.get();
      if (!snap.exists) {
        _setError('招待が無効です（オーナー情報が見つかりません）');
        return false;
      }
      final data = snap.data() as Map<String, dynamic>;
      final planType = data['planType'] as String?;
      final isActive = data['isActive'] as bool? ?? false;
      final members = List<String>.from(data['familyMembers'] ?? []);
      final maxMembers = SubscriptionPlan.family.maxFamilyMembers;

      if (planType != 'family' || !isActive) {
        _setError('このユーザーはファミリープランを利用していません');
        return false;
      }
      if (members.contains(user.uid)) {
        // 既に参加済み
        _familyOwnerId = ownerUserId;
        _attachFamilyOwnerListener(ownerUserId);
        await _saveToLocalStorage();
        notifyListeners();
        return true;
      }
      if (members.length >= maxMembers) {
        _setError('ファミリーの上限人数（$maxMembers人）に達しています');
        return false;
      }

      // 参加処理（オーナー側に自分のUIDを追加）
      await ownerDoc.set({
        'familyMembers': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 自身の状態を更新
      _familyOwnerId = ownerUserId;
      _attachFamilyOwnerListener(ownerUserId);
      await _saveToLocalStorage();
      notifyListeners();
      debugPrint('ファミリーに参加しました: owner=$ownerUserId, member=${user.uid}');
      return true;
    } catch (e) {
      _setError('ファミリー参加に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーから離脱
  Future<bool> leaveFamily() async {
    try {
      _setLoading(true);
      clearError();
      final user = _auth.currentUser;
      if (user == null) {
        _setError('ログインが必要です');
        return false;
      }
      if (_familyOwnerId == null) {
        return true; // 何もしない
      }
      final ownerDoc = _firestore
          .collection('users')
          .doc(_familyOwnerId)
          .collection('subscription')
          .doc('current');
      await ownerDoc.set({
        'familyMembers': FieldValue.arrayRemove([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _familyOwnerListener?.cancel();
      _familyOwnerListener = null;
      _familyOwnerId = null;
      _isFamilyOwnerActive = false;
      await _saveToLocalStorage();
      notifyListeners();
      debugPrint('ファミリーから離脱しました');
      return true;
    } catch (e) {
      _setError('ファミリー離脱に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 購入履歴を復元（Android: in_app_purchase）
  Future<bool> restorePurchases() async {
    try {
      if (!_isStoreAvailable) {
        _setError('ストアが利用できません。復元を実行できません。');
        return false;
      }
      _setLoading(true);
      clearError();
      _restoreCompleter = Completer<bool>();
      await _inAppPurchase.restorePurchases();
      // 購入ストリーム経由で状態が更新された後に結果が返る
      final result = await _restoreCompleter!.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => _isSubscriptionActive,
      );
      debugPrint('購入履歴復元完了: isActive=$result');
      return result;
    } catch (e) {
      _setError('購入履歴の復元に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ストアからの最新状態でサブスク有効かを確認
  Future<bool> refreshAndCheckActive() async {
    final ok = await restorePurchases();
    return ok && _isSubscriptionActive;
  }

  /// ProductId からプランへ変換
  SubscriptionPlan? _mapProductIdToPlan(String productId) {
    switch (productId) {
      case 'maikago_basic':
      case 'maikago_basic_yearly':
        return SubscriptionPlan.basic;
      case 'maikago_premium':
      case 'maikago_premium_yearly':
        return SubscriptionPlan.premium;
      case 'maikago_family':
      case 'maikago_family_yearly':
        return SubscriptionPlan.family;
      default:
        return null;
    }
  }

  // Android用ベースプランIDは現在未使用（GooglePlayPurchaseParamへの直接指定を行っていないため）

  /// Firestoreに保存
  Future<void> _saveToFirestore() async {
    try {
      debugPrint('_saveToFirestore開始: Firebase利用可能=$_isFirebaseAvailable');
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
      if (_familyOwnerId != null) {
        await prefs.setString('subscription_family_owner_id', _familyOwnerId!);
        await prefs.setBool(
            'subscription_family_owner_active', _isFamilyOwnerActive);
      } else {
        await prefs.remove('subscription_family_owner_id');
        await prefs.remove('subscription_family_owner_active');
      }
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
    debugPrint('=== サブスクリプションサービス状態 ===');
    debugPrint('現在のプラン: ${_currentPlan?.name}');
    debugPrint('アクティブ: $_isSubscriptionActive');
    debugPrint('有効期限: $_subscriptionExpiryDate');
    debugPrint('ファミリーメンバー: $_familyMembers');
    debugPrint('読み込み中: $_isLoading');
    debugPrint('エラー: $_error');
    debugPrint('Firebase利用可能状態: $_isFirebaseAvailable');
    debugPrint('リスナーアクティブ: ${_subscriptionListener != null}');
    debugPrint('================================');
  }

  /// リソース解放
  @override
  void dispose() {
    _stopSubscriptionListener();
    _purchaseSubscription?.cancel();
    _familyOwnerListener?.cancel();
    super.dispose();
  }
}
