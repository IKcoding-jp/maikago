import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import '../models/one_time_purchase.dart';

/// 非消耗型アプリ内課金管理サービス
class OneTimePurchaseService extends ChangeNotifier {
  static final OneTimePurchaseService _instance =
      OneTimePurchaseService._internal();
  factory OneTimePurchaseService() => _instance;
  OneTimePurchaseService._internal();

  // Firebase 依存は遅延取得にして、Firebase.initializeApp() 失敗時の
  // クラッシュを防止（オフライン/ローカルモードで継続可能にする）
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isStoreAvailable = false;

  final Set<String> _androidProductIds = {
    'maikago_premium_unlock',
  };

  final Map<String, ProductDetails> _productIdToDetails = {};
  Completer<bool>? _restoreCompleter;

  // 購入済み機能の状態
  bool _isPremiumUnlocked = false;

  // 体験期間の状態
  bool _isTrialActive = false;
  DateTime? _trialStartDate;
  DateTime? _trialEndDate;

  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isPremiumUnlocked => _isPremiumUnlocked || _isTrialActive;
  bool get isPremiumPurchased => _isPremiumUnlocked; // 実際の購入状態（体験期間除く）
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isStoreAvailable => _isStoreAvailable;

  // 体験期間のgetter
  bool get isTrialActive => _isTrialActive;
  DateTime? get trialStartDate => _trialStartDate;
  DateTime? get trialEndDate => _trialEndDate;
  int? get trialRemainingDays {
    if (!_isTrialActive || _trialEndDate == null) return null;
    final now = DateTime.now();
    final remaining = _trialEndDate!.difference(now).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// 初期化
  Future<void> initialize() async {
    try {
      debugPrint('非消耗型アプリ内課金初期化開始');
      await _initializeStore();
      await _loadFromLocalStorage();
      await _loadFromFirestore();
      debugPrint('非消耗型アプリ内課金初期化完了');
    } catch (e) {
      debugPrint('非消耗型アプリ内課金初期化エラー: $e');
      _setError('初期化に失敗しました: $e');
    }
  }

  /// ストア初期化（In-App Purchase）
  Future<void> _initializeStore() async {
    try {
      debugPrint('非消耗型アプリ内課金ストア初期化開始');

      // プラットフォームチェック
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('IAP: サポートされていないプラットフォーム');
        return;
      }

      _isStoreAvailable = await _inAppPurchase.isAvailable();
      debugPrint('非消耗型アプリ内課金利用可能: $_isStoreAvailable');
      if (!_isStoreAvailable) {
        debugPrint('非消耗型アプリ内課金: ストアが利用できません');
        return;
      }

      // 購入ストリーム購読
      _purchaseSubscription ??= _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () {
          debugPrint('非消耗型購入ストリームが終了しました');
        },
        onError: (Object error) {
          debugPrint('非消耗型購入ストリームエラー: $error');
        },
      );

      // 商品情報取得
      await _queryProductDetails();
    } catch (e) {
      debugPrint('非消耗型IAP初期化エラー: $e');
      _isStoreAvailable = false;
    }
  }

  /// 商品情報を取得
  Future<void> _queryProductDetails() async {
    if (!_isStoreAvailable) return;

    try {
      debugPrint('非消耗型商品情報取得開始');
      final response =
          await _inAppPurchase.queryProductDetails(_androidProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('見つからない商品ID: ${response.notFoundIDs}');
      }

      _productIdToDetails.clear();

      for (final productDetails in response.productDetails) {
        _productIdToDetails[productDetails.id] = productDetails;
        debugPrint(
            '商品情報取得: ${productDetails.id} - ${productDetails.title} - ${productDetails.price}');
      }

      debugPrint('非消耗型商品情報取得完了: ${response.productDetails.length}個');
    } catch (e) {
      debugPrint('非消耗型商品情報取得エラー: $e');
    }
  }

  /// 購入更新の処理
  Future<void> _onPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    debugPrint('非消耗型購入更新受信: ${purchaseDetailsList.length}件');

    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
          '非消耗型購入詳細: ${purchaseDetails.productID} - ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('非消耗型購入エラー: ${purchaseDetails.error}');
        _setError('購入に失敗しました: ${purchaseDetails.error?.message}');
      }

      // 購入完了の確認
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('非消耗型購入完了確認: ${purchaseDetails.productID}');
      }
    }
  }

  /// 成功した購入の処理
  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    debugPrint('非消耗型購入成功処理: ${purchaseDetails.productID}');

    // 購入済み機能を更新
    if (purchaseDetails.productID == 'maikago_premium_unlock') {
      _isPremiumUnlocked = true;
    }

    // ローカルストレージとFirestoreに保存
    await _saveToLocalStorage();
    await _saveToFirestore();

    notifyListeners();
    debugPrint('非消耗型購入成功処理完了: ${purchaseDetails.productID}');
  }

  /// 商品を購入
  Future<bool> purchaseProduct(OneTimePurchase purchase) async {
    try {
      _setLoading(true);
      clearError();

      if (!_isStoreAvailable) {
        _setError('ストアが利用できません。ネットワークやGoogle Playの状態を確認してください。');
        return false;
      }

      debugPrint('非消耗型購入処理開始: ${purchase.name} (${purchase.productId})');

      // 商品情報を再取得して最新の状態を確認
      await _queryProductDetails();

      final productDetails = _productIdToDetails[purchase.productId];
      if (productDetails == null) {
        _setError('商品情報が見つかりません: ${purchase.productId}');
        return false;
      }

      // 購入リクエストを作成
      final purchaseParam = PurchaseParam(productDetails: productDetails);

      // 購入を実行
      final success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (success) {
        debugPrint('非消耗型購入リクエスト送信成功: ${purchase.productId}');
      } else {
        _setError('購入リクエストの送信に失敗しました');
      }

      return success;
    } catch (e) {
      debugPrint('非消耗型購入エラー: $e');
      _setError('購入に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 購入を復元
  Future<bool> restorePurchases() async {
    try {
      _setLoading(true);
      clearError();

      if (!_isStoreAvailable) {
        _setError('ストアが利用できません。');
        return false;
      }

      debugPrint('非消耗型購入復元開始');

      _restoreCompleter = Completer<bool>();
      await _inAppPurchase.restorePurchases();

      // 復元完了を待つ（タイムアウト付き）
      final result = await _restoreCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('非消耗型購入復元タイムアウト');
          return false;
        },
      );

      debugPrint('非消耗型購入復元完了: $result');
      return result;
    } catch (e) {
      debugPrint('非消耗型購入復元エラー: $e');
      _setError('購入復元に失敗しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ローカルストレージから読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremiumUnlocked = prefs.getBool('premium_unlocked') ?? false;

      // 体験期間の情報を読み込み
      _isTrialActive = prefs.getBool('trial_active') ?? false;
      final trialStartTimestamp = prefs.getInt('trial_start_timestamp');
      final trialEndTimestamp = prefs.getInt('trial_end_timestamp');

      if (trialStartTimestamp != null) {
        _trialStartDate =
            DateTime.fromMillisecondsSinceEpoch(trialStartTimestamp);
      }
      if (trialEndTimestamp != null) {
        _trialEndDate = DateTime.fromMillisecondsSinceEpoch(trialEndTimestamp);
      }

      // 体験期間が期限切れの場合は終了
      if (_isTrialActive &&
          _trialEndDate != null &&
          DateTime.now().isAfter(_trialEndDate!)) {
        endTrial();
      }

      debugPrint('非消耗型購入状態をローカルストレージから読み込み完了');
    } catch (e) {
      debugPrint('非消耗型ローカルストレージ読み込みエラー: $e');
    }
  }

  /// ローカルストレージに保存
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium_unlocked', _isPremiumUnlocked);

      // 体験期間の情報を保存
      await prefs.setBool('trial_active', _isTrialActive);
      if (_trialStartDate != null) {
        await prefs.setInt(
            'trial_start_timestamp', _trialStartDate!.millisecondsSinceEpoch);
      }
      if (_trialEndDate != null) {
        await prefs.setInt(
            'trial_end_timestamp', _trialEndDate!.millisecondsSinceEpoch);
      }

      debugPrint('非消耗型購入状態をローカルストレージに保存完了');
    } catch (e) {
      debugPrint('非消耗型ローカルストレージ保存エラー: $e');
    }
  }

  /// Firestoreから読み込み
  Future<void> _loadFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .doc('one_time_purchases')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _isPremiumUnlocked = data['premium_unlocked'] ?? false;

        debugPrint('非消耗型購入状態をFirestoreから読み込み完了');
      }
    } catch (e) {
      debugPrint('非消耗型Firestore読み込みエラー: $e');
    }
  }

  /// Firestoreに保存
  Future<void> _saveToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .doc('one_time_purchases')
          .set({
        'premium_unlocked': _isPremiumUnlocked,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('非消耗型購入状態をFirestoreに保存完了');
    } catch (e) {
      debugPrint('非消耗型Firestore保存エラー: $e');
    }
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// エラーを設定
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 体験期間を開始
  void startTrial(int trialDays) {
    _isTrialActive = true;
    _trialStartDate = DateTime.now();
    _trialEndDate = _trialStartDate!.add(Duration(days: trialDays));

    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    debugPrint('体験期間開始: ${trialDays}日間');
  }

  /// 体験期間を終了
  void endTrial() {
    _isTrialActive = false;
    _trialStartDate = null;
    _trialEndDate = null;

    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    debugPrint('体験期間終了');
  }

  /// デバッグ用：プレミアム状態を手動で切り替え
  void debugTogglePremiumStatus(bool isUnlocked) {
    // デバッグモードのチェックを削除（configEnableDebugModeで制御）
    _isPremiumUnlocked = isUnlocked;
    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    debugPrint('デバッグ: プレミアム状態を${isUnlocked ? "アンロック" : "ロック"}に変更');
  }

  /// リソースを解放
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
