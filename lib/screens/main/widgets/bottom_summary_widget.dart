import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/shop.dart';
import '../../../models/ocr_session_result.dart';
import '../../ocr_result_confirm_screen.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import '../../../services/hybrid_ocr_service.dart';
import '../../../ad/interstitial_ad_service.dart';
import '../../../drawer/settings/settings_persistence.dart';
import '../../../widgets/image_analysis_progress_dialog.dart';
import '../../enhanced_camera_screen.dart';

/// ボトムサマリーウィジェット
/// 予算表示、合計金額表示、カメラ撮影、アイテム追加ボタンを含む
class BottomSummaryWidget extends StatefulWidget {
  final Shop shop;
  final VoidCallback onBudgetClick;
  final VoidCallback onFab;

  const BottomSummaryWidget({
    super.key,
    required this.shop,
    required this.onBudgetClick,
    required this.onFab,
  });

  @override
  State<BottomSummaryWidget> createState() => _BottomSummaryWidgetState();
}

class _BottomSummaryWidgetState extends State<BottomSummaryWidget> {
  String? _currentShopId;
  int? _cachedTotal;
  int? _cachedBudget;
  bool? _cachedSharedMode;
  int? _cachedCurrentTabTotal;
  bool _cacheInitialized = false;
  String? _cachedSharedGroupId;

  // ハイブリッドOCRサービス
  final HybridOcrService _hybridOcrService = HybridOcrService();

  @override
  void initState() {
    super.initState();
    _refreshData();

    // ハイブリッドOCRサービスの初期化
    _initializeHybridOcr();
  }

