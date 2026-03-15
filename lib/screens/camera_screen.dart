import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maikago/widgets/camera_guidelines_dialog.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/screens/widgets/camera/camera_top_bar.dart';
import 'package:maikago/screens/widgets/camera/camera_bottom_controls.dart';
import 'package:maikago/services/settings_theme.dart';

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

      if (status != PermissionStatus.granted) {
        DebugService().logWarning('カメラ権限が拒否されました');
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
        } catch (e) {
          DebugService().logError('カメラコントローラー解放エラー: $e');
        }
        _cameraController = null;
      }

      // カメラリソースの解放を待つ
      await Future.delayed(const Duration(milliseconds: 300));

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        DebugService().logError('利用可能なカメラが見つかりません');
        if (mounted) {
          showInfoSnackBar(context, 'カメラが見つかりませんでした');
        }
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 初期化を実行
      await _cameraController!.initialize();

      // 初期化が完了しているか確認
      if (!_cameraController!.value.isInitialized) {
        throw Exception('カメラの初期化が完了していません');
      }

      // 初期化完了後に向きを固定
      await _cameraController!
          .lockCaptureOrientation(DeviceOrientation.portraitUp);

      // ズーム範囲を設定
      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _isRequestingPermission = false;
      });
    } catch (e) {
      DebugService().logError('カメラ初期化エラー: $e');
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
      return;
    }

    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await _cameraController!.setZoomLevel(clampedZoom);
      setState(() {
        _currentZoomLevel = clampedZoom;
      });
    } catch (e) {
      DebugService().logError('ズーム設定エラー: $e');
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
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      if (!_cameraController!.value.isInitialized) {
        throw Exception('カメラが初期化されていません');
      }

      final image = await _cameraController!.takePicture();

      if (!mounted) return;

      // 撮影した画像をコールバックで送信
      if (widget.onImageCaptured != null) {
        widget.onImageCaptured!(File(image.path));
      }
    } catch (e) {
      DebugService().logError('撮影エラー: $e');
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

  /// ギャラリーから画像を選択
  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null || !mounted) return;

      widget.onImageCaptured?.call(File(pickedFile.path));
    } catch (e) {
      DebugService().logError('ギャラリー選択エラー: $e');
      if (mounted) {
        showErrorSnackBar(context, '画像の選択に失敗しました');
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
      _cameraController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
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
      backgroundColor: AppColors.cameraBackground,
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
        child: CircularProgressIndicator(color: AppColors.cameraForeground),
      );
    }

    return _buildCameraPreview();
  }

  /// カメラプレビューの構築
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.cameraForeground),
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
    return CameraTopBar(
      onClose: () => context.pop(),
      onPickFromGallery: _pickFromGallery,
      onHelp: _showGuidelinesDialog,
    );
  }

  /// 下部UIの構築
  Widget _buildBottomUI() {
    return CameraBottomControls(
      isCapturing: _isCapturing,
      isCameraInitialized: _isCameraInitialized,
      currentZoomLevel: _currentZoomLevel,
      onCapture: _takePicture,
      onZoomIn: _zoomIn,
      onZoomOut: _zoomOut,
    );
  }
}
