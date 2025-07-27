import 'package:flutter/material.dart';

/// 今後の新機能画面
/// アプリに今後追加される予定の機能リストを表示
class UpcomingFeaturesScreen extends StatelessWidget {
  const UpcomingFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今後の新機能'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildFeatureList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '開発中の新機能',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'まいカゴをより便利にする機能を開発中です。\nご期待ください！',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      {
        'title': 'カテゴリ機能',
        'description': '商品をカテゴリ別に分類して管理できるようになります',
        'icon': Icons.category_rounded,
        'status': '開発中',
        'color': Colors.blue,
      },
      {
        'title': '冷蔵庫リスト',
        'description': '家にある食材を管理して、在庫を把握できます',
        'icon': Icons.kitchen_rounded,
        'status': '計画中',
        'color': Colors.cyan,
      },
      {
        'title': 'AI献立考案機能',
        'description': '冷蔵庫の食材からAIが最適な献立を提案します',
        'icon': Icons.restaurant_menu_rounded,
        'status': '計画中',
        'color': Colors.deepPurple,
      },
      {
        'title': '買い物履歴',
        'description': '過去の買い物リストを確認できるようになります',
        'icon': Icons.history_rounded,
        'status': '計画中',
        'color': Colors.green,
      },
      {
        'title': '共有機能',
        'description': '家族や友達と買い物リストを共有できるようになります',
        'icon': Icons.share_rounded,
        'status': '計画中',
        'color': Colors.orange,
      },
      {
        'title': '通知機能',
        'description': '買い物の予定日や忘れ物を通知でお知らせします',
        'icon': Icons.notifications_rounded,
        'status': '計画中',
        'color': Colors.purple,
      },
      {
        'title': 'バーコードスキャン',
        'description': '商品のバーコードをスキャンして自動で商品名を入力',
        'icon': Icons.qr_code_scanner_rounded,
        'status': '計画中',
        'color': Colors.red,
      },
      {
        'title': 'レシート機能',
        'description': 'レシートを撮影して自動で商品リストを作成',
        'icon': Icons.receipt_rounded,
        'status': '計画中',
        'color': Colors.teal,
      },
      {
        'title': '統計機能',
        'description': '買い物の傾向や支出をグラフで確認できます',
        'icon': Icons.analytics_rounded,
        'status': '計画中',
        'color': Colors.indigo,
      },
      {
        'title': 'オフライン対応',
        'description': 'インターネットがなくても買い物リストを管理できます',
        'icon': Icons.cloud_off_rounded,
        'status': '計画中',
        'color': Colors.grey,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '予定されている機能',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureCard(context, feature)),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feature['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(feature['icon'], color: feature['color'], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feature['title'],
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: feature['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          feature['status'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: feature['color'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
}
