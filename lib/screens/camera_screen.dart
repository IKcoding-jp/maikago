import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maikago/widgets/camera_guidelines_dialog.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/utils/snackbar_utils.dart';

/// 値札撮影専用カメラ画面
class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.onImageCaptured,
  });

  /// 値札撮影時のコールバック
  final Function(File image)? onImageCaptured;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
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
      final result = await showConstrainedDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CameraGuidelinesDialog(),
      );

      if (result != null && result['confirmed'] == true) {
        // 「二度と表示しない」がチェックされている場合
        if (result['dontShowAgain'] == true) {
          await SettingsPersistence.setCameraGuidelinesDontShowAgain();
        }
      } else {
        // キャンセルされた場合は画面を閉じる
        if (mounted) {
          context.pop();
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
      DebugService().log('📸 カメラ権限ステータス: $status');

      if (status != PermissionStatus.granted) {
        DebugService().log('❌ カメラ権限が拒否されました');
        if (mounted) {
          showInfoSnackBar(context, 'カメラの使用には権限が必要です');
          context.pop();
        }
        return;
      }

      // 既存のコントローラーを解放
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
          DebugService().log('✅ 既存のカメラコントローラーを解放');
        } catch (e) {
          DebugService().log('⚠️ カメラコントローラー解放エラー: $e');
        }
        _cameraController = null;
      }

      // カメラリソースの解放を待つ
      await Future.delayed(const Duration(milliseconds: 300));

      final cameras = await availableCameras();
      DebugService().log('📸 利用可能なカメラ数: ${cameras.length}');
      if (cameras.isEmpty) {
        DebugService().log('❌ 利用可能なカメラが見つかりません');
        if (mounted) {
          showInfoSnackBar(context, 'カメラが見つかりませんでした');
        }
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      DebugService().log('📸 選択されたカメラ: ${camera.name} (${camera.lensDirection})');

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 初期化を実行
      await _cameraController!.initialize();
      DebugService().log('✅ カメラコントローラー初期化完了');

      // 初期化が完了しているか確認
      if (!_cameraController!.value.isInitialized) {
        throw Exception('カメラの初期化が完了していません');
      }

      // 初期化完了後に向きを固定
      await _cameraController!
          .lockCaptureOrientation(DeviceOrientation.portraitUp);
      DebugService().log('✅ カメラ向き固定完了');

      // ズーム範囲を設定
      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _isRequestingPermission = false;
      });
      DebugService().log('✅ カメラ初期化完了');
      DebugService().log('🔍 ズーム範囲: $_minZoomLevel - $_maxZoomLevel');
    } catch (e) {
      DebugService().log('❌ カメラ初期化エラー: $e');
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
        _isRequestingPermission = false;
      });
      if (mounted) {
        showErrorSnackBar(context, 'カメラの初期化に失敗しました: $e');
      }
    }
  }

  /// ズームレベル設定
  Future<void> _setZoomLevel(double zoomLevel) async {
    if (_cameraController == null || !_isCameraInitialized) {
      DebugService().log('❌ カメラが初期化されていません');
      return;
    }

    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await _cameraController!.setZoomLevel(clampedZoom);
      setState(() {
        _currentZoomLevel = clampedZoom;
      });
      DebugService().log('🔍 ズームレベル設定: $clampedZoom');
    } catch (e) {
      DebugService().log('❌ ズーム設定エラー: $e');
    }
  }

  /// ズームイン
  Future<void> _zoomIn() async {
    final newZoom =
        (_currentZoomLevel + 0.5).clamp(_minZoomLevel, _maxZoomLevel);
    await _setZoomLevel(newZoom);
  }

  /// ズームアウト
  Future<void> _zoomOut() async {
    final newZoom =
        (_currentZoomLevel - 0.5).clamp(_minZoomLevel, _maxZoomLevel);
    await _setZoomLevel(newZoom);
  }

  /// 値札撮影
  Future<void> _takePicture() async {
    if (_cameraController == null || !_isCameraInitialized || _isCapturing) {
      DebugService().log('❌ 撮影条件を満たしていません');
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });
      DebugService().log('📸 撮影開始');

      if (!_cameraController!.value.isInitialized) {
        throw Exception('カメラが初期化されていません');
      }

      final image = await _cameraController!.takePicture();
      DebugService().log('📸 撮影完了: ${image.path}');

      if (!mounted) return;

      // 撮影した画像をコールバックで送信
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(File(image.path));
      }
      DebugService().log('✅ 画像を解析に送信');
    } catch (e) {
      DebugService().log('❌ 撮影エラー: $e');
      if (mounted) {
        showErrorSnackBar(context, '撮影に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  /// ガイドラインダイアログを表示（手動再表示用）
  Future<void> _showGuidelinesDialog() async {
    await showConstrainedDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CameraGuidelinesDialog(
        showDontShowAgainCheckbox: false,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive) {
      DebugService().log('📱 アプリが非アクティブになりました');
      _cameraController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      DebugService().log('📱 アプリが再アクティブになりました');
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
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '値札を撮影',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
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

            // ズームコントロール
            if (_isCameraInitialized) _buildZoomControls(),
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
    return Text(
      '値札を正面から、できるだけ大きく\nピントを合わせて文字がくっきりした状態で\n撮影してください',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white70,
        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
      ),
    );
  }

  /// ズームコントロールの構築
  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(
              Icons.remove,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'ズームアウト',
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentZoomLevel.toStringAsFixed(1)}x',
              style: TextStyle(
                color: Colors.white,
                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'ズームイン',
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
