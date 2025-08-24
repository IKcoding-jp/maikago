import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../services/feature_access_control.dart';
import '../models/subscription_plan.dart';

/// アップグレード促進UIシステム
/// 使用状況に基づく推奨プラン表示と魅力的な特典説明を提供
class UpgradePromotionWidget extends StatelessWidget {
  final String? title;
  final String? description;
  final FeatureType? blockedFeature;
  final VoidCallback? onUpgrade;
  final bool showFullScreen;
  final bool showCompact;

  const UpgradePromotionWidget({
    super.key,
    this.title,
    this.description,
    this.blockedFeature,
    this.onUpgrade,
    this.showFullScreen = false,
    this.showCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final currentPlan = subscriptionService.currentPlan;

        // すでに最高プランの場合は何も表示しない
        if (currentPlan == SubscriptionPlan.family) {
          return const SizedBox.shrink();
        }

        // 推奨プランを決定
        SubscriptionPlan recommendedPlan = SubscriptionPlan.basic;
        if (currentPlan == null || currentPlan == SubscriptionPlan.free) {
          recommendedPlan = SubscriptionPlan.basic;
        } else if (currentPlan == SubscriptionPlan.basic) {
          recommendedPlan = SubscriptionPlan.premium;
        } else if (currentPlan == SubscriptionPlan.premium) {
          recommendedPlan = SubscriptionPlan.family;
        }

        if (showFullScreen) {
          return _buildFullScreenPromotion(context, recommendedPlan);
        } else if (showCompact) {
          return _buildCompactPromotion(context, recommendedPlan);
        } else {
          return _buildStandardPromotion(context, recommendedPlan);
        }
      },
    );
  }

  Widget _buildStandardPromotion(BuildContext context, SubscriptionPlan plan) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? '${plan.name}にアップグレード',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description ?? 'より多くの機能をご利用いただけます',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildFeatureList(plan),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade ?? () => _navigateToSubscription(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('${plan.name}を始める'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPromotion(BuildContext context, SubscriptionPlan plan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? '${plan.name}でもっと便利に',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: onUpgrade ?? () => _navigateToSubscription(context),
            child: const Text('詳細'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenPromotion(
      BuildContext context, SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.rocket_launch,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            title ?? '${plan.name}でパワーアップ！',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description ?? 'より多くの機能で、もっと便利にお使いいただけます',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureList(plan),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade ?? () => _navigateToSubscription(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text('${plan.name}を始める'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(SubscriptionPlan plan) {
    final features = plan.getFeatures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .take(3)
          .map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _navigateToSubscription(BuildContext context) {
    Navigator.pushNamed(context, '/subscription');
  }

  // 静的ファクトリーメソッド
  static Widget forFeature({
    required FeatureType featureType,
    VoidCallback? onUpgrade,
  }) {
    return UpgradePromotionWidget(
      title: _getFeatureTitle(featureType),
      description: _getFeatureDescription(featureType),
      blockedFeature: featureType,
      onUpgrade: onUpgrade,
    );
  }

  static Widget compact({
    String? title,
    VoidCallback? onUpgrade,
  }) {
    return UpgradePromotionWidget(
      title: title,
      onUpgrade: onUpgrade,
      showCompact: true,
    );
  }

  static Widget fullScreen({
    String? title,
    String? description,
    VoidCallback? onUpgrade,
  }) {
    return UpgradePromotionWidget(
      title: title,
      description: description,
      onUpgrade: onUpgrade,
      showFullScreen: true,
    );
  }

  static String _getFeatureTitle(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.adRemoval:
        return '広告を非表示にする';
      case FeatureType.themeCustomization:
        return 'テーマをカスタマイズ';
      case FeatureType.fontCustomization:
        return 'フォントを変更';
      case FeatureType.familySharing:
        return 'ファミリー共有';
      case FeatureType.listCreation:
        return 'もっとリストを作成';
      case FeatureType.analytics:
        return '分析機能を使用';
      case FeatureType.export:
        return 'データをエクスポート';
      case FeatureType.backup:
        return 'バックアップ機能';
    }
  }

  static String _getFeatureDescription(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.adRemoval:
        return 'プレミアムプランで広告なしの快適な体験を';
      case FeatureType.themeCustomization:
        return 'お好みのテーマでアプリをカスタマイズ';
      case FeatureType.fontCustomization:
        return '見やすいフォントに変更して使いやすく';
      case FeatureType.familySharing:
        return '家族でリストを共有して便利に';
      case FeatureType.listCreation:
        return 'もっと多くのリストを作成して整理';
      case FeatureType.analytics:
        return 'お買い物の傾向を分析して効率化';
      case FeatureType.export:
        return 'データをエクスポートしてバックアップ';
      case FeatureType.backup:
        return 'クラウドバックアップで安心';
    }
  }
}
