// デバッグ情報表示ウィジェット
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/debug_service.dart';
import '../services/subscription_service.dart';
import '../models/subscription_plan.dart';
import '../config.dart';

/// デバッグ情報表示ウィジェット
/// パフォーマンス、メモリ、エラー、使用状況の統計を表示
class DebugInfoWidget extends StatefulWidget {
  final bool showDetailedInfo;

  const DebugInfoWidget({super.key, this.showDetailedInfo = false});

  @override
  State<DebugInfoWidget> createState() => _DebugInfoWidgetState();
}

class _DebugInfoWidgetState extends State<DebugInfoWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!enableDebugMode) {
      return const SizedBox.shrink();
    }

    return Consumer<DebugService>(
      builder: (context, debugService, _) {
        final stats = debugService.getOverallStats();

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('デバッグ情報'),
                const Spacer(),
                _buildStatusIndicator(stats),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceSection(stats['performance']),
                    const SizedBox(height: 16),
                    _buildMemorySection(stats['memory']),
                    const SizedBox(height: 16),
                    _buildErrorSection(stats['errors']),
                    const SizedBox(height: 16),
                    _buildUsageSection(stats['usage']),
                    const SizedBox(height: 16),
                    _buildLogSection(stats['logs']),
                    const SizedBox(height: 16),
                    _buildSubscriptionDebugSection(),
                    const SizedBox(height: 16),
                    _buildActionButtons(debugService),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ステータスインジケーターを構築
  Widget _buildStatusIndicator(Map<String, dynamic> stats) {
    final errorCount = stats['errors']['total'] ?? 0;
    final performanceIssues = _countPerformanceIssues(stats['performance']);

    if (errorCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$errorCount エラー',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else if (performanceIssues > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$performanceIssues 警告',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '正常',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }
  }

  /// パフォーマンス問題の数をカウント
  int _countPerformanceIssues(Map<String, dynamic> performance) {
    int issues = 0;
    performance.forEach((key, value) {
      if (value is Map && value['avg'] != null) {
        if (value['avg'] > 100) issues++;
      }
    });
    return issues;
  }

  /// パフォーマンスセクションを構築
  Widget _buildPerformanceSection(Map<String, dynamic> performance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'パフォーマンス統計',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (performance.isEmpty)
          const Text('データなし', style: TextStyle(color: Colors.grey))
        else
          ...performance.entries.map(
            (entry) => _buildPerformanceItem(entry.key, entry.value),
          ),
      ],
    );
  }

  /// パフォーマンス項目を構築
  Widget _buildPerformanceItem(String name, Map<String, dynamic> stats) {
    final avg = stats['avg']?.toDouble() ?? 0.0;
    final color = avg > 100
        ? Colors.red
        : avg > 50
        ? Colors.orange
        : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(name, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${avg.round()}ms (${stats['count']}回)',
              style: TextStyle(color: color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// メモリセクションを構築
  Widget _buildMemorySection(Map<String, dynamic> memory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'メモリ使用量',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (memory.isEmpty)
          const Text('データなし', style: TextStyle(color: Colors.grey))
        else
          Column(
            children: [
              _buildMemoryItem('現在', memory['current']),
              _buildMemoryItem('平均', memory['average']),
              _buildMemoryItem('ピーク', memory['peak']),
            ],
          ),
      ],
    );
  }

  /// メモリ項目を構築
  Widget _buildMemoryItem(String label, Map<String, dynamic> data) {
    final used = data['used']?.toDouble() ?? 0.0;
    final total = data['total']?.toDouble() ?? 0.0;
    final percentage = data['percentage']?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${used.round()}MB / ${total.round()}MB (${percentage.round()}%)',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// エラーセクションを構築
  Widget _buildErrorSection(Map<String, dynamic> errors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'エラー統計',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (errors.isEmpty)
          const Text('エラーなし', style: TextStyle(color: Colors.green))
        else
          Column(
            children: [
              _buildErrorItem('総数', errors['total']),
              _buildErrorItem('過去24時間', errors['last24h']),
              _buildErrorItem('過去7日間', errors['last7d']),
            ],
          ),
      ],
    );
  }

  /// エラー項目を構築
  Widget _buildErrorItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$count件',
              style: TextStyle(
                color: count > 0 ? Colors.red : Colors.green,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 使用状況セクションを構築
  Widget _buildUsageSection(Map<String, dynamic> usage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '使用状況',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (usage.isEmpty)
          const Text('データなし', style: TextStyle(color: Colors.grey))
        else
          Column(
            children: [
              Text('総機能数: ${usage['totalFeatures']}'),
              const SizedBox(height: 8),
              if (usage['mostUsed'] != null) ...[
                const Text(
                  '最も使用された機能:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ...(usage['mostUsed'] as List)
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Text('${item['feature']}: ${item['count']}回'),
                      ),
                    ),
              ],
            ],
          ),
      ],
    );
  }

  /// ログセクションを構築
  Widget _buildLogSection(Map<String, dynamic> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ログ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text('総ログ数: ${logs['total']}'),
        if (widget.showDetailedInfo && logs['recent'] != null) ...[
          const SizedBox(height: 8),
          const Text('最近のログ:', style: TextStyle(fontWeight: FontWeight.w500)),
          ...(logs['recent'] as List)
              .take(5)
              .map(
                (log) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Text(
                    log.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  /// サブスクリプションデバッグセクションを構築
  Widget _buildSubscriptionDebugSection() {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'サブスクリプションデバッグ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // 現在のプラン情報
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '現在のプラン: ${subscriptionService.currentPlan?.name ?? '不明'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '有効: ${subscriptionService.isSubscriptionActive ? 'はい' : 'いいえ'}',
                    style: TextStyle(
                      color: subscriptionService.isSubscriptionActive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  if (subscriptionService.subscriptionExpiryDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '有効期限: ${subscriptionService.subscriptionExpiryDate!.toString().substring(0, 19)}',
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'ファミリーメンバー: ${subscriptionService.familyMembers.length}人',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // プラン変更ボタン
            const Text(
              'プラン変更（デバッグ用）:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SubscriptionPlan.availablePlans.map((plan) {
                final isCurrentPlan =
                    subscriptionService.currentPlan?.type == plan.type;
                return ElevatedButton(
                  onPressed: () => _changePlan(subscriptionService, plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentPlan ? Colors.green : null,
                    foregroundColor: isCurrentPlan ? Colors.white : null,
                  ),
                  child: Text(plan.name.replaceAll('まいカゴ', '')),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // 追加のデバッグボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resetToFreePlan(subscriptionService),
                    child: const Text('フリープランにリセット'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _refreshSubscriptionData(subscriptionService),
                    child: const Text('データ再読み込み'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// プランを変更
  Future<void> _changePlan(
    SubscriptionService subscriptionService,
    SubscriptionPlan plan,
  ) async {
    try {
      // 有効期限を設定（1ヶ月後）
      final expiryDate = DateTime.now().add(const Duration(days: 30));

      final success = await subscriptionService.purchasePlan(
        plan,
        expiryDate: expiryDate,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${plan.name}に変更しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('プラン変更に失敗しました: ${subscriptionService.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// フリープランにリセット
  Future<void> _resetToFreePlan(SubscriptionService subscriptionService) async {
    try {
      final success = await subscriptionService.setFreePlan();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フリープランにリセットしました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('リセットに失敗しました: ${subscriptionService.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// サブスクリプションデータを再読み込み
  Future<void> _refreshSubscriptionData(
    SubscriptionService subscriptionService,
  ) async {
    try {
      await subscriptionService.loadFromFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('サブスクリプションデータを再読み込みしました'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// アクションボタンを構築
  Widget _buildActionButtons(DebugService debugService) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              debugService.printDebugInfo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('デバッグ情報をコンソールに出力しました')),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('コンソール出力'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              debugService.clearLogs();
              setState(() {});
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('ログをクリアしました')));
            },
            icon: const Icon(Icons.clear),
            label: const Text('ログクリア'),
          ),
        ),
      ],
    );
  }
}

/// 簡易デバッグ情報バナー
class DebugInfoBanner extends StatelessWidget {
  const DebugInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!enableDebugMode) {
      return const SizedBox.shrink();
    }

    return Consumer<DebugService>(
      builder: (context, debugService, _) {
        final stats = debugService.getOverallStats();
        final errorCount = stats['errors']['total'] ?? 0;
        final performanceIssues = _countPerformanceIssues(stats['performance']);

        if (errorCount == 0 && performanceIssues == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: errorCount > 0 ? Colors.red.shade100 : Colors.orange.shade100,
          child: Row(
            children: [
              Icon(
                errorCount > 0 ? Icons.error : Icons.warning,
                color: errorCount > 0 ? Colors.red : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorCount > 0
                      ? '$errorCount件のエラーが発生しています'
                      : '$performanceIssues件のパフォーマンス警告があります',
                  style: TextStyle(
                    color: errorCount > 0 ? Colors.red : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('デバッグ情報'),
                      content: const SingleChildScrollView(
                        child: DebugInfoWidget(showDetailedInfo: true),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('詳細', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// パフォーマンス問題の数をカウント
  static int _countPerformanceIssues(Map<String, dynamic> performance) {
    int issues = 0;
    performance.forEach((key, value) {
      if (value is Map && value['avg'] != null) {
        if (value['avg'] > 100) issues++;
      }
    });
    return issues;
  }
}
