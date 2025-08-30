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
    final ownerId = _parseOwnerId(value);
    if (ownerId == null) return;
    _handled = true;

    final subscription = context.read<SubscriptionService>();
    final ok = await subscription.joinFamilyByOwnerId(ownerId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ファミリーに参加しました')),
      );
      Navigator.of(context).pop(true);
    } else {
      final err = subscription.error ?? '参加に失敗しました';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ファミリーに参加')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '表示されたQRコードを枠内に合わせてください',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // 右上に操作UI（ライト/カメラ切替）
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  tooltip: 'ライト',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _controller.switchCamera(),
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  tooltip: 'カメラ切替',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
