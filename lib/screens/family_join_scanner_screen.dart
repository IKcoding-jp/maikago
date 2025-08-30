import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';

class FamilyJoinScannerScreen extends StatefulWidget {
  const FamilyJoinScannerScreen({super.key});

  @override
  State<FamilyJoinScannerScreen> createState() =>
      _FamilyJoinScannerScreenState();
}

class _FamilyJoinScannerScreenState extends State<FamilyJoinScannerScreen>
    with TickerProviderStateMixin {
  bool _handled = false;
  late AnimationController _scanAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
    torchEnabled: false,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();

    // スキャンラインアニメーション
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));

    // パルスアニメーション
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // アニメーション開始
    _scanAnimationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _parseOwnerId(String data) {
    // 期待フォーマット: maikago://family_invite?v=1&owner={uid}
    try {
      if (data.startsWith('maikago://')) {
        final uri = Uri.parse(data.replaceFirst('maikago://', 'https://'));
        if (uri.host == 'family_invite') {
          return uri.queryParameters['owner'];
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue ?? '';

    debugPrint('🔍 QRコード読み取り: $value');

    final ownerId = _parseOwnerId(value);
    debugPrint('🔍 解析されたオーナーID: $ownerId');

    if (ownerId == null) {
      debugPrint('❌ オーナーIDの解析に失敗');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              const Text('無効なQRコードです'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    _handled = true;

    // 成功時のアニメーション効果
    _pulseController.stop();
    _scanAnimationController.stop();

    debugPrint('🔍 ファミリー参加処理開始: ownerId=$ownerId');
    final subscription = context.read<SubscriptionService>();
    final ok = await subscription.joinFamilyByOwnerId(ownerId);
    debugPrint('🔍 ファミリー参加結果: $ok');

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('ファミリーに参加しました'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final err = subscription.error ?? '参加に失敗しました';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(err),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // グラデーション色の定義
    final gradientColors = isDark
        ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
        : [const Color(0xFF667eea), const Color(0xFF764ba2)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ファミリーに参加'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.black87,
            ],
          ),
        ),
        child: Stack(
          children: [
            // カメラビュー
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),

            // オーバーレイUI
            _buildOverlayUI(gradientColors),

            // スキャンフレーム
            _buildScanFrame(gradientColors),

            // スキャンライン
            _buildScanLine(gradientColors),

            // 操作ボタン
            _buildControlButtons(),

            // 説明テキスト
            _buildInstructionText(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayUI(List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildScanFrame(List<Color> gradientColors) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: gradientColors[0],
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // コーナー装飾
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: gradientColors[0], width: 4),
                          left: BorderSide(color: gradientColors[0], width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: gradientColors[0], width: 4),
                          right: BorderSide(color: gradientColors[0], width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: gradientColors[0], width: 4),
                          left: BorderSide(color: gradientColors[0], width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: gradientColors[0], width: 4),
                          right: BorderSide(color: gradientColors[0], width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanLine(List<Color> gradientColors) {
    return Center(
      child: AnimatedBuilder(
        animation: _scanAnimation,
        builder: (context, child) {
          return Positioned(
            top: 140 + (_scanAnimation.value * 200),
            left: 40,
            right: 40,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    gradientColors[0],
                    gradientColors[1],
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      top: 100,
      right: 20,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 28),
              tooltip: 'ライト',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _controller.switchCamera(),
              icon:
                  const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
              tooltip: 'カメラ切替',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    return Positioned(
      bottom: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ファミリー招待QRを読み取り',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '表示されたQRコードを枠内に合わせてください',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
