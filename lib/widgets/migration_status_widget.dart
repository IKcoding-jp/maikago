import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../screens/subscription_screen.dart';

/// 移行状態表示ウィジェット
/// ユーザーの移行状態を表示し、適切な案内を提供
class MigrationStatusWidget extends StatelessWidget {
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onMigrationComplete;

  const MigrationStatusWidget({
    super.key,
    this.onUpgradePressed,
    this.onMigrationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionIntegrationService>(
      builder: (context, service, _) {
        final migrationStatus = service.getMigrationStatus();
        final isLegacyDonor = migrationStatus['isLegacyDonor'] as bool;
        final shouldRecommend =
            migrationStatus['shouldRecommendSubscription'] as bool;
        final hasSubscription = migrationStatus['hasSubscription'] as bool;

        // サブスクリプションがある場合は表示しない
        if (hasSubscription) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  context,
                  isLegacyDonor,
                  migrationStatus['isNewUser'] as bool,
                ),
                const SizedBox(height: 12),
                _buildStatusInfo(context, migrationStatus),
                const SizedBox(height: 16),
                _buildActionButtons(
                  context,
                  service,
                  isLegacyDonor,
                  shouldRecommend,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ヘッダーセクション
  Widget _buildHeader(
    BuildContext context,
    bool isLegacyDonor,
    bool isNewUser,
  ) {
    IconData icon;
    Color color;
    String title;

    if (isNewUser) {
      icon = Icons.person_add;
      color = Colors.blue;
      title = '新規ユーザー';
    } else {
      icon = Icons.info;
      color = Colors.orange;
      title = '移行案内';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                _getSubtitle(isLegacyDonor, isNewUser),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// サブタイトルを取得
  String _getSubtitle(bool isLegacyDonor, bool isNewUser) {
    if (isLegacyDonor) {
      return '既存の寄付特典が引き続き有効です';
    } else if (isNewUser) {
      return 'サブスクリプションでより多くの機能をお楽しみください';
    } else {
      return 'サブスクリプションに移行して特典を継続しましょう';
    }
  }

  /// ステータス情報セクション
  Widget _buildStatusInfo(BuildContext context, Map<String, dynamic> status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '現在の状態',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStatusRow('プラン', status['currentPlan']),
          _buildStatusRow('寄付特典', status['hasDonationBenefits'] ? '有効' : 'なし'),
          _buildStatusRow('サブスクリプション', status['hasSubscription'] ? '有効' : 'なし'),
          _buildStatusRow('移行完了', status['migrationCompleted'] ? '完了' : '未完了'),
        ],
      ),
    );
  }

  /// ステータス行を構築
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// アクションボタンセクション
  Widget _buildActionButtons(
    BuildContext context,
    SubscriptionIntegrationService service,
    bool isLegacyDonor,
    bool shouldRecommend,
  ) {
    if (shouldRecommend) {
      // 新規ユーザーまたは移行推奨：アップグレードボタン
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              onUpgradePressed ??
              () {
                Navigator.of(context).pushNamed('/subscription');
              },
          icon: const Icon(Icons.star),
          label: const Text('サブスクリプションにアップグレード'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      // その他：情報表示のみ
      return const SizedBox.shrink();
    }
  }
}

/// 移行状態バナー
/// 軽量な移行状態表示
class MigrationStatusBanner extends StatelessWidget {
  final VoidCallback? onUpgradePressed;

  const MigrationStatusBanner({super.key, this.onUpgradePressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionIntegrationService>(
      builder: (context, service, _) {
        final migrationStatus = service.getMigrationStatus();
        final isLegacyDonor = migrationStatus['isLegacyDonor'] as bool;
        final shouldRecommend =
            migrationStatus['shouldRecommendSubscription'] as bool;
        final hasSubscription = migrationStatus['hasSubscription'] as bool;

        // サブスクリプションがある場合は表示しない
        if (hasSubscription) {
          return const SizedBox.shrink();
        }

        // 移行推奨の場合のみ表示
        if (!shouldRecommend) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'サブスクリプション推奨',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      service.getMigrationRecommendationMessage(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (shouldRecommend)
                TextButton(
                  onPressed:
                      onUpgradePressed ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
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
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 移行完了ダイアログ
/// 移行完了時の確認ダイアログ
class MigrationCompleteDialog extends StatelessWidget {
  final VoidCallback? onConfirm;

  const MigrationCompleteDialog({super.key, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('移行完了'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('移行が完了しました。'),
          SizedBox(height: 8),
          Text('• サブスクリプションへの移行も可能です'),
          Text('• いつでも設定から変更できます'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: const Text('サブスクリプションを見る'),
        ),
      ],
    );
  }
}
