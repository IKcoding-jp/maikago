import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../models/subscription_plan.dart';

/// サブスクリプション有効化機能をテストするウィジェット
class SubscriptionActivationWidget extends StatefulWidget {
  const SubscriptionActivationWidget({super.key});

  @override
  State<SubscriptionActivationWidget> createState() => _SubscriptionActivationWidgetState();
}

class _SubscriptionActivationWidgetState extends State<SubscriptionActivationWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionIntegrationService>(
      builder: (context, integrationService, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔔 サブスクリプション有効化テスト',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 現在のプラン表示
                Row(
                  children: [
                    const Text('現在のプラン: '),
                    Text(
                      integrationService.currentPlanName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // サブスクリプション状態
                Row(
                  children: [
                    const Text('状態: '),
                    Text(
                      integrationService.isSubscriptionActive ? '有効' : '無効',
                      style: TextStyle(
                        color: integrationService.isSubscriptionActive 
                            ? Colors.green 
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 簡易機能テスト
                const Text('機能テスト:'),
                const SizedBox(height: 8),
                _buildFeatureCheck('広告非表示', integrationService.shouldHideAds),
                _buildFeatureCheck('テーマ変更', integrationService.canChangeTheme),
                _buildFeatureCheck('フォント変更', integrationService.canChangeFont),
                
                const SizedBox(height: 16),
                const Text(
                  '詳細なテスト機能は今後実装予定',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCheck(String feature, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}