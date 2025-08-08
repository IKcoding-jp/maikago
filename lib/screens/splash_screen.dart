import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';

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
  bool _isDataLoaded = false;
  bool _isAnimationComplete = false;
  bool _hasStartedDataLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // ビルドフェーズ完了後にデータ読み込みを開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStartedDataLoading) {
        _hasStartedDataLoading = true;
        _loadDataAndProceed();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependenciesでは何もしない
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

    _animationController.forward().then((_) {
      _isAnimationComplete = true;
      _checkIfReadyToProceed();
    });
  }

  Future<void> _loadDataAndProceed() async {
    try {
      // データ読み込みを開始
      final dataProvider = context.read<DataProvider>();
      final authProvider = context.read<AuthProvider>();

      // 認証プロバイダーを設定
      dataProvider.setAuthProvider(authProvider);
      dataProvider.setLocalMode(false);

      // データ読み込みを実行
      await dataProvider.loadData();

      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
        _checkIfReadyToProceed();
      }
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      // エラーが発生しても進める
      if (mounted) {
        setState(() {
          _isDataLoaded = true;
        });
        _checkIfReadyToProceed();
      }
    }
  }

  void _checkIfReadyToProceed() {
    // アニメーション完了とデータ読み込み完了の両方が揃ったら進む
    if (_isAnimationComplete && _isDataLoaded) {
      // 最小表示時間を確保（アニメーション完了後）
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onSplashComplete();
        }
      });
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
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_basket_rounded,
                        size: 60,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary, // テーマの色に変更
                      ),
                    ),
                    const SizedBox(height: 30),
                    // アプリ名
                    Text(
                      'まいカゴ',
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
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // ローディングインジケーター
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // データ読み込み状況を表示
                    if (_isDataLoaded)
                      Text(
                        'データ読み込み完了',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    else
                      Text(
                        'データを読み込み中...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
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
