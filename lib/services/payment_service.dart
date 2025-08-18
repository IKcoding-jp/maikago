// 決済システム統合サービス
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_service.dart';
import 'in_app_purchase_service.dart';
import '../config.dart';
import '../config/subscription_ids.dart';
import '../models/subscription_plan.dart';

/// 決済プラットフォームの種類
enum PaymentPlatform {
  googlePlay, // Android
  appStore, // iOS
  stripe, // Web
}

/// 決済商品の種類
enum ProductType {
  basicMonthly,
  basicYearly,
  premiumMonthly,
  premiumYearly,
  familyMonthly,
  familyYearly,
}

/// 決済状態
enum PaymentStatus {
  idle,
  loading,
  purchasing,
  restoring,
  success,
  failed,
  cancelled,
}

/// 決済エラーの種類
enum PaymentErrorType {
  network,
  invalidProduct,
  purchaseCancelled,
  purchaseFailed,
  restoreFailed,
  platformNotSupported,
  unknown,
}

/// 決済エラー情報
class PaymentError {
  final PaymentErrorType type;
  final String message;
  final String? details;

  PaymentError({required this.type, required this.message, this.details});

  @override
  String toString() =>
      'PaymentError(type: $type, message: $message, details: $details)';
}

/// サブスクリプション情報
class PaymentProduct {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final ProductType type;
  final SubscriptionPlan plan;

  PaymentProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.plan,
  });

  factory PaymentProduct.fromProductDetails(ProductDetails product) {
    try {
      final type = _getProductTypeFromId(product.id);
      final plan = _getPlanFromProductType(type);

      return PaymentProduct(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.rawPrice,
        currency: product.currencyCode,
        type: type,
        plan: plan,
      );
    } catch (e) {
      debugPrint(
        'PaymentService: Error in PaymentProduct.fromProductDetails: $e',
      );
      // フォールバック用のデフォルト値で作成
      return PaymentProduct(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.rawPrice,
        currency: product.currencyCode,
        type: ProductType.basicMonthly, // デフォルト値
        plan: SubscriptionPlan.basic, // デフォルト値
      );
    }
  }

  static ProductType _getProductTypeFromId(String id) {
    try {
      switch (id) {
        case SubscriptionIds.basicMonthly:
          return ProductType.basicMonthly;
        case SubscriptionIds.basicYearly:
          return ProductType.basicYearly;
        case SubscriptionIds.premiumMonthly:
          return ProductType.premiumMonthly;
        case SubscriptionIds.premiumYearly:
          return ProductType.premiumYearly;
        case SubscriptionIds.familyMonthly:
          return ProductType.familyMonthly;
        case SubscriptionIds.familyYearly:
          return ProductType.familyYearly;
        default:
          debugPrint(
            'PaymentService: Unknown product ID: $id, using basicMonthly as fallback',
          );
          return ProductType.basicMonthly; // フォールバック
      }
    } catch (e) {
      debugPrint('PaymentService: Error in _getProductTypeFromId: $e');
      return ProductType.basicMonthly; // エラー時のフォールバック
    }
  }

  static SubscriptionPlan _getPlanFromProductType(ProductType type) {
    switch (type) {
      case ProductType.basicMonthly:
      case ProductType.basicYearly:
        return SubscriptionPlan.basic;
      case ProductType.premiumMonthly:
      case ProductType.premiumYearly:
        return SubscriptionPlan.premium;
      case ProductType.familyMonthly:
      case ProductType.familyYearly:
        return SubscriptionPlan.family;
    }
  }
}

