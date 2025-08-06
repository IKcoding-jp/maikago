import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/donation_manager.dart';
import '../services/in_app_purchase_service.dart';

/// 寄付ページのウィジェット
/// 300円以上から任意で寄付できる機能
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

  int _selectedAmount = 500; // デフォルト500円
  final List<int> _presetAmounts = [300, 500, 1000, 2000, 5000, 10000];

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

    // 購入完了時のコールバックを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final purchaseService = Provider.of<InAppPurchaseService>(
        context,
        listen: false,
      );
      purchaseService.setPurchaseCompleteCallback(_onPurchaseComplete);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      body: Consumer<InAppPurchaseService>(
        builder: (context, purchaseService, child) {
          // 購入完了時にダイアログを表示
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!purchaseService.purchasePending &&
                purchaseService.products.isNotEmpty) {
              // 購入が完了した場合の処理は購入ストリームで処理される
            }
          });

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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildAmountSelection(),
                      const SizedBox(height: 20),
                      _buildDonationBenefits(),
                      const SizedBox(height: 24),
                      _buildDeveloperMessage(),
                      const SizedBox(height: 24),
                      _buildDonationButton(),
                      if (purchaseService.purchasePending)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('購入処理中...'),
                              ],
                            ),
                          ),
                        ),
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
                  'あなたの寄付が、より良いアプリの開発を支えます',
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
    return Consumer<InAppPurchaseService>(
      builder: (context, purchaseService, child) {
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

  /// 寄付特典を構築
  Widget _buildDonationBenefits() {
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
          Text(
            '🎁 寄付の特典',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(null, '🚫 アプリ内広告を永久に非表示', '広告なしで快適にアプリをお使いいただけます'),
          const SizedBox(height: 8),
          _buildBenefitItem(
            null,
            '🎨 テーマのカスタマイズ機能の開放',
            'お好みの色やデザインにカスタマイズできます',
          ),
          const SizedBox(height: 8),
          _buildBenefitItem(null, '🔤 フォント変更機能の開放', '読みやすいフォントに変更できます'),
          const SizedBox(height: 12),
          Text(
            '※300円以上で全特典付与',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 特典アイテムを構築
  Widget _buildBenefitItem(IconData? icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
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
            'iOS版もリリースしたいと考えているのですが、Appleの開発者登録費用などがネックになっていて、まだ実現できていません。',
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

  /// 寄付ボタンを構築
  Widget _buildDonationButton() {
    final isValidAmount = _selectedAmount >= 300;

    return Center(
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
          color: isValidAmount ? null : Colors.grey.withValues(alpha: 0.3),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    );
  }

  /// 寄付確認ダイアログを表示
  void _showDonationDialog() {
    showDialog(
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
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

  /// 寄付処理を実行
  Future<void> _processDonation() async {
    final purchaseService = Provider.of<InAppPurchaseService>(
      context,
      listen: false,
    );
    final productId = InAppPurchaseService.getProductIdFromAmount(
      _selectedAmount,
    );

    if (productId == null) {
      // カスタム金額の場合は従来の処理
      final donationManager = Provider.of<DonationManager>(
        context,
        listen: false,
      );
      await donationManager.processDonation(_selectedAmount);
      _showSuccessDialog();
      return;
    }

    // アプリ内購入で処理
    final success = await purchaseService.purchaseProduct(productId);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('購入の開始に失敗しました。しばらく時間をおいてから再度お試しください。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 購入完了時のコールバック
  void _onPurchaseComplete(int amount) {
    if (mounted) {
      _showSuccessDialog(amount);
    }
  }

  /// 成功ダイアログを表示
  void _showSuccessDialog([int? amount]) {
    final displayAmount = amount ?? _selectedAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              const SizedBox(width: 8),
              const Text('寄付完了'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¥${displayAmount.toString()}の寄付が完了しました！',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'まいカゴの開発を応援していただき、ありがとうございます。\nより良いアプリを作るために活用させていただきます。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 寄付ページを閉じる
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('ありがとうございます'),
            ),
          ],
        );
      },
    );
  }
}
