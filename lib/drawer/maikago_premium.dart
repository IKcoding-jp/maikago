import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/one_time_purchase.dart';
import '../services/one_time_purchase_service.dart';

/// 非消耗型アプリ内課金画面（旧サブスクリプションプラン選択画面）
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'まいかごプレミアム',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white, // 白に戻す
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        foregroundColor: Colors.white, // 白
        actions: [
          // 購入状態復元ボタン
          Consumer<OneTimePurchaseService>(
            builder: (context, service, child) {
              return IconButton(
                icon: const Icon(Icons.restore),
                color: Colors.white,
                onPressed: service.isLoading
                    ? null
                    : () => _restorePurchases(context, service),
                tooltip: '購入状態を復元',
              );
            },
          ),
        ],
      ),
      body: Consumer<OneTimePurchaseService>(
        builder: (context, purchaseService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 50), // 3ボタンナビゲーション分の余白を追加
            child: Column(
              children: [
                // ヒーローセクション
                _buildHeroSection(purchaseService),

                // プレミアム機能セクション
                _buildPremiumFeaturesSection(purchaseService),

                // 購入セクション
                _buildPurchaseSection(purchaseService),

                // 安心・安全セクション
                _buildTrustSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ヒーローセクション
  Widget _buildHeroSection(OneTimePurchaseService purchaseService) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
        child: Column(
          children: [
            // プレミアムアイコン
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // タイトル
            const Text(
              'まいかごプレミアム',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white, // 白に戻す
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // サブタイトル
            const Text(
              'あなたの買い物体験を\nより快適に、より美しく',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // 体験期間の表示
            if (purchaseService.isTrialActive) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '体験期間中（残り${_formatDuration(purchaseService.trialRemainingDuration)}）',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              // 体験期間未開始の場合
              if (!purchaseService.isTrialEverStarted) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '7日間無料でお試し！',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),

            // 価格表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¥280',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '買い切り',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// プレミアム機能セクション
  Widget _buildPremiumFeaturesSection(OneTimePurchaseService purchaseService) {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'プレミアム機能',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '一度購入すれば、永続的に利用可能',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 24),

            // 機能一覧
            _buildFeatureItem(
              icon: Icons.palette,
              title: '豊富なテーマ',
              description: 'お気に入りのテーマで\nアプリをカスタマイズ',
              color: const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.font_download,
              title: '美しいフォント',
              description: '読みやすいフォントで\n快適な使用体験',
              color: const Color(0xFF3498DB),
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.block,
              title: '広告完全非表示',
              description: '邪魔な広告なしで\n集中して買い物',
              color: const Color(0xFF2ECC71),
            ),
          ],
        ),
      ),
    );
  }

  /// 機能アイテム
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 購入セクション
  Widget _buildPurchaseSection(OneTimePurchaseService purchaseService) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          if (purchaseService.isPremiumUnlocked) ...[
            // 購入済みの場合
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'プレミアム機能を利用中',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'すべての機能が利用可能です',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 未購入の場合
            if (purchaseService.isTrialActive) ...[
              // 体験期間中の表示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '体験期間中',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '残り${_formatDuration(purchaseService.trialRemainingDuration)}で体験期間が終了します',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _purchaseProduct(
                            OneTimePurchase.premium, purchaseService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '今すぐ購入',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 体験期間未開始の場合
              _buildPurchaseCard(
                  OneTimePurchase.premium, false, purchaseService),
            ],
          ],
        ],
      ),
    );
  }

  /// 購入カード
  Widget _buildPurchaseCard(OneTimePurchase purchase, bool isPurchased,
      OneTimePurchaseService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${purchase.price}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '全機能パック',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 機能一覧
            ...purchase.features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // ボタン群
            Column(
              children: [
                // 体験期間開始ボタン
                if (purchase.trialDays != null &&
                    !isPurchased &&
                    !service.isTrialActive &&
                    !service.isTrialEverStarted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _startTrial(purchase.trialDays!, service),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${purchase.trialDays}日間無料でお試し',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 購入ボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isPurchased || _isLoading
                        ? null
                        : () => _purchaseProduct(purchase, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isPurchased ? '購入済み' : '購入する',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 商品を購入
  Future<void> _purchaseProduct(
      OneTimePurchase purchase, OneTimePurchaseService service) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await service.purchaseProduct(purchase);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${purchase.name}の購入を開始しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('購入に失敗しました: ${service.error ?? '不明なエラー'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('購入エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 体験期間を開始
  void _startTrial(int trialDays, OneTimePurchaseService service) {
    service.startTrial(trialDays);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$trialDays日間の無料体験を開始しました！'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 購入状態を復元
  Future<void> _restorePurchases(
      BuildContext context, OneTimePurchaseService service) async {
    try {
      await service.restorePurchases();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('購入状態を復元しました'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 安心・安全セクション
  Widget _buildTrustSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 40), // 下部マージンを増加
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '安心・安全',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),

          // 安心ポイント
          Row(
            children: [
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.security,
                  title: '安全な決済',
                  description: 'Google Play\nApp Store',
                ),
              ),
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.refresh,
                  title: '返金対応',
                  description: 'Google Play\n返金制度',
                ),
              ),
              Expanded(
                child: _buildTrustItem(
                  icon: Icons.phone_android,
                  title: '永続利用',
                  description: '一度購入\nずっと使える',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 安心メッセージ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '安心してお試しください',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '7日間体験後、\n勝手に請求されることはありません\n購入は完全に任意です',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 安心アイテム
  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7F8C8D),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  /// Durationを「X日Y時間Z分A秒」形式でフォーマットするヘルパー関数
  String _formatDuration(Duration? duration) {
    if (duration == null || duration.isNegative) {
      return '0日0時間0分0秒';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '$days日$hours時間$minutes分$seconds秒';
  }
}