/// 決済システム統合サービス
class PaymentService extends ChangeNotifier {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// 初期化済みフラグ
  bool _isInitialized = false;

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  /// 初期化を実行
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PaymentService: Already initialized');
      return;
    }

    try {
      await _initialize();
      _isInitialized = true;
      debugPrint('PaymentService: Initialization completed successfully');
    } catch (e) {
      debugPrint('PaymentService: Initialization failed: $e');
      // 初期化に失敗した場合でもダミー商品を追加（まだ追加されていない場合のみ）
      if (_products.isEmpty) {
        _addDummyProducts();
      }
      _isInitialized = true; // エラーでも初期化済みとする
    }
  }

  // サブスクリプションID定義
  static final Set<String> _productIds = SubscriptionIds.allBasePlans;

  // インスタンス変数
  late final InAppPurchase _inAppPurchase;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  late final SubscriptionService _subscriptionService;
  late final InAppPurchaseService _inAppPurchaseService;

  List<ProductDetails> _products = [];
  final List<PaymentProduct> _paymentProducts = [];
  PaymentStatus _status = PaymentStatus.idle;
  PaymentError? _lastError;
  bool _isAvailable = false;
  String? _currentUserId;

  // ゲッター
  List<ProductDetails> get products => _products;
  List<PaymentProduct> get paymentProducts => _paymentProducts;
  PaymentStatus get status => _status;
  PaymentError? get lastError => _lastError;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _status == PaymentStatus.loading;
  bool get isPurchasing => _status == PaymentStatus.purchasing;
  bool get isRestoring => _status == PaymentStatus.restoring;

  /// 商品IDから商品情報を取得
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      debugPrint('PaymentService: Product not found in _products: $productId');
      // InAppPurchaseServiceから取得を試行
      try {
        final iapService = InAppPurchaseService();
        final iapProducts = iapService.products;
        final product = iapProducts.firstWhere((p) => p.id == productId);

        // 見つかった商品を_productsに追加
        if (!_products.any((p) => p.id == productId)) {
          _products.add(product);
          debugPrint(
            'PaymentService: Added product from InAppPurchaseService: $productId',
          );
        }

        return product;
      } catch (e2) {
        debugPrint(
          'PaymentService: Product not found in InAppPurchaseService: $productId',
        );
        return null;
      }
    }
  }

  /// 初期化
  Future<void> _initialize() async {
    try {
      debugPrint('PaymentService: Initializing payment service...');

      _inAppPurchase = InAppPurchase.instance;
      _subscriptionService = SubscriptionService();
      _inAppPurchaseService = InAppPurchaseService();

      // InAppPurchaseServiceも初期化
      debugPrint('PaymentService: Initializing InAppPurchaseService...');
      await _inAppPurchaseService.initialize();

      // プラットフォームの可用性をチェック
      _isAvailable = await _inAppPurchase.isAvailable();
      debugPrint('PaymentService: In-app purchases available: $_isAvailable');

      if (_isAvailable) {
        debugPrint('PaymentService: Setting up purchase stream...');

        // 購入ストリームの監視を開始
        _subscription = _inAppPurchase.purchaseStream.listen(
          _onPurchaseUpdate,
          onDone: () {
            debugPrint('PaymentService: Purchase stream done');
            _subscription.cancel();
          },
          onError: (error) {
            debugPrint('PaymentService: Purchase stream error: $error');
            _handleError(PaymentErrorType.unknown, error.toString());
          },
        );

        // 商品情報を取得
        debugPrint('PaymentService: Loading products...');
        await _loadProducts();
      } else {
        debugPrint(
          'PaymentService: In-app purchases not available on this platform',
        );
        // プラットフォームが利用できない場合でもダミー商品を追加
        debugPrint('PaymentService: Adding dummy products for testing...');
        _addDummyProducts();
      }
    } catch (e) {
      debugPrint('PaymentService: Initialization error: $e');
      // エラーが発生した場合でもダミー商品を追加
      debugPrint(
        'PaymentService: Adding dummy products due to initialization error...',
      );
      _addDummyProducts();
      _handleError(
        PaymentErrorType.unknown,
        'Failed to initialize payment service: $e',
      );
    }
  }

  /// 現在のユーザーIDを設定
  void setCurrentUserId(String? userId) {
    debugPrint('PaymentService: Setting current user ID: $userId');
    _currentUserId = userId;
  }

  /// サブスクリプション情報を読み込み
  Future<void> _loadProducts() async {
    if (!_isAvailable) {
      debugPrint('PaymentService: In-app purchases not available');
      // 利用できない場合でもダミー商品を追加
      _addDummyProducts();
      return;
    }

    try {
      _setStatus(PaymentStatus.loading);

      debugPrint(
        'PaymentService: Loading subscriptions with IDs: $_productIds',
      );

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_productIds);

      debugPrint('PaymentService: Query response - Error: ${response.error}');
      debugPrint(
        'PaymentService: Found subscriptions: ${response.productDetails.length}',
      );
      debugPrint('PaymentService: Not found IDs: ${response.notFoundIDs}');

      // 詳細なデバッグ情報を追加
      debugPrint('PaymentService: Requested product IDs:');
      for (final id in _productIds) {
        debugPrint('  - $id');
      }

      debugPrint('PaymentService: Found product details:');
      for (final product in response.productDetails) {
        debugPrint(
          '  - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}',
        );
      }

      debugPrint('PaymentService: Not found product IDs:');
      for (final id in response.notFoundIDs) {
        debugPrint('  - $id');
      }

      // エラー情報の詳細出力
      if (response.error != null) {
        debugPrint('PaymentService: Product query error:');
        debugPrint('  Error: ${response.error}');
        debugPrint('  Error code: ${response.error!.code}');
        debugPrint('  Error message: ${response.error!.message}');
        debugPrint('  Error details: ${response.error!.details}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'PaymentService: Subscriptions not found: ${response.notFoundIDs}',
        );
        // サブスクリプションが見つからない場合はダミー商品を追加
        if (_products.isEmpty) {
          debugPrint(
            'PaymentService: Will add dummy products, ignoring not found error',
          );
        }
      }

      _products = response.productDetails;

      // PaymentProductを安全に作成
      _paymentProducts.clear();
      for (final product in _products) {
        try {
          final paymentProduct = PaymentProduct.fromProductDetails(product);
          _paymentProducts.add(paymentProduct);
        } catch (e) {
          debugPrint(
            'PaymentService: Error creating PaymentProduct for ${product.id}: $e',
          );
        }
      }

      // テスト用：商品が読み込まれない場合はダミー商品を追加
      if (_products.isEmpty) {
        debugPrint(
          'PaymentService: No subscriptions found. Adding dummy products for testing.',
        );
        _addDummyProducts();
      } else {
        debugPrint(
          'PaymentService: Successfully loaded ${_products.length} real products',
        );
      }

      // InAppPurchaseServiceの商品情報を確認して追加（重複を避けるため条件付き）
      if (_products.isEmpty) {
        await _tryLoadFromInAppPurchaseService();
      }

      debugPrint('PaymentService: Loaded ${_products.length} subscriptions');
      for (final product in _products) {
        debugPrint(
          'PaymentService: Subscription - ID: ${product.id}, Title: ${product.title}, Price: ${product.rawPrice}',
        );
      }

      _setStatus(PaymentStatus.idle);
    } catch (e) {
      debugPrint('PaymentService: Error loading subscriptions: $e');
      // エラーが発生した場合でもダミー商品を追加
      if (_products.isEmpty) {
        _addDummyProducts();
      }
      _handleError(
        PaymentErrorType.unknown,
        'Failed to load subscriptions: $e',
      );
    }
  }

  /// サブスクリプション情報を再読み込み
  Future<void> refreshProducts() async {
    debugPrint('PaymentService: Refreshing subscriptions...');
    await _loadProducts();
    debugPrint('PaymentService: Subscriptions refresh completed');
  }

  /// テスト用のダミー商品を追加
  void _addDummyProducts() {
    debugPrint(
      'PaymentService: Adding dummy subscription products for testing',
    );

    try {
      // 既に商品が存在する場合は追加しない
      if (_products.isNotEmpty) {
        debugPrint(
          'PaymentService: Products already exist, skipping dummy products',
        );
        return;
      }

      // InAppPurchaseServiceから既存の商品を取得
      final iapService = InAppPurchaseService();
      final existingProducts = iapService.products;

      // サブスクリプション商品のみをフィルタリング
      final subscriptionProducts = existingProducts
          .where((p) => _productIds.contains(p.id))
          .toList();

      if (subscriptionProducts.isNotEmpty) {
        debugPrint(
          'PaymentService: Found ${subscriptionProducts.length} subscription products from InAppPurchaseService',
        );

        // 既存の商品を追加
        for (final product in subscriptionProducts) {
          if (!_products.any((p) => p.id == product.id)) {
            _products.add(product);
            debugPrint(
              'PaymentService: Added subscription product: ${product.id}',
            );
          }
        }
      } else {
        debugPrint(
          'PaymentService: No subscription products found in InAppPurchaseService',
        );
      }

      // PaymentProductを安全に作成
      _paymentProducts.clear();
      for (final product in _products) {
        try {
          final paymentProduct = PaymentProduct.fromProductDetails(product);
          _paymentProducts.add(paymentProduct);
        } catch (e) {
          debugPrint(
            'PaymentService: Error creating PaymentProduct for ${product.id}: $e',
          );
          // エラーが発生した場合は、手動でPaymentProductを作成
          try {
            final manualProduct = _createManualPaymentProduct(product);
            if (manualProduct != null) {
              _paymentProducts.add(manualProduct);
              debugPrint(
                'PaymentService: Created manual PaymentProduct for ${product.id}',
              );
            }
          } catch (manualError) {
            debugPrint(
              'PaymentService: Failed to create manual PaymentProduct for ${product.id}: $manualError',
            );
          }
        }
      }

      debugPrint(
        'PaymentService: Added ${_products.length} subscription products',
      );
      for (final product in _products) {
        debugPrint(
          'PaymentService: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}',
        );
      }
    } catch (e) {
      debugPrint('PaymentService: Error adding dummy products: $e');
    }
  }


  /// サブスクリプションを購入
  Future<void> purchaseProduct(ProductDetails product) async {
    debugPrint(
      'PaymentService: Attempting to purchase subscription: ${product.id}',
    );

    if (!_isAvailable) {
      debugPrint('PaymentService: In-app purchases not available for purchase');
      _handleError(
        PaymentErrorType.platformNotSupported,
        'In-app purchases are not available',
      );
      return;
    }

    try {
      _setStatus(PaymentStatus.purchasing);
      debugPrint('PaymentService: Creating purchase param for: ${product.id}');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      if (product.id.contains('monthly') || product.id.contains('yearly')) {
        // サブスクリプション（定期購入）
        debugPrint('PaymentService: Purchasing subscription: ${product.id}');
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // 通常の商品（消耗品）
        debugPrint('PaymentService: Purchasing consumable: ${product.id}');
        await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('PaymentService: Purchase error: $e');
      _handleError(PaymentErrorType.purchaseFailed, 'Purchase failed: $e');
    }
  }

  /// サブスクリプションIDで購入
  Future<void> purchaseProductById(String productId) async {
    debugPrint(
      'PaymentService: Attempting to purchase subscription by ID: $productId',
    );

    try {
      // 初期化チェック
      if (!_isInitialized) {
        debugPrint('PaymentService: Not initialized, initializing now...');
        await initialize();
      }

      debugPrint(
        'PaymentService: Available subscriptions: ${_products.map((p) => p.id).toList()}',
      );

      // 商品が空の場合は再読み込みを試行
      if (_products.isEmpty) {
        debugPrint(
          'PaymentService: No products available, attempting to reload...',
        );
        await _loadProducts();

        if (_products.isEmpty) {
          debugPrint(
            'PaymentService: Still no products available after reload',
          );

          // InAppPurchaseServiceから商品を取得して再試行
          await _tryLoadFromInAppPurchaseService();

          if (_products.isEmpty) {
            _handleError(
              PaymentErrorType.invalidProduct,
              'No subscription products available',
            );
            return;
          }
        }
      }

      // 商品を検索
      ProductDetails? product;
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (e) {
        // 商品が見つからない場合、InAppPurchaseServiceから取得を試行
        debugPrint(
          'PaymentService: Product not found in _products, checking InAppPurchaseService...',
        );
        await _tryLoadFromInAppPurchaseService();

        // 再度検索
        try {
          product = _products.firstWhere((p) => p.id == productId);
        } catch (e2) {
          debugPrint('PaymentService: Subscription not found: $productId');
          debugPrint(
            'PaymentService: Available IDs: ${_products.map((p) => p.id).toList()}',
          );
          _handleError(
            PaymentErrorType.invalidProduct,
            'Subscription not found: $productId',
          );
          return;
        }
      }

      debugPrint(
        'PaymentService: Found subscription for purchase: ${product.id}',
      );
      await purchaseProduct(product);
    } catch (e) {
      debugPrint('PaymentService: Error in purchaseProductById: $e');
      _handleError(PaymentErrorType.unknown, 'Failed to purchase product: $e');
    }
  }

  /// InAppPurchaseServiceから商品を取得して追加
  Future<void> _tryLoadFromInAppPurchaseService() async {
    try {
      debugPrint(
        'PaymentService: Trying to load products from InAppPurchaseService...',
      );

      final iapService = InAppPurchaseService();
      await iapService.initialize(); // 確実に初期化

      final iapProducts = iapService.products;
      final subscriptionProducts = iapProducts
          .where((p) => _productIds.contains(p.id))
          .toList();

      if (subscriptionProducts.isNotEmpty) {
        debugPrint(
          'PaymentService: Found ${subscriptionProducts.length} subscription products from InAppPurchaseService',
        );

        // 既存の商品リストに重複しない商品を追加
        for (final product in subscriptionProducts) {
          if (!_products.any((p) => p.id == product.id)) {
            _products.add(product);
            debugPrint(
              'PaymentService: Added subscription product from InAppPurchaseService: ${product.id}',
            );
          }
        }

        // PaymentProductを安全に作成
        _paymentProducts.clear();
        for (final product in _products) {
          try {
            final paymentProduct = PaymentProduct.fromProductDetails(product);
            _paymentProducts.add(paymentProduct);
          } catch (e) {
            debugPrint(
              'PaymentService: Error creating PaymentProduct for ${product.id}: $e',
            );
          }
        }

        notifyListeners();
      } else {
        debugPrint(
          'PaymentService: No subscription products found in InAppPurchaseService',
        );
      }
    } catch (e) {
      debugPrint('PaymentService: Error loading from InAppPurchaseService: $e');
    }
  }

  /// 手動でPaymentProductを作成
  PaymentProduct? _createManualPaymentProduct(ProductDetails product) {
    try {
      final type = _getProductTypeFromId(product.id);
      final plan = _getPlanFromProductType(type);

      return PaymentProduct(
        id: product.id,
        title: product.title,
        description: product.description,
        price: product.rawPrice,
        currency: product.currencyCode,
        type: type,
        plan: plan,
      );
    } catch (e) {
      debugPrint('PaymentService: Error in _createManualPaymentProduct: $e');
      return null;
    }
  }

  /// 商品IDからProductTypeを取得
  static ProductType _getProductTypeFromId(String id) {
    switch (id) {
      case SubscriptionIds.basicMonthly:
        return ProductType.basicMonthly;
      case SubscriptionIds.basicYearly:
        return ProductType.basicYearly;
      case SubscriptionIds.premiumMonthly:
        return ProductType.premiumMonthly;
      case SubscriptionIds.premiumYearly:
        return ProductType.premiumYearly;
      case SubscriptionIds.familyMonthly:
        return ProductType.familyMonthly;
      case SubscriptionIds.familyYearly:
        return ProductType.familyYearly;
      default:
        throw ArgumentError('Unknown product ID: $id');
    }
  }

  /// ProductTypeからSubscriptionPlanを取得
  static SubscriptionPlan _getPlanFromProductType(ProductType type) {
    switch (type) {
      case ProductType.basicMonthly:
      case ProductType.basicYearly:
        return SubscriptionPlan.basic;
      case ProductType.premiumMonthly:
      case ProductType.premiumYearly:
        return SubscriptionPlan.premium;
      case ProductType.familyMonthly:
      case ProductType.familyYearly:
        return SubscriptionPlan.family;
    }
  }

  /// サブスクリプション履歴を復元
  Future<void> restorePurchases() async {
    debugPrint('PaymentService: Attempting to restore subscriptions');

    if (!_isAvailable) {
      debugPrint('PaymentService: In-app purchases not available for restore');
      _handleError(
        PaymentErrorType.platformNotSupported,
        'In-app purchases are not available',
      );
      return;
    }

    try {
      _setStatus(PaymentStatus.restoring);
      debugPrint('PaymentService: Calling restorePurchases...');
      await _inAppPurchase.restorePurchases();
      debugPrint('PaymentService: Restore subscriptions completed');
    } catch (e) {
      debugPrint('PaymentService: Restore subscriptions failed: $e');
      _handleError(PaymentErrorType.restoreFailed, 'Restore failed: $e');
    }
  }

  /// サブスクリプション更新の処理
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint(
      'PaymentService: Subscription update received: ${purchaseDetailsList.length} items',
    );
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint(
        'PaymentService: Processing subscription: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}',
      );
      _handlePurchaseUpdate(purchaseDetails);
    }
  }

  /// 個別サブスクリプションの処理
  void _handlePurchaseUpdate(PurchaseDetails purchaseDetails) {
    debugPrint(
      'PaymentService: Handling subscription update for: ${purchaseDetails.productID}',
    );
    debugPrint(
      'PaymentService: Subscription status: ${purchaseDetails.status}',
    );

    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        debugPrint('PaymentService: Subscription pending');
        _setStatus(PaymentStatus.purchasing);
        break;

      case PurchaseStatus.purchased:
        debugPrint('PaymentService: Subscription completed');
      case PurchaseStatus.restored:
        debugPrint('PaymentService: Subscription restored');
        _handleSuccessfulPurchase(purchaseDetails);
        break;

      case PurchaseStatus.canceled:
        debugPrint('PaymentService: Subscription canceled');
        _setStatus(PaymentStatus.cancelled);
        break;

      case PurchaseStatus.error:
        debugPrint(
          'PaymentService: Subscription error: ${purchaseDetails.error?.message}',
        );
        _handleError(
          PaymentErrorType.purchaseFailed,
          purchaseDetails.error?.message ?? 'Subscription error',
          purchaseDetails.error?.details,
        );
        break;
    }
  }

  /// 成功したサブスクリプションの処理
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    debugPrint(
      'PaymentService: Processing successful subscription for: ${purchaseDetails.productID}',
    );

    try {
      // サブスクリプションの検証
      debugPrint('PaymentService: Verifying subscription...');
      if (!await _verifyPurchase(purchaseDetails)) {
        debugPrint('PaymentService: Subscription verification failed');
        _handleError(
          PaymentErrorType.purchaseFailed,
          'Subscription verification failed',
        );
        return;
      }
      debugPrint('PaymentService: Subscription verification successful');

      // サブスクリプション状態を更新
      debugPrint(
        'PaymentService: Finding subscription for ID: ${purchaseDetails.productID}',
      );

      // 安全にProductDetailsを取得
      final productDetails = _products.firstWhere(
        (p) => p.id == purchaseDetails.productID,
        orElse: () =>
            throw Exception('Product not found: ${purchaseDetails.productID}'),
      );

      final product = PaymentProduct.fromProductDetails(productDetails);
      debugPrint('PaymentService: Found subscription: ${product.id}');

      debugPrint('PaymentService: Updating subscription from purchase...');
      await _updateSubscriptionFromPurchase(product, purchaseDetails);

      // サブスクリプション完了の処理
      debugPrint('PaymentService: Completing subscription...');
      await _completePurchase(purchaseDetails);

      _setStatus(PaymentStatus.success);
      debugPrint(
        'PaymentService: Subscription processing completed successfully',
      );

      // 成功通知
      notifyListeners();
    } catch (e) {
      debugPrint(
        'PaymentService: Error processing successful subscription: $e',
      );
      _handleError(
        PaymentErrorType.unknown,
        'Failed to process subscription: $e',
      );
    }
  }

  /// サブスクリプションの検証
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    debugPrint(
      'PaymentService: Verifying subscription for: ${purchaseDetails.productID}',
    );

    // プラットフォーム別の検証
    if (Platform.isAndroid) {
      debugPrint('PaymentService: Verifying Android subscription');
      return await _verifyAndroidPurchase(purchaseDetails);
    } else if (Platform.isIOS) {
      debugPrint('PaymentService: Verifying iOS subscription');
      return await _verifyIOSPurchase(purchaseDetails);
    } else {
      debugPrint('PaymentService: Verifying Web subscription');
      // Webの場合はStripeの検証
      return await _verifyWebPurchase(purchaseDetails);
    }
  }

  /// Androidサブスクリプションの検証
  Future<bool> _verifyAndroidPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint(
        'PaymentService: Android subscription verification - Status: ${purchaseDetails.status}',
      );
      // Google Play Billingの検証ロジック
      // 実際の実装では、サーバーサイドでの検証が必要
      final isValid = purchaseDetails.status == PurchaseStatus.purchased;
      debugPrint(
        'PaymentService: Android subscription verification result: $isValid',
      );
      return isValid;
    } catch (e) {
      debugPrint(
        'PaymentService: Android subscription verification failed: $e',
      );
      return false;
    }
  }

  /// iOSサブスクリプションの検証
  Future<bool> _verifyIOSPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint(
        'PaymentService: iOS subscription verification - Status: ${purchaseDetails.status}',
      );
      // App Store Connectの検証ロジック
      // 実際の実装では、サーバーサイドでの検証が必要
      final isValid = purchaseDetails.status == PurchaseStatus.purchased;
      debugPrint(
        'PaymentService: iOS subscription verification result: $isValid',
      );
      return isValid;
    } catch (e) {
      debugPrint('PaymentService: iOS subscription verification failed: $e');
      return false;
    }
  }

  /// Webサブスクリプションの検証
  Future<bool> _verifyWebPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint(
        'PaymentService: Web subscription verification - Status: ${purchaseDetails.status}',
      );
      // Stripeの検証ロジック
      // 実際の実装では、StripeのWebhookを使用した検証が必要
      final isValid = true; // 仮の実装
      debugPrint(
        'PaymentService: Web subscription verification result: $isValid',
      );
      return isValid;
    } catch (e) {
      debugPrint('PaymentService: Web subscription verification failed: $e');
      return false;
    }
  }

  /// サブスクリプション購入から状態を更新
  Future<void> _updateSubscriptionFromPurchase(
    PaymentProduct product,
    PurchaseDetails purchaseDetails,
  ) async {
    debugPrint(
      'PaymentService: Updating subscription from purchase - Subscription: ${product.id}, Plan: ${product.plan}',
    );

    try {
      // 有効期限の計算
      DateTime? expiryDate;

      if (product.type == ProductType.basicMonthly ||
          product.type == ProductType.premiumMonthly ||
          product.type == ProductType.familyMonthly) {
        // 月額サブスクリプション
        expiryDate = DateTime.now().add(const Duration(days: 30));
        debugPrint(
          'PaymentService: Monthly subscription - Expiry: $expiryDate',
        );
      } else {
        // 年額サブスクリプション
        expiryDate = DateTime.now().add(const Duration(days: 365));
        debugPrint('PaymentService: Yearly subscription - Expiry: $expiryDate');
      }

      // SubscriptionServiceに状態を更新
      debugPrint(
        'PaymentService: Processing subscription with plan: ${product.plan}',
      );
      await _subscriptionService.updatePlan(product.plan, expiryDate);
      debugPrint('PaymentService: Subscription updated successfully');

      // Firebaseにサブスクリプション履歴を記録
      if (_currentUserId != null && allowClientSubscriptionWrite) {
        debugPrint('PaymentService: Recording subscription to Firebase...');
        await _recordPurchaseToFirebase(product, purchaseDetails, expiryDate);
        debugPrint('PaymentService: Subscription recorded to Firebase');
      } else {
        debugPrint(
          'PaymentService: Skipping Firebase recording - UserID: $_currentUserId, AllowWrite: $allowClientSubscriptionWrite',
        );
      }
    } catch (e) {
      debugPrint(
        'PaymentService: Failed to update subscription from purchase: $e',
      );
      rethrow;
    }
  }

  /// Firebaseにサブスクリプション履歴を記録
  Future<void> _recordPurchaseToFirebase(
    PaymentProduct product,
    PurchaseDetails purchaseDetails,
    DateTime expiryDate,
  ) async {
    debugPrint(
      'PaymentService: Recording subscription to Firebase - Subscription: ${product.id}, User: $_currentUserId',
    );

    try {
      final subscriptionData = {
        'subscriptionId': product.id,
        'subscriptionType': product.type.toString(),
        'plan': product.plan.toString(),
        'price': product.price,
        'currency': product.currency,
        'subscriptionDate': FieldValue.serverTimestamp(),
        'expiryDate': expiryDate.toIso8601String(),
        'platform': _getCurrentPlatform().toString(),
        'transactionId': purchaseDetails.purchaseID,
        'status': 'active',
      };

      debugPrint(
        'PaymentService: Subscription data prepared: $subscriptionData',
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('subscriptions')
          .add(subscriptionData);

      debugPrint(
        'PaymentService: Subscription successfully recorded to Firebase',
      );
    } catch (e) {
      debugPrint(
        'PaymentService: Failed to record subscription to Firebase: $e',
      );
    }
  }

  /// 現在のプラットフォームを取得
  PaymentPlatform _getCurrentPlatform() {
    PaymentPlatform platform;
    if (Platform.isAndroid) {
      platform = PaymentPlatform.googlePlay;
    } else if (Platform.isIOS) {
      platform = PaymentPlatform.appStore;
    } else {
      platform = PaymentPlatform.stripe;
    }
    debugPrint('PaymentService: Current platform: $platform');
    return platform;
  }

  /// サブスクリプション完了の処理
  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    debugPrint(
      'PaymentService: Completing subscription for: ${purchaseDetails.productID}',
    );
    debugPrint(
      'PaymentService: Pending complete subscription: ${purchaseDetails.pendingCompletePurchase}',
    );

    try {
      // サブスクリプションの完了処理
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('PaymentService: Calling completePurchase...');
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('PaymentService: Subscription completed successfully');
      } else {
        debugPrint('PaymentService: No pending completion required');
      }
    } catch (e) {
      debugPrint('PaymentService: Failed to complete subscription: $e');
    }
  }

  /// サブスクリプションをキャンセル
  Future<void> cancelSubscription() async {
    debugPrint('PaymentService: Attempting to cancel subscription');

    try {
      // プラットフォーム別のキャンセル処理
      if (Platform.isAndroid) {
        debugPrint('PaymentService: Canceling Android subscription');
        await _cancelAndroidSubscription();
      } else if (Platform.isIOS) {
        debugPrint('PaymentService: Canceling iOS subscription');
        await _cancelIOSSubscription();
      } else {
        debugPrint('PaymentService: Canceling Web subscription');
        await _cancelWebSubscription();
      }
      debugPrint('PaymentService: Subscription cancellation completed');
    } catch (e) {
      debugPrint('PaymentService: Subscription cancellation failed: $e');
      _handleError(
        PaymentErrorType.unknown,
        'Failed to cancel subscription: $e',
      );
    }
  }

  /// Androidサブスクリプションのキャンセル
  Future<void> _cancelAndroidSubscription() async {
    debugPrint(
      'PaymentService: Android subscription cancellation not implemented',
    );
    // Google Play Consoleでのキャンセル処理
    // 実際の実装では、Google Play Developer APIを使用
  }

  /// iOSサブスクリプションのキャンセル
  Future<void> _cancelIOSSubscription() async {
    debugPrint('PaymentService: iOS subscription cancellation not implemented');
    // App Store Connectでのキャンセル処理
    // 実際の実装では、App Store Server APIを使用
  }

  /// Webサブスクリプションのキャンセル
  Future<void> _cancelWebSubscription() async {
    debugPrint('PaymentService: Web subscription cancellation not implemented');
    // Stripeでのキャンセル処理
    // 実際の実装では、Stripe APIを使用
  }

  /// 状態を設定
  void _setStatus(PaymentStatus status) {
    debugPrint('PaymentService: Setting status to: $status');
    _status = status;
    notifyListeners();
  }

  /// エラーハンドリング
  void _handleError(PaymentErrorType type, String message, [String? details]) {
    debugPrint(
      'PaymentService: Error occurred - Type: $type, Message: $message, Details: $details',
    );
    _lastError = PaymentError(type: type, message: message, details: details);
    _setStatus(PaymentStatus.failed);
    debugPrint('PaymentService: Error set: $_lastError');
  }

  /// エラーをクリア
  void clearError() {
    debugPrint('PaymentService: Clearing error');
    _lastError = null;
    notifyListeners();
  }

  /// サービスを破棄
  @override
  void dispose() {
    debugPrint('PaymentService: Disposing payment service');
    _subscription.cancel();
    super.dispose();
  }
}
