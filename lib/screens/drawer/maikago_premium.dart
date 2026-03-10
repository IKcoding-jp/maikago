import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maikago/models/one_time_purchase.dart';
import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/services/settings_theme.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'まいかごプレミアム',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
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
            Text(
              'コーヒー1杯分で、ずっと使える。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                color: Colors.white,
                height: 1.4,
              ),
            ),
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
                    '¥480',
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
                    child: Text(
                      '買い切り',
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
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
          color: Theme.of(context).cardColor,
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
            Text(
              'プレミアム機能',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.displayMedium?.fontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '一度購入すれば、永続的に利用可能',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // 機能一覧
            _buildFeatureItem(
              icon: Icons.camera_alt,
              title: 'OCR（値札撮影）無制限',
              description: '月5回の制限を解除\n値札を撮って自動入力',
              color: AppColors.featureRed,
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.store,
              title: 'ショップ（タブ）無制限',
              description: '2つの制限を解除\nお店ごとにリストを管理',
              color: AppColors.featurePremiumBlue,
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.restaurant_menu,
              title: 'レシピ解析',
              description: 'テキストから\n買い物リストを自動作成',
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.palette,
              title: '全テーマ・全フォント',
              description: 'お気に入りのテーマとフォントで\nアプリをカスタマイズ',
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              icon: Icons.block,
              title: '広告完全非表示',
              description: '邪魔な広告なしで\n集中して買い物',
              color: AppColors.featurePremiumGreen,
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
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  Text(
                    'プレミアム機能を利用中',
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'すべての機能が利用可能です',
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 未購入の場合
            _buildPurchaseCard(
                OneTimePurchase.premium, false, purchaseService),
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
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.description,
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                        fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
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
                      child: Text(
                        '全機能パック',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
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
                        style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // 購入ボタン
            Column(
              children: [
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
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
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
          showSuccessSnackBar(context, '${purchase.name}の購入を開始しました');
        }
      } else {
        if (mounted) {
          showErrorSnackBar(context, '購入に失敗しました: ${service.error ?? '不明なエラー'}');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, '購入エラー: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 購入状態を復元
  Future<void> _restorePurchases(
      BuildContext context, OneTimePurchaseService service) async {
    try {
      await service.restorePurchases();

      if (context.mounted) {
        showSuccessSnackBar(context, '購入状態を復元しました', duration: const Duration(seconds: 2));
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, '復元に失敗しました: ${e.toString()}');
      }
    }
  }

  /// 安心・安全セクション
  Widget _buildTrustSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 40), // 下部マージンを増加
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Text(
            '安心・安全',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '安心してご購入ください',
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '買い切り型なので、月額料金は一切かかりません\n一度のお支払いでずっとご利用いただけます',
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.2,
          ),
        ),
      ],
    );
  }

}
