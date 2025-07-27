import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../widgets/item_row.dart';
import '../widgets/bottom_summary.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/upcoming_features_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // 未使用のため削除
import '../providers/data_provider.dart'; // DataProviderをインポート
import '../widgets/ad_banner.dart'; // AdBannerをインポート

// _MainScreenStateから切り出されたUI部分
class MainScreenBody extends StatefulWidget {
  final bool isLoading;
  final List<Shop> shops;
  final String currentTheme;
  final double currentFontSize;
  final Map<String, Color> customColors;
  final Function showAddTabDialog;
  final Function(int, List<Shop>) showTabEditDialog;
  final void Function(bool) showSortDialog; // 型を修正
  final int Function(Shop) calcTotal;
  final void Function({Item? original, required Shop shop})
  showItemEditDialog; // 名前付きパラメータを受け入れるように変更
  final Function(Shop) showBudgetDialog;
  final SortMode incSortMode;
  final SortMode comSortMode;
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
    required this.currentFontSize,
    required this.customColors,
    required this.showAddTabDialog,
    required this.showTabEditDialog,
    required this.showSortDialog,
    required this.calcTotal,
    required this.showItemEditDialog,
    required this.showBudgetDialog,
    required this.incSortMode,
    required this.comSortMode,
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

class _MainScreenBodyState extends State<MainScreenBody>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.shops.length,
      vsync: this,
      initialIndex: widget.shops.isEmpty ? 0 : widget.selectedTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        widget.onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MainScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shops.length != oldWidget.shops.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: widget.shops.length,
        vsync: this,
        initialIndex: widget.shops.isEmpty ? 0 : widget.selectedTabIndex,
      );
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          widget.onTabChanged(_tabController.index);
        }
      });
    } else if (widget.selectedTabIndex != oldWidget.selectedTabIndex) {
      _tabController.index = widget.selectedTabIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 読み込み中の場合はローディング表示
    if (widget.isLoading) {
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

    if (widget.shops.isEmpty) {
      return Scaffold(
        backgroundColor: widget.theme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: widget.theme.colorScheme.primary.withAlpha(
                  (255 * 0.5).round(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ショップがありません',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: widget.currentTheme == 'dark'
                      ? Colors.white
                      : widget.theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'タブを追加してショッピングリストを作成しましょう',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.currentTheme == 'dark'
                      ? Colors.white.withAlpha((255 * 0.7).round())
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => widget.showAddTabDialog(),
                icon: const Icon(Icons.add),
                label: const Text('ショップを追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.theme.colorScheme.primary,
                  foregroundColor: Colors.white,
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
        : widget.shops[_tabController.index.clamp(0, widget.shops.length - 1)];

    // アイテムの分類とソートを一度だけ実行
    final incItems = shop?.items.where((e) => !e.isChecked).toList() ?? []
      ..sort(comparatorFor(widget.incSortMode));
    final comItems = shop?.items.where((e) => e.isChecked).toList() ?? []
      ..sort(comparatorFor(widget.comSortMode));

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
                final isSelected = index == _tabController.index;

                return GestureDetector(
                  onLongPress: () {
                    widget.showTabEditDialog(index, widget.shops);
                  },
                  onTap: () {
                    setState(() {
                      _tabController.index = index;
                    });
                    widget.onTabChanged(index);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (widget.currentTheme == 'custom' &&
                                    widget.customColors.containsKey('tabColor')
                                ? widget.customColors['tabColor']
                                : (widget.currentTheme == 'light'
                                      ? Color(0xFF757575)
                                      : widget.theme.colorScheme.primary))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (widget.currentTheme == 'dark'
                                  ? Colors.white.withAlpha((255 * 0.3).round())
                                  : Colors.grey.withAlpha((255 * 0.3).round())),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    (widget.currentTheme == 'custom' &&
                                                widget.customColors.containsKey(
                                                  'tabColor',
                                                )
                                            ? widget.customColors['tabColor']!
                                            : (widget.currentTheme == 'light'
                                                  ? Color(0xFF757575)
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
            tooltip: 'タブ追加',
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
                      currentFont:
                          widget.theme.textTheme.bodyLarge?.fontFamily ??
                          'Roboto',
                      currentFontSize: widget.currentFontSize,
                      onThemeChanged: widget.onThemeChanged,
                      onFontChanged: widget.onFontChanged,
                      onFontSizeChanged: widget.onFontSizeChanged,
                      onCustomThemeChanged: widget.onCustomThemeChanged,
                      onDarkModeChanged: widget.onDarkModeChanged,
                      customColors: widget.customColors,
                      isDarkMode: widget.theme.brightness == Brightness.dark,
                      theme: widget.theme,
                    ),
                  ),
                );
              },
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
          ],
        ),
      ),
      body: Column(
        children: [
          // 既存のリストUI
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '未完了',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              (widget.currentTheme == 'dark' ||
                                  widget.currentTheme == 'light')
                              ? Colors.white
                              : widget.theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sort),
                        onPressed: () {
                          widget.showSortDialog(true);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: incItems.isEmpty
                        ? Center(
                            child: Text(
                              '未完了アイテムはありません',
                              style: TextStyle(
                                color:
                                    (widget.currentTheme == 'dark' ||
                                        widget.currentTheme == 'light')
                                    ? Colors.white
                                    : widget.theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: incItems.length,
                            addAutomaticKeepAlives: false,
                            cacheExtent: 100,
                            itemBuilder: (context, idx) {
                              final item = incItems[idx];
                              return ItemRow(
                                item: item,
                                onCheckToggle: (checked) async {
                                  if (shop == null) return;
                                  final dataProvider = context
                                      .read<DataProvider>();
                                  final shopIndex = dataProvider.shops.indexOf(
                                    shop,
                                  );
                                  if (shopIndex != -1) {
                                    final updatedItems = shop.items.map((
                                      shopItem,
                                    ) {
                                      return shopItem.id == item.id
                                          ? item.copyWith(isChecked: checked)
                                          : shopItem;
                                    }).toList();
                                    final updatedShop = shop.copyWith(
                                      items: updatedItems,
                                    );
                                    dataProvider.shops[shopIndex] = updatedShop;
                                  }

                                  try {
                                    await context
                                        .read<DataProvider>()
                                        .updateItem(
                                          item.copyWith(isChecked: checked),
                                        );
                                  } catch (e) {
                                    if (shopIndex != -1) {
                                      final revertedItems = shop.items.map((
                                        shopItem,
                                      ) {
                                        return shopItem.id == item.id
                                            ? item.copyWith(isChecked: !checked)
                                            : shopItem;
                                      }).toList();
                                      final revertedShop = shop.copyWith(
                                        items: revertedItems,
                                      );
                                      dataProvider.shops[shopIndex] =
                                          revertedShop;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
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
                                  final dataProvider = context
                                      .read<DataProvider>();
                                  final shopIndex = dataProvider.shops.indexOf(
                                    shop,
                                  );
                                  if (shopIndex != -1) {
                                    final updatedItems = shop.items
                                        .where(
                                          (shopItem) => shopItem.id != item.id,
                                        )
                                        .toList();
                                    final updatedShop = shop.copyWith(
                                      items: updatedItems,
                                    );
                                    dataProvider.shops[shopIndex] = updatedShop;
                                  }

                                  try {
                                    await context
                                        .read<DataProvider>()
                                        .deleteItem(item.id);
                                  } catch (e) {
                                    if (shopIndex != -1) {
                                      final revertedItems = [
                                        ...shop.items,
                                        item,
                                      ];
                                      final revertedShop = shop.copyWith(
                                        items: revertedItems,
                                      );
                                      dataProvider.shops[shopIndex] =
                                          revertedShop;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '完了済み',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.currentTheme == 'dark'
                              ? Colors.white
                              : widget.theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sort),
                        onPressed: () {
                          widget.showSortDialog(false);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: comItems.isEmpty
                        ? Center(
                            child: Text(
                              '完了済みアイテムはありません',
                              style: TextStyle(
                                color: widget.currentTheme == 'dark'
                                    ? Colors.white
                                    : widget.theme.colorScheme.onSurface,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: comItems.length,
                            addAutomaticKeepAlives: false,
                            cacheExtent: 100,
                            itemBuilder: (context, idx) {
                              final item = comItems[idx];
                              return ItemRow(
                                item: item,
                                onCheckToggle: (checked) async {
                                  if (shop == null) return;
                                  final dataProvider = context
                                      .read<DataProvider>();
                                  final shopIndex = dataProvider.shops.indexOf(
                                    shop,
                                  );
                                  if (shopIndex != -1) {
                                    final updatedItems = shop.items.map((
                                      shopItem,
                                    ) {
                                      return shopItem.id == item.id
                                          ? item.copyWith(isChecked: checked)
                                          : shopItem;
                                    }).toList();
                                    final updatedShop = shop.copyWith(
                                      items: updatedItems,
                                    );
                                    dataProvider.shops[shopIndex] = updatedShop;
                                  }

                                  try {
                                    await context
                                        .read<DataProvider>()
                                        .updateItem(
                                          item.copyWith(isChecked: checked),
                                        );
                                  } catch (e) {
                                    if (shopIndex != -1) {
                                      final revertedItems = shop.items.map((
                                        shopItem,
                                      ) {
                                        return shopItem.id == item.id
                                            ? item.copyWith(isChecked: !checked)
                                            : shopItem;
                                      }).toList();
                                      final revertedShop = shop.copyWith(
                                        items: revertedItems,
                                      );
                                      dataProvider.shops[shopIndex] =
                                          revertedShop;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                onEdit: null,
                                onDelete: () async {
                                  if (shop == null) return;
                                  final dataProvider = context
                                      .read<DataProvider>();
                                  final shopIndex = dataProvider.shops.indexOf(
                                    shop,
                                  );
                                  if (shopIndex != -1) {
                                    final updatedItems = shop.items
                                        .where(
                                          (shopItem) => shopItem.id != item.id,
                                        )
                                        .toList();
                                    final updatedShop = shop.copyWith(
                                      items: updatedItems,
                                    );
                                    dataProvider.shops[shopIndex] = updatedShop;
                                  }

                                  try {
                                    await context
                                        .read<DataProvider>()
                                        .deleteItem(item.id);
                                  } catch (e) {
                                    if (shopIndex != -1) {
                                      final revertedItems = [
                                        ...shop.items,
                                        item,
                                      ];
                                      final revertedShop = shop.copyWith(
                                        items: revertedItems,
                                      );
                                      dataProvider.shops[shopIndex] =
                                          revertedShop;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                showEdit: false,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const AdBanner(), // バナー広告を追加
        ],
      ),
      bottomNavigationBar: shop != null
          ? BottomSummary(
              total: widget.calcTotal(shop),
              budget: shop.budget,
              onBudgetClick: () => widget.showBudgetDialog(shop),
              onFab: () => widget.showItemEditDialog(shop: shop),
            )
          : null,
      // floatingActionButtonは削除
    );
  }

  // ソートモードの比較関数（main_screen.dartから移動）
  int Function(Item, Item) comparatorFor(SortMode mode) {
    switch (mode) {
      case SortMode.jaAsc:
        return (a, b) => a.name.compareTo(b.name);
      case SortMode.jaDesc:
        return (a, b) => b.name.compareTo(a.name);
      case SortMode.priceAsc:
        return (a, b) => a.price.compareTo(b.price);
      case SortMode.priceDesc:
        return (a, b) => b.price.compareTo(a.price);
      case SortMode.qtyAsc:
        return (a, b) => a.quantity.compareTo(b.quantity);
      case SortMode.qtyDesc:
        return (a, b) => b.quantity.compareTo(a.quantity);
      default:
        return (a, b) => 0;
    }
  }
}
