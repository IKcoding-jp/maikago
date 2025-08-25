import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:maikago/widgets/camera_guidelines_dialog.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'package:image/image.dart' as img;
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
        // キャンセルされた場合は前の画面に戻る
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    _prepareAndOpenCamera();
  }

  /// ガイドラインを表示すべきかチェック
  Future<bool> _shouldShowGuidelines() async {
    // SettingsPersistenceを使用して判定
    return await SettingsPersistence.shouldShowCameraGuidelines();
  }

  /// ガイドライン表示済みとしてマーク
  Future<void> _markGuidelinesAsShown() async {
    // SettingsPersistenceを使用して保存
    await SettingsPersistence.markCameraGuidelinesAsShown();
  }

  /// ガイドラインダイアログを表示
  void _showGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (context) => const CameraGuidelinesDialog(),
    );
  }

  Future<void> _prepareAndOpenCamera() async {
    try {
      debugPrint('📸 カメラ準備開始');
      final granted = await _ensureCameraPermission();
      if (!granted) {
        debugPrint('❌ カメラ権限が許可されていません');
        return;
      }
      debugPrint('✅ カメラ権限確認完了');
      await _initializeCamera();
    } catch (e) {
      debugPrint('❌ カメラ準備エラー: $e');
    }
  }

  Future<bool> _ensureCameraPermission() async {
    try {
      setState(() {
        _isRequestingPermission = true;
      });
      final status = await Permission.camera.status;
      if (status.isGranted) {
        setState(() {
          _isRequestingPermission = false;
        });
        return true;
      }

      final result = await Permission.camera.request();
      setState(() {
        _isRequestingPermission = false;
      });

      if (result.isGranted) {
        debugPrint('✅ カメラ権限が許可されました');
        return true;
      }

      if (result.isPermanentlyDenied) {
        await _showPermissionDialog(permanentlyDenied: true);
      } else {
        await _showPermissionDialog(permanentlyDenied: false);
      }
      return false;
    } catch (e) {
      setState(() {
        _isRequestingPermission = false;
      });
      debugPrint('❌ 権限チェック中にエラー: $e');
      return false;
    }
  }

  Future<void> _showPermissionDialog({required bool permanentlyDenied}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カメラ権限が必要です'),
          content: Text(
            permanentlyDenied
                ? '設定アプリから「カメラ」を許可してください。'
                : 'カメラを使用するために権限を許可してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            if (permanentlyDenied)
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await openAppSettings();
                  if (mounted) navigator.pop();
                },
                child: const Text('設定を開く'),
              )
            else
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  final again = await Permission.camera.request();
                  if (again.isGranted && mounted) {
                    await _initializeCamera();
                  }
                },
                child: const Text('許可する'),
              ),
          ],
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 アプリライフサイクル変更: $state');

    if (state == AppLifecycleState.inactive) {
      debugPrint('📱 アプリが非アクティブになりました。カメラを破棄します。');
      _disposeCamera();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('📱 アプリが一時停止しました。カメラを破棄します。');
      _disposeCamera();
    } else if (state == AppLifecycleState.detached) {
      debugPrint('📱 アプリがデタッチされました。カメラを破棄します。');
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('📱 アプリが復帰しました。カメラを再初期化します。');
      _reinitializeAfterResume();
    }
  }

  void _disposeCamera() {
    final CameraController? cameraController = _controller;
    if (cameraController != null) {
      try {
        debugPrint('📸 カメラ破棄開始');
        // カメラが初期化されているかチェックしてから破棄
        if (cameraController.value.isInitialized) {
          debugPrint('📸 初期化済みカメラを破棄します');
          // 安全な破棄処理を使用
          _safeDisposeCamera(cameraController);
        } else {
          debugPrint('📸 未初期化カメラを破棄します');
          try {
            cameraController.dispose();
          } catch (e) {
            debugPrint('❌ 未初期化カメラ破棄エラー: $e');
          }
        }
        debugPrint('✅ カメラ破棄完了');
      } catch (e) {
        debugPrint('❌ カメラ破棄エラー: $e');
      } finally {
        // エラーが発生しても必ずnullに設定
        _controller = null;
        if (mounted) {
          setState(() {
            _isInitialized = false;
          });
        }
      }
    }
  }

  Future<void> _reinitializeAfterResume() async {
    try {
      debugPrint('📸 画面復帰時のカメラ再初期化開始');
      final description = _controller?.description;
      if (description == null) {
        debugPrint('❌ カメラ説明が見つかりません');
        return;
      }

      _controller = CameraController(
        description,
        ResolutionPreset.high, // 解像度を高くして鮮明な画像を撮影
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // まず初期化を実行
      await _controller!.initialize();

      // 初期化完了後に向きを固定
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      debugPrint('✅ 画面復帰時のカメラ再初期化完了');
    } catch (e) {
      debugPrint('❌ 画面復帰時の再初期化エラー: $e');
      // エラーが発生した場合、_controllerをnullにリセット
      _controller = null;
      setState(() {
        _isInitialized = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('📸 カメラ初期化開始');

      // 既存のコントローラーがあれば破棄
      if (_controller != null) {
        try {
          debugPrint('📸 既存のカメラコントローラーを破棄中...');
          if (_controller!.value.isInitialized) {
            _safeDisposeCamera(_controller!);
          } else {
            _controller!.dispose();
          }
          debugPrint('✅ 既存のカメラコントローラーを破棄しました');
        } catch (e) {
          debugPrint('❌ 既存のカメラコントローラー破棄エラー: $e');
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
      });
      debugPrint('✅ カメラ初期化完了');
      debugPrint('🔍 ズーム範囲: $_minZoomLevel - $_maxZoomLevel');
    } catch (e) {
      debugPrint('❌ カメラ初期化エラー: $e');
      // エラーが発生した場合、_controllerをnullにリセット
      _controller = null;
      setState(() {
        _isInitialized = false;
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

      // 元の画像を撮影
      final image = await _controller!.takePicture();
      debugPrint('📸 元画像撮影完了: ${image.path}');

      // 枠内の画像を切り取る
      final croppedImage = await _cropImageToGuidelines(File(image.path));

      if (!mounted) return;

      if (croppedImage != null) {
        debugPrint('✂️ 画像切り取り完了');
        widget.onImageCaptured(croppedImage);
      } else {
        debugPrint('⚠️ 画像切り取りに失敗、元画像を使用');
        widget.onImageCaptured(File(image.path));
      }
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

  /// 撮影枠内の画像を切り取る
  Future<File?> _cropImageToGuidelines(File originalImage) async {
    try {
      debugPrint('✂️ 画像切り取り処理開始');

      // 元画像を読み込み
      final bytes = await originalImage.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        debugPrint('❌ 画像のデコードに失敗');
        return null;
      }

      // 画面サイズを事前に取得
      final screenSize = MediaQuery.of(context).size;

      // カメラプレビューの実際のサイズと位置を計算
      // AspectRatio(9/16)で表示されているため、実際のプレビューサイズを計算
      final previewWidth = screenSize.width;
      final previewHeight = screenSize.width * 16 / 9;

      // カメラプレビューの実際の表示位置を計算
      // Centerウィジェットで中央配置されているため、上下の余白を計算
      final previewTop = (screenSize.height - previewHeight) / 2;

      // 撮影枠のサイズと位置を計算（UI上の実際の位置）
      final frameWidth = screenSize.width * 0.85; // 画面幅の85%
      final frameHeight = screenSize.height * 0.25; // 画面高さの25%
      final frameLeft = (screenSize.width - frameWidth) / 2;
      final frameTop = (screenSize.height - frameHeight) / 2;

      // 撮影枠のカメラプレビュー内での相対位置を計算
      final relativeFrameTop = frameTop - previewTop;

      debugPrint('📐 画面サイズ: ${screenSize.width}x${screenSize.height}');
      debugPrint('📐 プレビューサイズ: ${previewWidth}x$previewHeight');
      debugPrint('📐 プレビュー位置: top=$previewTop');
      debugPrint('📐 枠サイズ: ${frameWidth}x$frameHeight');
      debugPrint('📐 枠位置: ($frameLeft, $frameTop)');
      debugPrint('📐 相対枠位置: top=$relativeFrameTop');
      debugPrint('📐 元画像サイズ: ${image.width}x${image.height}');

      // カメラプレビューと実際の画像のスケール比を計算
      // 画像の向きを考慮してスケールを計算
      final scaleX = image.width / previewWidth;
      final scaleY = image.height / previewHeight;

      // 切り取り座標を計算（カメラプレビュー内での相対位置を使用）
      final cropX = (frameLeft * scaleX).round();
      final cropY = (relativeFrameTop * scaleY).round();
      final cropWidth = (frameWidth * scaleX).round();
      final cropHeight = (frameHeight * scaleY).round();

      debugPrint('📐 スケール: x=$scaleX, y=$scaleY');
      debugPrint('📐 切り取り座標: x=$cropX, y=$cropY, w=$cropWidth, h=$cropHeight');

      // 座標が有効範囲内かチェック
      if (cropX < 0 ||
          cropY < 0 ||
          cropX + cropWidth > image.width ||
          cropY + cropHeight > image.height) {
        debugPrint('⚠️ 切り取り座標が画像範囲外です');
        debugPrint('⚠️ 画像範囲: 0-${image.width}, 0-${image.height}');
        debugPrint(
            '⚠️ 要求範囲: $cropX-${cropX + cropWidth}, $cropY-${cropY + cropHeight}');
        return null;
      }

      // 画像を切り取り
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // 切り取った画像をJPEG形式でエンコード
      final croppedBytes = img.encodeJpg(croppedImage, quality: 90);

      // 一時ファイルとして保存
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(croppedBytes);

      debugPrint('✅ 画像切り取り完了: ${tempFile.path}');
      debugPrint('📊 切り取り後サイズ: ${croppedImage.width}x${croppedImage.height}');

      return tempFile;
    } catch (e) {
      debugPrint('❌ 画像切り取りエラー: $e');
      return null;
    }
  }

  @override
  void dispose() {
    debugPrint('📸 CameraScreen: dispose開始');
    WidgetsBinding.instance.removeObserver(this);

    final CameraController? cameraController = _controller;
    if (cameraController != null) {
      try {
        // カメラが初期化されているかチェック
        if (cameraController.value.isInitialized) {
          debugPrint('📸 カメラが初期化されているため、安全に破棄します');
          // 同期的に破棄処理を実行
          _safeDisposeCamera(cameraController);
        } else {
          debugPrint('📸 カメラが初期化されていないため、直接破棄します');
          cameraController.dispose();
          debugPrint('✅ 未初期化カメラコントローラーを破棄しました');
        }
      } catch (e) {
        debugPrint('❌ カメラコントローラー破棄エラー: $e');
        // エラーが発生してもnullに設定してメモリリークを防ぐ
      }
      _controller = null;
    }

    super.dispose();
    debugPrint('📸 CameraScreen: dispose完了');
  }

  /// カメラを安全に破棄する
  void _safeDisposeCamera(CameraController controller) {
    try {
      // 既に破棄されている場合は何もしない
      if (controller == null) {
        debugPrint('📸 カメラコントローラーは既にnullです');
        return;
      }

      // タイムアウト付きで同期的に破棄
      final completer = Completer<void>();
      Timer? timeoutTimer;

      // タイムアウトタイマーを設定（3秒）
      timeoutTimer = Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          debugPrint('⚠️ カメラ破棄タイムアウト、強制破棄します');
          completer.complete();
        }
      });

      // カメラ破棄を実行
      controller.dispose().then((_) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          debugPrint('✅ カメラ破棄完了');
          completer.complete();
        }
      }).catchError((e) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          debugPrint('❌ カメラ破棄エラー: $e');
          completer.complete();
        }
      });

      // 同期的に完了を待つ（ただし、disposeメソッド内では非同期処理を避ける）
      try {
        // 短時間で完了を待つ
        completer.future.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () {
            debugPrint('⚠️ カメラ破棄タイムアウト（短時間）');
            timeoutTimer?.cancel();
          },
        );
      } catch (e) {
        debugPrint('⚠️ カメラ破棄待機中にエラー: $e');
        timeoutTimer?.cancel();
      }
    } catch (e) {
      debugPrint('❌ 安全なカメラ破棄中にエラー: $e');
    }
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
                padding: const EdgeInsets.all(16),
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
                        '棚札を撮影',
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
            Center(
              child: Stack(
                children: [
                  // メインの撮影枠
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85, // 画面幅の85%
                    height: MediaQuery.of(context).size.height *
                        0.25, // 画面高さの25%に変更してより長方形に
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 3, // 枠線を少し太く
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        '棚札の商品名と価格が\nはっきり見えるように撮影',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // フォントサイズを大きく
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // コーナーガイドライン
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                          left: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                          right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                          left: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                          right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ズームレベル表示とテストボタン
            Positioned(
              top: 100,
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
                      '大きな枠内に棚札全体が\nはっきり見えるように撮影してください',
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
