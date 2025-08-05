import 'package:flutter/material.dart';
import '../drawer/settings/settings_persistence.dart';

class WelcomeDialog extends StatefulWidget {
  const WelcomeDialog({super.key});

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;

  final List<WelcomePage> _pages = [
    WelcomePage(
      icon: Icons.favorite_rounded,
      title: 'まいカゴをインストールしてくれて\nありがとうございます！',
      description:
          'あなたの買い物ライフをより楽しく、\nより効率的にするお手伝いをさせていただきます。\n\nさあ、賢い買い物を始めましょう！',
      color: Color(0xFFFFB6C1), // パステルピンク
    ),
    WelcomePage(
      icon: Icons.savings_rounded,
      title: '賢い買い物で\n節約を実現',
      description:
          '買い物で節約するなら、あらかじめ買うものを決めておいて、\n値段を計算しながら買うことが大事です。\n\n無駄な出費を避け、予算オーバーを防ぎましょう！',
      color: Color(0xFF90EE90), // ライトグリーン
    ),
    WelcomePage(
      icon: Icons.shopping_basket_rounded,
      title: 'メモと電卓の\n行き来はもう不要',
      description:
          'メモと電卓の行き来はめんどくさい。\nまいカゴはその機能が一体になったアプリです！\n\n買い物リストの作成から、\n合計金額の計算まで、すべてがここにあります。',
      color: Color(0xFF87CEEB), // スカイブルー
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    } else {
      _completeWelcome();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  void _completeWelcome() async {
    await SettingsPersistence.setFirstLaunchComplete();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isLargeScreen = screenSize.width > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 20,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 500 : 400,
              maxHeight: screenSize.height * 0.85,
              minHeight: 500,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー部分
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.shopping_basket_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 28 : 32,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'まいカゴへようこそ！',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '買い物リスト管理アプリ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ページビュー部分
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _buildPage(page, isSmallScreen);
                    },
                  ),
                ),

                // ページインジケーター
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                // ボタン部分
                Container(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 16 : 24,
                    0,
                    isSmallScreen ? 16 : 24,
                    isSmallScreen ? 16 : 24,
                  ),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '戻る',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0)
                        SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 14 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                            shadowColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1 ? '始める' : '次へ',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildPage(WelcomePage page, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アイコン
            Container(
              width: isSmallScreen ? 70 : 90,
              height: isSmallScreen ? 70 : 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    page.color.withValues(alpha: 0.1),
                    page.color.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                page.icon,
                size: isSmallScreen ? 35 : 45,
                color: page.color,
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 28),

            // タイトル
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 20),

            // 説明文
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[600],
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomePage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  WelcomePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
