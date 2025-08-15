import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../services/subscription_manager.dart';
import '../services/feature_access_control.dart';
// import '../config.dart'; // 未使用のためコメントアウト

/// アップグレード促進UIシステム
/// 使用状況に基づく推奨プラン表示と魅力的な特典説明を提供

/// アップグレード促進カードウィジェット
/// メインのアップグレード促進表示
class UpgradePromotionCard extends StatelessWidget {
  final UpgradeTrigger trigger;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onDismiss;
  final Map<String, dynamic>? context;

  const UpgradePromotionCard({
    super.key,
    required this.trigger,
    this.onUpgradePressed,
    this.onDismiss,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      SubscriptionIntegrationService,
      FeatureAccessControl,
      SubscriptionManager
    >(
      builder:
          (
            context,
            subscriptionService,
            featureControl,
            subscriptionManager,
            _,
          ) {
            final currentPlan = subscriptionService.currentPlan;
            final recommendedPlan = _getRecommendedPlan(
              subscriptionService,
              featureControl,
            );
            final benefits = _getPlanBenefits(recommendedPlan);
            final currentUsage = _getCurrentUsage(
              subscriptionService,
              featureControl,
            );

            return Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getPlanColor(recommendedPlan).withValues(alpha: 0.1),
                      _getPlanColor(recommendedPlan).withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ヘッダー
                      _buildHeader(context, recommendedPlan, currentPlan),
                      const SizedBox(height: 20),

                      // 使用状況分析
                      if (currentUsage.isNotEmpty) ...[
                        _buildUsageAnalysis(context, currentUsage),
                        const SizedBox(height: 20),
                      ],

                      // 特典リスト
                      _buildBenefitsList(context, benefits),
                      const SizedBox(height: 20),

                      // 価格表示
                      _buildPricingSection(context, recommendedPlan),
                      const SizedBox(height: 24),

                      // アクションボタン
                      _buildActionButtons(context, recommendedPlan),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  /// ヘッダーセクション
  Widget _buildHeader(
    BuildContext context,
    SubscriptionPlan recommendedPlan,
    SubscriptionPlan currentPlan,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getPlanColor(recommendedPlan).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getPlanIcon(recommendedPlan),
            color: _getPlanColor(recommendedPlan),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getPlanName(recommendedPlan)}にアップグレード',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getPlanColor(recommendedPlan),
                ),
              ),
              Text(
                _getUpgradeReason(trigger),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, color: Colors.grey[500]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  /// 使用状況分析セクション
  Widget _buildUsageAnalysis(BuildContext context, Map<String, dynamic> usage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                '現在の使用状況',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...usage.entries.map(
            (entry) => _buildUsageItem(context, entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  /// 使用状況アイテム
  Widget _buildUsageItem(BuildContext context, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 特典リストセクション
  Widget _buildBenefitsList(
    BuildContext context,
    List<Map<String, dynamic>> benefits,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アップグレード特典',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...benefits.map((benefit) => _buildBenefitItem(context, benefit)),
      ],
    );
  }

  /// 特典アイテム
  Widget _buildBenefitItem(BuildContext context, Map<String, dynamic> benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.check, color: Colors.green.shade600, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit['title'],
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (benefit['description'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    benefit['description'],
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 価格表示セクション
  Widget _buildPricingSection(BuildContext context, SubscriptionPlan plan) {
    final planInfo = Provider.of<SubscriptionIntegrationService>(
      context,
      listen: false,
    ).getPlanInfo(plan);
    final price = planInfo['price'] as int;
    final yearlyPrice = planInfo['yearlyPrice'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¥${price}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/月',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                '年額 ¥${yearlyPrice}（2ヶ月分お得）',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// アクションボタンセクション
  Widget _buildActionButtons(BuildContext context, SubscriptionPlan plan) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                onUpgradePressed ??
                () {
                  Navigator.of(context).pushNamed('/subscription');
                },
            icon: const Icon(Icons.star),
            label: Text('${_getPlanName(plan)}にアップグレード'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPlanColor(plan),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onDismiss,
          child: Text('後で', style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  // === ヘルパーメソッド ===

  /// 推奨プランを取得
  SubscriptionPlan _getRecommendedPlan(
    SubscriptionIntegrationService subscriptionService,
    FeatureAccessControl featureControl,
  ) {
    final currentPlan = subscriptionService.currentPlan;

    // 現在のプランに基づいて推奨プランを決定
    switch (currentPlan) {
      case SubscriptionPlan.free:
        return SubscriptionPlan.basic;
      case SubscriptionPlan.basic:
        return SubscriptionPlan.premium;
      case SubscriptionPlan.premium:
        return SubscriptionPlan.family;
      case SubscriptionPlan.family:
        return SubscriptionPlan.family; // 最高プラン
    }
  }

  /// 現在の使用状況を取得
  Map<String, dynamic> _getCurrentUsage(
    SubscriptionIntegrationService subscriptionService,
    FeatureAccessControl featureControl,
  ) {
    final usage = <String, dynamic>{};

    // リスト数使用状況（実際のリスト数は外部から渡す必要がある）
    if (subscriptionService.currentPlan == SubscriptionPlan.free) {
      usage['リスト数'] = '制限: ${subscriptionService.maxLists}個まで';
    }

    // 家族メンバー使用状況
    if (subscriptionService.hasFamilySharing) {
      usage['家族メンバー'] =
          '${subscriptionService.familyMembers.length}/${subscriptionService.maxFamilyMembers}';
    }

    return usage;
  }

  /// プラン特典を取得
  List<Map<String, dynamic>> _getPlanBenefits(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return [
          {'title': '無制限のタブ作成', 'description': 'タブ数の制限がなくなります'},
          {'title': '広告非表示', 'description': 'すべての広告が非表示になります'},
          {'title': '5種類のテーマ', 'description': 'カスタムテーマが利用可能になります'},
          {'title': 'カスタムフォント', 'description': 'フォントの変更が可能になります'},
        ];
      case SubscriptionPlan.premium:
        return [
          {'title': 'すべてのベーシック機能', 'description': null},
          {'title': '全テーマ利用可能', 'description': 'すべてのテーマが利用可能になります'},
          {'title': '家族共有（最大5人）', 'description': '家族メンバーとリストを共有できます'},
          {'title': '詳細分析機能', 'description': '購入履歴の詳細分析が利用可能になります'},
        ];
      case SubscriptionPlan.family:
        return [
          {'title': 'すべてのプレミアム機能', 'description': null},
          {'title': '家族共有（最大10人）', 'description': 'より多くの家族メンバーと共有できます'},
          {'title': '優先サポート', 'description': '優先的なカスタマーサポートが受けられます'},
        ];
      case SubscriptionPlan.free:
        return [];
    }
  }

  /// アップグレード理由を取得
  String _getUpgradeReason(UpgradeTrigger trigger) {
    switch (trigger) {
      case UpgradeTrigger.listLimit:
        return 'タブ数の制限に達しました';
      case UpgradeTrigger.itemLimit:
        return '商品アイテム数の制限に達しました';
      case UpgradeTrigger.familyLimit:
        return '家族メンバー数の制限に達しました';
      case UpgradeTrigger.featureLocked:
        return 'この機能を利用するにはアップグレードが必要です';
      case UpgradeTrigger.periodic:
        return 'より多くの機能をお楽しみください';
      case UpgradeTrigger.appLaunch:
        return 'アプリの機能を最大限活用しましょう';
    }
  }

  /// プラン名を取得
  String _getPlanName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'フリー';
      case SubscriptionPlan.basic:
        return 'ベーシック';
      case SubscriptionPlan.premium:
        return 'プレミアム';
      case SubscriptionPlan.family:
        return 'ファミリー';
    }
  }

  /// プランアイコンを取得
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

  /// プランカラーを取得
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
}

/// アップグレード促進バナーウィジェット
/// 画面上部に表示される軽量な促進バナー
class UpgradePromotionBanner extends StatelessWidget {
  final UpgradeTrigger trigger;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onDismiss;

  const UpgradePromotionBanner({
    super.key,
    required this.trigger,
    this.onUpgradePressed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final currentPlan = subscriptionService.currentPlan;
        final recommendedPlan = _getRecommendedPlan(currentPlan);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getPlanColor(recommendedPlan).withValues(alpha: 0.1),
                _getPlanColor(recommendedPlan).withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: _getPlanColor(recommendedPlan).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getPlanIcon(recommendedPlan),
                color: _getPlanColor(recommendedPlan),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getPlanName(recommendedPlan)}にアップグレード',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getPlanColor(recommendedPlan),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getUpgradeReason(trigger),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
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
                    color: _getPlanColor(recommendedPlan),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: Colors.grey[500], size: 16),
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

  SubscriptionPlan _getRecommendedPlan(SubscriptionPlan currentPlan) {
    switch (currentPlan) {
      case SubscriptionPlan.free:
        return SubscriptionPlan.basic;
      case SubscriptionPlan.basic:
        return SubscriptionPlan.premium;
      case SubscriptionPlan.premium:
        return SubscriptionPlan.family;
      case SubscriptionPlan.family:
        return SubscriptionPlan.family;
    }
  }

  String _getUpgradeReason(UpgradeTrigger trigger) {
    switch (trigger) {
      case UpgradeTrigger.listLimit:
        return 'タブ数の制限に達しました';
      case UpgradeTrigger.itemLimit:
        return '商品アイテム数の制限に達しました';
      case UpgradeTrigger.familyLimit:
        return '家族メンバー数の制限に達しました';
      case UpgradeTrigger.featureLocked:
        return 'この機能を利用するにはアップグレードが必要です';
      case UpgradeTrigger.periodic:
        return 'より多くの機能をお楽しみください';
      case UpgradeTrigger.appLaunch:
        return 'アプリの機能を最大限活用しましょう';
    }
  }

  String _getPlanName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'フリー';
      case SubscriptionPlan.basic:
        return 'ベーシック';
      case SubscriptionPlan.premium:
        return 'プレミアム';
      case SubscriptionPlan.family:
        return 'ファミリー';
    }
  }

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
}

/// アップグレード促進ダイアログ
/// モーダルダイアログとして表示される促進UI
class UpgradePromotionDialog extends StatelessWidget {
  final UpgradeTrigger trigger;
  final VoidCallback? onUpgradePressed;
  final Map<String, dynamic>? context;

  const UpgradePromotionDialog({
    super.key,
    required this.trigger,
    this.onUpgradePressed,
    this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UpgradePromotionCard(
              trigger: trigger,
              onUpgradePressed: onUpgradePressed,
              onDismiss: () => Navigator.of(context).pop(),
              context: this.context,
            ),
          ],
        ),
      ),
    );
  }
}

/// アップグレード促進オーバーレイ
/// 機能の上に表示される促進オーバーレイ
class UpgradePromotionOverlay extends StatelessWidget {
  final Widget child;
  final UpgradeTrigger trigger;
  final VoidCallback? onUpgradePressed;

  const UpgradePromotionOverlay({
    super.key,
    required this.child,
    required this.trigger,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final shouldShow = _shouldShowPromotion(
          subscriptionService,
          featureControl,
        );

        if (!shouldShow) {
          return child;
        }

        return Stack(
          children: [
            // 元のウィジェット（ぼかし効果付き）
            Opacity(opacity: 0.3, child: child),

            // 促進オーバーレイ
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
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
                          Icons.star,
                          color: Colors.orange.shade600,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'プレミアム機能',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getUpgradeMessage(trigger),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '後で',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  onUpgradePressed ??
                                  () {
                                    Navigator.of(context).pop();
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/subscription');
                                  },
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
                              child: const Text('アップグレード'),
                            ),
                          ],
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

  bool _shouldShowPromotion(
    SubscriptionIntegrationService subscriptionService,
    FeatureAccessControl featureControl,
  ) {
    // 制限に達しているか、機能がロックされている場合に表示
    switch (trigger) {
      case UpgradeTrigger.listLimit:
        // リスト数制限の判定は外部から渡す必要がある
        return subscriptionService.currentPlan == SubscriptionPlan.free;
      case UpgradeTrigger.itemLimit:
        // 商品アイテム数制限の判定は外部から渡す必要がある
        return subscriptionService.currentPlan == SubscriptionPlan.free;
      case UpgradeTrigger.familyLimit:
        return subscriptionService.familyMembers.length >=
            subscriptionService.maxFamilyMembers;
      case UpgradeTrigger.featureLocked:
        return true; // 常に表示
      case UpgradeTrigger.periodic:
        return subscriptionService.currentPlan == SubscriptionPlan.free;
      case UpgradeTrigger.appLaunch:
        return subscriptionService.currentPlan == SubscriptionPlan.free;
    }
  }

  String _getUpgradeMessage(UpgradeTrigger trigger) {
    switch (trigger) {
      case UpgradeTrigger.listLimit:
        return 'リスト数の制限に達しました。アップグレードで無制限にリストを作成できます。';
      case UpgradeTrigger.itemLimit:
        return '商品アイテム数の制限に達しました。アップグレードでより多くの商品を追加できます。';
      case UpgradeTrigger.familyLimit:
        return '家族メンバー数の制限に達しました。アップグレードでより多くのメンバーを追加できます。';
      case UpgradeTrigger.featureLocked:
        return 'この機能を利用するにはプレミアムプランへのアップグレードが必要です。';
      case UpgradeTrigger.periodic:
        return 'より多くの機能をお楽しみください。プレミアムプランにアップグレードしましょう。';
      case UpgradeTrigger.appLaunch:
        return 'アプリの機能を最大限活用しましょう。プレミアムプランにアップグレードしてください。';
    }
  }
}

/// アップグレード促進トリガー
enum UpgradeTrigger {
  listLimit, // リスト数制限
  itemLimit, // 商品アイテム数制限
  familyLimit, // 家族メンバー数制限
  featureLocked, // 機能ロック
  periodic, // 定期的な促進
  appLaunch, // アプリ起動時
}

/// アップグレード促進マネージャー
/// アプリ全体でのアップグレード促進を管理
class UpgradePromotionManager {
  static final UpgradePromotionManager _instance =
      UpgradePromotionManager._internal();
  factory UpgradePromotionManager() => _instance;
  UpgradePromotionManager._internal();

  /// アップグレード促進を表示すべきかチェック
  bool shouldShowPromotion(
    SubscriptionIntegrationService subscriptionService,
    FeatureAccessControl featureControl,
    UpgradeTrigger trigger,
  ) {
    final currentPlan = subscriptionService.currentPlan;

    // 最高プランの場合は表示しない
    if (currentPlan == SubscriptionPlan.family) {
      return false;
    }

    // トリガーに基づいて表示判定
    switch (trigger) {
      case UpgradeTrigger.listLimit:
        // リスト数制限の判定は外部から渡す必要がある
        return currentPlan == SubscriptionPlan.free;
      case UpgradeTrigger.itemLimit:
        // 商品アイテム数制限の判定は外部から渡す必要がある
        return currentPlan == SubscriptionPlan.free;
      case UpgradeTrigger.familyLimit:
        return subscriptionService.familyMembers.length >=
            subscriptionService.maxFamilyMembers;
      case UpgradeTrigger.featureLocked:
        return true;
      case UpgradeTrigger.periodic:
        // 定期的な促進はフリープランのみ
        return currentPlan == SubscriptionPlan.free;
      case UpgradeTrigger.appLaunch:
        // アプリ起動時の促進はフリープランのみ
        return currentPlan == SubscriptionPlan.free;
    }
  }

  /// 推奨プランを取得
  SubscriptionPlan getRecommendedPlan(SubscriptionPlan currentPlan) {
    switch (currentPlan) {
      case SubscriptionPlan.free:
        return SubscriptionPlan.basic;
      case SubscriptionPlan.basic:
        return SubscriptionPlan.premium;
      case SubscriptionPlan.premium:
        return SubscriptionPlan.family;
      case SubscriptionPlan.family:
        return SubscriptionPlan.family;
    }
  }
}

/// アプリ起動時アップグレード促進ウィジェット
/// アプリ起動時に表示される促進UI
class AppLaunchUpgradePromotion extends StatefulWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const AppLaunchUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  State<AppLaunchUpgradePromotion> createState() =>
      _AppLaunchUpgradePromotionState();
}

class _AppLaunchUpgradePromotionState extends State<AppLaunchUpgradePromotion> {
  bool _hasShownPromotion = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final shouldShow =
            !_hasShownPromotion &&
            UpgradePromotionManager().shouldShowPromotion(
              subscriptionService,
              featureControl,
              UpgradeTrigger.appLaunch,
            );

        if (!shouldShow) {
          return widget.child;
        }

        // 一度表示したらフラグを立てる
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _hasShownPromotion = true);
          }
        });

        return Stack(
          children: [
            widget.child,
            // 促進ダイアログを表示
            FutureBuilder(
              future: Future.delayed(const Duration(seconds: 2)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => UpgradePromotionDialog(
                          trigger: UpgradeTrigger.appLaunch,
                          onUpgradePressed: widget.onUpgradePressed,
                        ),
                      );
                    }
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }
}

/// リスト作成時アップグレード促進ウィジェット
/// リスト作成時に制限に達した場合の促進UI
class ListCreationUpgradePromotion extends StatelessWidget {
  final int currentListCount;
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const ListCreationUpgradePromotion({
    super.key,
    required this.currentListCount,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final canCreate = subscriptionService.canCreateList(currentListCount);

        if (canCreate) {
          return child;
        }

        return UpgradePromotionOverlay(
          child: child,
          trigger: UpgradeTrigger.listLimit,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// 家族共有時アップグレード促進ウィジェット
/// 家族共有機能使用時の促進UI
class FamilySharingUpgradePromotion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const FamilySharingUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final canUse = featureControl.canUseFamilySharing();
        final isLimitReached =
            subscriptionService.familyMembers.length >=
            subscriptionService.maxFamilyMembers;

        if (canUse && !isLimitReached) {
          return child;
        }

        return UpgradePromotionOverlay(
          child: child,
          trigger: isLimitReached
              ? UpgradeTrigger.familyLimit
              : UpgradeTrigger.featureLocked,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// テーマ設定時アップグレード促進ウィジェット
/// テーマ設定時の促進UI
class ThemeCustomizationUpgradePromotion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const ThemeCustomizationUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final canCustomize = featureControl.canCustomizeTheme();

        if (canCustomize) {
          return child;
        }

        return UpgradePromotionOverlay(
          child: child,
          trigger: UpgradeTrigger.featureLocked,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// フォント設定時アップグレード促進ウィジェット
/// フォント設定時の促進UI
class FontCustomizationUpgradePromotion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const FontCustomizationUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final canCustomize = featureControl.canCustomizeFont();

        if (canCustomize) {
          return child;
        }

        return UpgradePromotionOverlay(
          child: child,
          trigger: UpgradeTrigger.featureLocked,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// 分析機能時アップグレード促進ウィジェット
/// 分析機能使用時の促進UI
class AnalyticsUpgradePromotion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const AnalyticsUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final canUse = featureControl.canUseAnalytics();

        if (canUse) {
          return child;
        }

        return UpgradePromotionOverlay(
          child: child,
          trigger: UpgradeTrigger.featureLocked,
          onUpgradePressed: onUpgradePressed,
        );
      },
    );
  }
}

/// 定期的アップグレード促進ウィジェット
/// 定期的に表示される促進UI
class PeriodicUpgradePromotion extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final VoidCallback? onUpgradePressed;

  const PeriodicUpgradePromotion({
    super.key,
    required this.child,
    this.interval = const Duration(hours: 24),
    this.onUpgradePressed,
  });

  @override
  State<PeriodicUpgradePromotion> createState() =>
      _PeriodicUpgradePromotionState();
}

class _PeriodicUpgradePromotionState extends State<PeriodicUpgradePromotion> {
  DateTime? _lastShown;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final now = DateTime.now();
        final shouldShow =
            _lastShown == null ||
            now.difference(_lastShown!) >= widget.interval;

        if (!shouldShow) {
          return widget.child;
        }

        // 促進バナーを表示
        return Column(
          children: [
            if (UpgradePromotionManager().shouldShowPromotion(
              subscriptionService,
              featureControl,
              UpgradeTrigger.periodic,
            ))
              UpgradePromotionBanner(
                trigger: UpgradeTrigger.periodic,
                onUpgradePressed: () {
                  setState(() => _lastShown = now);
                  widget.onUpgradePressed?.call();
                },
                onDismiss: () => setState(() => _lastShown = now),
              ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}

/// 設定画面アップグレード促進ウィジェット
/// 設定画面での促進UI
class SettingsUpgradePromotion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const SettingsUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final currentPlan = subscriptionService.currentPlan;

        // 最高プランの場合は促進を表示しない
        if (currentPlan == SubscriptionPlan.family) {
          return child;
        }

        return Column(
          children: [
            // 現在のプラン情報とアップグレード促進
            Container(
              margin: const EdgeInsets.all(16),
              child: UpgradePromotionCard(
                trigger: UpgradeTrigger.periodic,
                onUpgradePressed: onUpgradePressed,
                onDismiss: null, // 設定画面では閉じるボタンを表示しない
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// メニュー画面アップグレード促進ウィジェット
/// メニュー画面での促進UI
class MenuUpgradePromotion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradePressed;

  const MenuUpgradePromotion({
    super.key,
    required this.child,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionIntegrationService, FeatureAccessControl>(
      builder: (context, subscriptionService, featureControl, _) {
        final currentPlan = subscriptionService.currentPlan;

        // 最高プランの場合は促進を表示しない
        if (currentPlan == SubscriptionPlan.family) {
          return child;
        }

        return Column(
          children: [
            // 軽量な促進バナー
            if (UpgradePromotionManager().shouldShowPromotion(
              subscriptionService,
              featureControl,
              UpgradeTrigger.periodic,
            ))
              UpgradePromotionBanner(
                trigger: UpgradeTrigger.periodic,
                onUpgradePressed: onUpgradePressed,
                onDismiss: null, // メニュー画面では閉じるボタンを表示しない
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
