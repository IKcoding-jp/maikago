import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../widgets/item_row.dart';
import '../widgets/bottom_summary.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'upcoming_features_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';

class MainScreen extends StatefulWidget {
  final void Function(ThemeData)? onThemeChanged;
  final void Function(String)? onFontChanged;
  const MainScreen({super.key, this.onThemeChanged, this.onFontChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int selectedTabIndex = 0;
  String currentTheme = 'pink';
  String currentFont = 'nunito'; // 初期値
  Map<String, Color> customColors = {
    'primary': Color(0xFFFFB6C1),
    'secondary': Color(0xFFB5EAD7),
    'surface': Color(0xFFFFF1F8),
  };
  String nextShopId = '1';
  String nextItemId = '0';
  SortMode incSortMode = SortMode.jaAsc;
  SortMode comSortMode = SortMode.jaAsc;
  bool includeTax = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // グローバルフォント設定を読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // フォント設定は親から渡されるため、ここでは初期化のみ
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ThemeData getCustomTheme() {
    Color primary, secondary, surface;
    Color onPrimary;
    Color onSurface;

    if (currentTheme == 'custom') {
      primary = customColors['primary']!;
      secondary = customColors['secondary']!;
      surface = customColors['surface']!;
    } else {
      switch (currentTheme) {
        case 'light':
          primary = Color(0xFFFFFFFF); // 白
          secondary = Color(0xFFF5F5F5); // 薄グレー
          surface = Color(0xFFFFFFFF); // 白
          break;
        case 'dark':
          primary = Color(0xFF111111); // 黒
          secondary = Color(0xFF333333); // 濃いグレー
          surface = Color(0xFF111111); // 黒
          break;
        case 'mint':
          primary = Color(0xFFB5EAD7);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE0F7FA);
          break;
        case 'lavender':
          primary = Color(0xFFB39DDB);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF3E5F5);
          break;
        case 'lemon':
          primary = Color(0xFFFFF176);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFFDE7);
          break;
        case 'soda':
          primary = Color(0xFF81D4FA);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE1F5FE);
          break;
        case 'coral':
          primary = Color(0xFFFFAB91);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF3E0);
          break;
        case 'orange':
          primary = Color(0xFFFFC107);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'green':
          primary = Color(0xFF8BC34A);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF1F8E9);
          break;
        case 'blue':
          primary = Color(0xFF2196F3);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE3F2FD);
          break;
        case 'gray':
          primary = Color(0xFF90A4AE);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF5F5F5);
          break;
        case 'beige':
          primary = Color(0xFFFFE0B2);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        default:
          primary = Color(0xFFFFB6C1);
          secondary = Color(0xFFB5EAD7);
          surface = Color(0xFFFFF1F8);
          break;
      }
    }
    // 明度判定で自動切替（primary: AppBarやボタン、surface:背景、両方で判定）
    double primaryLum = primary.computeLuminance();
    double surfaceLum = surface.computeLuminance();
    onPrimary = primaryLum > 0.5 ? Colors.black87 : Colors.white;
    onSurface = surfaceLum > 0.5 ? Colors.black87 : Colors.white;
    TextTheme textTheme;
    switch (currentFont) {
      case 'roboto':
        textTheme = GoogleFonts.robotoTextTheme();
        break;
      case 'sawarabi':
        textTheme = GoogleFonts.sawarabiMinchoTextTheme();
        break;
      default:
        textTheme = GoogleFonts.nunitoTextTheme();
    }
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: isDarkMode ? Colors.black : Colors.white,
        surface: surface,
        onSurface: onSurface,
        // background, onBackgroundは非推奨のため省略
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 現在のテーマからフォント設定を取得
    final currentThemeData = Theme.of(context);
    final currentFontFamily =
        currentThemeData.textTheme.bodyLarge?.fontFamily ?? 'nunito';

    // フォント設定を更新
    if (currentFontFamily != currentFont) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            currentFont = currentFontFamily;
          });
        }
      });
    }

    return _buildMain(context);
  }

  Widget _buildMain(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final shops = dataProvider.shops.isEmpty
            ? [Shop(id: '0', name: 'デフォルト', items: [])]
            : dataProvider.shops;

        // TabControllerの長さを更新
        if (_tabController.length != shops.length) {
          _tabController.dispose();
          _tabController = TabController(length: shops.length, vsync: this);
          _tabController.addListener(() {
            setState(() {});
          });
        }

        final selectedIndex = _tabController.index.clamp(0, shops.length - 1);
        final shop = shops[selectedIndex];
        final incItems = List<Item>.from(shop.items.where((e) => !e.isChecked))
          ..sort(comparatorFor(incSortMode));
        final comItems = List<Item>.from(shop.items.where((e) => e.isChecked))
          ..sort(comparatorFor(comSortMode));

        void showSortDialog({required bool isIncomplete}) {
          showDialog(
            context: context,
            builder: (context) {
              final current = isIncomplete ? incSortMode : comSortMode;
              return AlertDialog(
                title: const Text('並び替え'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: SortMode.values.map((mode) {
                      return ListTile(
                        title: Text(mode.label),
                        trailing: mode == current
                            ? const Icon(Icons.check)
                            : null,
                        enabled: mode != current,
                        onTap: mode == current
                            ? null
                            : () {
                                setState(() {
                                  if (isIncomplete) {
                                    incSortMode = mode;
                                  } else {
                                    comSortMode = mode;
                                  }
                                });
                                Navigator.of(context).pop();
                              },
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              );
            },
          );
        }

        void showItemEditDialog({Item? original}) {
          final nameController = TextEditingController(
            text: original?.name ?? '',
          );
          final qtyController = TextEditingController(
            text: original?.quantity.toString() ?? '',
          );
          final priceController = TextEditingController(
            text: original?.price.toString() ?? '',
          );
          final discountController = TextEditingController(
            text: ((original?.discount ?? 0.0) * 100).round().toString(),
          );
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(original == null ? 'アイテムを追加' : 'アイテムを編集'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: '商品名'),
                      ),
                      TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(labelText: '個数'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: '単価'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: discountController,
                        decoration: const InputDecoration(labelText: '割引(%)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final qty = int.tryParse(qtyController.text) ?? 1;
                      final price = int.tryParse(priceController.text) ?? 0;
                      final discount =
                          (int.tryParse(discountController.text) ?? 0) / 100.0;
                      if (name.isEmpty) return;
                      if (original == null) {
                        // 新しいアイテムを追加
                        final newItem = Item(
                          id: nextItemId,
                          name: name,
                          quantity: qty,
                          price: price,
                          discount: discount,
                        );

                        // DataProviderを使用してクラウドに保存
                        await context.read<DataProvider>().addItem(newItem);

                        // ローカルのshop.itemsにも追加
                        setState(() {
                          shop.items.add(newItem);
                          nextItemId = (int.parse(nextItemId) + 1).toString();
                        });
                      } else {
                        // 既存のアイテムを更新
                        final updatedItem = original.copyWith(
                          name: name,
                          quantity: qty,
                          price: price,
                          discount: discount,
                        );

                        // DataProviderを使用してクラウドに保存
                        await context.read<DataProvider>().updateItem(
                          updatedItem,
                        );

                        // ローカルのshop.itemsも更新
                        setState(() {
                          final idx = shop.items.indexOf(original);
                          shop.items[idx] = updatedItem;
                        });
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        }

        void showAddTabDialog() {
          final controller = TextEditingController();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('新しいタブを追加'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'タブ名'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;

                      final newShop = Shop(
                        id: nextShopId,
                        name: name,
                        items: [],
                      );

                      // DataProviderを使用してクラウドに保存
                      await context.read<DataProvider>().addShop(newShop);

                      setState(() {
                        nextShopId = (int.parse(nextShopId) + 1).toString();
                      });

                      Navigator.of(context).pop();
                    },
                    child: const Text('追加'),
                  ),
                ],
              );
            },
          );
        }

        void showBudgetDialog() {
          final controller = TextEditingController(
            text: shop.budget?.toString() ?? '',
          );
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('予算を設定'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: '金額 (¥)'),
                  keyboardType: TextInputType.number,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final budget = int.tryParse(controller.text);
                      final updatedShop = shop.copyWith(budget: budget);

                      // DataProviderを使用してクラウドに保存
                      await context.read<DataProvider>().updateShop(
                        updatedShop,
                      );

                      Navigator.of(context).pop();
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        }

        void showTabEditDialog(int tabIndex) {
          final controller = TextEditingController(text: shops[tabIndex].name);
          showDialog(
            context: context,
            builder: (context) {
              return Theme(
                data: getCustomTheme(),
                child: AlertDialog(
                  title: const Text('タブ編集'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'タブ名'),
                  ),
                  actions: [
                    if (shops.length > 1)
                      TextButton(
                        onPressed: () async {
                          final shopToDelete = shops[tabIndex];

                          // DataProviderを使用してクラウドから削除
                          await context.read<DataProvider>().deleteShop(
                            shopToDelete.id,
                          );

                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          '削除',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isEmpty) return;

                        final updatedShop = shops[tabIndex].copyWith(
                          name: name,
                        );

                        // DataProviderを使用してクラウドに保存
                        await context.read<DataProvider>().updateShop(
                          updatedShop,
                        );

                        Navigator.of(context).pop();
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
              );
            },
          );
        }

        int calcTotal(Shop currentShop) {
          int total = 0;
          for (final item in currentShop.items.where((e) => e.isChecked)) {
            final price = (item.price * (1 - item.discount)).round();
            total += price * item.quantity;
          }
          return includeTax ? (total * 1.1).round() : total;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          drawer: Drawer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: getCustomTheme().colorScheme.primary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_basket_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'まいカゴ',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_rounded,
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : getCustomTheme().colorScheme.primary,
                  ),
                  title: Text(
                    '設定',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark' ? Colors.white : null,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context); // Pop the Drawer
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          currentTheme: currentTheme,
                          currentFont: currentFont,
                          onThemeChanged: (themeKey) {
                            setState(() {
                              currentTheme = themeKey;
                            });
                            // main.dartのテーマを更新
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCustomTheme());
                            }
                          },
                          onFontChanged: (font) {
                            setState(() {
                              currentFont = font;
                            });
                            if (widget.onFontChanged != null) {
                              widget.onFontChanged!(font);
                            }
                          },
                          onCustomThemeChanged: (colors) {
                            setState(() {
                              customColors = colors;
                            });
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCustomTheme());
                            }
                          },
                          onDarkModeChanged: (isDark) {
                            setState(() {
                              isDarkMode = isDark;
                            });
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCustomTheme());
                            }
                          },
                          customColors: customColors,
                          isDarkMode: isDarkMode,
                          theme: getCustomTheme(),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : getCustomTheme().colorScheme.primary,
                  ),
                  title: Text(
                    'アプリについて',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark' ? Colors.white : null,
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
                    Icons.auto_awesome_rounded,
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : getCustomTheme().colorScheme.primary,
                  ),
                  title: Text(
                    '今後の新機能',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark' ? Colors.white : null,
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
              // 標準TabBarをAppBarなしで上部に配置
              SafeArea(
                top: true,
                bottom: false,
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: currentTheme == 'dark'
                              ? Colors.white
                              : Theme.of(context).iconTheme.color,
                        ),
                        tooltip: 'メニュー',
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                    for (int i = 0; i < shops.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 0,
                          right: 4,
                          top: 8,
                          bottom: 8,
                        ),
                        child: GestureDetector(
                          onLongPress: () {
                            showTabEditDialog(i);
                          },
                          child: ChoiceChip(
                            label: Text(
                              shops[i].name,
                              style: TextStyle(
                                color: currentTheme == 'dark'
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                            selected: _tabController.index == i,
                            selectedColor:
                                currentTheme == 'custom' &&
                                    customColors.containsKey('tabColor')
                                ? customColors['tabColor']
                                : Theme.of(context).colorScheme.primary,
                            backgroundColor:
                                currentTheme == 'custom' &&
                                    customColors.containsKey('tabColor')
                                ? customColors['tabColor']!.withOpacity(0.3)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                            labelStyle: TextStyle(
                              color: _tabController.index == i
                                  ? Colors.white
                                  : (currentTheme == 'custom' &&
                                            customColors.containsKey('tabColor')
                                        ? (customColors['tabColor']!
                                                      .computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.primary),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _tabController.index = i;
                              });
                            },
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color: currentTheme == 'dark'
                            ? Colors.white
                            : Theme.of(context).iconTheme.color,
                      ),
                      onPressed: showAddTabDialog,
                      tooltip: 'タブ追加',
                    ),
                  ],
                ),
              ),
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
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sort),
                            onPressed: () {
                              showSortDialog(isIncomplete: true);
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
                                    color: currentTheme == 'dark'
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: incItems.length,
                                itemBuilder: (context, idx) {
                                  final item = incItems[idx];
                                  return ItemRow(
                                    item: item,
                                    onCheckToggle: (checked) async {
                                      final updatedItem = item.copyWith(
                                        isChecked: checked,
                                      );

                                      // DataProviderを使用してクラウドに保存
                                      await context
                                          .read<DataProvider>()
                                          .updateItem(updatedItem);

                                      // ローカルのshop.itemsも更新
                                      setState(() {
                                        final i = shop.items.indexOf(item);
                                        shop.items[i] = updatedItem;
                                      });
                                    },
                                    onEdit: () {
                                      showItemEditDialog(original: item);
                                    },
                                    onDelete: () async {
                                      // DataProviderを使用してクラウドから削除
                                      await context
                                          .read<DataProvider>()
                                          .deleteItem(item.id);

                                      // ローカルのshop.itemsからも削除
                                      setState(() {
                                        shop.items.remove(item);
                                      });
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
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sort),
                            onPressed: () {
                              showSortDialog(isIncomplete: false);
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
                                    color: currentTheme == 'dark'
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: comItems.length,
                                itemBuilder: (context, idx) {
                                  final item = comItems[idx];
                                  return ItemRow(
                                    item: item,
                                    onCheckToggle: (checked) async {
                                      final updatedItem = item.copyWith(
                                        isChecked: checked,
                                      );

                                      // DataProviderを使用してクラウドに保存
                                      await context
                                          .read<DataProvider>()
                                          .updateItem(updatedItem);

                                      // ローカルのshop.itemsも更新
                                      setState(() {
                                        final i = shop.items.indexOf(item);
                                        shop.items[i] = updatedItem;
                                      });
                                    },
                                    onEdit: null,
                                    onDelete: () async {
                                      // DataProviderを使用してクラウドから削除
                                      await context
                                          .read<DataProvider>()
                                          .deleteItem(item.id);

                                      // ローカルのshop.itemsからも削除
                                      setState(() {
                                        shop.items.remove(item);
                                      });
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
            ],
          ),
          bottomNavigationBar: BottomSummary(
            total: calcTotal(shop),
            budget: shop.budget,
            onBudgetClick: showBudgetDialog,
            onFab: () => showItemEditDialog(),
          ),
          // floatingActionButtonは削除
        );
      },
    );
  }
}
