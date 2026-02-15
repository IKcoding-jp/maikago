import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:maikago/services/donation_service.dart';
import 'package:maikago/config.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/services/debug_service.dart';

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

  /// 課金システムの初期化
  Future<void> _initInAppPurchase() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = '課金システムを初期化中...';
    });

    try {
      // 課金サービスが利用可能かチェック
      _isAvailable = await _inAppPurchase.isAvailable();

      if (_isAvailable) {
        // 購入状態の変更をリッスン
        _subscription = _inAppPurchase.purchaseStream.listen(
          _listenToPurchaseUpdated,
          onDone: () => DebugService().log('課金ストリームが終了しました'),
          onError: (error) => DebugService().log('課金ストリームエラー: $error'),
        );

        // プロダクト情報を取得
        await _getProducts();
      } else {
        setState(() {
          _loadingMessage = '課金サービスが利用できません';
        });
      }
    } catch (e) {
      DebugService().log('課金システム初期化エラー: $e');
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
      DebugService().log('寄付サービス初期化エラー: $e');
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
        DebugService().log('見つからないプロダクトID: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        DebugService().log('プロダクト取得エラー: ${response.error}');
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
      DebugService().log('プロダクト取得エラー: $e');
      setState(() {
        _loadingMessage = '商品情報の取得に失敗しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('購入がキャンセルされました'),
              backgroundColor: Colors.grey,
            ),
          );
          break;
      }

      // 購入完了の確認
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

    // プロダクトIDから金額を取得
    final amount = _getAmountFromProductId(purchaseDetails.productID);

    // 寄付サービスに記録
    final donationService =
        Provider.of<DonationService>(context, listen: false);
    donationService.addDonation(
      amount: amount,
      productId: purchaseDetails.productID,
      transactionId: purchaseDetails.purchaseID,
    );

    // 寄付回数に応じたメッセージを表示
    final donationCount = donationService.donationCount;
    String message;
    if (donationCount == 1) {
      message = '¥$amountの寄付が完了しました！\nご支援ありがとうございます。';
    } else {
      message = '¥$amountの寄付が完了しました！\n$donationCount回目のご支援ありがとうございます。';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    DebugService().log('購入成功: ${purchaseDetails.productID}');
  }

  /// 購入エラー時の処理
  void _handlePurchaseError(IAPError error) {
    setState(() {
      _isLoading = false;
      _loadingMessage = '';
    });

    DebugService().log('購入エラー: ${error.code} - ${error.message}');

    String errorMessage = '購入処理中にエラーが発生しました';

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  /// プロダクトIDから金額を取得
  int _getAmountFromProductId(String productId) {
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

  @override
  void dispose() {
    _animationController.dispose();
    _subscription.cancel();
    super.dispose();
  }

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
                      _buildHeader(),
                      const SizedBox(height: 20),
                      Consumer<DonationService>(
                        builder: (context, donationService, child) {
                          return _buildDonationHistory(donationService);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildAmountSelection(),
                      const SizedBox(height: 32),
                      _buildDeveloperMessage(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                      if (_isLoading) _buildLoadingIndicator(),
                      if (!_isAvailable && !_isLoading)
                        _buildUnavailableMessage(),
                      if (_isAvailable && !_isLoading && _products.isEmpty)
                        _buildProductNotFoundMessage(),
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

  /// 寄付履歴を表示するウィジェットを構築
  Widget _buildDonationHistory(DonationService donationService) {
    if (!donationService.hasDonated) {
      return const SizedBox.shrink(); // 寄付履歴がない場合は何も表示しない
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '寄付履歴',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '合計寄付金額',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${donationService.totalDonationAmount.toString()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '寄付回数',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${donationService.donationCount}回',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '最終寄付日: ${donationService.lastDonationDate != null ? _formatDate(donationService.lastDonationDate!) : '不明'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// 日付をフォーマットするヘルパーメソッド
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// ヘッダー部分を構築
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'まいカゴを応援してください',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'あなたの寄付が、アプリの未来を創ります',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 金額選択部分を構築
  Widget _buildAmountSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '寄付金額を選択',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPresetAmounts(),
        ],
      ),
    );
  }

  /// プリセット金額を構築
  Widget _buildPresetAmounts() {
    return Consumer<DonationService>(
      builder: (context, donationService, child) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;

            return GestureDetector(
              onTap: () {
                // 一時的に制限を緩和：商品が利用できなくても選択可能
                setState(() {
                  _selectedAmount = amount;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '¥${amount.toString()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 開発者からのメッセージを構築
  Widget _buildDeveloperMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '開発者からのメッセージ',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: 16),
          Text(
            'このアプリは、エンジニアでもなんでもない人間が、たった一人で作っています。\n'
            '専門的な知識があるわけでもなく、時間を見つけては少しずつ開発してきました。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            '正直、アプリを作って維持していくにはお金も時間もかかります。\n'
            'iOS版もリリースしたいと考えているのですが、MacBookが必要でお金がないため、まだ実現できていません。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            'もしこのアプリが少しでも役に立ったと感じてもらえたら、応援の気持ちとして寄付してもらえると本当に励みになります。\n'
            'もちろん、金額に関係なく気持ちだけでも嬉しいです。\n'
            'ご支援、心からありがとうございます。今後もこつこつ改善を重ねていきます。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  /// アクションボタンを構築
  Widget _buildActionButtons() {
    return Consumer<DonationService>(
      builder: (context, service, _) {
        final isValidAmount = _selectedAmount >= 300;

        return Column(
          children: [
            // 寄付ボタン（サブスクリプションの有無に関係なく表示）
            Center(
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isValidAmount
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  color:
                      isValidAmount ? null : Colors.grey.withValues(alpha: 0.3),
                ),
                child: ElevatedButton(
                  onPressed: isValidAmount ? _showDonationDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: isValidAmount
                            ? Theme.of(context).colorScheme.onPrimary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${_selectedAmount.toString()} 寄付する',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isValidAmount
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Colors.grey,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  /// 寄付確認ダイアログを表示
  void _showDonationDialog() {
    showConstrainedDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('寄付の確認'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '以下の金額で寄付を行いますか？',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¥${_selectedAmount.toString()}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '※ 寄付は開発者の活動を支援するためのものです。\n※ 返金はできませんのでご了承ください。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processDonation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('寄付する'),
            ),
          ],
        );
      },
    );
  }

  /// プロダクトIDから金額を取得（逆引き）
  String _getProductIdFromAmount(int amount) {
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
        throw Exception('無効な金額です: $amount');
    }
  }

  /// 寄付処理を実行
  Future<void> _processDonation() async {
    if (!_isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('課金サービスが利用できません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('商品情報を取得中です。しばらくお待ちください。'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final productId = _getProductIdFromAmount(_selectedAmount);
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('商品が見つかりません: $productId'),
      );

      // 購入処理
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      DebugService().log('購入処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('購入処理に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ローディングインジケーターを構築
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _loadingMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 利用不可メッセージを構築
  Widget _buildUnavailableMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '課金サービスが利用できません。\nネットワーク接続を確認してください。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// 商品が見つからないメッセージを構築
  Widget _buildProductNotFoundMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Google Play Consoleで寄付用の課金アイテムが設定されていない可能性があります。\nプロダクトID: ${donationProductIds.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
