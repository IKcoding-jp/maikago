// 初回起動時に表示するウェルカム/オンボーディング画面
// 3ページのスライドでアプリの価値を訴求し、ゲストモードまたはログインへ誘導する
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maikago/providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.shopping_cart_outlined,
      title: '買い物リスト＋電卓\nこれ1つで',
      subtitle: 'メモと電卓はもういらない',
    ),
    _SlideData(
      icon: Icons.account_balance_wallet_outlined,
      title: '予算を設定して\nオーバーしない買い物を',
      subtitle: '残額をリアルタイムで確認',
    ),
    _SlideData(
      icon: Icons.camera_alt_outlined,
      title: '値札を撮るだけで\n自動入力',
      subtitle: 'AIが商品名と価格を認識',
    ),
  ];

  /// welcome_seenフラグを立てて、再表示を防止する
  Future<void> _markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
  }

  /// ゲストモードで開始
  Future<void> _enterGuestMode() async {
    await _markWelcomeSeen();
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    authProvider.enterGuestMode();
    context.go('/home');
  }

  /// ログイン画面へ遷移
  Future<void> _goToLogin() async {
    await _markWelcomeSeen();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    // Web時は横幅を制限
    final contentWidth = kIsWeb && screenWidth > 800 ? 800.0 : screenWidth;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                // スライド領域
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _SlideWidget(slide: slide);
                    },
                  ),
                ),

                // ボトムエリア: ドットインジケーター + ボタン
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ページインジケータードット
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => _DotIndicator(
                            isActive: index == _currentPage,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 「まずは使ってみる」ボタン（プライマリ）
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _enterGuestMode,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'まずは使ってみる',
                            style: TextStyle(
                              fontSize: theme.textTheme.bodyLarge?.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 「Googleでログイン」ボタン（セカンダリ）
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _goToLogin,
                          icon: const Icon(Icons.login, size: 20),
                          label: Text(
                            'Googleでログイン',
                            style: TextStyle(
                              fontSize: theme.textTheme.bodyLarge?.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// スライドデータモデル
class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

/// 各スライドのウィジェット
class _SlideWidget extends StatelessWidget {
  const _SlideWidget({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン背景
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 56,
              color: colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(height: 40),

          // タイトル
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // サブタイトル
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// アニメーション付きドットインジケーター
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.isActive,
    required this.color,
  });

  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
