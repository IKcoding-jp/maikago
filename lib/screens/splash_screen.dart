import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/interstitial_ad.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;

  const SplashScreen({super.key, required this.onSplashComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final InterstitialAdManager _adManager = InterstitialAdManager();
  bool _isAdLoaded = false;
  bool _hasShownAd = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAdAndProceed();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _loadAdAndProceed() async {
    // 広告表示の間隔をチェック
    final prefs = await SharedPreferences.getInstance();
    final lastAdTime = prefs.getInt('last_ad_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastAd = currentTime - lastAdTime;

    // 24時間（86400000ミリ秒）以内に広告を表示した場合はスキップ
    final shouldShowAd = timeSinceLastAd > 86400000;

    // 広告を読み込む（表示するかどうかに関係なく）
    await _adManager.loadAd();

    // アプリの初期化処理を待つ
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isAdLoaded = _adManager.isAdLoaded;
      });

      // 広告が読み込まれていて、表示条件を満たしている場合は表示
      if (_isAdLoaded && shouldShowAd && !_hasShownAd) {
        _hasShownAd = true;
        await _adManager.showAd();

        // 広告表示時刻を保存
        await prefs.setInt('last_ad_time', currentTime);
      }

      // スプラッシュ画面を終了
      widget.onSplashComplete();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // アプリアイコンまたはロゴ
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 60,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // アプリ名
                    Text(
                      'Maikago',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '買い物リスト管理アプリ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // ローディングインジケーター
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
