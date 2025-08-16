import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';
import '../services/in_app_purchase_service.dart';
import '../config.dart';

/// サブスクリプションプラン選択画面
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionPlan? _selectedPlan;
  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初期状態でフリープランを選択
    _selectedPlan = SubscriptionPlan.free;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスクリプション'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Consumer<SubscriptionService>(
            builder: (context, subscriptionService, child) {
              if (subscriptionService.currentPlan?.isPaidPlan == true) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionManagementScreen(),
                      ),
                    );
                  },
                  tooltip: 'サブスクリプション管理',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, subscriptionService, child) {
          return Column(
            children: [
              // プラン選択
              Expanded(child: _buildPlanSelection(subscriptionService)),

              // 購入ボタンエリア
              if (_selectedPlan != null)
                _buildPurchaseArea(subscriptionService),
            ],
          );
        },
      ),
    );
  }

  /// プラン選択セクション
  Widget _buildPlanSelection(SubscriptionService subscriptionService) {
    return Column(
      children: [
        // 期間選択タブ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _buildPeriodTabs(),
        ),
        const SizedBox(height: 8),
        // プラン比較表
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPlanComparisonTable(subscriptionService),
          ),
        ),
      ],
    );
  }

  /// プラン比較表
  Widget _buildPlanComparisonTable(SubscriptionService subscriptionService) {
    final plans = SubscriptionPlan.availablePlans;
    return Column(
      children: [
        // プランヘッダー行
        _buildPlanHeaders(plans, subscriptionService),
        const SizedBox(height: 8),
        // 機能比較行
        ..._buildFeatureRows(plans, subscriptionService),
        const SizedBox(height: 12),
      ],
    );
  }

  /// プランヘッダー行
  Widget _buildPlanHeaders(
    List<SubscriptionPlan> plans,
    SubscriptionService subscriptionService,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;
        final headerHeight = isSmallScreen ? 120.0 : 140.0;
        final fontSize = isSmallScreen ? 12.0 : 14.0;
        final priceSize = isSmallScreen ? 16.0 : 18.0;
        final iconSize = isSmallScreen ? 16.0 : 20.0;

        return SizedBox(
          height: headerHeight,
          child: Row(
            children: plans.map((plan) {
              final isCurrentPlan =
                  subscriptionService.currentPlan?.type == plan.type;
              final isSelected = _selectedPlan?.type == plan.type;
              final isActive = subscriptionService.isSubscriptionActive;
              final gradientColors = _getPlanGradientColors(plan.type);
              final iconData = _getPlanIcon(plan.type);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = plan;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? gradientColors
                            : [Colors.grey.shade50, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: gradientColors[0], width: 2)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? gradientColors[0].withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.1),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // アイコンと状態
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : gradientColors[0].withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  iconData,
                                  color: isSelected
                                      ? Colors.white
                                      : gradientColors[0],
                                  size: iconSize,
                                ),
                              ),
                              if (!isSmallScreen) const SizedBox(width: 4),
                              if (isCurrentPlan && isActive)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: isSmallScreen ? 12 : 14,
                                )
                              else if (isSelected && !isSmallScreen)
                                const Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.white,
                                  size: 12,
                                ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          // プラン名
                          Flexible(
                            child: Text(
                              plan.name.replaceAll('まいカゴ', ''),
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          // 料金表示
                          if (plan.isPaidPlan)
                            Flexible(
                              child: Text(
                                '¥${plan.getPrice(_selectedPeriod)}',
                                style: TextStyle(
                                  fontSize: priceSize,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : gradientColors[0],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            Text(
                              '無料',
                              style: TextStyle(
                                fontSize: priceSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          if (plan.isPaidPlan && !isSmallScreen)
                            Text(
                              _selectedPeriod == SubscriptionPeriod.monthly
                                  ? '/月'
                                  : '/年',
                              style: TextStyle(
                                fontSize: 8,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 機能比較行一覧
  List<Widget> _buildFeatureRows(
    List<SubscriptionPlan> plans,
    SubscriptionService subscriptionService,
  ) {
    final features = <Map<String, dynamic>>[
      {
        'title': 'リスト作成数',
        'icon': Icons.list_alt,
        'values': plans
            .map((plan) => plan.hasListLimit ? '${plan.maxLists}個まで' : '無制限')
            .toList(),
      },
      {
        'title': 'タブ作成数',
        'icon': Icons.tab,
        'values': plans
            .map((plan) => plan.hasTabLimit ? '${plan.maxTabs}個まで' : '無制限')
            .toList(),
      },
      {
        'title': '広告表示',
        'icon': Icons.ads_click,
        'values': plans.map((plan) => plan.showAds ? 'あり' : 'なし').toList(),
      },
      {
        'title': 'テーマカスタマイズ',
        'icon': Icons.palette,
        'values': plans
            .map((plan) => plan.canCustomizeTheme ? '可能' : '制限')
            .toList(),
      },
      {
        'title': 'フォントカスタマイズ',
        'icon': Icons.text_fields,
        'values': plans
            .map((plan) => plan.canCustomizeFont ? '可能' : '制限')
            .toList(),
      },
      {
        'title': '新機能早期アクセス',
        'icon': Icons.new_releases,
        'values': plans
            .map((plan) => plan.hasEarlyAccess ? 'あり' : '-')
            .toList(),
      },
      {
        'title': 'ファミリーメンバー',
        'icon': Icons.family_restroom,
        'values': plans
            .map(
              (plan) => plan.isFamilyPlan ? '最大${plan.maxFamilyMembers}人' : '-',
            )
            .toList(),
      },
    ];

    return features.map((feature) {
      return _buildFeatureRow(
        feature['title'] as String,
        feature['icon'] as IconData,
        feature['values'] as List<String>,
        plans,
        subscriptionService,
      );
    }).toList();
  }

  /// 機能比較行
  Widget _buildFeatureRow(
    String title,
    IconData icon,
    List<String> values,
    List<SubscriptionPlan> plans,
    SubscriptionService subscriptionService,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;
        final titleWidth = isSmallScreen ? 100.0 : 120.0;
        final fontSize = isSmallScreen ? 10.0 : 11.0;
        final titleFontSize = isSmallScreen ? 11.0 : 12.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 6 : 8,
              horizontal: isSmallScreen ? 8 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 機能アイコンとタイトル
                SizedBox(
                  width: titleWidth,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 5),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          icon,
                          size: isSmallScreen ? 14 : 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 各プランの値
                Expanded(
                  child: Row(
                    children: values.asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value;
                      final plan = plans[index];
                      final isSelected = _selectedPlan?.type == plan.type;
                      final gradientColors = _getPlanGradientColors(plan.type);

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 3 : 4,
                              horizontal: isSmallScreen ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? gradientColors[0].withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: isSelected
                                  ? Border.all(
                                      color: gradientColors[0].withValues(
                                        alpha: 0.3,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _getFeatureValueColor(
                                  value,
                                  isSelected,
                                  gradientColors,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 機能値の色を取得
  Color _getFeatureValueColor(
    String value,
    bool isSelected,
    List<Color> gradientColors,
  ) {
    if (isSelected) {
      return gradientColors[0];
    }

    switch (value) {
      case '無制限':
      case 'なし':
      case '可能':
      case 'あり':
        if (value == 'なし' || value == '可能' || value == '無制限') {
          return Colors.green.shade700;
        }
        return value == 'あり' ? Colors.orange.shade700 : Colors.green.shade700;
      case '制限':
      case '-':
        return Colors.grey.shade600;
      default:
        if (value.contains('人') || value.contains('個')) {
          return Colors.blue.shade700;
        }
        return Colors.black87;
    }
  }

  /// 期間選択タブ
  Widget _buildPeriodTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;

        final monthlyPrice = _selectedPlan?.monthlyPrice ?? 0;
        final yearlyPrice = _selectedPlan?.yearlyPrice ?? 0;
        final yearlyDiscount = monthlyPrice > 0
            ? ((monthlyPrice * 12 - yearlyPrice) / (monthlyPrice * 12) * 100)
                  .round()
            : 0;
        final gradientColors = _getPlanGradientColors(
          _selectedPlan?.type ?? SubscriptionPlanType.free,
        );

        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gradientColors[0].withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = SubscriptionPeriod.monthly;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 6 : 8,
                      horizontal: isSmallScreen ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: _selectedPeriod == SubscriptionPeriod.monthly
                          ? LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedPeriod == SubscriptionPeriod.monthly
                          ? null
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _selectedPeriod == SubscriptionPeriod.monthly
                          ? [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: _selectedPeriod == SubscriptionPeriod.monthly
                              ? Colors.white
                              : gradientColors[0],
                          size: isSmallScreen ? 16 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          '月額',
                          style: TextStyle(
                            color: _selectedPeriod == SubscriptionPeriod.monthly
                                ? Colors.white
                                : gradientColors[0],
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = SubscriptionPeriod.yearly;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 6 : 8,
                      horizontal: isSmallScreen ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: _selectedPeriod == SubscriptionPeriod.yearly
                          ? LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedPeriod == SubscriptionPeriod.yearly
                          ? null
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _selectedPeriod == SubscriptionPeriod.yearly
                          ? [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _selectedPeriod == SubscriptionPeriod.yearly
                              ? Colors.white
                              : gradientColors[0],
                          size: isSmallScreen ? 16 : 18,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          '年額',
                          style: TextStyle(
                            color: _selectedPeriod == SubscriptionPeriod.yearly
                                ? Colors.white
                                : gradientColors[0],
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        if (yearlyDiscount > 0 && !isSmallScreen) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _selectedPeriod == SubscriptionPeriod.yearly
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$yearlyDiscount%OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 購入エリア
  Widget _buildPurchaseArea(SubscriptionService subscriptionService) {
    if (_selectedPlan?.type == subscriptionService.currentPlan?.type &&
        subscriptionService.isSubscriptionActive) {
      return _buildCurrentPlanArea(subscriptionService);
    }
    return _buildPurchaseButton(subscriptionService);
  }

  /// 現在のプラン表示エリア
  Widget _buildCurrentPlanArea(SubscriptionService subscriptionService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在のプラン',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _selectedPlan!.name.replaceAll('まいカゴ', ''),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'このプランをご利用中です',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 購入ボタン
  Widget _buildPurchaseButton(SubscriptionService subscriptionService) {
    final gradientColors = _getPlanGradientColors(
      _selectedPlan?.type ?? SubscriptionPlanType.free,
    );
    final planName = _selectedPlan!.name.replaceAll('まいカゴ', '');
    final price = _selectedPlan?.getPrice(_selectedPeriod) ?? 0;
    final periodText = _selectedPeriod == SubscriptionPeriod.monthly
        ? '月額'
        : '年額';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // プラン特徴ハイライト
          if (_selectedPlan != null) ..._buildPlanHighlights(),
          const SizedBox(height: 16),
          // メインCTAボタン
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              return Container(
                height: isSmallScreen ? 50 : 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedPlan!.isFreePlan
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_selectedPlan!.isFreePlan
                                  ? Colors.grey.shade400
                                  : gradientColors[0])
                              .withValues(alpha: 0.4),
                      blurRadius: isSmallScreen ? 10 : 15,
                      offset: Offset(0, isSmallScreen ? 5 : 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading || _selectedPlan!.isFreePlan
                        ? null
                        : () => _purchaseSubscription(subscriptionService),
                    borderRadius: BorderRadius.circular(
                      isSmallScreen ? 16 : 20,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '処理中...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _selectedPlan!.isFreePlan
                                          ? Icons.shopping_cart
                                          : Icons.rocket_launch,
                                      color: _selectedPlan!.isFreePlan
                                          ? Colors.grey.shade300
                                          : Colors.white,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Flexible(
                                      child: Text(
                                        _selectedPlan!.isFreePlan
                                            ? 'フリープランを選択'
                                            : '$planNameを始める',
                                        style: TextStyle(
                                          color: _selectedPlan!.isFreePlan
                                              ? Colors.grey.shade300
                                              : Colors.white,
                                          fontSize: isSmallScreen ? 16 : 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedPlan?.isPaidPlan == true)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '¥$price',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        ' / $periodText',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_selectedPlan!.isFreePlan)
                                  Text(
                                    '無料で利用',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: isSmallScreen ? 12 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          // 特典情報
          if (_selectedPeriod == SubscriptionPeriod.yearly &&
              _selectedPlan?.isPaidPlan == true)
            ..._buildYearlyDiscount(),
          // エラー表示
          if (subscriptionService.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subscriptionService.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// プラン特徴ハイライト
  List<Widget> _buildPlanHighlights() {
    if (_selectedPlan == null) return [];

    final highlights = <String>[];
    final plan = _selectedPlan!;

    if (!plan.hasListLimit) highlights.add('リスト無制限');
    if (!plan.hasTabLimit) highlights.add('タブ無制限');
    if (!plan.showAds) highlights.add('広告非表示');
    if (plan.canCustomizeTheme) highlights.add('テーマカスタマイズ');
    if (plan.canCustomizeFont) highlights.add('フォントカスタマイズ');
    if (plan.hasEarlyAccess) highlights.add('新機能早期アクセス');
    if (plan.isFamilyPlan) highlights.add('ファミリープラン');

    // ベーシックプランの場合、特別な特徴を追加
    if (plan.type == SubscriptionPlanType.basic) {
      highlights.add('リスト30個・タブ10個まで');
      highlights.add('無駄な機能はいらない人向け');
    }

    if (highlights.isEmpty) return [];

    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.blue.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'このプランの特徴',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: highlights.map((highlight) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    highlight,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ];
  }

  /// 年額割引情報
  List<Widget> _buildYearlyDiscount() {
    if (_selectedPlan == null) return [];

    final monthlyPrice = _selectedPlan!.monthlyPrice ?? 0;
    final yearlyPrice = _selectedPlan!.yearlyPrice ?? 0;

    if (monthlyPrice == 0 || yearlyPrice == 0) return [];

    final yearlyTotal = monthlyPrice * 12;
    final savings = yearlyTotal - yearlyPrice;
    final discountPercent = ((savings / yearlyTotal) * 100).round();

    if (savings <= 0) return [];

    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.savings,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '年額プランで$discountPercent%お得！',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    '年間で¥$savingsの節約',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// サブスクリプション購入処理
  Future<void> _purchaseSubscription(
    SubscriptionService subscriptionService,
  ) async {
    if (_selectedPlan == null) return;

    setState(() => _isLoading = true);
    subscriptionService.clearError();

    try {
      // フリープランの場合は無料プランに設定
      if (_selectedPlan!.isFreePlan) {
        final success = await subscriptionService.setFreePlan();
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_selectedPlan?.name ?? 'フリープラン'}に変更しました'),
                backgroundColor: Colors.green,
              ),
            );
            // フリープラン設定後、画面を閉じる
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(subscriptionService.error ?? 'プランの変更に失敗しました'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      // 有料プランの場合は従来通りの購入処理
      final productId = _selectedPlan?.getProductId(_selectedPeriod);
      if (productId == null) {
        throw Exception('商品IDが見つかりません');
      }

      // InAppPurchaseServiceを使用して直接購入
      final purchaseService = InAppPurchaseService();
      if (!purchaseService.isAvailable) {
        throw Exception('アプリ内購入が利用できません');
      }

      final product = purchaseService.getProductById(productId);
      if (product == null) {
        throw Exception('商品が見つかりません');
      }

      final success = await purchaseService.purchaseProduct(productId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedPlan?.name ?? 'プラン'}を開始しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(subscriptionService.error ?? '購入に失敗しました'),
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// プランに応じたグラデーション色を取得
  List<Color> _getPlanGradientColors(SubscriptionPlanType planType) {
    switch (planType) {
      case SubscriptionPlanType.free:
        return [const Color(0xFF6C757D), const Color(0xFF495057)];
      case SubscriptionPlanType.basic:
        return [const Color(0xFF007BFF), const Color(0xFF0056B3)];
      case SubscriptionPlanType.premium:
        return [const Color(0xFF9C27B0), const Color(0xFF673AB7)];
      case SubscriptionPlanType.family:
        return [const Color(0xFFFF8C00), const Color(0xFFFF6347)];
    }
  }

  /// プランに応じたアイコンを取得
  IconData _getPlanIcon(SubscriptionPlanType planType) {
    switch (planType) {
      case SubscriptionPlanType.free:
        return Icons.shopping_cart;
      case SubscriptionPlanType.basic:
        return Icons.star;
      case SubscriptionPlanType.premium:
        return Icons.diamond;
      case SubscriptionPlanType.family:
        return Icons.family_restroom;
    }
  }
}

/// サブスクリプション管理画面
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスクリプション管理'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Consumer<SubscriptionService>(
        builder: (context, subscriptionService, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 現在のプラン情報
                _buildCurrentPlanInfo(subscriptionService),

                const SizedBox(height: 24),

                // ファミリーメンバー管理（ファミリープランの場合）
                if (subscriptionService.currentPlan?.isFamilyPlan == true)
                  _buildFamilyManagement(subscriptionService),

                const Spacer(),

                // アクションボタン
                _buildActionButtons(subscriptionService),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 現在のプラン情報
  Widget _buildCurrentPlanInfo(SubscriptionService subscriptionService) {
    final currentPlan = subscriptionService.currentPlan;
    final isActive = subscriptionService.isSubscriptionActive;
    final expiryDate = subscriptionService.subscriptionExpiryDate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('現在のプラン', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              currentPlan?.name ?? '不明',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  color: isActive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? '有効' : '無効',
                  style: TextStyle(color: isActive ? Colors.green : Colors.red),
                ),
              ],
            ),
            if (currentPlan?.isPaidPlan == true && expiryDate != null) ...[
              const SizedBox(height: 8),
              Text(
                '有効期限: ${_formatDate(expiryDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ファミリーメンバー管理
  Widget _buildFamilyManagement(SubscriptionService subscriptionService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ファミリーメンバー', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${subscriptionService.familyMembers.length}人 / ${subscriptionService.currentPlan?.maxFamilyMembers ?? 0}人',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: subscriptionService.canAddFamilyMember()
                        ? () => _showAddFamilyMemberDialog(subscriptionService)
                        : null,
                    icon: const Icon(Icons.person_add),
                    label: const Text('メンバー追加'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: subscriptionService.familyMembers.isNotEmpty
                        ? () => _showFamilyMembersList(subscriptionService)
                        : null,
                    icon: const Icon(Icons.people),
                    label: const Text('メンバー一覧'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(SubscriptionService subscriptionService) {
    return Column(
      children: [
        if (subscriptionService.currentPlan?.isPaidPlan == true) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () => _cancelSubscription(subscriptionService),
              child: const Text('サブスクリプションをキャンセル'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _restorePurchases(),
            child: const Text('購入履歴を復元'),
          ),
        ),
      ],
    );
  }

  /// ファミリーメンバー追加ダイアログ
  void _showAddFamilyMemberDialog(SubscriptionService subscriptionService) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーメンバー追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('追加するユーザーのメールアドレスを入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;

              Navigator.of(context).pop();
              await _addFamilyMember(subscriptionService, email);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  /// ファミリーメンバー追加
  Future<void> _addFamilyMember(
    SubscriptionService subscriptionService,
    String email,
  ) async {
    setState(() => _isLoading = true);

    try {
      // 実際の実装では、メールアドレスからユーザーIDを取得する必要があります
      // ここでは簡略化のため、メールアドレスをそのまま使用
      final success = await subscriptionService.addFamilyMember(email);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ファミリーメンバーを追加しました')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(subscriptionService.error ?? '追加に失敗しました')),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ファミリーメンバー一覧表示
  void _showFamilyMembersList(SubscriptionService subscriptionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーメンバー一覧'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: subscriptionService.familyMembers.length,
            itemBuilder: (context, index) {
              final member = subscriptionService.familyMembers[index];
              return ListTile(
                title: Text(member),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      _removeFamilyMember(subscriptionService, member),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// ファミリーメンバー削除
  Future<void> _removeFamilyMember(
    SubscriptionService subscriptionService,
    String memberId,
  ) async {
    final success = await subscriptionService.removeFamilyMember(memberId);

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ファミリーメンバーを削除しました')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(subscriptionService.error ?? '削除に失敗しました')),
        );
      }
    }
  }

  /// サブスクリプションキャンセル
  Future<void> _cancelSubscription(
    SubscriptionService subscriptionService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブスクリプションキャンセル'),
        content: const Text('本当にサブスクリプションをキャンセルしますか？\n\nこの操作は取り消せません。'),
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
            child: const Text('キャンセルする'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await subscriptionService.cancelSubscription();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('サブスクリプションをキャンセルしました')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 購入履歴復元
  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final purchaseService = InAppPurchaseService();
      await purchaseService.restorePurchases();

      // サブスクリプション情報を再読み込み
      final subscriptionService = SubscriptionService();
      await subscriptionService.loadFromFirestore();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('購入履歴を復元しました')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 日付フォーマット
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
