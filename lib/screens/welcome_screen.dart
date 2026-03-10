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
      icon: Icons.shopping_cart_rounded,
      title: '買い物リスト＋電卓\nこれ1つで',
      subtitle: 'メモと電卓はもういらない。\n商品を追加するだけで合計金額を自動計算。',
      features: ['リスト管理', '自動計算', '店別タブ'],
    ),
    _SlideData(
      icon: Icons.account_balance_wallet_rounded,
      title: '予算オーバーしない\n買い物を',
      subtitle: '予算を設定すれば、残額をリアルタイム表示。\n「あとどれだけ使える？」が一目でわかる。',
      features: ['予算設定', '残額表示', '超過警告'],
    ),
    _SlideData(
      icon: Icons.camera_alt_rounded,
      title: '値札を撮るだけで\n自動入力',
      subtitle: 'カメラで値札を撮影するだけ。\nAIが商品名と価格を自動で読み取ります。',
      features: ['値札OCR', 'AI認識', 'ワンタップ追加'],
    ),
  ];

  Future<void> _markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
  }

  Future<void> _enterGuestMode() async {
    await _markWelcomeSeen();
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    authProvider.enterGuestMode();
    context.go('/home');
  }

  Future<void> _goToLogin() async {
    await _markWelcomeSeen();
    if (!mounted) return;
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
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
    final contentWidth = kIsWeb && screenWidth > 500 ? 500.0 : screenWidth;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(15),
              colorScheme.surface,
              colorScheme.primary.withAlpha(25),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                children: [
                  // ステップ表示 (1/3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_currentPage + 1} / ${_slides.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // プログレスバー
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 8, 48, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / _slides.length,
                        backgroundColor: colorScheme.primary.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),

                  // スライド領域
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
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

                        // 左矢印
                        if (_currentPage > 0)
                          Positioned(
                            left: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                onPressed: _prevPage,
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 36,
                                  color: colorScheme.primary.withAlpha(150),
                                ),
                              ),
                            ),
                          ),

                        // 右矢印
                        if (_currentPage < _slides.length - 1)
                          Positioned(
                            right: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                onPressed: _nextPage,
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 36,
                                  color: colorScheme.primary.withAlpha(150),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ボトムエリア
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ドットインジケーター
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

                        const SizedBox(height: 24),

                        // 「まずは使ってみる」
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _enterGuestMode,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'まずは使ってみる',
                              style: TextStyle(
                                fontSize:
                                    theme.textTheme.titleMedium?.fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 「Googleでログイン」
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _goToLogin,
                            icon: const Icon(Icons.login, size: 18),
                            label: Text(
                              'Googleでログイン',
                              style: TextStyle(
                                fontSize:
                                    theme.textTheme.bodyLarge?.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: colorScheme.primary.withAlpha(150),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'アカウント不要ですぐ使えます',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
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
    required this.features,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン（大きく目立たせる）
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withAlpha(40),
                  colorScheme.primary.withAlpha(80),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(30),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: 64,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 32),

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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          // 機能チップ
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: slide.features.map((feature) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(50),
                  ),
                ),
                child: Text(
                  feature,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
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
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? color : color.withAlpha(60),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
