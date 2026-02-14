import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maikago/widgets/camera_guidelines_dialog.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'dart:async'; // Added for Completer and Timer

class CameraScreen extends StatefulWidget {
  final Function(File image) onImageCaptured;

  const CameraScreen({
    super.key,
    required this.onImageCaptured,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isRequestingPermission = false;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 0.5; // ズームアウト可能に変更
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
      if (_controller != null) {
        try {
          await _controller!.dispose();
          debugPrint('✅ 既存のカメラコントローラーを解放');
        } catch (e) {
          debugPrint('⚠️ カメラコントローラー解放エラー: $e');
        }
        _controller = null;
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

      _controller = CameraController(
        camera,
        ResolutionPreset.high, // 解像度を高くして鮮明な画像を撮影
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 初期化を実行
      await _controller!.initialize();
      debugPrint('✅ カメラコントローラー初期化完了');

      // 初期化が完了しているか確認
      if (!_controller!.value.isInitialized) {
        throw Exception('カメラの初期化が完了していません');
      }

      // 初期化完了後に向きを固定
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      debugPrint('✅ カメラ向き固定完了');

      // ズーム範囲を設定
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _isRequestingPermission = false;
      });
      debugPrint('✅ カメラ初期化完了');
      debugPrint('🔍 ズーム範囲: $_minZoomLevel - $_maxZoomLevel');
    } catch (e) {
      debugPrint('❌ カメラ初期化エラー: $e');
      // エラーが発生した場合、_controllerをnullにリセット
      _controller = null;
      setState(() {
        _isInitialized = false;
        _isRequestingPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カメラの初期化に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _setZoomLevel(double zoomLevel) async {
    if (_controller == null || !_isInitialized) {
      debugPrint('❌ カメラが初期化されていません');
      return;
    }

    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await _controller!.setZoomLevel(clampedZoom);
      setState(() {
        _currentZoomLevel = clampedZoom;
      });
      debugPrint(
          '🔍 ズームレベル設定: $clampedZoom (範囲: $_minZoomLevel - $_maxZoomLevel)');
    } catch (e) {
      debugPrint('❌ ズーム設定エラー: $e');
      // エラーが発生した場合、スライダーでズームを試す
      try {
        await _controller!.setZoomLevel(clampedZoom);
        setState(() {
          _currentZoomLevel = clampedZoom;
        });
        debugPrint('🔍 ズームレベル再設定成功: $clampedZoom');
      } catch (e2) {
        debugPrint('❌ ズーム再設定も失敗: $e2');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isInitialized || _isCapturing) {
      debugPrint(
          '❌ 撮影条件を満たしていません: controller=${_controller != null}, initialized=$_isInitialized, capturing=$_isCapturing');
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });
      debugPrint('📸 撮影開始');

      // カメラが初期化されているか再確認
      if (!_controller!.value.isInitialized) {
        throw Exception('カメラが初期化されていません');
      }

      // カメラコントローラーが有効かチェック
      if (_controller == null) {
        throw Exception('カメラコントローラーが無効です');
      }

      // 画像を撮影（切り取りなしで全体を使用）
      final image = await _controller!.takePicture();
      debugPrint('📸 撮影完了: ${image.path}');

      if (!mounted) return;

      // 撮影した画像全体を解析に使用
      widget.onImageCaptured(File(image.path));
      debugPrint('✅ 画像全体を解析に送信');
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
      builder: (context) => const CameraGuidelinesDialog(
        showDontShowAgainCheckbox: false,
      ),
    );

    if (result != null && result['confirmed'] == true) {
      // ガイドラインを確認済みとして保存
      await SettingsPersistence.markCameraGuidelinesAsShown();

      // 「二度と表示しない」がチェックされている場合
      if (result['dontShowAgain'] == true) {
        await SettingsPersistence.setCameraGuidelinesDontShowAgain();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // アプリが非アクティブになった場合、カメラを一時停止
    if (state == AppLifecycleState.inactive) {
      debugPrint('📱 アプリが非アクティブになりました');
      _controller?.pausePreview();
    }
    // アプリが再アクティブになった場合、カメラを再開
    else if (state == AppLifecycleState.resumed) {
      debugPrint('📱 アプリが再アクティブになりました');
      _controller?.resumePreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isRequestingPermission)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_isInitialized && _controller != null)
              GestureDetector(
                onScaleStart: (details) {
                  _baseScale = _currentZoomLevel;
                },
                onScaleUpdate: (details) {
                  // ピンチジェスチャーでズーム
                  final newZoom = _baseScale * details.scale;
                  _setZoomLevel(newZoom);
                },
                onDoubleTap: () {
                  // ダブルタップでズーム切り替え
                  if (_currentZoomLevel > 1.0) {
                    _setZoomLevel(1.0); // 標準ズームに戻る
                  } else if (_currentZoomLevel < 1.0) {
                    _setZoomLevel(1.0); // 標準ズームに戻る
                  } else {
                    _setZoomLevel(_maxZoomLevel * 0.5); // ズームイン
                  }
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16, // 縦画面のアスペクト比
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
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
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
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
            ),

            // ズームレベル表示とコントロール
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentZoomLevel.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _setZoomLevel(_currentZoomLevel - 0.25),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _setZoomLevel(1.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '1x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _setZoomLevel(_currentZoomLevel + 0.25),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 撮影ボタン
            Positioned(
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
                  children: [
                    GestureDetector(
                      onTap: _isCapturing ? null : _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing ? Colors.grey : Colors.white,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'タップして撮影',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '値札を正面から、できるだけ大きく\nピントを合わせて文字がくっきりした状態で\n撮影してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
