import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../services/subscription_manager.dart';
import '../services/payment_service.dart'; // Added
import '../config.dart';
import '../config/subscription_ids.dart';

/// サブスクリプション管理画面
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  final TextEditingController _familyMemberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
  }

  @override
  void dispose() {
    _familyMemberController.dispose();
    super.dispose();
  }

  /// PaymentServiceの初期化
  Future<void> _initializePaymentService() async {
    try {
      final paymentService = PaymentService();
      if (!paymentService.isInitialized) {
        await paymentService.initialize();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('決済サービスの初期化に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスクリプション'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<SubscriptionIntegrationService, PaymentService>(
        builder: (context, subscriptionService, paymentService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 現在のプラン情報
                _buildCurrentPlanCard(subscriptionService),
                const SizedBox(height: 24),

                // プラン選択
                _buildPlanSelection(subscriptionService, paymentService),
                const SizedBox(height: 24),

                // 家族共有（該当プランの場合）
                if (subscriptionService.hasFamilySharing) ...[
                  _buildFamilySharingSection(subscriptionService),
                  const SizedBox(height: 24),
                ],

                // 復元ボタン
                _buildRestoreButton(subscriptionService, paymentService),
                const SizedBox(height: 24),

                // 決済状態表示
                _buildPaymentStatusSection(paymentService),
                const SizedBox(height: 24),

                // デバッグ情報（開発モードのみ）
                if (enableDebugMode) ...[
                  _buildDebugSection(subscriptionService),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// 現在のプラン情報カード
  Widget _buildCurrentPlanCard(SubscriptionIntegrationService service) {
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            const SizedBox(height: 16),
            _buildFeatureList(service),
            if (service.isSubscriptionActive &&
                service.subscriptionExpiry != null) ...[
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

  /// プラン選択セクション
  Widget _buildPlanSelection(
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) {
    final allPlans = service.getAllPlans();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プランを選択',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...allPlans.entries.map((entry) {
          final plan = entry.key;
          final planInfo = entry.value;
          final isCurrentPlan = plan == service.currentPlan;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isCurrentPlan ? 4 : 2,
            color: isCurrentPlan
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: InkWell(
              onTap: () => _selectPlan(plan, service, paymentService),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getPlanIcon(plan),
                          color: _getPlanColor(plan),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                planInfo['name'],
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                planInfo['price'] == 0
                                    ? '無料'
                                    : '月額 ¥${planInfo['price']}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentPlan)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPlanFeatures(planInfo),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 家族共有セクション
  Widget _buildFamilySharingSection(SubscriptionIntegrationService service) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.family_restroom, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '家族共有',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '家族メンバー: ${service.familyMembers.length}/${service.maxFamilyMembers}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // 家族メンバーリスト
            if (service.familyMembers.isNotEmpty) ...[
              ...service.familyMembers.map(
                (email) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeFamilyMember(email, service),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 家族メンバー追加
            if (service.canAddFamilyMember()) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _familyMemberController,
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        hintText: 'family@example.com',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _addFamilyMember(service),
                    child: const Text('追加'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '家族メンバーの上限に達しています',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 復元ボタン
  Widget _buildRestoreButton(
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading || service.isRestoring
            ? null
            : () => _restorePurchases(service, paymentService),
        icon: service.isRestoring
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore),
        label: Text(service.isRestoring ? '復元中...' : '購入履歴を復元'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// デバッグセクション
  Widget _buildDebugSection(SubscriptionIntegrationService service) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'デバッグ情報',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('特典有効: ${service.hasBenefits}'),
            Text('広告非表示: ${service.shouldHideAds}'),
            Text('テーマ変更可能: ${service.canChangeTheme}'),
            Text('フォント変更可能: ${service.canChangeFont}'),
            Text('最大リスト数: ${service.maxLists}'),
            Text('各リスト内の最大商品アイテム数: ${service.maxItemsPerList}'),
            Text('利用可能テーマ数: ${service.availableThemes}'),
            Text('利用可能フォント数: ${service.availableFonts}'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _resetSubscription(service),
                  child: const Text('リセット'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _testSubscription(service),
                  child: const Text('テスト'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// プラン機能リスト
  Widget _buildFeatureList(SubscriptionIntegrationService service) {
    final features = <String>[];

    if (service.maxLists == -1) {
      features.add('無制限のリスト作成');
    } else {
      features.add('最大${service.maxLists}個のリスト');
    }

    if (service.maxItemsPerList == -1) {
      features.add('無制限の商品アイテム追加');
    } else {
      features.add('各リスト内最大${service.maxItemsPerList}個の商品');
    }

    if (!service.shouldShowAds) {
      features.add('広告非表示');
    }

    if (service.availableThemes == -1) {
      features.add('全テーマ利用可能');
    } else if (service.availableThemes > 1) {
      features.add('${service.availableThemes}種類のテーマ');
    }

    if (service.availableFonts == -1) {
      features.add('全フォント利用可能');
    } else if (service.availableFonts > 1) {
      features.add('${service.availableFonts}種類のフォント');
    }

    if (service.hasFamilySharing) {
      features.add('家族共有（最大${service.maxFamilyMembers}人）');
    }

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// プラン機能表示
  Widget _buildPlanFeatures(Map<String, dynamic> planInfo) {
    final features = <String>[];

    if (planInfo['maxLists'] == -1) {
      features.add('無制限のリスト作成');
    } else {
      features.add('最大${planInfo['maxLists']}個のリスト');
    }

    if (planInfo['maxItemsPerList'] == -1) {
      features.add('無制限の商品アイテム追加');
    } else {
      features.add('各リスト内最大${planInfo['maxItemsPerList']}個の商品');
    }

    if (!planInfo['showAds']) {
      features.add('広告非表示');
    }

    if (planInfo['themes'] == -1) {
      features.add('全テーマ利用可能');
    } else if (planInfo['themes'] > 1) {
      features.add('${planInfo['themes']}種類のテーマ');
    }

    if (planInfo['fonts'] == -1) {
      features.add('全フォント利用可能');
    } else if (planInfo['fonts'] > 1) {
      features.add('${planInfo['fonts']}種類のフォント');
    }

    if (planInfo['familySharing']) {
      features.add('家族共有（最大${planInfo['maxFamilyMembers']}人）');
    }

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          )
          .toList(),
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

  /// プランダウングレード確認ダイアログを表示
  Future<bool> _showDowngradeConfirmationDialog(
    SubscriptionIntegrationService service,
  ) async {
    final currentPlanName = service.getPlanInfo(service.currentPlan)['name'];

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('プランの変更確認'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('現在の$currentPlanNameからフリープランに変更しますか？'),
                  const SizedBox(height: 16),
                  const Text(
                    'フリープランに変更すると、以下の機能が制限されます：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• タブ数が3つまでに制限されます'),
                  const Text('• 各リストの商品数が10個までに制限されます'),
                  const Text('• 広告が表示されます'),
                  const Text('• テーマ・フォントの選択が制限されます'),
                  const SizedBox(height: 16),
                  const Text(
                    'この変更は取り消すことができません。',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('フリープランに変更'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // === アクションメソッド ===

  void _selectPlan(
    SubscriptionPlan plan,
    SubscriptionIntegrationService service,
    PaymentService? paymentService,
  ) async {
    if (plan == service.currentPlan) return;

    setState(() => _isLoading = true);

    try {
      if (plan == SubscriptionPlan.free) {
        // 現在のプランが有料プランの場合、確認ダイアログを表示
        if (service.currentPlan != SubscriptionPlan.free) {
          final shouldDowngrade = await _showDowngradeConfirmationDialog(
            service,
          );
          if (!shouldDowngrade) {
            setState(() => _isLoading = false);
            return;
          }
        }

        // フリープランは直接変更
        await service.processSubscription(plan);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${service.getPlanInfo(plan)['name']}に変更しました'),
            ),
          );
        }
      } else {
        // 有料プランは決済処理を実行
        if (paymentService != null) {
          // PaymentServiceの初期化を確認
          if (!paymentService.isInitialized) {
            await paymentService.initialize();
          }

          if (paymentService.isAvailable) {
            final productId = _getProductIdForPlan(plan);
            await paymentService.purchaseProductById(productId);

            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('決済処理を開始しました')));
            }
          } else {
            // 決済サービスが利用できない場合はテスト用に直接変更
            await service.processSubscription(plan);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${service.getPlanInfo(plan)['name']}に変更しました（テストモード）',
                  ),
                ),
              );
            }
          }
        } else {
          // PaymentServiceがnullの場合はテスト用に直接変更
          await service.processSubscription(plan);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${service.getPlanInfo(plan)['name']}に変更しました（テストモード）',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// プランに対応する商品IDを取得（月額）
  String _getProductIdForPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return SubscriptionIds.basicMonthly;
      case SubscriptionPlan.premium:
        return SubscriptionIds.premiumMonthly;
      case SubscriptionPlan.family:
        return SubscriptionIds.familyMonthly;
      case SubscriptionPlan.free:
        throw ArgumentError('Free plan does not have a product ID');
    }
  }

  void _addFamilyMember(SubscriptionIntegrationService service) async {
    final email = _familyMemberController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await service.addFamilyMember(email);
      _familyMemberController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$email を家族メンバーに追加しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeFamilyMember(
    String email,
    SubscriptionIntegrationService service,
  ) async {
    setState(() => _isLoading = true);

    try {
      await service.removeFamilyMember(email);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$email を家族メンバーから削除しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _restorePurchases(
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) async {
    setState(() => _isLoading = true);

    try {
      await paymentService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('購入履歴を復元しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetSubscription(SubscriptionIntegrationService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('サブスクリプション状態をリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await service.resetSubscriptionStatus();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('サブスクリプション状態をリセットしました')));
      }
    }
  }

  void _testSubscription(SubscriptionIntegrationService service) async {
    await service.processSubscription(SubscriptionPlan.premium);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('プレミアムプランでテストしました')));
    }
  }

  /// 決済状態表示セクション
  Widget _buildPaymentStatusSection(PaymentService paymentService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '決済状態',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 決済サービスの可用性
            Row(
              children: [
                Icon(
                  paymentService.isAvailable ? Icons.check_circle : Icons.error,
                  color: paymentService.isAvailable ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  paymentService.isAvailable ? '決済サービス利用可能' : '決済サービス利用不可',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 決済状態
            Row(
              children: [
                Icon(
                  _getPaymentStatusIcon(paymentService.status),
                  color: _getPaymentStatusColor(paymentService.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getPaymentStatusText(paymentService.status),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            // エラー表示
            if (paymentService.lastError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'エラー: ${paymentService.lastError!.type}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paymentService.lastError!.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                    if (paymentService.lastError!.details != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        paymentService.lastError!.details!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // 商品情報
            if (paymentService.paymentProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '利用可能な商品',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...paymentService.paymentProducts.map(
                (product) => ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: Text(product.title),
                  subtitle: Text('${product.price} ${product.currency}'),
                  trailing: ElevatedButton(
                    onPressed:
                        paymentService.isLoading || paymentService.isPurchasing
                        ? null
                        : () => _purchaseProduct(product.id, paymentService),
                    child: const Text('購入'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 商品を購入
  void _purchaseProduct(String productId, PaymentService paymentService) async {
    setState(() => _isLoading = true);

    try {
      await paymentService.purchaseProductById(productId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('購入処理を開始しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('購入エラー: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 決済状態のアイコンを取得
  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.idle:
        return Icons.check_circle;
      case PaymentStatus.loading:
        return Icons.hourglass_empty;
      case PaymentStatus.purchasing:
        return Icons.shopping_cart;
      case PaymentStatus.restoring:
        return Icons.restore;
      case PaymentStatus.success:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// 決済状態の色を取得
  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.idle:
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.loading:
      case PaymentStatus.purchasing:
      case PaymentStatus.restoring:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  /// 決済状態のテキストを取得
  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.idle:
        return '待機中';
      case PaymentStatus.loading:
        return '読み込み中...';
      case PaymentStatus.purchasing:
        return '購入処理中...';
      case PaymentStatus.restoring:
        return '復元中...';
      case PaymentStatus.success:
        return '成功';
      case PaymentStatus.failed:
        return '失敗';
      case PaymentStatus.cancelled:
        return 'キャンセル';
    }
  }
}
