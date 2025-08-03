import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/shop.dart';
import '../providers/data_provider.dart';
import '../screens/settings_persistence.dart';
import 'dart:async';

class BottomSummary extends StatefulWidget {
  final Shop shop;
  final VoidCallback onBudgetClick;
  final VoidCallback onFab;
  const BottomSummary({
    super.key,
    required this.shop,
    required this.onBudgetClick,
    required this.onFab,
  });

  @override
  State<BottomSummary> createState() => _BottomSummaryState();
}

class _BottomSummaryState extends State<BottomSummary> {
  String? _currentShopId;
  int? _cachedTotal;
  int? _cachedBudget;
  bool? _cachedSharedMode;
  StreamSubscription<Map<String, dynamic>>? _sharedDataSubscription;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _setupSharedDataListener();
  }

  /// 共有データ変更の監視を開始
  void _setupSharedDataListener() {
    _sharedDataSubscription = DataProvider.sharedDataStream.listen((data) {
      debugPrint('BottomSummary: 共有データ変更通知を受信: $data');

      if (!mounted) return;

      final type = data['type'] as String?;
      if (type == 'total_updated') {
        final newTotal = data['sharedTotal'] as int?;
        if (newTotal != null) {
          _refreshDataForSharedUpdate(newTotal: newTotal);
        }
      } else if (type == 'budget_updated') {
        final newBudget = data['sharedBudget'] as int?;
        _refreshDataForSharedUpdate(newBudget: newBudget);
      } else if (type == 'individual_budget_updated') {
        final shopId = data['shopId'] as String?;
        final newBudget = data['budget'] as int?;
        if (shopId == widget.shop.id) {
          _refreshDataForIndividualUpdate(newBudget: newBudget);
        }
      } else if (type == 'individual_total_updated') {
        final shopId = data['shopId'] as String?;
        final newTotal = data['total'] as int?;
        if (shopId == widget.shop.id && newTotal != null) {
          _refreshDataForIndividualUpdate(newTotal: newTotal);
        }
      }
    });
  }

  @override
  void didUpdateWidget(BottomSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    _sharedDataSubscription?.cancel();
    super.dispose();
  }

  void _refreshData() {
    _getAllSummaryData().then((data) {
      if (mounted) {
        setState(() {
          _cachedTotal = data['total'] as int;
          _cachedBudget = data['budget'] as int?;
          _cachedSharedMode = data['isSharedMode'] as bool;
        });
      }
    });
  }

  /// 共有データ更新専用のリフレッシュ（非同期処理なしで即座更新）
  void _refreshDataForSharedUpdate({int? newTotal, int? newBudget}) async {
    if (!mounted) return;

    final isSharedMode = await SettingsPersistence.loadBudgetSharingEnabled();
    if (!isSharedMode) return; // 共有モードでない場合は無視

    debugPrint(
      'BottomSummary: 共有データ更新専用リフレッシュ - total: $newTotal, budget: $newBudget',
    );

    setState(() {
      if (newTotal != null) {
        _cachedTotal = newTotal;
      }
      if (newBudget != null) {
        _cachedBudget = newBudget;
      }
      _cachedSharedMode = true;
    });
  }

  /// 個別データ更新専用のリフレッシュ（非同期処理なしで即座更新）
  void _refreshDataForIndividualUpdate({int? newBudget, int? newTotal}) {
    if (!mounted) return;

    debugPrint(
      'BottomSummary: 個別データ更新専用リフレッシュ - budget: $newBudget, total: $newTotal',
    );

    setState(() {
      if (newBudget != null) {
        _cachedBudget = newBudget;
      }
      if (newTotal != null) {
        _cachedTotal = newTotal;
      }
      _cachedSharedMode = false;
    });
  }

  // 現在のショップの即座の合計を計算
  int _calculateCurrentShopTotal() {
    int total = 0;
    for (final item in widget.shop.items.where((e) => e.isChecked)) {
      final price = (item.price * (1 - item.discount)).round();
      total += price * item.quantity;
    }
    debugPrint(
      '_calculateCurrentShopTotal: $total (チェック済みアイテム数: ${widget.shop.items.where((e) => e.isChecked).length})',
    );
    return total;
  }

  // 全てのサマリーデータを一度に取得
  Future<Map<String, dynamic>> _getAllSummaryData() async {
    try {
      final isSharedMode = await SettingsPersistence.loadBudgetSharingEnabled();
      debugPrint('=== _getAllSummaryData ===');
      debugPrint('合計金額・予算取得開始: 共有モード=$isSharedMode, ショップ=${widget.shop.id}');

      int total;
      int? budget;

      if (isSharedMode) {
        // 共有モードの場合
        final results = await Future.wait([
          SettingsPersistence.loadSharedTotal(),
          SettingsPersistence.loadSharedBudget(),
        ]);
        total = results[0] ?? 0;
        budget = results[1];
        debugPrint('共有データ取得完了: total=$total, budget=$budget');
      } else {
        // 個別モードの場合
        total = _calculateCurrentShopTotal();
        budget =
            await SettingsPersistence.loadTabBudget(widget.shop.id) ??
            widget.shop.budget;
        debugPrint('個別データ取得完了: total=$total, budget=$budget');
      }

      return {'total': total, 'budget': budget, 'isSharedMode': isSharedMode};
    } catch (e) {
      debugPrint('_getAllSummaryData エラー: $e');
      return {
        'total': _calculateCurrentShopTotal(),
        'budget': widget.shop.budget,
        'isSharedMode': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        // ショップが変更された場合、IDを更新
        if (_currentShopId != widget.shop.id) {
          _currentShopId = widget.shop.id;
          _refreshData(); // データを再取得
        }

        // キャッシュされたデータがあるかチェック
        int displayTotal;
        int? budget;
        bool isSharedMode = false;

        if (_cachedTotal != null &&
            _cachedBudget != null &&
            _cachedSharedMode != null) {
          // キャッシュされたデータを使用
          displayTotal = _cachedTotal!;
          budget = _cachedBudget;
          isSharedMode = _cachedSharedMode!;
          debugPrint(
            'BottomSummary: キャッシュデータ使用: total=$displayTotal, budget=$budget, 共有モード=$isSharedMode',
          );
        } else {
          // キャッシュがない場合は即座計算値を使用
          displayTotal = _calculateCurrentShopTotal();
          budget = widget.shop.budget;
          debugPrint(
            'BottomSummary: キャッシュなし、即座計算値を使用: total=$displayTotal, budget=$budget',
          );
        }

        final over = budget != null && displayTotal > budget;
        final remainingBudget = budget != null ? budget - displayTotal : null;
        final isNegative = remainingBudget != null && remainingBudget < 0;

        return _buildSummaryContent(
          context,
          displayTotal,
          budget,
          over,
          remainingBudget,
          isNegative,
          isSharedMode,
        );
      },
    );
  }

  Widget _buildSummaryContent(
    BuildContext context,
    int total,
    int? budget,
    bool over,
    int? remainingBudget,
    bool isNegative,
    bool isSharedMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: widget.onBudgetClick,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                ),
                child: const Text('予算変更'),
              ),
              const SizedBox(width: 8),
              if (over)
                Expanded(
                  child: Text(
                    '⚠ 予算を超えています！',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!over) Expanded(child: Container()),
              FloatingActionButton(
                onPressed: widget.onFab,
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 2,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: themeNotifier,
            builder: (context, _) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
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
                        // 左側の表示（予算情報またはプレースホルダー）
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    budget != null
                                        ? (isSharedMode ? '共有残り予算' : '残り予算')
                                        : (isSharedMode ? '共有予算' : '予算'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  if (isSharedMode && budget != null)
                                    Text(
                                      '全ショッピング共通',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black38,
                                            fontSize: 10,
                                          ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                budget != null
                                    ? '¥${remainingBudget.toString()}'
                                    : '未設定',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: budget != null && isNegative
                                          ? Theme.of(context).colorScheme.error
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black87),
                                      fontWeight: FontWeight.bold,
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
                        // 合計金額表示
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '合計金額',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '¥$total',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
