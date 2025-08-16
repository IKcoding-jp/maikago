import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'donation_manager.dart';
import 'subscription_service.dart';
import '../config/subscription_ids.dart';
import '../models/subscription_plan.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    'donation_10000', // ¥10000
  };

  // サブスクリプション商品のID
  static final Set<String> _subscriptionProductIds =
      SubscriptionIds.allBasePlans;

  // 全商品ID（寄付 + サブスクリプション）
  Set<String> get allProductIds => {
    ..._donationProductIds,
    ..._subscriptionProductIds,
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
      case 'donation_10000':
        return 10000;
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
      case 10000:
        return 'donation_10000';
      default:
        return null;
    }
  }

  /// 商品IDがサブスクリプション商品かどうかを判定
  static bool isSubscriptionProduct(String productId) {
    return _subscriptionProductIds.contains(productId);
  }

  /// 商品IDが寄付商品かどうかを判定
  static bool isDonationProduct(String productId) {
    return _donationProductIds.contains(productId);
  }

  /// サブスクリプション商品IDからプランを取得
  static SubscriptionPlan? getSubscriptionPlanFromProductId(String productId) {
    if (SubscriptionIds.isBasicPlan(productId)) {
      return SubscriptionPlan.basic;
    } else if (SubscriptionIds.isPremiumPlan(productId)) {
      return SubscriptionPlan.premium;
    } else if (SubscriptionIds.isFamilyPlan(productId)) {
      return SubscriptionPlan.family;
    } else {
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
    // 必ず最初に商品リストをクリア
    _products.clear();
    debugPrint('商品リストをクリアしました');

    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(allProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('見つからない商品ID: ${response.notFoundIDs}');
      }

      _products.addAll(response.productDetails);

      _queryProductError = response.error?.message;

      // テスト用：商品が読み込まれない場合はダミー商品を追加
      if (_products.isEmpty) {
        debugPrint('商品が読み込まれませんでした。テスト用のダミー商品を追加します。');
        _addDummyProducts();
      } else {
        // サブスクリプション商品が含まれているかチェック
        final subscriptionProducts = _products
            .where((p) => isSubscriptionProduct(p.id))
            .toList();
        if (subscriptionProducts.isEmpty) {
          debugPrint('サブスクリプション商品が見つかりませんでした。ダミー商品を追加します。');
          _addDummyProducts();
        } else {
          debugPrint('サブスクリプション商品が見つかりました: ${subscriptionProducts.length}個');
        }
      }

      notifyListeners();
      debugPrint('商品情報を読み込みました: ${_products.length}個');
      // デバッグ用：商品リストの内容を詳細に確認
      for (final product in _products) {
        debugPrint('商品: ${product.id} - ${product.price}');
      }
    } catch (e) {
      debugPrint('商品情報の読み込みエラー: $e');
      _queryProductError = e.toString();

      // エラー時は商品リストをクリアしてからダミー商品を追加
      if (_products.isEmpty) {
        _products.clear();
        _addDummyProducts();
      }
      notifyListeners();
    }
  }

  /// テスト用のダミー商品を追加
  void _addDummyProducts() {
    debugPrint('ダミー商品追加開始: 現在の商品数: ${_products.length}');

    // 既に商品が存在する場合は追加しない
    if (_products.isNotEmpty) {
      debugPrint('商品が既に存在するため、ダミー商品の追加をスキップします');
      return;
    }

    // 既存の商品IDをチェックして重複を防ぐ
    final existingIds = _products.map((p) => p.id).toSet();
    debugPrint('既存の商品ID: $existingIds');

    // ダミーのProductDetailsを作成（テスト用）
    final dummyProducts = [
      // 寄付商品
      _createDummyProduct('donation_300', '¥300'),
      _createDummyProduct('donation_500', '¥500'),
      _createDummyProduct('donation_1000', '¥1000'),
      _createDummyProduct('donation_2000', '¥2000'),
      _createDummyProduct('donation_5000', '¥5000'),
      _createDummyProduct('donation_10000', '¥10000'),
      // サブスクリプション商品
      _createDummyProduct(SubscriptionIds.basicMonthly, '¥300'),
      _createDummyProduct(SubscriptionIds.basicYearly, '¥2,800'),
      _createDummyProduct(SubscriptionIds.premiumMonthly, '¥500'),
      _createDummyProduct(SubscriptionIds.premiumYearly, '¥4,500'),
      _createDummyProduct(SubscriptionIds.familyMonthly, '¥700'),
      _createDummyProduct(SubscriptionIds.familyYearly, '¥6,500'),
    ];

    // 重複しない商品のみを追加
    int addedCount = 0;
    for (final product in dummyProducts) {
      if (!existingIds.contains(product.id)) {
        _products.add(product);
        addedCount++;
        debugPrint('商品を追加: ${product.id}');
      } else {
        debugPrint('商品をスキップ（重複）: ${product.id}');
      }
    }

    debugPrint('追加された商品数: $addedCount');

    debugPrint('ダミー商品を追加しました: ${_products.length}個');
    // デバッグ用：商品リストの内容を詳細に確認
    for (final product in _products) {
      debugPrint('商品: ${product.id} - ${product.price}');
    }
  }

  /// ダミー商品を作成（テスト用）
  ProductDetails _createDummyProduct(String id, String price) {
    String title;
    String description;

    if (isSubscriptionProduct(id)) {
      // サブスクリプション商品の場合
      if (id.contains('basic')) {
        title = 'ベーシックプラン';
        description = 'まいカゴのベーシックプラン $price';
      } else if (id.contains('premium')) {
        title = 'プレミアムプラン';
        description = 'まいカゴのプレミアムプラン $price';
      } else if (id.contains('family')) {
        title = 'ファミリープラン';
        description = 'まいカゴのファミリープラン $price';
      } else {
        title = 'サブスクリプション $price';
        description = 'まいカゴのサブスクリプション $price';
      }
    } else {
      // 寄付商品の場合
      title = '寄付 $price';
      description = 'まいカゴへの寄付 $price';
    }

    return ProductDetails(
      id: id,
      title: title,
      description: description,
      price: price,
      rawPrice: _getPriceFromString(price),
      currencyCode: 'JPY',
    );
  }

  /// 価格文字列から数値を取得
  double _getPriceFromString(String priceString) {
    // "¥120" から 120.0 を取得
    final cleanPrice = priceString.replaceAll('¥', '').replaceAll(',', '');
    return double.tryParse(cleanPrice) ?? 0.0;
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

      // サブスクリプション商品の場合はbuyNonConsumable、寄付商品の場合はbuyConsumableを使用
      if (isSubscriptionProduct(productId)) {
        // サブスクリプション（定期購入）の場合はbuyNonConsumable
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        debugPrint('サブスクリプション購入を開始: $productId');
      } else {
        // 寄付商品（消耗品）の場合はbuyConsumable
        success = await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
        );
        debugPrint('寄付購入を開始: $productId');
      }

      if (!success) {
        _purchasePending = false;
        notifyListeners();
        debugPrint('購入の開始に失敗しました: $productId');
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
      final String productId = purchaseDetails.productID;

      // 現在のユーザーがログインしているかチェック
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('ユーザーがログインしていないため、購入処理を実行できません');
        return;
      }

      // 購入の検証
      if (!await _verifyPurchase(purchaseDetails)) {
        debugPrint('購入の検証に失敗しました: $productId');
        return;
      }

      if (isDonationProduct(productId)) {
        // 寄付商品の処理
        final int amount = getAmountFromProductId(productId);
        if (amount >= 300) {
          // DonationManagerを使用して寄付を記録（特典なし）
          final donationManager = DonationManager();
          await donationManager.processDonation(amount);

          // コールバックを実行
          _onPurchaseComplete?.call(amount);

          // PII（メールアドレス等）をログに出さない
          debugPrint(
            '寄付が完了しました: ¥$amount ($productId) - uid: ${currentUser.uid}',
          );
        }
      } else if (isSubscriptionProduct(productId)) {
        // サブスクリプション商品の処理
        debugPrint('サブスクリプション購入が完了しました: $productId - uid: ${currentUser.uid}');

        // 商品IDからプランを取得
        final plan = getSubscriptionPlanFromProductId(productId);
        if (plan != null) {
          // 期限を商品タイプに応じて設定
          DateTime expiry;
          if (productId.contains('yearly')) {
            // 年額プランは1年後
            expiry = DateTime.now().add(const Duration(days: 365));
          } else {
            // 月額プランは1ヶ月後
            expiry = DateTime.now().add(const Duration(days: 30));
          }

          // SubscriptionServiceを使用してサブスクリプションを処理
          final subscriptionService = SubscriptionService();
          await subscriptionService.updatePlan(plan, expiry);

          debugPrint('サブスクリプション処理が完了しました: $plan, 期限: $expiry');
        } else {
          debugPrint('未知のサブスクリプション商品IDです: $productId');
        }

        // コールバックを実行（金額は0として渡す）
        _onPurchaseComplete?.call(0);
      } else {
        debugPrint('未知の商品IDです: $productId');
      }
    } catch (e) {
      debugPrint('購入完了処理エラー: $e');
    }
  }

  /// 購入の検証
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // 基本的な検証
      if (purchaseDetails.status != PurchaseStatus.purchased &&
          purchaseDetails.status != PurchaseStatus.restored) {
        debugPrint('購入状態が無効です: ${purchaseDetails.status}');
        return false;
      }

      // 購入トークンの検証（Android）
      if (Platform.isAndroid) {
        if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
          debugPrint('サーバー検証データが空です');
          return false;
        }

        // 実際の実装では、サーバーサイドでGoogle Play Developer APIを使用して
        // 購入トークンを検証する必要があります
        debugPrint('Android購入検証: トークン検証が必要');
      }

      // iOSの検証
      if (Platform.isIOS) {
        if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
          debugPrint('App Store検証データが空です');
          return false;
        }

        // 実際の実装では、サーバーサイドでApp Store Server APIを使用して
        // レシートを検証する必要があります
        debugPrint('iOS購入検証: レシート検証が必要');
      }

      debugPrint('購入検証が完了しました: ${purchaseDetails.productID}');
      return true;
    } catch (e) {
      debugPrint('購入検証エラー: $e');
      return false;
    }
  }

  /// 購入完了時のコールバックを設定
  void setPurchaseCompleteCallback(Function(int) callback) {
    _onPurchaseComplete = callback;
  }

  /// 購入履歴を復元
  Future<void> restorePurchases() async {
    try {
      _purchasePending = true;
      notifyListeners();

      await _inAppPurchase.restorePurchases();
      debugPrint('購入履歴の復元を開始しました');
    } catch (e) {
      debugPrint('購入履歴の復元エラー: $e');
    } finally {
      _purchasePending = false;
      notifyListeners();
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
      // デバッグ用：商品リストの内容を確認
      final matchingProducts = _products
          .where((product) => product.id == productId)
          .toList();
      if (matchingProducts.length > 1) {
        debugPrint(
          '警告: 同じ商品IDの商品が複数存在します: $productId (${matchingProducts.length}個)',
        );
      }
      return getProductById(productId);
    }
    return null;
  }

  /// サブスクリプションプランから商品情報を取得（月額）
  ProductDetails? getProductBySubscriptionPlan(SubscriptionPlan plan) {
    String? productId;
    switch (plan.type) {
      case SubscriptionPlanType.basic:
        productId = SubscriptionIds.basicMonthly;
        break;
      case SubscriptionPlanType.premium:
        productId = SubscriptionIds.premiumMonthly;
        break;
      case SubscriptionPlanType.family:
        productId = SubscriptionIds.familyMonthly;
        break;
      case SubscriptionPlanType.free:
        return null; // フリープランは商品なし
    }
    return productId != null ? getProductById(productId) : null;
  }

  /// サブスクリプションプランから年額商品情報を取得
  ProductDetails? getYearlyProductBySubscriptionPlan(SubscriptionPlan plan) {
    String? productId;
    switch (plan.type) {
      case SubscriptionPlanType.basic:
        productId = SubscriptionIds.basicYearly;
        break;
      case SubscriptionPlanType.premium:
        productId = SubscriptionIds.premiumYearly;
        break;
      case SubscriptionPlanType.family:
        productId = SubscriptionIds.familyYearly;
        break;
      case SubscriptionPlanType.free:
        return null; // フリープランは商品なし
    }
    return productId != null ? getProductById(productId) : null;
  }

  /// 期間とプランから商品情報を取得（新しいUI用）
  ProductDetails? getProductByPlanAndPeriod(
    SubscriptionPlan plan,
    SubscriptionPeriod period,
  ) {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return getProductBySubscriptionPlan(plan);
      case SubscriptionPeriod.yearly:
        return getYearlyProductBySubscriptionPlan(plan);
    }
  }

  /// 商品IDから期間を取得
  SubscriptionPeriod? getPeriodFromProductId(String productId) {
    if (productId.contains('yearly')) {
      return SubscriptionPeriod.yearly;
    } else if (productId.contains('monthly')) {
      return SubscriptionPeriod.monthly;
    }
    return null;
  }

  /// 商品IDからプランと期間を取得
  Map<String, dynamic>? getPlanAndPeriodFromProductId(String productId) {
    final plan = getSubscriptionPlanFromProductId(productId);
    final period = getPeriodFromProductId(productId);

    if (plan != null && period != null) {
      return {'plan': plan, 'period': period};
    }
    return null;
  }
}
