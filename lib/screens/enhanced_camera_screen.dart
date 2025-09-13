import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maikago/widgets/camera_guidelines_dialog.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'dart:async';

/// 値札撮影専用カメラ画面
class EnhancedCameraScreen extends StatefulWidget {
  /// 値札撮影時のコールバック
  final Function(File image)? onImageCaptured;

  const EnhancedCameraScreen({
    super.key,
    this.onImageCaptured,
  });

  @override
  State<EnhancedCameraScreen> createState() => _EnhancedCameraScreenState();
}

class _EnhancedCameraScreenState extends State<EnhancedCameraScreen>
    with WidgetsBindingObserver {
  // カメラ関連
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isRequestingPermission = false;

  // ズーム関連
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 0.5;
  double _maxZoomLevel = 10.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showGuidelinesAndPrepareCamera();
  }

  /// ガイドライン表示後にカメラを準備
  Future<void> _showGuidelinesAndPrepareCamera() async {
    // ガイドラインを表示すべきかチェック
    final shouldShowGuidelines =
        await SettingsPersistence.shouldShowCameraGuidelines();

    if (shouldShowGuidelines && mounted) {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CameraGuidelinesDialog(),
      );

      if (result != null && result['confirmed'] == true) {
        // ガイドラインを確認済みとして保存
        await SettingsPersistence.markCameraGuidelinesAsShown();

        // 「二度と表示しない」がチェックされている場合
        if (result['dontShowAgain'] == true) {
          await SettingsPersistence.setCameraGuidelinesDontShowAgain();
        }
      } else {
        // キャンセルされた場合は画面を閉じる
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    await _initializeCamera();
  }

  /// カメラの初期化
  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _isRequestingPermission = true;
      });
    }

    try {
      // カメラ権限をリクエスト
      final status = await Permission.camera.request();
      debugPrint('📸 カメラ権限ステータス: $status');

      if (status != PermissionStatus.granted) {
        debugPrint('❌ カメラ権限が拒否されました');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('カメラの使用には権限が必要です'),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 既存のコントローラーを解放
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
          debugPrint('✅ 既存のカメラコントローラーを解放');
        } catch (e) {
          debugPrint('⚠️ カメラコントローラー解放エラー: $e');
        }
        _cameraController = null;
      }

      // カメラリソースの解放を待つ
      await Future.delayed(const Duration(milliseconds: 300));

      final cameras = await availableCameras();
      debugPrint('📸 利用可能なカメラ数: ${cameras.length}');
      if (cameras.isEmpty) {
        debugPrint('❌ 利用可能なカメラが見つかりません');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('カメラが見つかりませんでした')),
          );
        }
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      debugPrint('📸 選択されたカメラ: ${camera.name} (${camera.lensDirection})');

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 初期化を実行
      await _cameraController!.initialize();
      debugPrint('✅ カメラコントローラー初期化完了');

      // 初期化が完了しているか確認
      if (!_cameraController!.value.isInitialized) {
        throw Exception('カメラの初期化が完了していません');
      }

      // 初期化完了後に向きを固定
      await _cameraController!
          .lockCaptureOrientation(DeviceOrientation.portraitUp);
      debugPrint('✅ カメラ向き固定完了');

      // ズーム範囲を設定
      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _isRequestingPermission = false;
      });
      debugPrint('✅ カメラ初期化完了');
      debugPrint('🔍 ズーム範囲: $_minZoomLevel - $_maxZoomLevel');
    } catch (e) {
      debugPrint('❌ カメラ初期化エラー: $e');
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
        _isRequestingPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カメラの初期化に失敗しました: $e')),
        );
      }
    }
  }

  /// ズームレベル設定
  Future<void> _setZoomLevel(double zoomLevel) async {
    if (_cameraController == null || !_isCameraInitialized) {
      debugPrint('❌ カメラが初期化されていません');
      return;
    }

    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await _cameraController!.setZoomLevel(clampedZoom);
      setState(() {
        _currentZoomLevel = clampedZoom;
      });
      debugPrint('🔍 ズームレベル設定: $clampedZoom');
    } catch (e) {
      debugPrint('❌ ズーム設定エラー: $e');
    }
  }

  /// 値札撮影
  Future<void> _takePicture() async {
    if (_cameraController == null || !_isCameraInitialized || _isCapturing) {
      debugPrint('❌ 撮影条件を満たしていません');
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });
      debugPrint('📸 撮影開始');

      if (!_cameraController!.value.isInitialized) {
        throw Exception('カメラが初期化されていません');
      }

      final image = await _cameraController!.takePicture();
      debugPrint('📸 撮影完了: ${image.path}');

      if (!mounted) return;

      // 撮影した画像をコールバックで送信
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(File(image.path));
      }
      debugPrint('✅ 画像を解析に送信');
    } catch (e) {
      debugPrint('❌ 撮影エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撮影に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  /// ガイドラインダイアログを表示
  Future<void> _showGuidelinesDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CameraGuidelinesDialog(),
    );

    if (result != null && result['confirmed'] == true) {
      await SettingsPersistence.markCameraGuidelinesAsShown();
      if (result['dontShowAgain'] == true) {
        await SettingsPersistence.setCameraGuidelinesDontShowAgain();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) {
      debugPrint('📱 アプリが非アクティブになりました');
      _cameraController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('📱 アプリが再アクティブになりました');
      _cameraController?.resumePreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // メインコンテンツ
            _buildMainContent(),

            // 上部UI
            _buildTopUI(),

            // 下部UI
            _buildBottomUI(),
          ],
        ),
      ),
    );
  }

  /// メインコンテンツの構築
  Widget _buildMainContent() {
    if (_isRequestingPermission) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return _buildCameraPreview();
  }

  /// カメラプレビューの構築
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _currentZoomLevel;
      },
      onScaleUpdate: (details) {
        final newZoom = _baseScale * details.scale;
        _setZoomLevel(newZoom);
      },
      onDoubleTap: () {
        if (_currentZoomLevel > 1.0) {
          _setZoomLevel(1.0);
        } else {
          _setZoomLevel(_maxZoomLevel * 0.5);
        }
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  /// 上部UIの構築
  Widget _buildTopUI() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '値札を撮影',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showGuidelinesDialog(),
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: '撮影ガイドライン',
            ),
          ],
        ),
      ),
    );
  }

  /// 下部UIの構築
  Widget _buildBottomUI() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 撮影ボタン
            _buildCaptureButton(),
            const SizedBox(height: 16),

            // 説明テキスト
            _buildDescriptionText(),
          ],
        ),
      ),
    );
  }

  /// 撮影ボタンの構築
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _takePicture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isCapturing ? Colors.grey : Colors.white,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: _isCapturing
            ? const CircularProgressIndicator(color: Colors.black)
            : const Icon(Icons.camera_alt, color: Colors.black, size: 40),
      ),
    );
  }

  /// 説明テキストの構築
  Widget _buildDescriptionText() {
    return const Text(
      '値札を正面から、できるだけ大きく\nピントを合わせて文字がくっきりした状態で\n撮影してください',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }
}
