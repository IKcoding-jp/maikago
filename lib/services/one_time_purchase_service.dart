import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint, ChangeNotifier, defaultTargetPlatform, TargetPlatform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:async';
import 'dart:convert';
import '../models/one_time_purchase.dart';

/// 非消耗型アプリ内課金管理サービス
class OneTimePurchaseService extends ChangeNotifier {
  static final OneTimePurchaseService _instance =
      OneTimePurchaseService._internal();
  factory OneTimePurchaseService() => _instance;
  OneTimePurchaseService._internal();

  // Firebase 依存は遅延取得にして、Firebase.initializeApp() 失敗時の
  // クラッシュを防止（オフライン/ローカルモードで継続可能にする）
  FirebaseFirestore? get _firestore {
    try {
      if (kIsWeb) {
        // WebプラットフォームではFirebaseが初期化されていない可能性がある
        if (Firebase.apps.isEmpty) {
          return null;
        }
      }
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firebase Firestore取得エラー: $e');
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      if (kIsWeb) {
        // WebプラットフォームではFirebaseが初期化されていない可能性がある
        if (Firebase.apps.isEmpty) {
          return null;
        }
      }
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth取得エラー: $e');
      return null;
    }
  }
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isStoreAvailable = false;

  final Set<String> _androidProductIds = {
    'maikago_premium_unlock',
  };

  final Map<String, ProductDetails> _productIdToDetails = {};
  Completer<bool>? _restoreCompleter;

  static const String _prefsPremiumStatusMapKey = 'premium_status_map';
  static const String _prefsLegacyPremiumKey = 'premium_unlocked';
  static const String _legacyUserKey = '_legacy_default';

  // 購入済み機能の状態
  final Map<String, bool> _userPremiumStatus = {};
  String _currentUserId = '';

  // 体験期間の状態
  bool _isTrialActive = false;
  DateTime? _trialStartDate;
  DateTime? _trialEndDate;
  Timer? _trialEndTimer; // 体験期間終了を監視するタイマー
  bool _isTrialEverStarted = false; // 体験期間が一度でも開始されたか

  // デバイスフィンガープリント
  String? _deviceFingerprint;

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false; // 追加

  // Getters
  bool get isPremiumUnlocked =>
      (_userPremiumStatus[_currentUserId] ?? false) || _isTrialActive;
  bool get isPremiumPurchased =>
      _userPremiumStatus[_currentUserId] ?? false; // 実際の購入状態（体験期間除く）
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isStoreAvailable => _isStoreAvailable;
  bool get isInitialized => _isInitialized; // 初期化完了状態を公開

  // 体験期間のgetter
  bool get isTrialActive => _isTrialActive;
  bool get isTrialEverStarted => _isTrialEverStarted; // 追加
  DateTime? get trialStartDate => _trialStartDate;
  DateTime? get trialEndDate => _trialEndDate;