  /// ハイブリッドOCRサービスの初期化
  Future<void> _initializeHybridOcr() async {
    try {
      await _hybridOcrService.initialize();
    } catch (e) {
      debugPrint('❌ ハイブリッドOCR初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    // ハイブリッドOCRサービスの破棄
    _hybridOcrService.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BottomSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id) {
      _refreshData();
    }
  }

  void _refreshData() {
    final String shopId = widget.shop.id;
    final String? sharedGroupId = widget.shop.sharedGroupId;
    _getAllSummaryData().then((data) {
      if (mounted) {
        if (shopId != widget.shop.id) return;
        if (sharedGroupId != widget.shop.sharedGroupId) return;

        setState(() {
          _cachedTotal = data['total'] as int;
          _cachedBudget = data['budget'] as int?;
          _cachedSharedMode = data['isSharedMode'] as bool;
          _cachedCurrentTabTotal = data['currentTabTotal'] as int?;
          _cachedSharedGroupId = sharedGroupId;
          _cacheInitialized = true;
        });
      }
    });
  }

  // 現在のショップの即座の合計を計算
  int _calculateCurrentShopTotal() {
    int total = 0;
    for (final item in widget.shop.items.where((e) => e.isChecked)) {
      final price = (item.price * (1 - item.discount)).round();
      total += price * item.quantity;
    }
    return total;
  }

  // 全てのサマリーデータを一度に取得
  Future<Map<String, dynamic>> _getAllSummaryData() async {
    try {
      // 共有グループモードの場合
      if (widget.shop.sharedGroupId != null) {
        final dataProvider = context.read<DataProvider>();
        final sharedTotal =
            await dataProvider.getSharedGroupTotal(widget.shop.sharedGroupId!);
        final sharedBudget =
            dataProvider.getSharedGroupBudget(widget.shop.sharedGroupId!);

        return {
          'total': sharedTotal,
          'currentTabTotal': _calculateCurrentShopTotal(),
          'budget': sharedBudget,
          'isSharedMode': true,
        };
      } else {
        // 個別モードの場合
        final total = _calculateCurrentShopTotal();
        final budget =
            await SettingsPersistence.loadTabBudget(widget.shop.id) ??
                widget.shop.budget;

        return {
          'total': total,
          'currentTabTotal': null,
          'budget': budget,
          'isSharedMode': false,
        };
      }
    } catch (e) {
      debugPrint('❌ サマリーデータ取得エラー: $e');
      return {
        'total': _calculateCurrentShopTotal(),
        'currentTabTotal': null,
        'budget': widget.shop.budget,
        'isSharedMode': false,
      };
    }
  }

  Future<void> _onImageAnalyzePressed() async {
    try {
      debugPrint('📷 統合カメラ画面で追加フロー開始');

      // 値札撮影カメラ画面を表示
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => EnhancedCameraScreen(
            onImageCaptured: (File image) {
              Navigator.of(context).pop({'type': 'image', 'data': image});
            },
          ),
        ),
      );

      if (result == null) {
        debugPrint('ℹ️ カメラをキャンセルしました');
        return;
      }

      if (!mounted) return;

      // 値札撮影結果の処理
      if (result['type'] == 'image') {
        final imageFile = result['data'] as File;
        await _handleImageCaptured(imageFile);
      }
    } catch (e) {
      debugPrint('❌ カメラ処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 値札撮影結果の処理
  Future<void> _handleImageCaptured(File imageFile) async {
    try {
      debugPrint('📸 値札画像処理開始');
      // 広告がWebViewレンダラーを使用しているため、OCR実行中は
      // インタースティシャル広告リソースを解放して競合を避ける
      try {
        InterstitialAdService().dispose();
      } catch (_) {}

      // 改善されたローディングダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ImageAnalysisProgressDialog(),
      );

      // Cloud Functionsのみを使用した高速OCR解析
      var res = await _hybridOcrService.detectItemFromImageFast(
        imageFile,
        onProgress: (step, message) {
          debugPrint('📊 OCR進行状況(Cloud Functions): $step - $message');
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // ローディング閉じる

      // OCR完了後は広告サービスを再初期化（非同期で安全に）
      try {
        InterstitialAdService().resetSession();
      } catch (_) {}

      if (res == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: const Text('読み取りに失敗しました'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
        return;
      }

      // OCR結果からOcrSessionResultを作成
      final ocrResult = OcrSessionResult(
        items: [
          OcrSessionResultItem(
            id: const Uuid().v4(),
            name: res.name,
            price: res.price,
            quantity: 1,
          ),
        ],
        createdAt: DateTime.now(),
      );

      // OCR結果確認画面に遷移
      // OCR結果確認画面をダイアログで表示
      final saveResult = await OcrResultConfirmScreen.show(
        context,
        ocrResult: ocrResult,
        currentShopId: widget.shop.id,
      );

      if (!mounted) return;

      // 保存結果に応じてメッセージを表示
      if (saveResult != null && saveResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saveResult.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ 値札画像処理完了');
    } catch (e) {
      debugPrint('❌ 値札画像処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('値札の読み取りに失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 即座の計算値を使用
    final instantTotal = _calculateCurrentShopTotal();

    // キャッシュが初期化されていない場合は即座の計算値を使用
    final total =
        _cacheInitialized ? (_cachedTotal ?? instantTotal) : instantTotal;
    final budget = _cacheInitialized ? _cachedBudget : widget.shop.budget;
    final isSharedMode =
        _cacheInitialized ? (_cachedSharedMode ?? false) : false;
    final currentTabTotal = _cacheInitialized ? _cachedCurrentTabTotal : null;

    // 予算関連の計算
    final over = budget != null && total > budget;
    final remainingBudget = budget != null ? budget - total : null;
    final isNegative = remainingBudget != null && remainingBudget < 0;

    // ショップIDが変わった場合はデータを非同期で再取得
    if (_currentShopId != widget.shop.id ||
        _cachedSharedGroupId != widget.shop.sharedGroupId) {
      _currentShopId = widget.shop.id;
      _cacheInitialized = false;
      _refreshData();
    }

    return _buildSummaryContent(
      total,
      budget,
      over,
      remainingBudget,
      isNegative,
      isSharedMode,
      currentTabTotal,
    );
  }

  Widget _buildSummaryContent(
    int total,
    int? budget,
    bool over,
    int? remainingBudget,
    bool isNegative,
    bool isSharedMode,
    int? currentTabTotal,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // アクションボタン（予算変更、カメラ、追加）
          Row(
            children: [
              // 予算変更ボタン
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: widget.onBudgetClick,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(80, 40),
                    ),
                    child: const Text(
                      '予算変更',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              // カメラで追加ボタン
              ElevatedButton.icon(
                onPressed: _onImageAnalyzePressed,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text(
                  'カメラで追加',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(90, 40),
                ),
              ),
              // 追加ボタン
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton(
                    onPressed: widget.onFab,
                    mini: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 2,
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 予算・合計表示エリア
          AnimatedBuilder(
            animation: themeNotifier,
            builder: (context, _) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // 左側の表示（予算情報）
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget != null
                                    ? (isSharedMode ? '共有残り予算' : '残り予算')
                                    : (isSharedMode ? '共有予算' : '予算'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                budget != null
                                    ? '¥${remainingBudget.toString()}'
                                    : '未設定',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: budget != null && isNegative
                                      ? theme.colorScheme.error
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (over)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SizedBox(
                                        width: constraints.maxWidth,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '⚠ 予算を超えています！',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // 区切り線
                        Container(
                          width: 1,
                          height: 60,
                          color: Theme.of(context).dividerColor,
                        ),
                        // 右側の表示（合計金額）
                        Expanded(
                          child: isSharedMode && currentTabTotal != null
                              ? _buildSharedModeTotalDisplay(
                                  isDark, currentTabTotal, total)
                              : _buildSingleModeTotalDisplay(isDark, total),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// 共有モードの合計表示
  Widget _buildSharedModeTotalDisplay(
      bool isDark, int currentTabTotal, int total) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1行目: 現在のタブの合計
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '現在のタブ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '¥$currentTabTotal',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 2行目: 共有グループ全体の合計
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '共有合計',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '¥$total',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 通常モードの合計表示
  Widget _buildSingleModeTotalDisplay(bool isDark, int total) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '合計金額',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¥$total',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
