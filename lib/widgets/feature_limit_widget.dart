import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feature_access_control.dart';
import '../services/subscription_integration_service.dart';

/// 機能制限表示ウィジェット
/// 制限に達した際の優しい案内とアップグレード促進を提供
class FeatureLimitWidget extends StatelessWidget {
  final FeatureType featureType;
  final Widget? child;
  final VoidCallback? onUpgradePressed;
  final Map<String, dynamic>? context;

  const FeatureLimitWidget({
    super.key,
    required this.featureType,
    this.child,
    this.onUpgradePressed,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final isLocked = featureControl.isFeatureLocked(featureType);

        if (!isLocked) {
          return child ?? const SizedBox.shrink();
        }

        return _buildLimitCard(context, featureControl, subscriptionService);
      },
    );
  }

  Widget _buildLimitCard(
    BuildContext context,
    FeatureAccessControl featureControl,
    SubscriptionIntegrationService subscriptionService,
  ) {
    final message = featureControl.getFeatureLockedMessage(featureType);
    final upgradeMessage = featureControl.getUpgradeRecommendationMessage(
      featureType,
    );
    final recommendedPlan = featureControl.getRecommendedUpgradePlan(
      featureType,
    );
    final planInfo = subscriptionService.getPlanInfo(recommendedPlan);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade50, Colors.orange.shade100],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFeatureIcon(featureType),
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getFeatureTitle(featureType),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'プレミアム',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade800),
            ),
            const SizedBox(height: 12),
            Text(
              upgradeMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    onUpgradePressed ??
                    () {
                      Navigator.of(context).pushNamed('/subscription');
                    },
                icon: const Icon(Icons.star),
                label: Text('${planInfo['name']}にアップグレード'),
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

  IconData _getFeatureIcon(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.listCreation:
        return Icons.list;
      case FeatureType.themeCustomization:
        return Icons.palette;
      case FeatureType.fontCustomization:
        return Icons.text_fields;
      case FeatureType.familySharing:
        return Icons.family_restroom;
      case FeatureType.analytics:
        return Icons.analytics;
      case FeatureType.adRemoval:
        return Icons.block;
      case FeatureType.export:
        return Icons.download;
      case FeatureType.backup:
        return Icons.backup;
    }
  }

  String _getFeatureTitle(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.listCreation:
        return 'タブ数制限';
      case FeatureType.themeCustomization:
        return 'テーマカスタマイズ';
      case FeatureType.fontCustomization:
        return 'フォントカスタマイズ';
      case FeatureType.familySharing:
        return 'グループ共有';
      case FeatureType.analytics:
        return '分析機能';
      case FeatureType.adRemoval:
        return '広告非表示';
      case FeatureType.export:
        return 'エクスポート機能';
      case FeatureType.backup:
        return 'バックアップ機能';
    }
  }
}

/// 制限に達した際の表示ウィジェット
class LimitReachedWidget extends StatelessWidget {
  final LimitReachedType limitType;
  final int currentUsage;
  final int limit;
  final VoidCallback? onUpgradePressed;
  final Map<String, dynamic>? context;

  const LimitReachedWidget({
    super.key,
    required this.limitType,
    required this.currentUsage,
    required this.limit,
    this.onUpgradePressed,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final message = featureControl.getLimitReachedMessage(
          limitType,
          context: this.context,
        );
        final upgradeMessage = featureControl.getUpgradeRecommendationMessage(
          _getFeatureType(limitType),
        );
        final recommendedPlan = featureControl.getRecommendedUpgradePlan(
          _getFeatureType(limitType),
        );
        final planInfo = subscriptionService.getPlanInfo(recommendedPlan);

        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade50, Colors.red.shade100],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getLimitIcon(limitType),
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getLimitTitle(limitType),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '制限到達',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 使用状況の可視化
                _buildUsageProgress(currentUsage, limit),
                const SizedBox(height: 12),

                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade800),
                ),
                const SizedBox(height: 12),
                Text(
                  upgradeMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        onUpgradePressed ??
                        () {
                          Navigator.of(context).pushNamed('/subscription');
                        },
                    icon: const Icon(Icons.star),
                    label: Text('${planInfo['name']}にアップグレード'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
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
      },
    );
  }

  Widget _buildUsageProgress(int currentUsage, int limit) {
    final progress = currentUsage / limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '使用状況',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              '$currentUsage / $limit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.red.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
          minHeight: 8,
        ),
      ],
    );
  }

  FeatureType? _getFeatureType(LimitReachedType limitType) {
    switch (limitType) {
      case LimitReachedType.listLimit:
        return FeatureType.listCreation;
      case LimitReachedType.itemLimit:
        return FeatureType.listCreation; // アイテム制限もタブ作成機能に関連
      case LimitReachedType.themeLimit:
        return FeatureType.themeCustomization;
      case LimitReachedType.fontLimit:
        return FeatureType.fontCustomization;
      case LimitReachedType.familyLimit:
        return FeatureType.familySharing;
      case LimitReachedType.featureLocked:
        return null;
    }
  }

  IconData _getLimitIcon(LimitReachedType limitType) {
    switch (limitType) {
      case LimitReachedType.listLimit:
        return Icons.list;
      case LimitReachedType.itemLimit:
        return Icons.shopping_cart; // アイテム制限用のアイコン
      case LimitReachedType.themeLimit:
        return Icons.palette;
      case LimitReachedType.fontLimit:
        return Icons.text_fields;
      case LimitReachedType.familyLimit:
        return Icons.family_restroom;
      case LimitReachedType.featureLocked:
        return Icons.lock;
    }
  }

  String _getLimitTitle(LimitReachedType limitType) {
    switch (limitType) {
      case LimitReachedType.listLimit:
        return 'タブ数制限';
      case LimitReachedType.itemLimit:
        return 'リストアイテム数制限';
      case LimitReachedType.themeLimit:
        return 'テーマ数制限';
      case LimitReachedType.fontLimit:
        return 'フォント数制限';
      case LimitReachedType.familyLimit:
        return '家族メンバー数制限';
      case LimitReachedType.featureLocked:
        return '機能ロック';
    }
  }
}

