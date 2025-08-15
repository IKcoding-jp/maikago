import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
import '../services/subscription_manager.dart';
import '../services/payment_service.dart';
import '../config.dart';

/// サブスクリプション選択画面
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _showYearly = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<SubscriptionIntegrationService, PaymentService>(
        builder: (context, subscriptionService, paymentService, child) {
          return CustomScrollView(
            slivers: [
              // カスタムAppBar
              _buildSliverAppBar(subscriptionService),

              // メインコンテンツ
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ヘッダーセクション
                          _buildHeaderSection(subscriptionService),
                          const SizedBox(height: 32),

                          // プラン切り替えボタン
                          _buildPlanToggle(),
                          const SizedBox(height: 24),

                          // プラン比較表
                          _buildPlanComparisonTable(
                            subscriptionService,
                            paymentService,
                          ),
                          const SizedBox(height: 32),

                          // 無料トライアルセクション
                          _buildFreeTrialSection(
                            subscriptionService,
                            paymentService,
                          ),
                          const SizedBox(height: 32),

                          // よくある質問
                          _buildFAQSection(),
                          const SizedBox(height: 32),

                          // 決済状態表示（開発モードのみ）
                          if (enableDebugMode) ...[
                            _buildPaymentStatusSection(paymentService),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// スライバーAppBar
  Widget _buildSliverAppBar(SubscriptionIntegrationService service) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 背景パターン
              Positioned.fill(
                child: CustomPaint(painter: _BackgroundPatternPainter()),
              ),
              // 現在のプラン情報
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildCurrentPlanInfo(service),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 現在のプラン情報
  Widget _buildCurrentPlanInfo(SubscriptionIntegrationService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPlanIcon(service.currentPlan),
                color: _getPlanColor(service.currentPlan),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '現在のプラン',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    Text(
                      service.currentPlanName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getPlanColor(service.currentPlan),
                      ),
                    ),
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
          // 無料トライアル残り日数表示
          if (service.isTrialActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '無料トライアル: あと${service.trialRemainingDays}日',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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

  /// ヘッダーセクション
  Widget _buildHeaderSection(SubscriptionIntegrationService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最適なプランを選択',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'あなたのニーズに合わせて、最適なプランをお選びください',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// プラン切り替えボタン
  Widget _buildPlanToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            text: '月額',
            isSelected: !_showYearly,
            onTap: () => setState(() => _showYearly = false),
          ),
          _buildToggleButton(
            text: '年額（2ヶ月分お得）',
            isSelected: _showYearly,
            onTap: () => setState(() => _showYearly = true),
          ),
        ],
      ),
    );
  }

  /// トグルボタン
  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// プラン比較表
  Widget _buildPlanComparisonTable(
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) {
    final plans = _getPlansForDisplay();

    return Column(
      children: [
        // プランカード
        ...plans.map((plan) => _buildPlanCard(plan, service, paymentService)),

        // 機能比較表
        const SizedBox(height: 24),
        _buildFeatureComparisonTable(),
      ],
    );
  }

  /// 表示用プラン情報を取得
  List<Map<String, dynamic>> _getPlansForDisplay() {
    final plans = [
      {
        'plan': SubscriptionPlan.free,
        'name': 'フリー',
        'price': 0,
        'yearlyPrice': 0,
        'description': '基本的な機能をお試しいただけます',
        'features': ['最大7個のリスト', '基本テーマ', '広告表示'],
        'recommended': false,
        'popular': false,
      },
      {
        'plan': SubscriptionPlan.basic,
        'name': 'ベーシック',
        'price': 120,
        'yearlyPrice': 1200,
        'description': '個人利用に最適なプラン',
        'features': ['無制限のリスト', '5種類のテーマ', '広告非表示', 'カスタムフォント'],
        'recommended': true,
        'popular': false,
      },
      {
        'plan': SubscriptionPlan.premium,
        'name': 'プレミアム',
        'price': 240,
        'yearlyPrice': 2400,
        'description': 'すべての機能をお楽しみいただけます',
        'features': ['すべてのベーシック機能', '全テーマ利用可能', '家族共有（最大5人）', '詳細分析'],
        'recommended': false,
        'popular': true,
      },
      {
        'plan': SubscriptionPlan.family,
        'name': 'ファミリー',
        'price': 360,
        'yearlyPrice': 3600,
        'description': '家族全員でお楽しみいただけます',
        'features': ['すべてのプレミアム機能', '家族共有（最大10人）', '優先サポート'],
        'recommended': false,
        'popular': false,
      },
    ];

    return plans;
  }

  /// プランカード
  Widget _buildPlanCard(
    Map<String, dynamic> plan,
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) {
    final isCurrentPlan = plan['plan'] == service.currentPlan;
    final isRecommended = plan['recommended'] as bool;
    final isPopular = plan['popular'] as bool;
    final price = _showYearly ? plan['yearlyPrice'] : plan['price'];
    final isFree = price == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // メインカード
          Card(
            elevation: isCurrentPlan || isPopular ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isCurrentPlan
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isPopular
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.withValues(alpha: 0.1),
                          Colors.purple.withValues(alpha: 0.05),
                        ],
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー
                    Row(
                      children: [
                        Icon(
                          _getPlanIcon(plan['plan']),
                          color: _getPlanColor(plan['plan']),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan['name'],
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getPlanColor(plan['plan']),
                                    ),
                              ),
                              Text(
                                plan['description'],
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentPlan)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '現在',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 価格
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isFree) ...[
                          Text(
                            '無料',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                          ),
                        ] else ...[
                          Text(
                            '¥${price}',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showYearly ? '/年' : '/月',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    if (!isFree && _showYearly) ...[
                      const SizedBox(height: 4),
                      Text(
                        '月額¥${(price / 12).round()}相当',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 機能リスト
                    ...plan['features'].map<Widget>(
                      (feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(feature)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // アクションボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isCurrentPlan
                            ? null
                            : () => _selectPlan(
                                plan['plan'],
                                service,
                                paymentService,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentPlan
                              ? Colors.grey[300]
                              : _getPlanColor(plan['plan']),
                          foregroundColor: isCurrentPlan
                              ? Colors.grey[600]
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isCurrentPlan
                              ? '現在のプラン'
                              : isFree
                              ? '無料で開始'
                              : '選択する',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // おすすめバッジ
          if (isRecommended)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'おすすめ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 人気バッジ
          if (isPopular)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '人気',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 機能比較表
  Widget _buildFeatureComparisonTable() {
    final features = [
      {
        'name': 'リスト作成',
        'free': '10個まで',
        'basic': '無制限',
        'premium': '無制限',
        'family': '無制限',
      },
      {
        'name': 'テーマ',
        'free': '基本のみ',
        'basic': '5種類',
        'premium': '全種類',
        'family': '全種類',
      },
      {
        'name': '広告',
        'free': '表示',
        'basic': '非表示',
        'premium': '非表示',
        'family': '非表示',
      },
      {
        'name': 'フォント',
        'free': '基本のみ',
        'basic': 'カスタム',
        'premium': 'カスタム',
        'family': 'カスタム',
      },
      {
        'name': '家族共有',
        'free': '×',
        'basic': '×',
        'premium': '最大5人',
        'family': '最大10人',
      },
      {
        'name': '分析機能',
        'free': '×',
        'basic': '×',
        'premium': '○',
        'family': '○',
      },
      {
        'name': '優先サポート',
        'free': '×',
        'basic': '×',
        'premium': '×',
        'family': '○',
      },
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '機能比較',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => _buildFeatureRow(feature)),
          ],
        ),
      ),
    );
  }

  /// 機能行
  Widget _buildFeatureRow(Map<String, String> feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature['name']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              feature['free']!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              feature['basic']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              feature['premium']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              feature['family']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 無料トライアルセクション
  Widget _buildFreeTrialSection(
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) {
    // トライアル状態に応じて表示を変更
    if (service.isTrialActive) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '無料トライアル利用中',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                          ),
                          Text(
                            'あと${service.trialRemainingDays}日で終了します',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• トライアル終了日: ${_formatDate(service.trialEndDate)}\n• 終了後は自動でフリープランに移行\n• 継続する場合はサブスクリプションをご契約ください',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _selectPlan(
                      SubscriptionPlan.premium,
                      service,
                      paymentService,
                    ),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('プレミアムプランにアップグレード'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (service.trialUsed) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '無料トライアル終了',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                          ),
                          Text(
                            'トライアル期間が終了しました',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '• 無料トライアルは1回のみ利用可能\n• 継続する場合はサブスクリプションをご契約ください\n• フリープランでも基本的な機能をご利用いただけます',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.purple.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.free_breakfast,
                      color: Colors.blue[600],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '7日間の無料トライアル',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[600],
                                ),
                          ),
                          Text(
                            'すべての機能をお試しいただけます',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '• いつでもキャンセル可能\n• クレジットカード情報は安全に保護\n• トライアル期間中は全機能利用可能',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startFreeTrial(service, paymentService),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('無料トライアルを開始'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// よくある質問セクション
  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'いつでもキャンセルできますか？',
        'answer': 'はい、いつでもキャンセル可能です。キャンセル後も期間終了まではサービスをご利用いただけます。',
      },
      {
        'question': '複数のデバイスで利用できますか？',
        'answer': 'はい、同じアカウントで複数のデバイスからアクセスできます。',
      },
      {
        'question': '家族共有は何人まで利用できますか？',
        'answer': 'プレミアムプランは最大5人、ファミリープランは最大10人まで家族共有が可能です。',
      },
      {
        'question': '支払い方法は何がありますか？',
        'answer': 'クレジットカード、デビットカード、Google Pay、Apple Payに対応しています。',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'よくある質問',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...faqs.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)),
      ],
    );
  }

  /// FAQアイテム
  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  /// 決済状態表示セクション
  Widget _buildPaymentStatusSection(PaymentService paymentService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '決済状態',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === アクションメソッド ===

  /// プランを選択
  void _selectPlan(
    SubscriptionPlan plan,
    SubscriptionIntegrationService service,
    PaymentService paymentService,
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 有料プランは決済処理を実行
        if (paymentService.isAvailable) {
          final productId = _getProductIdForPlan(plan);

          // 商品が利用可能かチェック
          var product = paymentService.getProductById(productId);
          if (product == null) {
            // PaymentServiceを再初期化して再試行
            debugPrint('Product not found, reinitializing PaymentService...');
            await paymentService.initialize();
            await paymentService.refreshProducts();
            
            product = paymentService.getProductById(productId);
            if (product == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('商品が見つかりません: $productId'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }

          // 購入処理を開始
          await paymentService.purchaseProductById(productId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.title}の購入処理を開始しました'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // 決済サービスが利用できない場合の処理
          if (mounted) {
            final shouldUseTestMode = await _showTestModeConfirmationDialog();
            if (shouldUseTestMode) {
              // テスト用に直接変更
              await service.processSubscription(plan);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${service.getPlanInfo(plan)['name']}に変更しました（テストモード）',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 無料トライアルを開始
  void _startFreeTrial(
    SubscriptionIntegrationService service,
    PaymentService paymentService,
  ) async {
    setState(() => _isLoading = true);

    try {
      // 無料トライアルを開始
      await service.startFreeTrial();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('7日間の無料トライアルを開始しました'),
            backgroundColor: Colors.green,
          ),
        );
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

  /// 日付をフォーマット
  String _formatDate(DateTime? date) {
    if (date == null) return '未設定';
    return '${date.year}年${date.month}月${date.day}日';
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

  /// プランに対応する商品IDを取得
  String _getProductIdForPlan(SubscriptionPlan plan) {
    final suffix = _showYearly ? '-yearly' : '-monthly';

    switch (plan) {
      case SubscriptionPlan.basic:
        return 'maikago-basic$suffix';
      case SubscriptionPlan.premium:
        return 'maikago-premium$suffix';
      case SubscriptionPlan.family:
        return 'maikago-family$suffix';
      case SubscriptionPlan.free:
        throw ArgumentError('Free plan does not have a product ID');
    }
  }

  /// テストモード確認ダイアログ
  Future<bool> _showTestModeConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('決済サービスが利用できません'),
            content: const Text(
              'Google Play Billing サービスが利用できません。\n'
              'テストモードでプランを変更しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('テストモードで実行'),
              ),
            ],
          ),
        ) ??
        false;
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

/// 背景パターンペインター
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // 斜めの線パターン
    for (int i = 0; i < size.width + size.height; i += 20) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(0, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
