import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/shop.dart';
import '../providers/data_provider.dart';
import '../screens/settings_persistence.dart';

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

  // 予算を非同期で取得
  Future<int?> _getCurrentBudget() async {
    try {
      final tabBudget = await SettingsPersistence.getCurrentBudget(
        widget.shop.id,
      );
      debugPrint('タブ別予算を取得: $tabBudget');
      return tabBudget;
    } catch (e) {
      debugPrint('_getCurrentBudget エラー: $e');
      return widget.shop.budget;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        // ショップが変更された場合、IDを更新
        if (_currentShopId != widget.shop.id) {
          _currentShopId = widget.shop.id;
        }

        // 最初に現在のショップの合計を即座に計算
        final immediateTotal = _calculateCurrentShopTotal();

        return FutureBuilder<int>(
          key: ValueKey(
            '${widget.shop.id}_${dataProvider.hashCode}',
          ), // キーでFutureBuilderを強制再構築
          future: dataProvider.getDisplayTotal(widget.shop),
          builder: (context, snapshot) {
            // マウント状態をチェック
            if (!mounted) {
              return Container();
            }

            int displayTotal;

            if (snapshot.connectionState == ConnectionState.waiting) {
              // ローディング中は即座計算値を使用
              displayTotal = immediateTotal;
              debugPrint('BottomSummary: ローディング中、即座計算値を使用: $displayTotal');
            } else if (snapshot.hasData) {
              // データが取得できた場合、その値を使用
              displayTotal = snapshot.data!;
              debugPrint('BottomSummary: データ取得成功: $displayTotal');
            } else {
              // エラーの場合は現在のショップの合計を使用
              displayTotal = immediateTotal;
              debugPrint('BottomSummary: エラー、即座計算値を使用: $displayTotal');
            }

            return FutureBuilder<int?>(
              future: _getCurrentBudget(),
              builder: (context, budgetSnapshot) {
                final budget = budgetSnapshot.data ?? widget.shop.budget;
                debugPrint(
                  'BottomSummary: 予算取得結果: $budget (ショップ予算: ${widget.shop.budget})',
                );

                final over = budget != null && displayTotal > budget;
                final remainingBudget = budget != null
                    ? budget - displayTotal
                    : null;
                final isNegative =
                    remainingBudget != null && remainingBudget < 0;

                return _buildSummaryContent(
                  context,
                  displayTotal,
                  budget,
                  over,
                  remainingBudget,
                  isNegative,
                );
              },
            );
          },
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
                              Text(
                                budget != null ? '残り予算' : '予算',
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
