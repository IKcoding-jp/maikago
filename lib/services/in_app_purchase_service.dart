import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'donation_manager.dart';

/// アプリ内購入サービス
/// Google Play ストア向けの寄付機能を管理
class InAppPurchaseService extends ChangeNotifier {
  static final InAppPurchaseService _instance =
      InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;
  Function(int)? _onPurchaseComplete;

  // 寄付商品のID
  static const Set<String> _donationProductIds = {
    'donation_300', // ¥300
    'donation_500', // ¥500
    'donation_1000', // ¥1000
    'donation_2000', // ¥2000
    'donation_5000', // ¥5000
  };

  /// 商品IDから金額を取得
  static int getAmountFromProductId(String productId) {
    switch (productId) {
      case 'donation_300':
        return 300;
      case 'donation_500':
        return 500;
      case 'donation_1000':
        return 1000;
      case 'donation_2000':
        return 2000;
      case 'donation_5000':
        return 5000;
      default:
        return 0;
    }
  }

  /// 金額から商品IDを取得
  static String? getProductIdFromAmount(int amount) {
    switch (amount) {
      case 300:
        return 'donation_300';
      case 500:
        return 'donation_500';
      case 1000:
        return 'donation_1000';
      case 2000:
        return 'donation_2000';
      case 5000:
        return 'donation_5000';
      default:
        return null;
    }
  }

  /// 利用可能な商品リスト
  List<ProductDetails> get products => _products;

  /// アプリ内購入が利用可能かどうか
  bool get isAvailable => _isAvailable;

  /// 購入処理中かどうか
  bool get purchasePending => _purchasePending;

  /// エラーメッセージ
  String? get queryProductError => _queryProductError;

  /// 初期化
  Future<void> initialize() async {
    try {
      // アプリ内購入が利用可能かチェック
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        debugPrint('アプリ内購入が利用できません');
        return;
      }

      // 購入状態の監視を開始
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => debugPrint('購入ストリームエラー: $error'),
      );

      // 商品情報を取得
      await _loadProducts();

      debugPrint('アプリ内購入サービスが初期化されました');
    } catch (e) {
      debugPrint('アプリ内購入の初期化エラー: $e');
    }
  }

  /// 商品情報を読み込み
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_donationProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('見つからない商品ID: ${response.notFoundIDs}');
      }

      _products.clear();
      _products.addAll(response.productDetails);

      _queryProductError = response.error?.message;

      // テスト用：商品が読み込まれない場合はダミー商品を追加
      if (_products.isEmpty) {
        debugPrint('商品が読み込まれませんでした。テスト用のダミー商品を追加します。');
        _addDummyProducts();
      }

      notifyListeners();
      debugPrint('商品情報を読み込みました: ${_products.length}個');
    } catch (e) {
      debugPrint('商品情報の読み込みエラー: $e');
      _queryProductError = e.toString();

      // エラー時もダミー商品を追加
      _addDummyProducts();
      notifyListeners();
    }
  }

  /// テスト用のダミー商品を追加
  void _addDummyProducts() {
    // ダミーのProductDetailsを作成（テスト用）
    final dummyProducts = [
      _createDummyProduct('donation_300', '¥300'),
      _createDummyProduct('donation_500', '¥500'),
      _createDummyProduct('donation_1000', '¥1000'),
      _createDummyProduct('donation_2000', '¥2000'),
      _createDummyProduct('donation_5000', '¥5000'),
    ];

    _products.addAll(dummyProducts);
    debugPrint('ダミー商品を追加しました: ${_products.length}個');
  }

  /// ダミー商品を作成（テスト用）
  ProductDetails _createDummyProduct(String id, String price) {
    return ProductDetails(
      id: id,
      title: '寄付 $price',
      description: 'まいカゴへの寄付 $price',
      price: price,
      rawPrice: 0.0,
      currencyCode: 'JPY',
    );
  }

  /// 購入処理
  Future<bool> purchaseProduct(String productId) async {
    try {
      final ProductDetails product = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('商品が見つかりません: $productId'),
      );

      _purchasePending = true;
      notifyListeners();

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      bool success = false;
      if (Platform.isAndroid) {
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else if (Platform.isIOS) {
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }

      if (!success) {
        _purchasePending = false;
        notifyListeners();
        debugPrint('購入の開始に失敗しました');
        return false;
      }

      debugPrint('購入を開始しました: $productId');
      return true;
    } catch (e) {
      _purchasePending = false;
      notifyListeners();
      debugPrint('購入エラー: $e');
      return false;
    }
  }

  /// 購入状態の更新処理
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  /// 購入の処理
  void _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint('購入処理中: ${purchaseDetails.productID}');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      _purchasePending = false;
      notifyListeners();
      debugPrint('購入エラー: ${purchaseDetails.error}');
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      _purchasePending = false;
      notifyListeners();

      // 購入完了の処理
      await _completePurchase(purchaseDetails);
    }

    // 購入が完了したら、購入詳細を完了としてマーク
    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// 購入完了の処理
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    try {
      final int amount = getAmountFromProductId(purchaseDetails.productID);

      if (amount >= 300) {
        // DonationManagerを使用して特典を有効化
        final donationManager = DonationManager();
        await donationManager.processDonation(amount);

        // コールバックを実行
        _onPurchaseComplete?.call(amount);

        debugPrint('寄付特典が有効になりました: ¥$amount (${purchaseDetails.productID})');
      }
    } catch (e) {
      debugPrint('購入完了処理エラー: $e');
    }
  }

  /// 購入完了時のコールバックを設定
  void setPurchaseCompleteCallback(Function(int) callback) {
    _onPurchaseComplete = callback;
  }

  /// 購入履歴を復元（iOS用）
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('購入履歴の復元を開始しました');
    } catch (e) {
      debugPrint('購入履歴の復元エラー: $e');
    }
  }

  /// 破棄
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// 商品情報を取得
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// 金額から商品情報を取得
  ProductDetails? getProductByAmount(int amount) {
    final productId = getProductIdFromAmount(amount);
    if (productId != null) {
      return getProductById(productId);
    }
    return null;
  }
}
