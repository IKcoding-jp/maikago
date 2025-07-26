import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class UpcomingFeaturesScreen extends StatefulWidget {
  const UpcomingFeaturesScreen({super.key});

  @override
  State<UpcomingFeaturesScreen> createState() => _UpcomingFeaturesScreenState();
}

class _UpcomingFeaturesScreenState extends State<UpcomingFeaturesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _sparkleController;
  late AnimationController _badgeController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();

    // フェードインアニメーション
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // スライドインアニメーション
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // キラキラエフェクトアニメーション
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Coming Soonバッジアニメーション
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _badgeAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );

    // アニメーション開始
    _fadeController.forward();
    _slideController.forward();
    _sparkleController.repeat(reverse: true);
    _badgeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '今後の新機能',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.onPrimary),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // ヘッダーセクション
                _buildHeaderSection(),
                const SizedBox(height: 32),

                // 新機能紹介セクション
                _buildFeaturesSection(),
                const SizedBox(height: 32),

                // 特徴・メリットセクション
                _buildBenefitsSection(),
                const SizedBox(height: 32),

                // 最新情報セクション
                _buildUpdateInfoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ヘッダーセクション
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
            AppColors.tertiary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Coming Soonバッジ
          ScaleTransition(
            scale: _badgeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Coming Soon',
                    style: GoogleFonts.nunito(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // タイトル
          Text(
            '今後の新機能',
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // サブタイトル
          Text(
            'まいカゴがもっと便利になります！',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // キラキラエフェクト
          FadeTransition(
            opacity: _sparkleAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome, color: AppColors.secondary, size: 16),
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome, color: AppColors.tertiary, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 新機能紹介セクション
  Widget _buildFeaturesSection() {
    return Column(
      children: [
        // 冷蔵庫リスト機能
        _buildFeatureCard(
          icon: Icons.kitchen_rounded,
          title: '冷蔵庫リスト',
          subtitle: '食材管理で無駄を削減',
          description:
              '冷蔵庫にあるものの在庫を管理・記録。賞味期限の管理も可能で、'
              '足りなくなったものを自動で買い物リストに追加。食材の無駄を減らしてお財布にも優しく。',
          gradientColors: [AppColors.secondary, AppColors.tertiary],
          delay: 200,
        ),
        const SizedBox(height: 20),

        // AI献立考案機能
        _buildFeatureCard(
          icon: Icons.restaurant_menu_rounded,
          title: 'AI献立アシスタント',
          subtitle: '最適なレシピを提案',
          description:
              '冷蔵庫リストの食材から最適なレシピを提案。栄養バランスを考えた献立作成で、'
              '詳しい作り方も一緒に表示。今日の晩ご飯に悩まない毎日を。',
          gradientColors: [AppColors.primary, AppColors.accent],
          delay: 400,
        ),
      ],
    );
  }

  // 特徴・メリットセクション
  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.thumb_up_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '新機能のメリット',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBenefitItem(
            icon: Icons.savings_rounded,
            title: '節約効果',
            description: '食材の無駄を削減',
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.timer_rounded,
            title: '時短効果',
            description: '献立を考える時間を短縮',
            color: AppColors.info,
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.favorite_rounded,
            title: '栄養管理',
            description: 'バランスの良い食事',
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.touch_app_rounded,
            title: '簡単操作',
            description: '直感的な使いやすさ',
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  // 最新情報セクション
  Widget _buildUpdateInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_active_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            '最新情報',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '新機能の実装時期や詳細は随時更新予定です。\nアップデート情報をお楽しみに！',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 機能カード
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required List<Color> gradientColors,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withOpacity(0.1),
            gradientColors[1].withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gradientColors[0].withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.onPrimary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 実装予定バッジ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '実装予定',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // メリットアイテム
  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
