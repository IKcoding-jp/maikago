import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feature_access_control.dart';
import '../services/subscription_integration_service.dart';
import '../services/subscription_manager.dart';
import '../widgets/feature_limit_widget.dart';
import '../providers/data_provider.dart';

/// 使用状況表示画面
class UsageStatusScreen extends StatelessWidget {
  const UsageStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用状況'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer3<FeatureAccessControl, SubscriptionIntegrationService, DataProvider>(
        builder: (context, featureControl, subscriptionService, dataProvider, _) {
          final currentListCount = dataProvider.shops.length;
          final limitedFeatures = featureControl.getLimitedFeatures(currentListCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 現在のプラン情報
                _buildCurrentPlanCard(context, subscriptionService),
                const SizedBox(height: 24),

                // 使用状況
                _buildUsageSection(context, featureControl, currentListCount),
                const SizedBox(height: 24),

                // 機能制限状況
                if (limitedFeatures.isNotEmpty) ...[
                  _buildLimitedFeaturesSection(context, limitedFeatures, featureControl),
                  const SizedBox(height: 24),
                ],

                // 利用可能機能
                _buildAvailableFeaturesSection(context, subscriptionService),
                const SizedBox(height: 24),

                // アップグレード推奨
                _buildUpgradeRecommendationSection(context, featureControl, limitedFeatures),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 現在のプラン情報カード
  Widget _buildCurrentPlanCard(BuildContext context, SubscriptionIntegrationService service) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPlanIcon(service.currentPlan),
                  color: _getPlanColor(service.currentPlan),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.currentPlanName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getPlanColor(service.currentPlan),
                        ),
                      ),
                      if (service.isSubscriptionActive) ...[
                        const SizedBox(height: 4),
                        Text(
                          '月額 ¥${service.currentPlanPrice}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (service.isSubscriptionActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'アクティブ',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (service.isSubscriptionActive && service.subscriptionExpiry != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '期限: ${_formatDate(service.subscriptionExpiry!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 使用状況セクション
  Widget _buildUsageSection(BuildContext context, FeatureAccessControl featureControl, int currentListCount) {
    final listUsage = featureControl.getListUsageInfo(currentListCount);
    final familySharing = featureControl.getFamilySharingInfo();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '使用状況',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildUsageItem(
              context,
              'リスト',
              listUsage['current'].toString(),
              listUsage['max']?.toString() ?? '無制限',
              listUsage['usagePercentage']?.toDouble() ?? 0.0,
              listUsage['isLimitReached'] ?? false,
            ),
            if (familySharing['available']) ...[
              const SizedBox(height: 16),
              _buildUsageItem(
                context,
                '家族メンバー',
                familySharing['current'].toString(),
                familySharing['max'].toString(),
                familySharing['usagePercentage'].toDouble(),
                familySharing['isLimitReached'] ?? false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 使用状況アイテム
  Widget _buildUsageItem(
    BuildContext context,
    String label,
    String current,
    String max,
    double percentage,
    bool isLimitReached,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$current / $max',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isLimitReached ? Colors.red : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isLimitReached ? Colors.red : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.round()}% 使用中',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// 制限機能セクション
  Widget _buildLimitedFeaturesSection(
    BuildContext context,
    List<FeatureType> limitedFeatures,
    FeatureAccessControl featureControl,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  '制限されている機能',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...limitedFeatures.map((featureType) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureLimitWidget(
                featureType: featureType,
                onUpgradePressed: () => _navigateToSubscription(context),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 利用可能機能セクション
  Widget _buildAvailableFeaturesSection(BuildContext context, SubscriptionIntegrationService service) {
    final availableFeatures = <Map<String, dynamic>>[];

    if (service.canChangeTheme) {
      availableFeatures.add({
        'title': 'テーマカスタマイズ',
        'icon': Icons.palette,
        'description': 'お好みのテーマに変更できます',
        'color': Colors.blue,
      });
    }

    if (service.canChangeFont) {
      availableFeatures.add({
        'title': 'フォント変更',
        'icon': Icons.text_fields,
        'description': '読みやすいフォントに変更できます',
        'color': Colors.green,
      });
    }

    if (service.shouldHideAds) {
      availableFeatures.add({
        'title': '広告非表示',
        'icon': Icons.block,
        'description': '広告なしで快適に利用できます',
        'color': Colors.purple,
      });
    }

    if (service.hasFamilySharing) {
      availableFeatures.add({
        'title': '家族共有',
        'icon': Icons.family_restroom,
        'description': '家族メンバーと共有できます',
        'color': Colors.orange,
      });
    }

    if (service.currentPlan == SubscriptionPlan.premium || service.currentPlan == SubscriptionPlan.family) {
      availableFeatures.add({
        'title': '分析・レポート',
        'icon': Icons.analytics,
        'description': '詳細な分析データを確認できます',
        'color': Colors.indigo,
      });
    }

    if (availableFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  '利用可能な機能',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...availableFeatures.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                                         decoration: BoxDecoration(
                       color: feature['color'].withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                    child: Icon(
                      feature['icon'],
                      color: feature['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          feature['description'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// アップグレード推奨セクション
  Widget _buildUpgradeRecommendationSection(
    BuildContext context,
    FeatureAccessControl featureControl,
    List<FeatureType> limitedFeatures,
  ) {
    if (limitedFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    final upgradeMessage = featureControl.getUpgradeRecommendationMessage(limitedFeatures.first);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'アップグレード推奨',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              upgradeMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSubscription(context),
                icon: const Icon(Icons.upgrade, size: 16),
                label: const Text('プランを確認'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === ヘルパーメソッド ===

  IconData _getPlanIcon(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Icons.free_breakfast;
      case SubscriptionPlan.basic:
        return Icons.star;
      case SubscriptionPlan.premium:
        return Icons.diamond;
      case SubscriptionPlan.family:
        return Icons.family_restroom;
    }
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey;
      case SubscriptionPlan.basic:
        return Colors.blue;
      case SubscriptionPlan.premium:
        return Colors.purple;
      case SubscriptionPlan.family:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.of(context).pushNamed('/subscription');
  }
}
