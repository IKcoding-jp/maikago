import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/one_time_purchase.dart';
import '../services/one_time_purchase_service.dart';
import '../services/debug_service.dart';

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
      appBar: AppBar(
        title: const Text('プレミアム機能'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // デバッグモードの場合のみ表示
          if (DebugService().enableDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => _showDebugDialog(context),
            ),
        ],
      ),
      body: Consumer<OneTimePurchaseService>(
        builder: (context, purchaseService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダーセクション
                _buildHeaderSection(),
                const SizedBox(height: 24),

                // 現在の購入状況
                _buildCurrentStatusSection(purchaseService),
                const SizedBox(height: 24),

                // 購入可能な商品一覧
                _buildPurchaseSection(purchaseService),
                const SizedBox(height: 24),

                // エラーメッセージ
                if (purchaseService.error != null)
                  _buildErrorSection(purchaseService.error!),

                // ローディング表示
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ヘッダーセクション
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'プレミアム機能をアンロック',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '一度購入すれば、永続的に利用可能',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• テーマ・フォントカスタマイズ\n• 広告非表示',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 現在の購入状況セクション
  Widget _buildCurrentStatusSection(OneTimePurchaseService purchaseService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '現在の購入状況',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusItem(
              'まいかごプレミアム',
              purchaseService.isPremiumUnlocked,
              Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  /// ステータスアイテム
  Widget _buildStatusItem(String title, bool isUnlocked, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isUnlocked ? Icons.check_circle : Icons.circle_outlined,
            color: isUnlocked ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            size: 20,
            color: isUnlocked ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isUnlocked ? Colors.black : Colors.grey,
              fontWeight: isUnlocked ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          if (isUnlocked) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '購入済み',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 購入セクション
  Widget _buildPurchaseSection(OneTimePurchaseService purchaseService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '購入可能な機能',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...OneTimePurchase.availablePurchases.map((purchase) {
          final isPurchased =
              _isPurchaseAlreadyOwned(purchase, purchaseService);
          return _buildPurchaseCard(purchase, isPurchased, purchaseService);
        }),
      ],
    );
  }

  /// 購入済みかどうかをチェック
  bool _isPurchaseAlreadyOwned(
      OneTimePurchase purchase, OneTimePurchaseService service) {
    return service.isPremiumUnlocked;
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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

            // 購入ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPurchased || _isLoading
                    ? null
                    : () => _purchaseProduct(purchase, service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPurchased ? Colors.green : Colors.blue,
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
      ),
    );
  }

  /// エラーセクション
  Widget _buildErrorSection(String error) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
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

  /// デバッグダイアログを表示
  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('デバッグ情報'),
        content: Consumer<OneTimePurchaseService>(
          builder: (context, service, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('まいかごプレミアム: ${service.isPremiumUnlocked}'),
                Text('ストア利用可能: ${service.isStoreAvailable}'),
                if (service.error != null) Text('エラー: ${service.error}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service =
                  Provider.of<OneTimePurchaseService>(context, listen: false);
              await service.restorePurchases();
              Navigator.of(context).pop();
            },
            child: const Text('購入復元'),
          ),
        ],
      ),
    );
  }
}
