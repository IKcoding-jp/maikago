import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../widgets/item_row.dart';
import '../widgets/bottom_summary.dart';
import '../widgets/ad_banner.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/upcoming_features_screen.dart';
import '../screens/donation_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/usage_screen.dart';
import '../screens/calculator_screen.dart';
import '../services/interstitial_ad_service.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // 未使用のため削除
import '../providers/data_provider.dart'; // DataProviderをインポート

// _MainScreenStateから切り出されたUI部分
class MainScreenBody extends StatefulWidget {
  final bool isLoading;
  final List<Shop> shops;
  final String currentTheme;
  final String currentFont; // currentFontプロパティを追加
  final double currentFontSize;
  final Map<String, Color> customColors;
  final Function showAddTabDialog;
  final Function(int, List<Shop>) showTabEditDialog;
  final void Function(bool, int) showSortDialog; // 型を修正
  final int Function(Shop) calcTotal;
  final void Function({Item? original, required Shop shop})
  showItemEditDialog; // 名前付きパラメータを受け入れるように変更
  final Function(Shop) showBudgetDialog;
  final Function(Shop, bool) showBulkDeleteDialog;

  final Function(int) onTabChanged;
  final Function(String) onThemeChanged;
  final Function(String) onFontChanged; // これを追加
  final Function(double) onFontSizeChanged;
  final Function(Map<String, Color>) onCustomThemeChanged;
  final Function(bool) onDarkModeChanged;
  final ThemeData theme;
  final int selectedTabIndex; // 選択されたタブのインデックスを追加

  const MainScreenBody({
    super.key,
    required this.isLoading,
    required this.shops,
    required this.currentTheme,
    required this.currentFont, // currentFontを追加
    required this.currentFontSize,
    required this.customColors,
    required this.showAddTabDialog,
    required this.showTabEditDialog,
    required this.showSortDialog,
    required this.calcTotal,
    required this.showItemEditDialog,
    required this.showBudgetDialog,
    required this.showBulkDeleteDialog,

    required this.onTabChanged,
    required this.onThemeChanged,
    required this.onFontChanged,
    required this.onFontSizeChanged,
    required this.onCustomThemeChanged,
    required this.onDarkModeChanged,
    required this.theme,
    required this.selectedTabIndex, // selectedTabIndexを追加
  });

