import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/subscription_manager.dart';

/// デバッグ用のプラン変更ウィジェット
/// リリースビルドでは非表示
class DebugPlanSelectorWidget extends StatefulWidget {
  const DebugPlanSelectorWidget({super.key});

  @override
  State<DebugPlanSelectorWidget> createState() => _DebugPlanSelectorWidgetState();
}

class _DebugPlanSelectorWidgetState extends State<DebugPlanSelectorWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // リリースビルドでは表示しない
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    return Consumer<SubscriptionManager>(
      builder: (context, subscriptionManager, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'デバッグ: プラン変更',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '現在のプラン: ${subscriptionManager.currentPlanName}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SubscriptionPlan.values.map((plan) {
                      final isCurrentPlan =
                          subscriptionManager.currentPlan == plan;
                      return ElevatedButton(
                        onPressed: () => _changePlan(context, plan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentPlan
                              ? Colors.orange.shade700
                              : Colors.orange.shade100,
                          foregroundColor: isCurrentPlan
                              ? Colors.white
                              : Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _getPlanDisplayName(plan),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _toggleSubscription(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade700),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            subscriptionManager.isActive
                                ? 'サブスクリプション無効化'
                                : 'サブスクリプション有効化',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _resetTrial(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade700),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'トライアルリセット',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPlanDisplayName(SubscriptionPlan plan) {
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

  Future<void> _changePlan(BuildContext context, SubscriptionPlan plan) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionManager = Provider.of<SubscriptionManager>(
        context,
        listen: false,
      );

      // デバッグ用のプラン変更
      subscriptionManager.setDebugPlan(plan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プランを${_getPlanDisplayName(plan)}に変更しました'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSubscription(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionManager = Provider.of<SubscriptionManager>(
        context,
        listen: false,
      );

      // デバッグ用のサブスクリプション状態切り替え
      subscriptionManager.setDebugSubscriptionActive(
        !subscriptionManager.isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              subscriptionManager.isActive
                  ? 'サブスクリプションを有効化しました'
                  : 'サブスクリプションを無効化しました',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetTrial(BuildContext context) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionManager = Provider.of<SubscriptionManager>(
        context,
        listen: false,
      );

      // デバッグ用のトライアルリセット
      subscriptionManager.resetDebugTrial();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('トライアルをリセットしました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