/// 使用状況表示ウィジェット
class UsageStatusWidget extends StatelessWidget {
  final FeatureType featureType;
  final int currentUsage;
  final int limit;
  final VoidCallback? onUpgradePressed;

  const UsageStatusWidget({
    super.key,
    required this.featureType,
    required this.currentUsage,
    required this.limit,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentUsage / limit;
    final isNearLimit = progress >= 0.8;
    final isAtLimit = progress >= 1.0;

    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final isLocked = featureControl.isFeatureLocked(featureType);

        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 1,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isAtLimit
                  ? Colors.red.shade50
                  : isNearLimit
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getFeatureIcon(featureType),
                      color: _getStatusColor(isAtLimit, isNearLimit),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFeatureTitle(featureType),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(isAtLimit, isNearLimit),
                        ),
                      ),
                    ),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            isAtLimit,
                            isNearLimit,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '制限',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(isAtLimit, isNearLimit),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // 使用状況バー
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _getStatusColor(
                    isAtLimit,
                    isNearLimit,
                  ).withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(isAtLimit, isNearLimit),
                  ),
                  minHeight: 6,
                ),
                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentUsage / $limit',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(isAtLimit, isNearLimit),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isLocked)
                      TextButton(
                        onPressed:
                            onUpgradePressed ??
                            () {
                              Navigator.of(context).pushNamed('/subscription');
                            },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'アップグレード',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(isAtLimit, isNearLimit),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(bool isAtLimit, bool isNearLimit) {
    if (isAtLimit) return Colors.red.shade600;
    if (isNearLimit) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  IconData _getFeatureIcon(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.listCreation:
        return Icons.list;
      case FeatureType.themeCustomization:
        return Icons.palette;
      case FeatureType.fontCustomization:
        return Icons.text_fields;
      case FeatureType.familySharing:
        return Icons.family_restroom;
      case FeatureType.analytics:
        return Icons.analytics;
      case FeatureType.adRemoval:
        return Icons.block;
      case FeatureType.export:
        return Icons.download;
      case FeatureType.backup:
        return Icons.backup;
    }
  }

  String _getFeatureTitle(FeatureType featureType) {
    switch (featureType) {
      case FeatureType.listCreation:
        return 'タブ数';
      case FeatureType.themeCustomization:
        return 'テーマ';
      case FeatureType.fontCustomization:
        return 'フォント';
      case FeatureType.familySharing:
        return 'グループメンバー';
      case FeatureType.analytics:
        return '分析機能';
      case FeatureType.adRemoval:
        return '広告非表示';
      case FeatureType.export:
        return 'エクスポート機能';
      case FeatureType.backup:
        return 'バックアップ機能';
    }
  }
}

