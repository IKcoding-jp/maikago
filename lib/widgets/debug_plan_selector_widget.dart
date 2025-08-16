import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/donation_manager.dart';

/// デバッグ用のプラン選択ウィジェット
/// 開発時のみ表示され、サブスクリプションプランをテストできる
class DebugPlanSelectorWidget extends StatefulWidget {
  const DebugPlanSelectorWidget({super.key});

  @override
  State<DebugPlanSelectorWidget> createState() =>
      _DebugPlanSelectorWidgetState();
}

class _DebugPlanSelectorWidgetState extends State<DebugPlanSelectorWidget> {
  String? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    // 本番環境では表示しない
    const bool isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    if (!isDebugMode) {
      return const SizedBox.shrink();
    }

    return Consumer<DonationManager>(
      builder: (context, donationManager, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: const Text(
              'デバッグプラン選択',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            subtitle: const Text(
              '開発者向けプランテスト',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            leading: const Icon(Icons.workspace_premium, color: Colors.orange),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在のプラン: ${_getCurrentPlanName(donationManager)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '利用可能機能:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureStatus(
                      'テーマ変更',
                      donationManager.canChangeTheme,
                    ),
                    _buildFeatureStatus(
                      'フォント変更',
                      donationManager.canChangeFont,
                    ),
                    _buildFeatureStatus('特典有効', donationManager.hasBenefits),
                    _buildFeatureStatus('広告非表示', donationManager.shouldHideAds),
                    const SizedBox(height: 16),
                    const Text(
                      'テスト用プラン選択:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPlanSelector(donationManager),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _resetToFreePlan(donationManager),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('無料プランにリセット'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setPremiumPlan(donationManager),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('プレミアムプラン'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureStatus(String feature, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              fontSize: 12,
              color: isAvailable ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(DonationManager donationManager) {
    return DropdownButtonFormField<String>(
      value: _selectedPlan,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'プランを選択',
      ),
      items: [
        const DropdownMenuItem(value: 'free', child: Text('無料プラン')),
        const DropdownMenuItem(value: 'premium', child: Text('プレミアムプラン')),
        const DropdownMenuItem(value: 'family', child: Text('ファミリープラン')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPlan = value;
        });
        if (value != null) {
          _setPlan(donationManager, value);
        }
      },
    );
  }

  String _getCurrentPlanName(DonationManager donationManager) {
    if (donationManager.hasBenefits) {
      return 'プレミアムプラン';
    }
    return '無料プラン';
  }

  void _setPlan(DonationManager donationManager, String planType) {
    switch (planType) {
      case 'free':
        _resetToFreePlan(donationManager);
        break;
      case 'premium':
        _setPremiumPlan(donationManager);
        break;
      case 'family':
        _setFamilyPlan(donationManager);
        break;
    }
  }

  void _resetToFreePlan(DonationManager donationManager) async {
    // 無料プランにリセット
    await donationManager.resetDonationStatus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('無料プランにリセットしました')));
  }

  void _setPremiumPlan(DonationManager donationManager) async {
    // プレミアムプランを設定
    await donationManager.enableDonationBenefits();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('プレミアムプランを設定しました')));
  }

  void _setFamilyPlan(DonationManager donationManager) async {
    // ファミリープランを設定（プレミアムプランと同じ）
    await donationManager.enableDonationBenefits();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ファミリープランを設定しました')));
  }
}
