import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/store_preparation_service.dart';

/// ストア申請エクスポートウィジェット
class StoreExportWidget extends StatelessWidget {
  const StoreExportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StorePreparationService>(
      builder: (context, storeService, _) {
        final exportData = storeService.getStoreExportData();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExportCard(context, storeService),
              const SizedBox(height: 16),
              _buildStoreListingCard(context, exportData),
              const SizedBox(height: 16),
              _buildIapProductsCard(context, exportData),
              const SizedBox(height: 16),
              _buildConfigurationCard(context, exportData),
            ],
          ),
        );
      },
    );
  }

  /// エクスポートカードを構築
  Widget _buildExportCard(BuildContext context, StorePreparationService storeService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.download,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'ストア申請データのエクスポート',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'ストア申請に必要なデータをエクスポートできます。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportToJson(context, storeService),
                    icon: const Icon(Icons.code),
                    label: const Text('JSON形式'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportToCsv(context, storeService),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV形式'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  /// ストア情報カードを構築
  Widget _buildStoreListingCard(BuildContext context, Map<String, dynamic> exportData) {
    final storeListing = exportData['storeListing'] as Map<String, dynamic>;
    
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
                Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'ストア情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('アプリ名', storeListing['appName']),
            _buildInfoRow('短い説明', storeListing['shortDescription']),
            _buildInfoRow('カテゴリ', storeListing['category']),
            _buildInfoRow('対象年齢', storeListing['contentRating']),
            _buildInfoRow('対象ユーザー', storeListing['targetAudience']),
            const SizedBox(height: 12),
            const Text(
              '完全な説明:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                storeListing['fullDescription'],
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// アプリ内購入商品カードを構築
  Widget _buildIapProductsCard(BuildContext context, Map<String, dynamic> exportData) {
    final iapProducts = exportData['iapProducts'] as Map<String, Map<String, dynamic>>;
    
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
                Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'アプリ内購入商品',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...iapProducts.entries.map((entry) => _buildProductItem(context, entry.value)),
          ],
        ),
      ),
    );
  }

  /// 設定カードを構築
  Widget _buildConfigurationCard(BuildContext context, Map<String, dynamic> exportData) {
    final appInfo = exportData['appInfo'] as Map<String, dynamic>;
    final preparationStatus = exportData['preparationStatus'] as Map<String, dynamic>;
    
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
                Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '設定情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('アプリ名', appInfo['name']),
            _buildInfoRow('バージョン', appInfo['version']),
            _buildInfoRow('ビルド番号', appInfo['buildNumber']),
            _buildInfoRow('パッケージ名', appInfo['packageName']),
            const SizedBox(height: 12),
            const Text(
              '準備状況:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusRow('ストア準備完了', preparationStatus['isStoreReady']),
            _buildStatusRow('IAP設定', preparationStatus['iapConfigured']),
            _buildStatusRow('プライバシーポリシー', preparationStatus['privacyPolicyUpdated']),
            _buildStatusRow('利用規約', preparationStatus['termsOfServiceUpdated']),
            _buildStatusRow('スクリーンショット', preparationStatus['screenshotsReady']),
            _buildStatusRow('コンプライアンス', preparationStatus['complianceChecked']),
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

  /// ステータス行を構築
  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.error,
            color: value ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: value ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 商品アイテムを構築
  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product['price'],
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product['description'],
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product['type'],
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product['billingPeriod'],
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// JSON形式でエクスポート
  void _exportToJson(BuildContext context, StorePreparationService storeService) {
    final exportData = storeService.getStoreExportData();
    final jsonString = _formatJson(exportData);
    
    _showExportDialog(context, 'JSON形式', jsonString);
  }

  /// CSV形式でエクスポート
  void _exportToCsv(BuildContext context, StorePreparationService storeService) {
    final exportData = storeService.getStoreExportData();
    final csvString = _formatCsv(exportData);
    
    _showExportDialog(context, 'CSV形式', csvString);
  }

  /// エクスポートダイアログを表示
  void _showExportDialog(BuildContext context, String format, String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$format エクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$format データが生成されました。'),
            const SizedBox(height: 16),
            Container(
              width: double.maxFinite,
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  data,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 実際のファイル保存機能を実装
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$format ファイルを保存しました'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// JSON形式にフォーマット
  String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// CSV形式にフォーマット
  String _formatCsv(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // ヘッダー
    buffer.writeln('項目,値');
    
    // アプリ情報
    final appInfo = data['appInfo'] as Map<String, dynamic>;
    buffer.writeln('アプリ名,${appInfo['name']}');
    buffer.writeln('バージョン,${appInfo['version']}');
    buffer.writeln('ビルド番号,${appInfo['buildNumber']}');
    buffer.writeln('パッケージ名,${appInfo['packageName']}');
    
    // 準備状況
    final preparationStatus = data['preparationStatus'] as Map<String, dynamic>;
    buffer.writeln('ストア準備完了,${preparationStatus['isStoreReady']}');
    buffer.writeln('IAP設定,${preparationStatus['iapConfigured']}');
    buffer.writeln('プライバシーポリシー,${preparationStatus['privacyPolicyUpdated']}');
    buffer.writeln('利用規約,${preparationStatus['termsOfServiceUpdated']}');
    buffer.writeln('スクリーンショット,${preparationStatus['screenshotsReady']}');
    buffer.writeln('コンプライアンス,${preparationStatus['complianceChecked']}');
    
    return buffer.toString();
  }
}
