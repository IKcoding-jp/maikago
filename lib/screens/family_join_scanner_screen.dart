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

class _FamilyJoinScannerScreenState extends State<FamilyJoinScannerScreen> {
  bool _handled = false;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
    torchEnabled: false,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
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

    debugPrint('🔍 ファミリー参加処理開始: ownerId=$ownerId');
    final subscription = context.read<SubscriptionService>();
    final ok = await subscription.joinFamilyByOwnerId(ownerId);
    debugPrint('🔍 ファミリー参加結果: $ok');

    if (!mounted) return;
    if (ok) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ファミリーに参加'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          // カメラビュー
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // オーバーレイ
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),

          // スキャンエリア
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // 操作ボタン
          Positioned(
            top: 100,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: Icon(Icons.flash_on,
                        color: theme.colorScheme.onSurface),
                    tooltip: 'ライト',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _controller.switchCamera(),
                    icon: Icon(Icons.cameraswitch,
                        color: theme.colorScheme.onSurface),
                    tooltip: 'カメラ切替',
                  ),
                ),
              ],
            ),
          ),

          // 説明テキスト
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ファミリー招待QRを読み取り',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '表示されたQRコードを枠内に合わせてください',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
