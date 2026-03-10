import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/ocr_session_result.dart';
import 'package:maikago/screens/ocr_result_confirm_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:maikago/services/hybrid_ocr_service.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/widgets/image_analysis_progress_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:maikago/widgets/recipe_import_bottom_sheet.dart';
import 'package:maikago/widgets/premium_upgrade_dialog.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/utils/snackbar_utils.dart';

/// ボトムサマリーウィジェット
/// 予算表示、合計金額表示、カメラ撮影、アイテム追加ボタンを含む
class BottomSummaryWidget extends StatefulWidget {
  const BottomSummaryWidget({
    super.key,
    required this.shop,
    required this.onBudgetClick,
    required this.onFab,
    this.fabKey,
    this.budgetKey,
  });

  final Shop shop;
  final VoidCallback onBudgetClick;
  final VoidCallback onFab;
  final GlobalKey? fabKey;
  final GlobalKey? budgetKey;

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
  int? _lastItemsHash; // アイテムの変更検出用

  // ハイブリッドOCRサービス
  final HybridOcrService _hybridOcrService = HybridOcrService();

  // DataProviderのリスナー
  DataProvider? _dataProvider;
  VoidCallback? _dataProviderListener;

  @override
  void initState() {
    super.initState();
    _currentShopId = widget.shop.id;
    _lastItemsHash = _calculateItemsHash();
    _refreshData();

    // ハイブリッドOCRサービスの初期化
    _initializeHybridOcr();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // DataProviderのリスナーを設定
    final newDataProvider = context.read<DataProvider>();
    if (_dataProvider != newDataProvider) {
      // 古いリスナーを削除
      if (_dataProvider != null && _dataProviderListener != null) {
        _dataProvider!.removeListener(_dataProviderListener!);
      }
      // 新しいリスナーを設定
      _dataProvider = newDataProvider;
      _dataProviderListener = _onDataProviderChanged;
      _dataProvider!.addListener(_dataProviderListener!);
    }
  }

  void _onDataProviderChanged() {
    // DataProviderの変更を検出してUIをリフレッシュ
    if (mounted) {
      _refreshData();
    }
  }

