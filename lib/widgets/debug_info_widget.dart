import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';

import '../services/feature_access_control.dart';

/// デバッグ情報表示ウィジェット
/// 開発時のみ使用し、本番環境では非表示にする
class DebugInfoWidget extends StatelessWidget {
  const DebugInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        return ExpansionTile(
          title: const Text('🔧 デバッグ情報（開発用）'),
          children: [
            _buildSubscriptionInfo(subscriptionService),
            _buildAdControlInfo(subscriptionService, featureControl),
            _buildFeatureAccessInfo(featureControl),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionInfo(
    SubscriptionIntegrationService subscriptionService,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 サブスクリプション情報',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('現在のプラン: ${subscriptionService.currentPlanName}'),
            Text('サブスクリプション有効: ${subscriptionService.isSubscriptionActive}'),
            Text(
              '期限: ${subscriptionService.subscriptionExpiry?.toString() ?? 'なし'}',
            ),
            Text('期限切れ: ${subscriptionService.isSubscriptionExpired}'),
            Text('グループ共有: ${subscriptionService.hasFamilySharing}'),
            Text('最大リスト数: ${subscriptionService.maxLists}'),
            Text('最大アイテム数: ${subscriptionService.maxItemsPerList}'),
          ],
        ),
      ),
    );
  }

  // 寄付情報セクションは削除（寄付特典がなくなったため）

  Widget _buildAdControlInfo(
    SubscriptionIntegrationService subscriptionService,
    FeatureAccessControl featureControl,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📺 広告制御情報',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('サブスクリプションによる広告非表示: ${!subscriptionService.shouldShowAds}'),
            Text('最終的な広告非表示: ${subscriptionService.shouldHideAds}'),
            Text('FeatureAccessControl広告非表示: ${featureControl.isAdRemoved()}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: subscriptionService.shouldHideAds
                    ? Colors.green[100]
                    : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subscriptionService.shouldHideAds ? '✅ 広告非表示' : '❌ 広告表示',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ 寄付による広告非表示は廃止されました',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureAccessInfo(FeatureAccessControl featureControl) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔓 機能アクセス情報',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'テーマカスタマイズ: ${featureControl.canCustomizeTheme() ? '✅' : '❌'}',
            ),
            Text(
              'フォントカスタマイズ: ${featureControl.canCustomizeFont() ? '✅' : '❌'}',
            ),
            Text('グループ共有: ${featureControl.canUseFamilySharing() ? '✅' : '❌'}'),
            Text('分析機能: ${featureControl.canUseAnalytics() ? '✅' : '❌'}'),
            Text('エクスポート機能: ${featureControl.canUseExport() ? '✅' : '❌'}'),
            Text('バックアップ機能: ${featureControl.canUseBackup() ? '✅' : '❌'}'),
          ],
        ),
      ),
    );
  }
}
