import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatefulWidget {
  final ThemeData? globalTheme; // グローバルテーマを受け取る
  const AboutScreen({super.key, this.globalTheme});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // フェードインアニメーションの初期化
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // アニメーション開始
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.globalTheme ?? Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'アプリについて',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // アプリアイコン・ロゴセクション
              _buildAppIconSection(theme),
              const SizedBox(height: 24),

              // アプリ説明セクション
              _buildAppDescriptionSection(theme),
              const SizedBox(height: 24),

              // 開発者の思いセクション
              _buildDeveloperThoughtsSection(theme),
              const SizedBox(height: 24),

              // 開発者情報セクション
              _buildDeveloperInfoSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  // アプリアイコン・ロゴセクション
  Widget _buildAppIconSection(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // アプリアイコン
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_basket_rounded,
                color: theme.colorScheme.onPrimary,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),

            // アプリ名
            Text(
              'まいカゴ',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),

            // サブタイトル
            Text(
              'お買い物をもっと便利に',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // アプリ説明セクション
  Widget _buildAppDescriptionSection(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      icon: Icons.info_outline_rounded,
      title: 'アプリについて',
      children: [
        _buildFeatureItem(
          theme: theme,
          icon: Icons.add_shopping_cart_rounded,
          title: '商品管理',
          description: '商品ごとに個数、単価、割引率を入力',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          theme: theme,
          icon: Icons.calculate_rounded,
          title: '自動計算',
          description: '合計金額が自動で計算されます',
        ),
      ],
    );
  }

  // 開発者の思いセクション
  Widget _buildDeveloperThoughtsSection(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      icon: Icons.psychology_rounded,
      title: '開発者の思い',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Text(
            'スーパーで買い物をしているとき、メモと電卓の行ったり来たりがめんどくさくて、'
            '自分が欲しかったからこのアプリを作りました。',
            style: GoogleFonts.nunito(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 開発者情報セクション
  Widget _buildDeveloperInfoSection(ThemeData theme) {
    return _buildSectionCard(
      theme: theme,
      icon: Icons.person_rounded,
      title: '開発者情報',
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.person_rounded,
                color: theme.colorScheme.onSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '開発者',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  'IK',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // セクションカードの共通ウィジェット
  Widget _buildSectionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セクションヘッダー
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // セクションコンテンツ
            ...children,
          ],
        ),
      ),
    );
  }

  // 機能アイテムの共通ウィジェット
  Widget _buildFeatureItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: theme.colorScheme.secondary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
