import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/subscription_ids.dart';
import '../models/subscription_plan.dart';
import 'subscription_service.dart';

/// アプリ内課金（定期購入）サービス（Android向け）
class IapService extends ChangeNotifier {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal() {
    _initialize();
  }

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _isAvailable = false;
  bool _isInitializing = false;
  bool _isPurchasing = false;
  String? _errorMessage;

  List<ProductDetails> _products = <ProductDetails>[];
  Set<String> _notFoundIds = <String>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool get isAvailable => _isAvailable;
  bool get isInitializing => _isInitializing;
  bool get isPurchasing => _isPurchasing;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// 初期化
  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    notifyListeners();

    try {
      debugPrint('IAP初期化開始');
      _isAvailable = await _iap.isAvailable();
      debugPrint('IAP利用可能: $_isAvailable');

      if (!_isAvailable) {
        debugPrint('IAPが利用できません');
        return;
      }

      // 商品情報を取得
      await _queryProductDetails();

      // 購入更新ストリームを購読
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () {
          debugPrint('購入ストリーム終了');
        },
        onError: (Object error) {
          debugPrint('購入ストリームエラー: $error');
          _setError('購入ストリームでエラーが発生しました');
        },
      );

      // 起動時に復元を呼び、端末の権利を同期
      await restorePurchases();
      debugPrint('IAP初期化完了');
    } catch (e) {
      debugPrint('IAP初期化エラー: $e');
      _setError('IAP初期化に失敗しました');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// 商品情報の問い合わせ
  Future<void> _queryProductDetails() async {
    try {
      final response = await _iap.queryProductDetails(
        SubscriptionIds.allProducts,
      );
      _products = response.productDetails;
      _notFoundIds = response.notFoundIDs.toSet();

      debugPrint(
        '商品情報取得: 件数=${_products.length}, 未検出=${_notFoundIds.toList()}',
      );
    } catch (e) {
      debugPrint('商品情報取得エラー: $e');
      _setError('商品情報の取得に失敗しました');
    }
  }

  /// 指定プラン/期間の購入を開始
  Future<bool> purchaseSubscription({
    required SubscriptionPlan plan,
    required SubscriptionPeriod period,
  }) async {
    if (!_isAvailable) {
      _setError('ストアが利用できません');
      return false;
    }

    if (plan.isFreePlan) {
      // 無料プランはIAP不要
      final ok = await SubscriptionService().setFreePlan();
      return ok;
    }

    try {
      _isPurchasing = true;
      _errorMessage = null;
      notifyListeners();

      final ids = _resolveIds(plan.type, period);
      if (ids == null) {
        _setError('購入IDの解決に失敗しました');
        return false;
      }

      final product = _products.firstWhere(
        (p) => p.id == ids.productId,
        orElse: () => throw StateError('商品が見つかりません: ${ids.productId}'),
      );

      // 現在のプラグインでは offerToken 指定は必須ではないため省略
      final purchaseParam = PurchaseParam(productDetails: product);

      debugPrint('購入開始: product=${ids.productId}, basePlan=${ids.basePlanId}');

      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _setError('購入を開始できませんでした');
      }
      return started;
    } catch (e) {
      debugPrint('購入開始エラー: $e');
      _setError('購入の開始に失敗しました');
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// 購入履歴の復元
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      debugPrint('購入復元要求を送信');
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('購入復元エラー: $e');
      _setError('購入の復元に失敗しました');
    }
  }

  /// 端末のストア状態から有効性を再同期し、現在有効か返す
  Future<bool> syncAndCheckActive() async {
    await restorePurchases();
    // 購入ストリームからの反映を待機（最大5秒）
    final completer = Completer<bool>();
    late StreamSubscription sub;
    sub = _iap.purchaseStream.listen((event) async {
      // 反映後に現在の状態を返す
      try {
        sub.cancel();
      } catch (_) {}
      completer.complete(SubscriptionService().isSubscriptionActive);
    });
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => SubscriptionService().isSubscriptionActive,
    );
  }

  /// 購入更新イベント
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint('購入更新: id=${purchase.productID}, 状態=${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('購入保留');
          break;
        case PurchaseStatus.error:
          _setError('購入でエラーが発生しました');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleEntitlement(purchase);
          break;
        case PurchaseStatus.canceled:
          debugPrint('購入キャンセル');
          break;
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
          debugPrint('購入完了処理を実行');
        } catch (e) {
          debugPrint('購入完了処理エラー: $e');
        }
      }
    }
  }

  /// 購入品目から権利付与
  Future<void> _handleEntitlement(PurchaseDetails purchase) async {
    final plan = _mapProductToPlan(purchase.productID);
    if (plan == null) {
      debugPrint('不明な商品: ${purchase.productID}');
      return;
    }

    // 期限はストア検証がないため未設定（null）。
    await SubscriptionService().updatePlan(plan, null);
    debugPrint('権利付与: ${plan.name}');
  }

  /// プロダクトID→プランのマッピング
  SubscriptionPlan? _mapProductToPlan(String productId) {
    if (productId == SubscriptionIds.basicProduct)
      return SubscriptionPlan.basic;
    if (productId == SubscriptionIds.premiumProduct)
      return SubscriptionPlan.premium;
    if (productId == SubscriptionIds.familyProduct)
      return SubscriptionPlan.family;
    return null;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// プラン種別と期間から購入用IDを解決
  _ResolvedIds? _resolveIds(
    SubscriptionPlanType type,
    SubscriptionPeriod period,
  ) {
    switch (type) {
      case SubscriptionPlanType.basic:
        return _ResolvedIds(
          productId: SubscriptionIds.basicProduct,
          basePlanId: period == SubscriptionPeriod.monthly
              ? SubscriptionIds.basicMonthly
              : SubscriptionIds.basicYearly,
        );
      case SubscriptionPlanType.premium:
        return _ResolvedIds(
          productId: SubscriptionIds.premiumProduct,
          basePlanId: period == SubscriptionPeriod.monthly
              ? SubscriptionIds.premiumMonthly
              : SubscriptionIds.premiumYearly,
        );
      case SubscriptionPlanType.family:
        return _ResolvedIds(
          productId: SubscriptionIds.familyProduct,
          basePlanId: period == SubscriptionPeriod.monthly
              ? SubscriptionIds.familyMonthly
              : SubscriptionIds.familyYearly,
        );
      case SubscriptionPlanType.free:
        return null;
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

class _ResolvedIds {
  final String productId;
  final String basePlanId;
  const _ResolvedIds({required this.productId, required this.basePlanId});
}