/// 機能制限オーバーレイウィジェット
/// 制限された機能の上に表示されるオーバーレイ
class FeatureLimitOverlay extends StatelessWidget {
  final FeatureType featureType;
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const FeatureLimitOverlay({
    super.key,
    required this.featureType,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final isLocked = featureControl.isFeatureLocked(featureType);

        if (!isLocked) {
          return child;
        }

        return Stack(
          children: [
            // 元のウィジェット（ぼかし効果付き）
            Opacity(opacity: 0.3, child: child),

            // 制限オーバーレイ
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          color: Colors.orange.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'プレミアム機能',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          featureControl.getFeatureLockedMessage(featureType),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed:
                              onUpgradePressed ??
                              () {
                                Navigator.of(
                                  context,
                                ).pushNamed('/subscription');
                              },
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text('アップグレード'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 制限通知バナーウィジェット
/// 画面上部に表示される制限通知
class LimitNotificationBanner extends StatelessWidget {
  final FeatureType featureType;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onDismiss;

  const LimitNotificationBanner({
    super.key,
    required this.featureType,
    this.onUpgradePressed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final isLocked = featureControl.isFeatureLocked(featureType);

        if (!isLocked) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade100, Colors.orange.shade200],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  featureControl.getFeatureLockedMessage(featureType),
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed:
                    onUpgradePressed ??
                    () {
                      Navigator.of(context).pushNamed('/subscription');
                    },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'アップグレード',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// タブ作成制限ウィジェット
/// タブ作成画面で使用
class ListCreationLimitWidget extends StatelessWidget {
  final int currentListCount;
  final VoidCallback? onUpgradePressed;

  const ListCreationLimitWidget({
    super.key,
    required this.currentListCount,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final canCreate = featureControl.canCreateList(currentListCount);
        final maxLists = subscriptionService.maxLists;

        if (canCreate) {
          return const SizedBox.shrink();
        }

        return LimitReachedWidget(
          limitType: LimitReachedType.listLimit,
          currentUsage: currentListCount,
          limit: maxLists,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// テーマ設定制限ウィジェット
/// テーマ設定画面で使用
class ThemeCustomizationLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgradePressed;

  const ThemeCustomizationLimitWidget({super.key, this.onUpgradePressed});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final canCustomize = featureControl.canCustomizeTheme();

        if (canCustomize) {
          return const SizedBox.shrink();
        }

        return FeatureLimitWidget(
          featureType: FeatureType.themeCustomization,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// フォント設定制限ウィジェット
/// フォント設定画面で使用
class FontCustomizationLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgradePressed;

  const FontCustomizationLimitWidget({super.key, this.onUpgradePressed});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final canCustomize = featureControl.canCustomizeFont();

        if (canCustomize) {
          return const SizedBox.shrink();
        }

        return FeatureLimitWidget(
          featureType: FeatureType.fontCustomization,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// 家族共有制限ウィジェット
/// 家族共有画面で使用
class FamilySharingLimitWidget extends StatelessWidget {
  final int currentFamilyMembers;
  final VoidCallback? onUpgradePressed;

  const FamilySharingLimitWidget({
    super.key,
    required this.currentFamilyMembers,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final canUse = featureControl.canUseFamilySharing();
        final maxMembers = subscriptionService.maxFamilyMembers;

        if (!canUse) {
          return FeatureLimitWidget(
            featureType: FeatureType.familySharing,
            onUpgradePressed: onUpgradePressed,
          );
        }

        if (currentFamilyMembers >= maxMembers) {
          return LimitReachedWidget(
            limitType: LimitReachedType.familyLimit,
            currentUsage: currentFamilyMembers,
            limit: maxMembers,
            onUpgradePressed: onUpgradePressed,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// 分析機能制限ウィジェット
/// 分析・レポート画面で使用
class AnalyticsLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgradePressed;

  const AnalyticsLimitWidget({super.key, this.onUpgradePressed});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final canUse = featureControl.canUseAnalytics();

        if (canUse) {
          return const SizedBox.shrink();
        }

        return FeatureLimitWidget(
          featureType: FeatureType.analytics,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// 広告制限ウィジェット
/// 広告表示制御で使用
class AdRemovalLimitWidget extends StatelessWidget {
  final VoidCallback? onUpgradePressed;

  const AdRemovalLimitWidget({super.key, this.onUpgradePressed});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final isRemoved = featureControl.isAdRemoved();

        if (isRemoved) {
          return const SizedBox.shrink();
        }

        return FeatureLimitWidget(
          featureType: FeatureType.adRemoval,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// 使用状況サマリーウィジェット
/// 現在の使用状況を表示
class UsageSummaryWidget extends StatelessWidget {
  final int currentListCount;
  final int currentFamilyMembers;
  final VoidCallback? onUpgradePressed;

  const UsageSummaryWidget({
    super.key,
    required this.currentListCount,
    required this.currentFamilyMembers,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<FeatureAccessControl, SubscriptionIntegrationService>(
      builder: (context, featureControl, subscriptionService, _) {
        final maxLists = subscriptionService.maxLists;
        final maxFamilyMembers = subscriptionService.maxFamilyMembers;

        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '使用状況',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // リスト数使用状況
                UsageStatusWidget(
                  featureType: FeatureType.listCreation,
                  currentUsage: currentListCount,
                  limit: maxLists,
                  onUpgradePressed: onUpgradePressed,
                ),

                // 家族メンバー使用状況（利用可能な場合）
                if (subscriptionService.hasFamilySharing) ...[
                  const SizedBox(height: 8),
                  UsageStatusWidget(
                    featureType: FeatureType.familySharing,
                    currentUsage: currentFamilyMembers,
                    limit: maxFamilyMembers,
                    onUpgradePressed: onUpgradePressed,
                  ),
                ],

                const SizedBox(height: 12),
                Text(
                  '現在のプラン: ${subscriptionService.currentPlanName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
