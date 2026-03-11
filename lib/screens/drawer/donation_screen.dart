import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:maikago/services/donation_service.dart';
import 'package:maikago/config.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/services/debug_service.dart';

import 'package:maikago/screens/drawer/donation_screen_widgets.dart';
import 'package:maikago/screens/drawer/donation_screen_dialogs.dart';

/// 寄付・サブスクリプション移行ページのウィジェット
/// 寄付機能とサブスクリプション移行を統合
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  int _selectedAmount = 500; // デフォルト500円
  final List<int> _presetAmounts = [300, 500, 1000, 2000, 5000, 10000];

  bool _isAvailable = false;
  bool _isLoading = false;
  String _loadingMessage = '';
  List<ProductDetails> _products = [];

  static const Map<String, int> _productIdToAmount = {
    'donation_300': 300,
    'donation_500': 500,
    'donation_1000': 1000,
    'donation_2000': 2000,
    'donation_5000': 5000,
    'donation_10000': 10000,
  };

  static final Map<int, String> _amountToProductId =
      _productIdToAmount.map((k, v) => MapEntry(v, k));

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    // 課金システムの初期化と寄付サービスの初期化
    _initInAppPurchase();
    _initDonationService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 初期化・課金ロジック
  // ---------------------------------------------------------------------------

  /// 課金システムの初期化
  Future<void> _initInAppPurchase() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '課金システムを初期化中...';
    });

    try {
      _isAvailable = await _inAppPurchase.isAvailable();

      if (_isAvailable) {
        _subscription = _inAppPurchase.purchaseStream.listen(
          _listenToPurchaseUpdated,
          onDone: () {},
          onError: (error) =>
              DebugService().logError('課金ストリームエラー: $error'),
        );
        await _getProducts();
      } else {
        setState(() {
          _loadingMessage = '課金サービスが利用できません';
        });
      }
    } catch (e) {
      DebugService().logError('課金システム初期化エラー: $e');
      setState(() {
        _loadingMessage = '課金システムの初期化に失敗しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 寄付サービスの初期化
  Future<void> _initDonationService() async {
    try {
      final donationService =
          Provider.of<DonationService>(context, listen: false);
      await donationService.initialize();
    } catch (e) {
      DebugService().logError('寄付サービス初期化エラー: $e');
    }
  }

  /// プロダクト情報を取得
  Future<void> _getProducts() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '商品情報を取得中...';
    });

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(donationProductIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        DebugService()
            .logWarning('見つからないプロダクトID: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        DebugService().logError('プロダクト取得エラー: ${response.error}');
        setState(() {
          _loadingMessage = '商品情報の取得に失敗しました';
        });
      } else {
        setState(() {
          _products = response.productDetails;
          _loadingMessage = '';
        });
      }
    } catch (e) {
      DebugService().logError('プロダクト取得エラー: $e');
      setState(() {
        _loadingMessage = '商品情報の取得に失敗しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 購入ハンドラー
  // ---------------------------------------------------------------------------

  /// 購入状態の変更を監視
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          setState(() {
            _isLoading = true;
            _loadingMessage = '購入処理中...';
          });
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handlePurchaseError(purchaseDetails.error!);
          break;
        case PurchaseStatus.canceled:
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
          showInfoSnackBar(context, '購入がキャンセルされました');
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// 購入成功時の処理
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    setState(() {
      _isLoading = false;
      _loadingMessage = '';
    });

    final amount = _productIdToAmount[purchaseDetails.productID] ?? 0;

    final donationService =
        Provider.of<DonationService>(context, listen: false);
    donationService.addDonation(
      amount: amount,
      productId: purchaseDetails.productID,
      transactionId: purchaseDetails.purchaseID,
    );

    final donationCount = donationService.donationCount;
    final message = donationCount == 1
        ? '¥$amountの寄付が完了しました！\nご支援ありがとうございます。'
        : '¥$amountの寄付が完了しました！\n$donationCount回目のご支援ありがとうございます。';

    showSuccessSnackBar(context, message,
        duration: const Duration(seconds: 5));
  }

  /// 購入エラー時の処理
  void _handlePurchaseError(IAPError error) {
    setState(() {
      _isLoading = false;
      _loadingMessage = '';
    });

    DebugService().logError('購入エラー: ${error.code} - ${error.message}');

    String errorMessage;
    switch (error.code) {
      case 'user_cancelled':
        errorMessage = '購入がキャンセルされました';
        break;
      case 'network_error':
        errorMessage = 'ネットワークエラーが発生しました';
        break;
      case 'billing_unavailable':
        errorMessage = '課金サービスが利用できません';
        break;
      default:
        errorMessage = 'エラーが発生しました: ${error.message}';
    }

    showErrorSnackBar(context, errorMessage);
  }

  /// 寄付処理を実行
  Future<void> _processDonation() async {
    if (!_isAvailable) {
      showErrorSnackBar(context, '課金サービスが利用できません');
      return;
    }

    if (_products.isEmpty) {
      showWarningSnackBar(context, '商品情報を取得中です。しばらくお待ちください。');
      return;
    }

    try {
      final productId = _amountToProductId[_selectedAmount];
      if (productId == null) throw Exception('無効な金額です: $_selectedAmount');

      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('商品が見つかりません: $productId'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      DebugService().logError('購入処理エラー: $e');
      if (mounted) {
        showErrorSnackBar(context, '購入処理に失敗しました: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('寄付'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<DonationService>(
        builder: (context, donationService, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).padding.bottom + 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DonationHeader(),
                      const SizedBox(height: 20),
                      Consumer<DonationService>(
                        builder: (context, donationService, child) {
                          return DonationHistory(
                            donationService: donationService,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      DonationAmountSelection(
                        selectedAmount: _selectedAmount,
                        presetAmounts: _presetAmounts,
                        onAmountSelected: (amount) {
                          setState(() {
                            _selectedAmount = amount;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      const DonationDeveloperMessage(),
                      const SizedBox(height: 24),
                      DonationActionButton(
                        selectedAmount: _selectedAmount,
                        onDonate: () {
                          DonationDialogs.showDonationConfirmDialog(
                            context: context,
                            selectedAmount: _selectedAmount,
                            onConfirm: _processDonation,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        DonationLoadingIndicator(message: _loadingMessage),
                      if (!_isAvailable && !_isLoading)
                        const DonationUnavailableMessage(),
                      if (_isAvailable && !_isLoading && _products.isEmpty)
                        const DonationProductNotFoundMessage(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
