import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../services/feature_access_control.dart';
import '../drawer/maikago_premium.dart';

/// 買い切り型アプリ内課金のアップグレード促進UIシステム
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
        final isPremiumUnlocked = subscriptionService.isPremiumUnlocked;

        // すでにプレミアム機能を利用中の場合は何も表示しない
        if (isPremiumUnlocked) {
          return const SizedBox.shrink();
        }

        if (showFullScreen) {
          return _buildFullScreenPromotion(context);
        } else if (showCompact) {
          return _buildCompactPromotion(context);
        } else {
          return _buildStandardPromotion(context);
        }
      },
    );
  }

  /// 標準的なアップグレード促進表示
  Widget _buildStandardPromotion(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC0CB), Color(0xFFFFB6C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title ?? 'まいかごプレミアム',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description ?? 'すべてのプレミアム機能を利用可能に',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgrade ?? () => _navigateToPremium(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFFC0CB),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'プレミアム機能を確認',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// コンパクトなアップグレード促進表示
  Widget _buildCompactPromotion(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC0CB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFC0CB).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Color(0xFFFFC0CB),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? 'プレミアム機能でより快適に',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          TextButton(
            onPressed: onUpgrade ?? () => _navigateToPremium(context),
            child: const Text(
              '詳細',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFC0CB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// フルスクリーンのアップグレード促進表示
  Widget _buildFullScreenPromotion(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC0CB), Color(0xFFFFB6C1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title ?? 'まいかごプレミアム',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description ?? 'すべてのプレミアム機能を利用可能に',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeatureList(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpgrade ?? () => _navigateToPremium(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFFC0CB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'プレミアム機能を確認',
                    style: TextStyle(
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
    );
  }

  /// 機能一覧を表示
  Widget _buildFeatureList() {
    final features = [
      '全テーマ利用可能',
      '全フォント利用可能',
      '広告完全非表示',
    ];

    return Column(
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// プレミアム画面に遷移
  void _navigateToPremium(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionScreen(),
      ),
    );
  }
}
