import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:maikago/widgets/camera_guidelines_dialog.dart';
import 'package:maikago/widgets/product_confirmation_dialog.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'package:maikago/models/product_info.dart';
import 'package:maikago/models/item.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/services/yahoo_shopping_service.dart';
import 'dart:async';

/// カメラモードの列挙型
enum CameraMode {
  /// 値札撮影モード
  priceTag,

  /// バーコードスキャンモード
  barcodeScan,
}

/// 統合カメラ画面
/// 値札撮影とバーコードスキャンの両方の機能を提供
class EnhancedCameraScreen extends StatefulWidget {
  /// 値札撮影時のコールバック
  final Function(File image)? onImageCaptured;

  /// バーコードスキャン時のコールバック
  final Function(ProductInfo productInfo)? onProductScanned;

  /// 初期モード（デフォルト: 値札撮影）
  final CameraMode initialMode;

  /// ショップ情報（商品追加時に必要）
  final Shop shop;

  const EnhancedCameraScreen({
    super.key,
    this.onImageCaptured,
    this.onProductScanned,
    this.initialMode = CameraMode.priceTag,
    required this.shop,
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

  // モード関連
  CameraMode _currentMode = CameraMode.priceTag;

  // バーコードスキャン関連
  MobileScannerController? _scannerController;
  bool _isScannerInitialized = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  // 商品情報取得関連
  bool _isLoadingProductInfo = false;
  ProductInfo? _lastProductInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentMode = widget.initialMode;
    _showGuidelinesAndPrepareCamera();
  }

  /// ガイドライン表示後にカメラを準備
  Future<void> _showGuidelinesAndPrepareCamera() async {
    // ガイドラインを表示すべきかチェック（値札撮影モードの場合のみ）
    if (_currentMode == CameraMode.priceTag) {
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
    }

    await _initializeCurrentMode();
  }

  /// 現在のモードに応じてカメラまたはスキャナーを初期化
  Future<void> _initializeCurrentMode() async {
    if (_currentMode == CameraMode.priceTag) {
      await _initializeCamera();
    } else {
      await _initializeScanner();
    }
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

      // スキャナーを停止
      if (_scannerController != null) {
        await _scannerController!.stop();
        _scannerController = null;
        _isScannerInitialized = false;
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

  /// バーコードスキャナーの初期化
  Future<void> _initializeScanner() async {
    if (mounted) {
      setState(() {
        _isRequestingPermission = true;
      });
    }

    try {
      // カメラ権限をリクエスト
      final status = await Permission.camera.request();
      debugPrint('📱 バーコードスキャナー権限ステータス: $status');

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
        _isCameraInitialized = false;
      }

      // スキャナーを初期化
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      if (!mounted) return;
      setState(() {
        _isScannerInitialized = true;
        _isRequestingPermission = false;
      });
      debugPrint('✅ バーコードスキャナー初期化完了');
    } catch (e) {
      debugPrint('❌ バーコードスキャナー初期化エラー: $e');
      _scannerController = null;
      setState(() {
        _isScannerInitialized = false;
        _isRequestingPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('バーコードスキャナーの初期化に失敗しました: $e')),
        );
      }
    }
  }

  /// モード切り替え
  Future<void> _switchMode(CameraMode newMode) async {
    if (_currentMode == newMode) return;

    debugPrint('🔄 モード切り替え: $_currentMode -> $newMode');

    setState(() {
      _currentMode = newMode;
      _isLoadingProductInfo = false;
      _errorMessage = null;
      _lastProductInfo = null;
    });

    await _initializeCurrentMode();
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

  /// バーコード検出時の処理
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isLoadingProductInfo) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    // 同じコードの重複検出を防ぐ（1秒以内）
    final now = DateTime.now();
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 1) {
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    debugPrint('📱 バーコード検出: $code');
    _fetchProductInfo(code);
  }