  /// ハイブリッドOCRサービスの初期化
  Future<void> _initializeHybridOcr() async {
    try {
      await _hybridOcrService.initialize();
    } catch (e) {
      DebugService().logError('ハイブリッドOCR初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    // DataProviderのリスナーを削除
    if (_dataProvider != null && _dataProviderListener != null) {
      _dataProvider!.removeListener(_dataProviderListener!);
    }
    // ハイブリッドOCRサービスの破棄
    _hybridOcrService.dispose();
    super.dispose();
  }

  /// アイテムリストのハッシュを計算（変更検出用）
  int _calculateItemsHash() {
    int hash = 0;
    for (final item in widget.shop.items) {
      hash ^= item.id.hashCode;
      hash ^= item.price.hashCode;
      hash ^= item.quantity.hashCode;
      hash ^= item.discount.hashCode;
      hash ^= item.isChecked.hashCode;
    }
    return hash;
  }

  @override
  void didUpdateWidget(BottomSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool shopIdChanged = oldWidget.shop.id != widget.shop.id;
    final bool sharedGroupIdChanged =
        oldWidget.shop.sharedGroupId != widget.shop.sharedGroupId;
    final bool budgetChanged = oldWidget.shop.budget != widget.shop.budget;
    final int currentItemsHash = _calculateItemsHash();
    final bool itemsChanged = _lastItemsHash != currentItemsHash;

    if (shopIdChanged) {
      // タブ切り替え時: ちらつき防止のため、キャッシュをクリアせず新しいデータを取得
      _currentShopId = widget.shop.id;
      _lastItemsHash = currentItemsHash;
      _refreshData();
    } else if (sharedGroupIdChanged || itemsChanged || budgetChanged) {
      // 同じタブ内でのアイテム変更、共有グループ変更、または予算変更時
      _lastItemsHash = currentItemsHash;
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
          _currentShopId = shopId;
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
            dataProvider.getSharedGroupTotal(widget.shop.sharedGroupId!);
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
      DebugService().logError('サマリーデータ取得エラー: $e');
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
      // OCR使用回数の制限チェック
      final featureControl = context.read<FeatureAccessControl>();
      if (!featureControl.canUseOcr()) {
        await PremiumUpgradeDialog.show(
          context,
          title: 'OCR回数制限',
          message:
              '今月の無料OCR（月${FeatureAccessControl.maxFreeOcrPerMonth}回）を使い切りました。\nプレミアムにアップグレードすると無制限に使えます。',
          onUpgrade: () => context.push('/subscription'),
        );
        return;
      }

      // 値札撮影カメラ画面を表示
      final result = await context.push<Map<String, dynamic>>(
        '/camera',
        extra: {
          'onImageCaptured': (File image) {
            context.pop({'type': 'image', 'data': image});
          },
        },
      );

      if (result == null) {
        return;
      }

      if (!mounted) return;

      // 値札撮影結果の処理
      if (result['type'] == 'image') {
        final imageFile = result['data'] as File;
        await _handleImageCaptured(imageFile);
      }
    } catch (e) {
      DebugService().logError('カメラ処理エラー: $e');
      if (mounted) {
        showErrorSnackBar(context, 'エラーが発生しました: $e');
      }
    }
  }

  /// レシピから追加ボタンが押された際の処理
  void _onRecipeImportPressed() {
    // レシピ解析はプレミアム限定機能
    final featureControl = context.read<FeatureAccessControl>();
    if (!featureControl.canUseRecipeParser()) {
      PremiumUpgradeDialog.show(
        context,
        title: 'プレミアム機能',
        message: 'レシピ解析はプレミアム限定機能です。\nレシピテキストから買い物リストを自動作成できます。',
        onUpgrade: () => context.push('/subscription'),
      );
      return;
    }

    showConstrainedModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecipeImportBottomSheet(),
    );
  }

  /// 値札撮影結果の処理
  Future<void> _handleImageCaptured(File imageFile) async {
    try {
      // 改善されたローディングダイアログを表示
      unawaited(showConstrainedDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ImageAnalysisProgressDialog(),
      ));

      // Cloud Functionsのみを使用した高速OCR解析
      final res = await _hybridOcrService.detectItemFromImageFast(
        imageFile,
      );

      if (!mounted) return;
      context.pop(); // ローディング閉じる

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
        showSuccessSnackBar(context, saveResult.message, duration: const Duration(seconds: 2));
      }

      // OCR成功時にカウンターを増加
      context.read<FeatureAccessControl>().incrementOcrUsage();

    } catch (e) {
      DebugService().logError('値札画像処理エラー: $e');
      if (mounted) {
        showErrorSnackBar(context, '値札の読み取りに失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 即座の計算値を使用（共有モード時は現在のタブのみ計算）
    final instantTotal = _calculateCurrentShopTotal();

    // キャッシュが初期化されていて、現在のショップに対応するキャッシュの場合はキャッシュを使用
    // タブ切り替え時はキャッシュ値を維持してちらつきを防止
    final bool useCache = _cacheInitialized && _currentShopId == widget.shop.id;

    final total = useCache ? (_cachedTotal ?? instantTotal) : instantTotal;
    final budget = useCache ? _cachedBudget : widget.shop.budget;
    final isSharedMode = useCache ? (_cachedSharedMode ?? false) : false;
    final currentTabTotal = useCache ? _cachedCurrentTabTotal : null;

    // 予算関連の計算
    final over = budget != null && total > budget;
    final remainingBudget = budget != null ? budget - total : null;
    final isNegative = remainingBudget != null && remainingBudget < 0;

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
          // アクションボタン（予算変更、カメラ、レシピ、追加）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 予算変更ボタン
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    key: widget.budgetKey,
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
                    child: Text(
                      '予算変更',
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // カメラで追加ボタン（残り回数バッジ付き）
              Consumer<FeatureAccessControl>(
                builder: (context, featureControl, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ElevatedButton(
                        onPressed: _onImageAnalyzePressed,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          elevation: 2,
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 24),
                      ),
                      if (!featureControl.isPremiumUnlocked)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: featureControl.canUseOcr()
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${featureControl.ocrRemainingCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              // レシピから追加ボタン（アイコンのみ）
              ElevatedButton(
                onPressed: _onRecipeImportPressed,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  elevation: 2,
                  padding: const EdgeInsets.all(12),
                  minimumSize: const Size(48, 48),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 24),
              ),
              const SizedBox(width: 12),
              // リスト追加ボタン
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    key: widget.fabKey,
                    onPressed: widget.onFab,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'リスト追加',
                      style: TextStyle(
                        fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 予算・合計表示エリア
          Builder(
            builder: (context) {
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