  // 体験期間の残り時間を取得
  Duration? get trialRemainingDuration {
    if (!_isTrialActive || _trialEndDate == null) return null;
    final now = DateTime.now();
    final remaining = _trialEndDate!.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// デバイスフィンガープリントを生成
  Future<String> _generateDeviceFingerprint() async {
    try {
      // WebプラットフォームではSharedPreferencesを使用（DeviceInfoPluginは使用しない）
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        String? storedId = prefs.getString('device_fingerprint');
        if (storedId == null) {
          storedId = sha256
              .convert(utf8.encode(
                  '${DateTime.now().millisecondsSinceEpoch}_${Uri.base.host}'))
              .toString();
          await prefs.setString('device_fingerprint', storedId);
        }
        debugPrint('デバイスフィンガープリント生成: ${storedId.substring(0, 8)}...');
        return storedId;
      }

      // ネイティブプラットフォームではDeviceInfoを使用
      String deviceId = '';
      try {
        final deviceInfo = DeviceInfoPlugin();
        // defaultTargetPlatformを使用してプラットフォームを判定
        // Platformクラスは条件付きインポートで使用できないため、defaultTargetPlatformを使用
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          // Android ID + モデル名のハッシュ
          final rawId = '${androidInfo.id}_${androidInfo.model}';
          deviceId = sha256.convert(utf8.encode(rawId)).toString();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          // identifierForVendor
          deviceId = sha256
              .convert(utf8.encode(iosInfo.identifierForVendor ?? 'unknown'))
              .toString();
        }
      } catch (e) {
        debugPrint('デバイス情報取得エラー: $e');
      }

      // デバイス情報が取得できなかった場合、SharedPreferencesを使用
      if (deviceId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        String? storedId = prefs.getString('device_fingerprint');
        if (storedId == null) {
          storedId = sha256
              .convert(utf8.encode(
                  '${DateTime.now().millisecondsSinceEpoch}_fallback'))
              .toString();
          await prefs.setString('device_fingerprint', storedId);
        }
        deviceId = storedId;
      }

      debugPrint('デバイスフィンガープリント生成: ${deviceId.substring(0, 8)}...');
      return deviceId;
    } catch (e) {
      debugPrint('デバイスフィンガープリント生成エラー: $e');
      // フォールバック: タイムスタンプベースのID
      return sha256
          .convert(
              utf8.encode('${DateTime.now().millisecondsSinceEpoch}_fallback'))
          .toString();
    }
  }

  /// 初期化
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      debugPrint('非消耗型アプリ内課金サービスは既に初期化済みです。');
      if (userId != null) {
        _currentUserId = userId;
        await _loadFromFirestore();
        notifyListeners(); // ユーザーID変更時の通知を追加
      }
      return;
    }
    try {
      debugPrint('非消耗型アプリ内課金初期化開始');
      await _initializeStore();
      await _loadFromLocalStorage();
      _currentUserId = userId ?? _auth?.currentUser?.uid ?? '';

      // デバイスフィンガープリントを生成
      _deviceFingerprint = await _generateDeviceFingerprint();

      await _loadFromFirestore();
      debugPrint('非消耗型アプリ内課金初期化完了');
      // 初期化時に体験期間タイマーをセット
      _startTrialTimer();
      _isInitialized = true; // 初期化完了後にフラグを設定
      // 初期化完了をリスナーに通知
      notifyListeners();
    } catch (e) {
      debugPrint('非消耗型アプリ内課金初期化エラー: $e');
      _setError('初期化に失敗しました: $e');
      _isInitialized = true; // エラーでも初期化完了とする
      notifyListeners(); // エラー時も通知
    }
  }

  /// ストア初期化（In-App Purchase）
  Future<void> _initializeStore() async {
    try {
      debugPrint('非消耗型アプリ内課金ストア初期化開始');

      // WebプラットフォームではIAPをスキップ
      if (kIsWeb) {
        debugPrint('IAP: Webプラットフォームではスキップ');
        _isStoreAvailable = false;
        return;
      }

      // プラットフォームチェック（Web以外）
      // defaultTargetPlatformを使用してプラットフォームを判定
      // Platformクラスは条件付きインポートで使用できないため、defaultTargetPlatformを使用
      try {
        if (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
          debugPrint('IAP: サポートされていないプラットフォーム');
          _isStoreAvailable = false;
          return;
        }
      } catch (e) {
        debugPrint('プラットフォーム判定エラー: $e');
        _isStoreAvailable = false;
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
      // エラーを再スローせず、ローカルモードで継続
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
      _userPremiumStatus[_currentUserId] = true;
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
      final premiumMapString = prefs.getString(_prefsPremiumStatusMapKey);
      if (premiumMapString != null) {
        final decoded = Map<String, dynamic>.from(
            jsonDecode(premiumMapString) as Map<String, dynamic>);
        _userPremiumStatus
          ..clear()
          ..addAll(decoded.map(
            (key, value) => MapEntry(key, value == true),
          ));
      } else {
        final legacyValue = prefs.getBool(_prefsLegacyPremiumKey);
        if (legacyValue != null) {
          _userPremiumStatus[_legacyUserKey] = legacyValue;
        }
      }

      // 体験期間の情報を読み込み
      _isTrialActive = prefs.getBool('trial_active') ?? false;
      final trialStartTimestamp = prefs.getInt('trial_start_timestamp');
      final trialEndTimestamp = prefs.getInt('trial_end_timestamp');
      _isTrialEverStarted =
          prefs.getBool('trial_ever_started') ?? false; // 体験期間が一度でも開始されたかを読み込み

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
      final encoded = jsonEncode(_userPremiumStatus);
      await prefs.setString(_prefsPremiumStatusMapKey, encoded);

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
      await prefs.setBool(
          'trial_ever_started', _isTrialEverStarted); // 体験期間が一度でも開始されたかを保存

      debugPrint('非消耗型購入状態をローカルストレージに保存完了');
    } catch (e) {
      debugPrint('非消耗型ローカルストレージ保存エラー: $e');
    }
  }

  /// Firestoreから読み込み
  Future<void> _loadFromFirestore() async {
    try {
      if (_currentUserId.isEmpty || _deviceFingerprint == null) {
        return;
      }

      // WebプラットフォームではFirebaseが初期化されていない可能性があるため、早期リターン
      if (kIsWeb) {
        try {
          if (Firebase.apps.isEmpty) {
            debugPrint('Firestoreが利用できません（Webプラットフォーム: Firebase未初期化）');
            return;
          }
        } catch (e) {
          debugPrint('Firebase初期化状態確認エラー（Web）: $e');
          return;
        }
      }

      final firestore = _firestore;
      if (firestore == null) {
        debugPrint('Firestoreが利用できません（Webプラットフォームまたは未初期化）');
        return;
      }

      final doc = await firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('purchases')
          .doc('one_time_purchases')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final map = Map<String, dynamic>.from(
          data['premium_status_map'] as Map? ?? {},
        );
        final bool status = map[_currentUserId] == true;
        _userPremiumStatus[_currentUserId] = status;

        // 体験期間履歴をチェック
        final trialHistory =
            data['trial_history'] as Map<String, dynamic>? ?? {};
        if (trialHistory.containsKey(_deviceFingerprint)) {
          final deviceTrialData =
              trialHistory[_deviceFingerprint!] as Map<String, dynamic>?;
          if (deviceTrialData != null &&
              deviceTrialData['ever_started'] == true) {
            // このデバイスで体験期間が開始されていた場合、制限を適用
            _isTrialEverStarted = true;
            debugPrint(
                'デバイスベースの体験期間制限を適用: ${_deviceFingerprint!.substring(0, 8)}...');
          }
        }

        debugPrint('非消耗型購入状態をFirestoreから読み込み完了');
      }
    } catch (e) {
      debugPrint('非消耗型Firestore読み込みエラー: $e');
      // WebプラットフォームではFirebaseExceptionがJavaScriptObjectにキャストできないエラーが発生する可能性がある
      if (kIsWeb) {
        debugPrint('WebプラットフォームではFirestore読み込みをスキップします');
      }
      // エラーを再スローせず、ローカルモードで継続
    }
  }

  /// Firestoreに保存
  Future<void> _saveToFirestore() async {
    try {
      if (_currentUserId.isEmpty || _deviceFingerprint == null) {
        return;
      }

      // WebプラットフォームではFirebaseが初期化されていない可能性があるため、早期リターン
      if (kIsWeb) {
        try {
          if (Firebase.apps.isEmpty) {
            debugPrint('Firestoreが利用できません（Webプラットフォーム: Firebase未初期化）');
            return;
          }
        } catch (e) {
          debugPrint('Firebase初期化状態確認エラー（Web）: $e');
          return;
        }
      }

      final firestore = _firestore;
      if (firestore == null) {
        debugPrint('Firestoreが利用できません（Webプラットフォームまたは未初期化）');
        return;
      }

      // 体験期間履歴データを準備
      Map<String, dynamic> trialHistory = {};
      if (_isTrialEverStarted) {
        trialHistory[_deviceFingerprint!] = {
          'ever_started': _isTrialEverStarted,
          'start_date': _trialStartDate != null
              ? Timestamp.fromDate(_trialStartDate!)
              : null,
          'end_date':
              _trialEndDate != null ? Timestamp.fromDate(_trialEndDate!) : null,
          'user_id': _currentUserId,
          'device_fingerprint': _deviceFingerprint!,
        };
      }

      await firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('purchases')
          .doc('one_time_purchases')
          .set({
        'premium_status_map': {
          _currentUserId: _userPremiumStatus[_currentUserId] ?? false,
        },
        'trial_history': trialHistory,
        'updated_at': FieldValue.serverTimestamp(),
      });

      debugPrint('非消耗型購入状態をFirestoreに保存完了');
    } catch (e) {
      debugPrint('非消耗型Firestore保存エラー: $e');
      // WebプラットフォームではFirebaseExceptionがJavaScriptObjectにキャストできないエラーが発生する可能性がある
      if (kIsWeb) {
        debugPrint('WebプラットフォームではFirestore保存をスキップします');
      }
      // エラーを再スローせず、ローカルモードで継続
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
    // デバイスフィンガープリントベースでの二重開始チェック
    if (_isTrialEverStarted) {
      debugPrint('このデバイスでは既に体験期間が使用されています');
      return; // 体験期間開始を拒否
    }

    _isTrialActive = true;
    _isTrialEverStarted = true; // 体験期間が開始されたことを記録
    _trialStartDate = DateTime.now();
    _trialEndDate = _trialStartDate!.add(Duration(days: trialDays));

    _saveToLocalStorage();
    _saveToFirestore();
    _startTrialTimer(); // 体験期間タイマーを開始
    notifyListeners();

    debugPrint('体験期間開始: $trialDays日間');
  }

  /// 体験期間を終了
  void endTrial() {
    _isTrialActive = false;
    _trialStartDate = null;
    _trialEndDate = null;

    _cancelTrialTimer(); // 体験期間タイマーをキャンセル
    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    debugPrint('体験期間終了');
  }

  /// 体験期間終了を監視するタイマーを開始
  void _startTrialTimer() {
    _cancelTrialTimer(); // 既存のタイマーをキャンセル
    if (_isTrialActive && _trialEndDate != null) {
      final remainingDuration = _trialEndDate!.difference(DateTime.now());
      if (remainingDuration.isNegative) {
        // すでに期限切れの場合、即座に終了処理を行う
        endTrial();
        return;
      }
      _trialEndTimer = Timer(remainingDuration, () {
        debugPrint('デバッグログ: 体験期間タイマーが終了しました。'); // 日本語のデバッグログ
        endTrial();
      });
      debugPrint(
          'デバッグログ: 体験期間タイマーを開始しました。残り ${remainingDuration.inSeconds} 秒です。'); // 日本語のデバッグログ
      // タイマーが発火するたびに残り時間を更新
      _trialEndTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isTrialActive || _trialEndDate == null) {
          _cancelTrialTimer();
          return;
        }
        if (DateTime.now().isAfter(_trialEndDate!)) {
          endTrial();
        } else {
          notifyListeners(); // UIを更新するために通知
        }
      });
    }
  }

  /// 体験期間終了タイマーをキャンセル
  void _cancelTrialTimer() {
    _trialEndTimer?.cancel();
    _trialEndTimer = null;
    debugPrint('デバッグログ: 体験期間タイマーをキャンセルしました。'); // 日本語のデバッグログ
  }

  /// リソースを解放
  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _cancelTrialTimer(); // dispose時にもタイマーをキャンセル
    super.dispose();
  }
}