  @override
  State<MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<MainScreenBody> {
  @override
  Widget build(BuildContext context) {
    // データプロバイダーのローディング状態を取得（Consumerで最適化）
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final isDataLoading = dataProvider.isLoading;

        // ローディング中またはデータがまだ読み込まれていない場合
        if (widget.isLoading || isDataLoading || widget.shops.isEmpty) {
          return Scaffold(
            backgroundColor: widget.theme.colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: widget.theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'データを読み込み中...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : widget.theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // shopsが空でないことを確認してからshopを初期化
        final shop = widget.shops.isEmpty
            ? null
            : widget.shops[widget.selectedTabIndex.clamp(
                0,
                widget.shops.length - 1,
              )];

        // アイテムの分類とソートを一度だけ実行
        final incItems = shop?.items.where((e) => !e.isChecked).toList() ?? []
          ..sort(comparatorFor(shop?.incSortMode ?? SortMode.dateNew));
        final comItems = shop?.items.where((e) => e.isChecked).toList() ?? []
          ..sort(comparatorFor(shop?.comSortMode ?? SortMode.dateNew));

        return Scaffold(
          backgroundColor: widget.theme.colorScheme.surface,
          appBar: AppBar(
            title: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.shops.length,
                  itemBuilder: (context, index) {
                    final shop = widget.shops[index];
                    final isSelected = index == widget.selectedTabIndex;

                    return GestureDetector(
                      onLongPress: () {
                        widget.showTabEditDialog(index, widget.shops);
                      },
                      onTap: () {
                        if (widget.shops.isNotEmpty &&
                            index < widget.shops.length) {
                          widget.onTabChanged(index);
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (widget.currentTheme == 'custom' &&
                                        widget.customColors.containsKey(
                                          'tabColor',
                                        )
                                    ? widget.customColors['tabColor']
                                    : (widget.currentTheme == 'light'
                                          ? Color(0xFF9E9E9E)
                                          : widget.currentTheme == 'dark'
                                          ? Colors
                                                .white // ダークテーマでは白色で目立たせる
                                          : widget.theme.colorScheme.primary))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (widget.currentTheme == 'dark'
                                      ? Colors.white.withAlpha(
                                          (255 * 0.3).round(),
                                        )
                                      : Colors.grey.withAlpha(
                                          (255 * 0.3).round(),
                                        )),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        (widget.currentTheme == 'custom' &&
                                                    widget.customColors
                                                        .containsKey('tabColor')
                                                ? widget
                                                      .customColors['tabColor']!
                                                : (widget.currentTheme ==
                                                          'light'
                                                      ? Color(0xFF9E9E9E)
                                                      : widget.currentTheme ==
                                                            'dark'
                                                      ? Colors
                                                            .white // ダークテーマでは白色で目立たせる
                                                      : widget
                                                            .theme
                                                            .colorScheme
                                                            .primary))
                                            .withAlpha((255 * 0.3).round()),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            shop.name,
                            style: TextStyle(
                              color: isSelected
                                  ? (widget.currentTheme == 'light'
                                        ? Colors.black87
                                        : widget.currentTheme == 'dark'
                                        ? Colors
                                              .black87 // ダークテーマでは黒文字で白背景とのコントラストを確保
                                        : Colors.white)
                                  : (widget.currentTheme == 'dark'
                                        ? Colors.white.withAlpha(
                                            (255 * 0.7).round(),
                                          )
                                        : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            backgroundColor: widget.theme.colorScheme.surface,
            foregroundColor: widget.currentTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color:
                      (widget.currentTheme == 'dark' ||
                          widget.currentTheme == 'light')
                      ? Colors.white
                      : Theme.of(context).iconTheme.color,
                ),
                onPressed: () => widget.showAddTabDialog(),
                tooltip: 'ショッピング追加',
              ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: widget.theme.colorScheme.primary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_basket_rounded,
                        size: 48,
                        color: widget.currentTheme == 'lemon'
                            ? Color(0xFF8B6914)
                            : (widget.currentTheme == 'light'
                                  ? Colors.black87
                                  : Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'まいカゴ',
                        style: TextStyle(
                          fontSize: 22,
                          color: widget.currentTheme == 'lemon'
                              ? Color(0xFF8B6914)
                              : (widget.currentTheme == 'light'
                                    ? Colors.black87
                                    : Colors.white),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    'アプリについて',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help_outline_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    '使い方',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsageScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.calculate_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    '簡単電卓',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CalculatorScreen(
                          currentTheme: widget.currentTheme,
                          theme: widget.theme,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.favorite_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    '寄付',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DonationScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    '今後の新機能',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpcomingFeaturesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.feedback_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    'フィードバック',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_rounded,
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : (widget.currentTheme == 'light'
                              ? Colors.black87
                              : widget.theme.colorScheme.primary),
                  ),
                  title: Text(
                    '設定',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.currentTheme == 'dark'
                          ? Colors.white
                          : (widget.currentTheme == 'light'
                                ? Colors.black87
                                : null),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Pop the Drawer
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          currentTheme: widget.currentTheme,
                          currentFont: widget.currentFont, // 正しいフォント設定を渡す
                          currentFontSize: widget.currentFontSize,
                          onThemeChanged: widget.onThemeChanged,
                          onFontChanged: widget.onFontChanged,
                          onFontSizeChanged: widget.onFontSizeChanged,
                          onCustomThemeChanged: widget.onCustomThemeChanged,
                          onDarkModeChanged: widget.onDarkModeChanged,
                          customColors: widget.customColors,
                          isDarkMode:
                              widget.theme.brightness == Brightness.dark,
                          theme: widget.theme,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 0.0),
            child: Row(
              children: [
                // 未完了セクション（左側）
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            Text(
                              '未購入',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: widget.currentTheme == 'dark'
                                    ? Colors.white
                                    : widget.theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: () {
                                widget.showSortDialog(
                                  true,
                                  widget.selectedTabIndex,
                                );
                              },
                              tooltip: '未購入アイテムの並び替え',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep),
                              onPressed: () {
                                if (shop != null) {
                                  widget.showBulkDeleteDialog(shop, true);
                                }
                              },
                              tooltip: '未購入アイテムを一括削除',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: incItems.isEmpty
                              ? Container()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  itemCount: incItems.length,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  addSemanticIndexes: false,
                                  cacheExtent: 50,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (context, idx) {
                                    final item = incItems[idx];
                                    return ItemRow(
                                      item: item,
                                      onCheckToggle: (checked) async {
                                        if (shop == null) return;
                                        debugPrint('アイテムチェック処理開始'); // デバッグ用
                                        debugPrint(
                                          '更新前のショップ予算: ${shop.budget}',
                                        ); // デバッグ用

                                        final dataProvider = context
                                            .read<DataProvider>();
                                        final shopIndex = dataProvider.shops
                                            .indexOf(shop);
                                        if (shopIndex != -1) {
                                          final updatedItems = shop.items.map((
                                            shopItem,
                                          ) {
                                            return shopItem.id == item.id
                                                ? item.copyWith(
                                                    isChecked: checked,
                                                  )
                                                : shopItem;
                                          }).toList();
                                          final updatedShop = shop.copyWith(
                                            items: updatedItems,
                                          );
                                          debugPrint(
                                            'copyWith後のショップ予算: ${updatedShop.budget}',
                                          ); // デバッグ用
                                          dataProvider.shops[shopIndex] =
                                              updatedShop;
                                        }

                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .updateItem(
                                                item.copyWith(
                                                  isChecked: checked,
                                                ),
                                              );
                                        } catch (e) {
                                          if (shopIndex != -1) {
                                            final revertedItems = shop.items
                                                .map((shopItem) {
                                                  return shopItem.id == item.id
                                                      ? item.copyWith(
                                                          isChecked: !checked,
                                                        )
                                                      : shopItem;
                                                })
                                                .toList();
                                            final revertedShop = shop.copyWith(
                                              items: revertedItems,
                                            );
                                            dataProvider.shops[shopIndex] =
                                                revertedShop;
                                          }

                                          if (!context.mounted) {
                                            return; // Change to context.mounted
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onEdit: () {
                                        if (shop != null) {
                                          widget.showItemEditDialog(
                                            original: item,
                                            shop: shop,
                                          );
                                        }
                                      },
                                      onDelete: () async {
                                        if (shop == null) return;

                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .deleteItem(item.id);

                                          // インタースティシャル広告の表示を試行
                                          InterstitialAdService()
                                              .incrementOperationCount();
                                          await InterstitialAdService()
                                              .showAdIfReady();
                                        } catch (e) {
                                          if (!context.mounted) {
                                            return; // Change to context.mounted
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 境界線
                Container(width: 1, color: widget.theme.dividerColor),
                // 完了済みセクション（右側）
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            Text(
                              '購入済み',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: widget.currentTheme == 'dark'
                                    ? Colors.white
                                    : widget.theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: () {
                                widget.showSortDialog(
                                  false,
                                  widget.selectedTabIndex,
                                );
                              },
                              tooltip: '購入済みアイテムの並び替え',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep),
                              onPressed: () {
                                if (shop != null) {
                                  widget.showBulkDeleteDialog(shop, false);
                                }
                              },
                              tooltip: '購入済みアイテムを一括削除',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: comItems.isEmpty
                              ? Container()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  itemCount: comItems.length,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                  addSemanticIndexes: false,
                                  cacheExtent: 50,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (context, idx) {
                                    final item = comItems[idx];
                                    return ItemRow(
                                      item: item,
                                      onCheckToggle: (checked) async {
                                        if (shop == null) return;
                                        debugPrint('購入済みアイテムチェック処理開始'); // デバッグ用
                                        debugPrint(
                                          '更新前のショップ予算: ${shop.budget}',
                                        ); // デバッグ用

                                        final dataProvider = context
                                            .read<DataProvider>();
                                        final shopIndex = dataProvider.shops
                                            .indexOf(shop);
                                        if (shopIndex != -1) {
                                          final updatedItems = shop.items.map((
                                            shopItem,
                                          ) {
                                            return shopItem.id == item.id
                                                ? item.copyWith(
                                                    isChecked: checked,
                                                  )
                                                : shopItem;
                                          }).toList();
                                          final updatedShop = shop.copyWith(
                                            items: updatedItems,
                                          );
                                          debugPrint(
                                            'copyWith後のショップ予算: ${updatedShop.budget}',
                                          ); // デバッグ用
                                          dataProvider.shops[shopIndex] =
                                              updatedShop;
                                        }

                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .updateItem(
                                                item.copyWith(
                                                  isChecked: checked,
                                                ),
                                              );
                                        } catch (e) {
                                          if (shopIndex != -1) {
                                            final revertedItems = shop.items
                                                .map((shopItem) {
                                                  return shopItem.id == item.id
                                                      ? item.copyWith(
                                                          isChecked: !checked,
                                                        )
                                                      : shopItem;
                                                })
                                                .toList();
                                            final revertedShop = shop.copyWith(
                                              items: revertedItems,
                                            );
                                            dataProvider.shops[shopIndex] =
                                                revertedShop;
                                          }

                                          if (!context.mounted) {
                                            return; // Change to context.mounted
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onEdit: () {
                                        if (shop != null) {
                                          widget.showItemEditDialog(
                                            original: item,
                                            shop: shop,
                                          );
                                        }
                                      },
                                      onDelete: () async {
                                        if (shop == null) return;

                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .deleteItem(item.id);

                                          // インタースティシャル広告の表示を試行
                                          InterstitialAdService()
                                              .incrementOperationCount();
                                          await InterstitialAdService()
                                              .showAdIfReady();
                                        } catch (e) {
                                          if (!context.mounted) {
                                            return; // Change to context.mounted
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      showEdit: true,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: shop != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // バナー広告
                    Container(
                      width: double.infinity,
                      color: widget.theme.colorScheme.surface,
                      child: const AdBanner(),
                    ),
                    // ボトムサマリー
                    BottomSummary(
                      shop: shop,
                      onBudgetClick: () => widget.showBudgetDialog(shop),
                      onFab: () => widget.showItemEditDialog(shop: shop),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // バナー広告（ショップがない場合も表示）
                    Container(
                      width: double.infinity,
                      color: widget.theme.colorScheme.surface,
                      child: const AdBanner(),
                    ),
                  ],
                ),
          // floatingActionButtonは削除
        );
      },
    );
  }

  // ソートモードの比較関数（main_screen.dartから移動）
  int Function(Item, Item) comparatorFor(SortMode mode) {
    switch (mode) {
      case SortMode.priceAsc:
        return (a, b) => a.price.compareTo(b.price);
      case SortMode.priceDesc:
        return (a, b) => b.price.compareTo(a.price);
      case SortMode.qtyAsc:
        return (a, b) => a.quantity.compareTo(b.quantity);
      case SortMode.qtyDesc:
        return (a, b) => b.quantity.compareTo(a.quantity);
      case SortMode.dateNew:
        return (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        );
      case SortMode.dateOld:
        return (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
          b.createdAt ?? DateTime.now(),
        );
    }
  }
}