  /// 商品情報取得
  Future<void> _fetchProductInfo(String janCode) async {
    if (_isLoadingProductInfo) return;

    setState(() {
      _isLoadingProductInfo = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🛒 商品情報取得開始: $janCode');

      final product = await YahooShoppingService.getCheapestProduct(janCode);

      if (!mounted) return;

      if (product != null) {
        setState(() {
          _lastProductInfo = product;
        });

        // 商品確認ダイアログを表示
        final shouldAdd =
            await ProductConfirmationDialog.show(context, product);

        if (!mounted) return;

        if (shouldAdd == true) {
          // ユーザーが追加を選択した場合、直接商品情報を処理
          // カメラ画面に留まるため、コールバックは呼ばない
          await _addProductToList(product);
          debugPrint('✅ 商品情報追加完了: ${product.name}');
        } else {
          debugPrint('ℹ️ ユーザーが商品追加をキャンセル: ${product.name}');
        }
      } else {
        setState(() {
          _errorMessage = '商品情報が見つかりませんでした';
        });
        debugPrint('❌ 商品情報が見つかりませんでした');
      }
    } catch (e) {
      debugPrint('❌ 商品情報取得エラー: $e');
      if (mounted) {
        setState(() {
          if (e is YahooShoppingRateLimitException) {
            _errorMessage = 'API利用制限に達しました。しばらく時間をおいてから再度お試しください。';
          } else if (e is YahooShoppingException) {
            _errorMessage = '商品情報の取得に失敗しました: ${e.message}';
          } else {
            _errorMessage = '商品情報の取得に失敗しました: $e';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProductInfo = false;
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
      _scannerController?.stop();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('📱 アプリが再アクティブになりました');
      _cameraController?.resumePreview();
      if (_currentMode == CameraMode.barcodeScan &&
          _scannerController != null) {
        _scannerController!.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scannerController?.dispose();
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

    if (_currentMode == CameraMode.priceTag) {
      return _buildCameraPreview();
    } else {
      return _buildScannerPreview();
    }
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

  /// スキャナープレビューの構築
  Widget _buildScannerPreview() {
    if (!_isScannerInitialized || _scannerController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return MobileScanner(
      controller: _scannerController!,
      onDetect: _onBarcodeDetected,
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
            Expanded(
              child: Text(
                _currentMode == CameraMode.priceTag ? '値札を撮影' : 'バーコードをスキャン',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_currentMode == CameraMode.priceTag)
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
            // モード切り替えボタン
            _buildModeToggle(),
            const SizedBox(height: 24),

            // メインアクションボタン
            _buildMainActionButton(),
            const SizedBox(height: 16),

            // 説明テキスト
            _buildDescriptionText(),
          ],
        ),
      ),
    );
  }

  /// モード切り替えボタンの構築
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            mode: CameraMode.priceTag,
            icon: Icons.camera_alt,
            label: '値札撮影',
          ),
          const SizedBox(width: 8),
          _buildModeButton(
            mode: CameraMode.barcodeScan,
            icon: Icons.qr_code_scanner,
            label: 'バーコード',
          ),
        ],
      ),
    );
  }

  /// 個別のモードボタンの構築
  Widget _buildModeButton({
    required CameraMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// メインアクションボタンの構築
  Widget _buildMainActionButton() {
    if (_currentMode == CameraMode.priceTag) {
      return _buildCaptureButton();
    } else {
      return _buildScanStatus();
    }
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

  /// スキャン状態の構築
  Widget _buildScanStatus() {
    if (_isLoadingProductInfo) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              '商品情報を取得中...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_lastProductInfo != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              _lastProductInfo!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Text(
              '商品情報提供: Yahoo!ショッピング',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
          SizedBox(height: 8),
          Text(
            'バーコードをスキャン中...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// 説明テキストの構築
  Widget _buildDescriptionText() {
    if (_currentMode == CameraMode.priceTag) {
      return const Text(
        '値札を正面から、できるだけ大きく\nピントを合わせて文字がくっきりした状態で\n撮影してください',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      );
    } else {
      return const Text(
        '商品のバーコードを\nカメラの中央に合わせてください',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      );
    }
  }

  /// 商品をリストに追加する（カメラ画面に留まる）
  Future<void> _addProductToList(ProductInfo productInfo) async {
    try {
      debugPrint('🛒 商品情報処理開始: ${productInfo.name}');

      // データプロバイダーを取得
      final dataProvider = context.read<DataProvider>();

      // 商品情報からItemオブジェクトを作成（バーコードスキャンは価格0で追加）
      final item = Item(
        id: '', // IDはDataProviderで生成されるため空
        name: productInfo.name,
        quantity: 1,
        price: 0, // バーコードスキャンは価格0で追加（参考価格は表示のみ）
        shopId: widget.shop.id,
        timestamp: DateTime.now(),
        isReferencePrice: true, // バーコードスキャンは常に参考価格として扱う
        janCode: productInfo.janCode,
        productUrl: productInfo.url,
        imageUrl: productInfo.imageUrl,
        storeName: productInfo.storeName,
      );

      // データプロバイダーに追加
      await dataProvider.addItem(item);

      if (!mounted) return;

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${productInfo.name} を追加しました'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      debugPrint('✅ 商品情報追加完了');
    } catch (e) {
      debugPrint('❌ 商品情報処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('商品情報の追加に失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
