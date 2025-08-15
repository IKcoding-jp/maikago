import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/store_preparation_service.dart';

/// ストア申請チェックリストウィジェット
class StoreChecklistWidget extends StatelessWidget {
  const StoreChecklistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StorePreparationService>(
      builder: (context, storeService, _) {
        final checklist = storeService.getStoreChecklist();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: checklist.length,
          itemBuilder: (context, index) {
            final category = checklist[index];
            return _buildCategoryCard(context, category, storeService);
          },
        );
      },
    );
  }

  /// カテゴリカードを構築
  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
    StorePreparationService storeService,
  ) {
    final categoryName = category['category'] as String;
    final items = category['items'] as List<Map<String, dynamic>>;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            _getCategoryIcon(categoryName),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildCategoryStatus(items),
          ],
        ),
        children: items.map((item) => _buildChecklistItem(context, item, storeService)).toList(),
      ),
    );
  }

  /// カテゴリアイコンを取得
  Widget _getCategoryIcon(String categoryName) {
    IconData iconData;
    Color iconColor;
    
    switch (categoryName) {
      case 'アプリ内購入':
        iconData = Icons.shopping_cart;
        iconColor = Colors.blue;
        break;
      case '法的要件':
        iconData = Icons.gavel;
        iconColor = Colors.red;
        break;
      case 'ストア申請':
        iconData = Icons.store;
        iconColor = Colors.green;
        break;
      case 'コンプライアンス':
        iconData = Icons.security;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.check_circle;
        iconColor = Colors.grey;
    }
    
    return Icon(iconData, color: iconColor);
  }

  /// カテゴリステータスを構築
  Widget _buildCategoryStatus(List<Map<String, dynamic>> items) {
    final completedCount = items.where((item) => item['completed'] == true).length;
    final totalCount = items.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completedCount == totalCount ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$completedCount/$totalCount',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// チェックリストアイテムを構築
  Widget _buildChecklistItem(
    BuildContext context,
    Map<String, dynamic> item,
    StorePreparationService storeService,
  ) {
    final title = item['title'] as String;
    final description = item['description'] as String;
    final completed = item['completed'] as bool;
    final action = item['action'] as String;
    
    return ListTile(
      leading: Checkbox(
        value: completed,
        onChanged: (value) => _handleItemToggle(context, title, value ?? false, storeService),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: completed ? TextDecoration.lineThrough : null,
          color: completed ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 4),
          Text(
            action,
            style: TextStyle(
              color: completed ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: completed
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.pending, color: Colors.orange),
    );
  }

  /// アイテムのトグル処理
  void _handleItemToggle(
    BuildContext context,
    String title,
    bool value,
    StorePreparationService storeService,
  ) {
    // 特定のアイテムに基づいて適切なメソッドを呼び出す
    switch (title) {
      case '商品設定の完了':
      case '価格設定の確認':
        if (value) {
          storeService.markIapConfigured();
        }
        break;
      case 'プライバシーポリシーの更新':
        if (value) {
          storeService.markPrivacyPolicyUpdated();
        }
        break;
      case '利用規約の更新':
        if (value) {
          storeService.markTermsOfServiceUpdated();
        }
        break;
      case 'スクリーンショットの準備':
        if (value) {
          storeService.markScreenshotsReady();
        }
        break;
      case 'データ保護の確認':
      case '解約方法の明記':
        if (value) {
          storeService.markComplianceChecked();
        }
        break;
    }
    
    // 完了メッセージを表示
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title を完了としてマークしました'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
