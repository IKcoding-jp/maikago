import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';
import '../services/subscription_integration_service.dart';

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
          // デバッグモード時のみデバッグボタンを表示
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => _showDebugPanel(context),
              tooltip: 'デバッグパネル',
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

  /// デバッグパネルを表示
  void _showDebugPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DebugPanelDialog(),
    );
  }

  /// プラン選択セクション
  Widget _buildPlanSelection(SubscriptionService subscriptionService) {
    return Column(
      children: [
        // 期間選択タブ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: _buildPeriodTabs(),
        ),
        const SizedBox(height: 4),
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
        const SizedBox(height: 4),
        // 機能比較行
        ..._buildFeatureRows(plans, subscriptionService),
        const SizedBox(height: 8),
      ],
    );
  }

  /// プランヘッダー行
  Widget _buildPlanHeaders(
    List<SubscriptionPlan> plans,
    SubscriptionService subscriptionService,
  ) {
    return Consumer<SubscriptionIntegrationService>(
      builder: (context, integrationService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            // 小さい画面でも文字が見切れないように閾値とサイズを調整
            final isSmallScreen = screenWidth < 420;
            final headerHeight = isSmallScreen ? 120.0 : 140.0;
            final fontSize = isSmallScreen ? 11.0 : 14.0;
            final priceSize = isSmallScreen ? 14.0 : 18.0;
            final iconSize = isSmallScreen ? 14.0 : 20.0;

            return SizedBox(
              height: headerHeight,
              child: Row(
                children: plans.map((plan) {
                  final currentPlan = integrationService.currentPlan;
                  final isCurrentPlan =
                      currentPlan != null && plan.type == currentPlan.type;
                  final isSelected = _selectedPlan?.type == plan.type;
                  final isActive = integrationService.isSubscriptionActive;
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
                              : Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
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
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // メインアイコン
                                  Container(
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 6 : 8,
                                    ),
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
                                  // チェックマーク（右上に配置）
                                  if (isCurrentPlan &&
                                      (isActive ||
                                          plan.type ==
                                              SubscriptionPlanType.free))
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: isSmallScreen ? 12 : 14,
                                      ),
                                    )
                                  else if (isSelected && !isCurrentPlan)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: const Icon(
                                        Icons.radio_button_checked,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    )
                                  else if (isSelected &&
                                      isCurrentPlan &&
                                      (isActive ||
                                          plan.type ==
                                              SubscriptionPlanType.free))
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              // プラン名
                              Flexible(
                                child: Text(
                                  plan.name.replaceAll('まいカゴ', ''),
                                  style: TextStyle(
                                    // ベーシック・プレミアム・ファミリーなど有料プランは文字を小さくする
                                    fontSize:
                                        plan.type == SubscriptionPlanType.free
                                        ? fontSize
                                        : (fontSize - 2),
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: isSmallScreen ? 3 : 2,
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
        'title': 'タブ作成数',
        'icon': Icons.tab,
        'values': plans
            .map((plan) => plan.hasTabLimit ? '${plan.maxTabs}個まで' : '無制限')
            .toList(),
      },
      {
        'title': 'リスト作成数',
        'icon': Icons.list_alt,
        'values': plans
            .map((plan) => plan.hasListLimit ? '${plan.maxLists}個まで' : '無制限')
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
        'title': 'ファミリー共有',
        'icon': Icons.family_restroom,
        'values': plans.map((plan) => plan.isFamilyPlan ? 'あり' : '-').toList(),
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
          margin: const EdgeInsets.only(bottom: 2),
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
              vertical: isSmallScreen ? 4 : 6,
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
          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
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
                      vertical: isSmallScreen ? 4 : 6,
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
                      vertical: isSmallScreen ? 4 : 6,
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
    return Consumer<SubscriptionIntegrationService>(
      builder: (context, integrationService, child) {
        final currentPlan = integrationService.currentPlan;

        // 現在のプランと同じ場合は「ご利用中」を表示
        if ((integrationService.isSubscriptionActive &&
                currentPlan != null &&
                _selectedPlan?.type == currentPlan.type) ||
            (_selectedPlan?.type == SubscriptionPlanType.free &&
                (currentPlan == null ||
                    currentPlan.type == SubscriptionPlanType.free))) {
          return _buildCurrentPlanArea(integrationService);
        }

        // フリープランへの変更は制限
        if (integrationService.isSubscriptionActive &&
            _selectedPlan?.type == SubscriptionPlanType.free) {
          return Container(); // フリープランへの変更は非表示
        }

        return _buildPurchaseButton(subscriptionService);
      },
    );
  }

  /// 現在のプラン名を取得
  String _getCurrentPlanNameInline(
    SubscriptionIntegrationService integrationService,
  ) {
    final currentPlan = integrationService.currentPlan;
    return currentPlan?.name ?? 'フリープラン';
  }

  /// 現在のプラン表示エリア
  Widget _buildCurrentPlanArea(
    SubscriptionIntegrationService integrationService,
  ) {
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
                      _getCurrentPlanNameInline(
                        integrationService,
                      ).replaceAll('プラン', ''),
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
                    onTap: _isLoading
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
          const SizedBox(height: 12),
          // 復元ボタン（Android向け）
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        final ok = await subscriptionService.restorePurchases();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? '購入情報を復元しました' : '購入情報は見つかりませんでした',
                              ),
                              backgroundColor: ok
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('復元エラー: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('復元に失敗しました: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              icon: const Icon(Icons.restore),
              label: const Text('購入を復元'),
            ),
          ),
          // 特典情報（年額の詳細パネルは削除。%OFF 表示は年額タブ側に残します）
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

    if (!plan.hasTabLimit) highlights.add('タブ無制限');
    if (!plan.hasListLimit) highlights.add('リスト無制限');
    if (!plan.showAds) highlights.add('広告非表示');
    if (plan.canCustomizeTheme) highlights.add('テーマカスタマイズ');
    if (plan.canCustomizeFont) highlights.add('フォントカスタマイズ');
    if (plan.hasEarlyAccess) highlights.add('新機能早期アクセス');
    if (plan.isFamilyPlan) highlights.add('ファミリープラン');

    // ベーシックプランの場合、特別な特徴を追加
    if (plan.type == SubscriptionPlanType.basic) {
      highlights.add('タブ10個・リスト30個まで');
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

  // 年額割引の詳細パネルは削除しました

  /// サブスクリプション購入処理
  Future<void> _purchaseSubscription(
    SubscriptionService subscriptionService,
  ) async {
    if (_selectedPlan == null || _selectedPlan!.isFreePlan) return;

    setState(() => _isLoading = true);
    try {
      final ok = await subscriptionService.purchasePlan(
        _selectedPlan!,
        period: _selectedPeriod,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('購入を開始できませんでした。しばらくしてから再度お試しください。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('購入開始エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

/// デバッグパネルダイアログ
class DebugPanelDialog extends StatefulWidget {
  const DebugPanelDialog({super.key});

  @override
  State<DebugPanelDialog> createState() => _DebugPanelDialogState();
}

class _DebugPanelDialogState extends State<DebugPanelDialog> {
  SubscriptionPlan? _selectedDebugPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 現在のプランを初期値として設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectedPlan();
    });
  }

  void _updateSelectedPlan() {
    final integrationService = Provider.of<SubscriptionIntegrationService>(
      context,
      listen: false,
    );
    setState(() {
      _selectedDebugPlan =
          integrationService.currentPlan ?? SubscriptionPlan.free;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('デバッグパネル'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Consumer<SubscriptionIntegrationService>(
            builder: (context, integrationService, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 現在の状態表示
                  _buildCurrentStatusSection(integrationService),
                  const SizedBox(height: 16),

                  // プラン変更セクション
                  _buildPlanChangeSection(integrationService),
                  const SizedBox(height: 16),

                  // デバッグ機能セクション
                  _buildDebugFunctionsSection(integrationService),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  /// 現在の状態表示セクション
  Widget _buildCurrentStatusSection(
    SubscriptionIntegrationService integrationService,
  ) {
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
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                '現在の状態',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'プラン',
            integrationService.currentPlan?.name ?? 'フリープラン',
          ),
          _buildStatusRow(
            'サブスクリプション有効',
            integrationService.isSubscriptionActive ? 'はい' : 'いいえ',
          ),
          _buildStatusRow(
            '特典有効',
            integrationService.hasBenefits ? 'はい' : 'いいえ',
          ),
          _buildStatusRow(
            '広告非表示',
            integrationService.shouldHideAds ? 'はい' : 'いいえ',
          ),
          _buildStatusRow(
            'テーマ変更可能',
            integrationService.canChangeTheme ? 'はい' : 'いいえ',
          ),
          _buildStatusRow(
            'フォント変更可能',
            integrationService.canChangeFont ? 'はい' : 'いいえ',
          ),
        ],
      ),
    );
  }

  /// 状態行を構築
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: value == 'はい'
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value == 'はい'
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// プラン変更セクション
  Widget _buildPlanChangeSection(
    SubscriptionIntegrationService integrationService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'プラン変更（デバッグ用）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              '⚠️ 開発用のプラン変更機能です。本番環境では使用できません。',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),
          // プラン選択ドロップダウン
          DropdownButtonFormField<SubscriptionPlan>(
            value: _selectedDebugPlan,
            decoration: const InputDecoration(
              labelText: 'プランを選択',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: SubscriptionPlan.availablePlans.map((plan) {
              return DropdownMenuItem(value: plan, child: Text(plan.name));
            }).toList(),
            onChanged: (plan) {
              setState(() {
                _selectedDebugPlan = plan;
              });
            },
          ),
          const SizedBox(height: 12),
          // プラン変更ボタン
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _changePlan(integrationService),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(_isLoading ? '変更中...' : 'プランを変更'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// デバッグ機能セクション
  Widget _buildDebugFunctionsSection(
    SubscriptionIntegrationService integrationService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'デバッグ機能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _resetToFreePlan(integrationService),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      'フリープランにリセット',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _debugPrintStatus(integrationService),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text(
                      '状態をログ出力',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  /// プランを変更
  Future<void> _changePlan(
    SubscriptionIntegrationService integrationService,
  ) async {
    if (_selectedDebugPlan == null) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('デバッグ: プランを変更中... ${_selectedDebugPlan!.name}');

      // SubscriptionServiceを使用してプランを変更
      final subscriptionService = Provider.of<SubscriptionService>(
        context,
        listen: false,
      );

      bool success = false;
      if (_selectedDebugPlan!.isFreePlan) {
        success = await subscriptionService.setFreePlan();
      } else {
        // 有料プランの場合はテスト用に直接設定
        success = await subscriptionService.setTestPlan(_selectedDebugPlan!);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('プランを${_selectedDebugPlan!.name}に変更しました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('プランの変更に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('デバッグ: プラン変更エラー: $e');
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

  /// フリープランにリセット
  Future<void> _resetToFreePlan(
    SubscriptionIntegrationService integrationService,
  ) async {
    try {
      debugPrint('デバッグ: フリープランにリセット中...');

      final subscriptionService = Provider.of<SubscriptionService>(
        context,
        listen: false,
      );

      final success = await subscriptionService.setFreePlan();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フリープランにリセットしました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('リセットに失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('デバッグ: リセットエラー: $e');
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

  /// 状態をログ出力
  void _debugPrintStatus(SubscriptionIntegrationService integrationService) {
    debugPrint('=== デバッグ: サブスクリプション状態 ===');
    debugPrint('現在のプラン: ${integrationService.currentPlan?.name ?? 'フリープラン'}');
    debugPrint('サブスクリプション有効: ${integrationService.isSubscriptionActive}');
    debugPrint('特典有効: ${integrationService.hasBenefits}');
    debugPrint('広告非表示: ${integrationService.shouldHideAds}');
    debugPrint('テーマ変更可能: ${integrationService.canChangeTheme}');
    debugPrint('フォント変更可能: ${integrationService.canChangeFont}');
    // 寄付特典関連のプロパティは削除（寄付特典がなくなったため）
    debugPrint('========================');

    // 統合サービスのデバッグ出力も実行
    integrationService.debugPrintStatus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('状態をログに出力しました'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
