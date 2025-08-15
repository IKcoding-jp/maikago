import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_preparation_service.dart';

/// ストア申請状況確認ウィジェット
class StoreStatusWidget extends StatelessWidget {
  const StoreStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StorePreparationService>(
      builder: (context, storeService, _) {
        final status = storeService.getStorePreparationStatus();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallStatusCard(context, status),
              const SizedBox(height: 16),
              _buildAppInfoCard(context, status),
              const SizedBox(height: 16),
              _buildComplianceCard(context, storeService),
              const SizedBox(height: 16),
              _buildProgressCard(context, status),
            ],
          ),
        );
      },
    );
  }

  /// 全体状況カードを構築
  Widget _buildOverallStatusCard(BuildContext context, Map<String, dynamic> status) {
    final isReady = status['isStoreReady'] as bool;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isReady
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isReady ? Icons.celebration : Icons.pending,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              isReady ? 'ストア申請準備完了！' : 'ストア申請準備中',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isReady
                  ? 'すべての準備が完了しました。ストア申請を開始できます。'
                  : 'いくつかの項目がまだ完了していません。',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// アプリ情報カードを構築
  Widget _buildAppInfoCard(BuildContext context, Map<String, dynamic> status) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'アプリ情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('アプリ名', 'まいカゴ'),
            _buildInfoRow('バージョン', status['appVersion'] ?? ''),
            _buildInfoRow('ビルド番号', status['buildNumber'] ?? ''),
            _buildInfoRow('パッケージ名', status['packageName'] ?? ''),
          ],
        ),
      ),
    );
  }

  /// コンプライアンスカードを構築
  Widget _buildComplianceCard(BuildContext context, StorePreparationService storeService) {
    final complianceChecks = storeService.complianceChecks;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'コンプライアンスチェック',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...complianceChecks.entries.map((entry) => _buildComplianceItem(
              context,
              entry.key,
              entry.value,
            )),
          ],
        ),
      ),
    );
  }

  /// 進捗カードを構築
  Widget _buildProgressCard(BuildContext context, Map<String, dynamic> status) {
    final totalItems = 6;
    final completedItems = [
      status['iapConfigured'],
      status['privacyPolicyUpdated'],
      status['termsOfServiceUpdated'],
      status['screenshotsReady'],
      status['complianceChecked'],
      status['complianceChecks'].values.every((check) => check),
    ].where((item) => item == true).length;
    
    final progress = completedItems / totalItems;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '準備進捗',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.orange,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '$completedItems / $totalItems 項目完了 (${(progress * 100).toInt()}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressItems(context, status),
          ],
        ),
      ),
    );
  }

  /// 情報行を構築
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// コンプライアンスアイテムを構築
  Widget _buildComplianceItem(BuildContext context, String key, bool value) {
    final labels = {
      'privacy_policy': 'プライバシーポリシー',
      'terms_of_service': '利用規約',
      'data_collection': 'データ収集',
      'user_consent': 'ユーザー同意',
      'data_retention': 'データ保持期間',
      'data_deletion': 'データ削除',
      'subscription_terms': 'サブスクリプション条項',
      'cancellation_policy': '解約ポリシー',
      'refund_policy': '返金ポリシー',
      'age_rating': '年齢制限',
      'content_guidelines': 'コンテンツガイドライン',
      'security_measures': 'セキュリティ対策',
    };
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.error,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              labels[key] ?? key,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: value ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 進捗アイテムを構築
  Widget _buildProgressItems(BuildContext context, Map<String, dynamic> status) {
    final items = [
      {'label': 'アプリ内購入設定', 'completed': status['iapConfigured']},
      {'label': 'プライバシーポリシー更新', 'completed': status['privacyPolicyUpdated']},
      {'label': '利用規約更新', 'completed': status['termsOfServiceUpdated']},
      {'label': 'スクリーンショット準備', 'completed': status['screenshotsReady']},
      {'label': 'コンプライアンスチェック', 'completed': status['complianceChecked']},
      {'label': '全コンプライアンス項目', 'completed': status['complianceChecks'].values.every((check) => check)},
    ];
    
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              item['completed'] ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item['completed'] ? Colors.green : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              item['label'],
              style: TextStyle(
                fontSize: 14,
                color: item['completed'] ? Colors.green : Colors.grey,
                fontWeight: item['completed'] ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
