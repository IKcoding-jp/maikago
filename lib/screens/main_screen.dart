import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final void Function(double)? onFontSizeChanged;
  final ThemeData? globalTheme; // グローバルテーマを受け取る
  const MainScreen({
    super.key,
    this.onThemeChanged,
    this.onFontChanged,
    this.onFontSizeChanged,
    this.globalTheme,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int selectedTabIndex = 0;
  String currentTheme = 'pink';
  String currentFont = 'nunito'; // 初期値
  double currentFontSize = 16.0;
  Map<String, Color> customColors = {
    'primary': Color(0xFFFFB6C1),
    'secondary': Color(0xFFB5EAD7),
    'surface': Color(0xFFFFF1F8),
  };
  Map<String, Color> detailedColors = {
    'appBarColor': Color(0xFFFFB6C1),
    'backgroundColor': Color(0xFFFFF1F8),
    'buttonColor': Color(0xFFFFB6C1),
    'backgroundColor2': Color(0xFFFFF1F8),
    'fontColor1': Colors.black87,
    'fontColor2': Colors.white,
    'iconColor': Color(0xFFFFB6C1),
    'cardBackgroundColor': Colors.white,
    'borderColor': Color(0xFFE0E0E0),
    'dialogBackgroundColor': Colors.white,
    'dialogTextColor': Colors.black87,
    'inputBackgroundColor': Color(0xFFF5F5F5),
    'inputTextColor': Colors.black87,
    'tabColor': Color(0xFFFFB6C1),
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

    // 保存された設定を読み込み
    _loadSavedSettings();
  }

  // 保存された設定を読み込む
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentTheme = prefs.getString('selected_theme') ?? 'pink';
      currentFont = prefs.getString('selected_font') ?? 'nunito';
      currentFontSize = prefs.getDouble('selected_font_size') ?? 16.0;
    });
  }

  // テーマ設定を保存する
  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', currentTheme);
  }

  // フォント設定を保存
  void _saveFontSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_font', currentFont);
    await prefs.setDouble('selected_font_size', currentFontSize);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // グローバルテーマを取得する
  ThemeData getCurrentTheme() {
    return widget.globalTheme ?? Theme.of(context);
  }

  // テーマ色とフォント情報から新しいテーマを作成
  ThemeData _createThemeWithColor(String themeColor, String fontFamily, double fontSize) {
    // テーマ色を設定
    Color primaryColor;
    switch (themeColor) {
      case 'orange':
        primaryColor = Color(0xFFFFC107);
        break;
      case 'green':
        primaryColor = Color(0xFF8BC34A);
        break;
      case 'blue':
        primaryColor = Color(0xFF2196F3);
        break;
      case 'gray':
        primaryColor = Color(0xFF90A4AE);
        break;
      case 'beige':
        primaryColor = Color(0xFFFFE0B2);
        break;
      case 'mint':
        primaryColor = Color(0xFFB5EAD7);
        break;
      case 'lavender':
        primaryColor = Color(0xFFB39DDB);
        break;
      case 'lemon':
        primaryColor = Color(0xFFFFF176);
        break;
      case 'soda':
        primaryColor = Color(0xFF81D4FA);
        break;
      case 'coral':
        primaryColor = Color(0xFFFFAB91);
        break;
      default:
        primaryColor = Color(0xFFFFB6C1); // デフォルトはピンク
    }

    // フォントテーマを設定
    TextTheme textTheme;
    switch (fontFamily) {
      case 'sawarabi':
        textTheme = GoogleFonts.sawarabiMinchoTextTheme();
        break;
      case 'mplus':
        textTheme = GoogleFonts.mPlus1pTextTheme();
        break;
      case 'zenmaru':
        textTheme = GoogleFonts.zenMaruGothicTextTheme();
        break;
      case 'yuseimagic':
        textTheme = GoogleFonts.yuseiMagicTextTheme();
        break;
      case 'yomogi':
        textTheme = GoogleFonts.yomogiTextTheme();
        break;
      default:
        textTheme = GoogleFonts.nunitoTextTheme();
    }

    // フォントサイズを明示的に指定
    textTheme = textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontSize: fontSize + 10),
      displayMedium: textTheme.displayMedium?.copyWith(fontSize: fontSize + 6),
      displaySmall: textTheme.displaySmall?.copyWith(fontSize: fontSize + 2),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: fontSize + 4),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: fontSize + 2),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: fontSize),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: fontSize),
      titleMedium: textTheme.titleMedium?.copyWith(fontSize: fontSize - 2),
      titleSmall: textTheme.titleSmall?.copyWith(fontSize: fontSize - 4),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: fontSize),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: fontSize - 2),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: fontSize - 4),
      labelLarge: textTheme.labelLarge?.copyWith(fontSize: fontSize - 2),
      labelMedium: textTheme.labelMedium?.copyWith(fontSize: fontSize - 4),
      labelSmall: textTheme.labelSmall?.copyWith(fontSize: fontSize - 6),
    );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: Color(0xFFB5EAD7),
        surface: Color(0xFFFFF1F8),
        onPrimary: Colors.white,
        onSurface: Color(0xFF333333),
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );
  }

  // テーマオブジェクトからテーマキーを抽出
  String _extractThemeKey(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    
    // 色の値に基づいてテーマキーを判定
    if (primaryColor.value == Color(0xFFFFC107).value) return 'orange';
    if (primaryColor.value == Color(0xFF8BC34A).value) return 'green';
    if (primaryColor.value == Color(0xFF2196F3).value) return 'blue';
    if (primaryColor.value == Color(0xFF90A4AE).value) return 'gray';
    if (primaryColor.value == Color(0xFFFFE0B2).value) return 'beige';
    if (primaryColor.value == Color(0xFFB5EAD7).value) return 'mint';
    if (primaryColor.value == Color(0xFFB39DDB).value) return 'lavender';
    if (primaryColor.value == Color(0xFFFFF176).value) return 'lemon';
    if (primaryColor.value == Color(0xFF81D4FA).value) return 'soda';
    if (primaryColor.value == Color(0xFFFFAB91).value) return 'coral';
    
    return 'pink'; // デフォルト
  }

  void showAddTabDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '新しいタブを追加',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'タブ名',
              labelStyle: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'キャンセル',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final newShop = Shop(id: nextShopId, name: name, items: []);

                // DataProviderを使用してクラウドに保存
                await context.read<DataProvider>().addShop(newShop);

                setState(() {
                  nextShopId = (int.parse(nextShopId) + 1).toString();
                });

                Navigator.of(context).pop();
              },
              child: Text('追加', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        );
      },
    );
  }

  void showBudgetDialog(Shop shop) {
    final controller = TextEditingController(
      text: shop.budget?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('予算を設定', style: Theme.of(context).textTheme.titleLarge),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: '金額 (¥)',
              labelStyle: Theme.of(context).textTheme.bodyLarge,
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'キャンセル',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final budget = int.tryParse(controller.text);
                final updatedShop = shop.copyWith(budget: budget);

                // DataProviderを使用してクラウドに保存
                await context.read<DataProvider>().updateShop(updatedShop);

                Navigator.of(context).pop();
              },
              child: Text('保存', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        );
      },
    );
  }

  void showTabEditDialog(int tabIndex, List<Shop> shops) {
    final controller = TextEditingController(text: shops[tabIndex].name);
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: getCurrentTheme(),
          child: AlertDialog(
            title: Text('タブ編集', style: Theme.of(context).textTheme.titleLarge),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'タブ名',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
              ),
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
                  child: Text('削除', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'キャンセル',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  final updatedShop = shops[tabIndex].copyWith(name: name);

                  // DataProviderを使用してクラウドに保存
                  await context.read<DataProvider>().updateShop(updatedShop);

                  Navigator.of(context).pop();
                },
                child: Text('保存', style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        );
      },
    );
  }

  void showItemEditDialog({Item? original, required Shop shop}) {
    final nameController = TextEditingController(text: original?.name ?? '');
    final qtyController = TextEditingController(
      text: original?.quantity.toString() ?? '1', // デフォルトで1に設定
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
          title: Text(
            original == null ? 'アイテムを追加' : 'アイテムを編集',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '商品名',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextField(
                  controller: qtyController,
                  decoration: InputDecoration(
                    labelText: '個数',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: '単価',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(
                    labelText: '割引(%)',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'キャンセル',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
                    shopId: shop.id, // ショップIDを設定
                  );

                  // 楽観的更新：DataProviderのshopsリストを即座に更新
                  final dataProvider = context.read<DataProvider>();
                  final shopIndex = dataProvider.shops.indexOf(shop);
                  if (shopIndex != -1) {
                    final updatedShop = shop.copyWith(
                      items: [...shop.items, newItem],
                    );
                    dataProvider.shops[shopIndex] = updatedShop;
                    dataProvider.notifyListeners(); // DataProviderに通知
                    setState(() {
                      nextItemId = (int.parse(nextItemId) + 1).toString();
                    });
                  }

                  // バックグラウンドでDataProviderに保存
                  try {
                    await context.read<DataProvider>().addItem(newItem);
                  } catch (e) {
                    // エラーが発生した場合は追加を取り消し
                    if (shopIndex != -1) {
                      final revertedShop = shop.copyWith(
                        items: shop.items
                            .where((item) => item.id != newItem.id)
                            .toList(),
                      );
                      dataProvider.shops[shopIndex] = revertedShop;
                      dataProvider.notifyListeners(); // DataProviderに通知
                      setState(() {
                        nextItemId = (int.parse(nextItemId) - 1).toString();
                      });
                    }

                    // エラーメッセージを表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  // 既存のアイテムを更新
                  final updatedItem = original.copyWith(
                    name: name,
                    quantity: qty,
                    price: price,
                    discount: discount,
                  );

                  // 楽観的更新：DataProviderのshopsリストを即座に更新
                  final dataProvider = context.read<DataProvider>();
                  final shopIndex = dataProvider.shops.indexOf(shop);
                  if (shopIndex != -1) {
                    final updatedItems = shop.items.map((shopItem) {
                      return shopItem.id == original.id
                          ? updatedItem
                          : shopItem;
                    }).toList();
                    final updatedShop = shop.copyWith(items: updatedItems);
                    dataProvider.shops[shopIndex] = updatedShop;
                    dataProvider.notifyListeners(); // DataProviderに通知
                    setState(() {});
                  }

                  // バックグラウンドでDataProviderを更新
                  try {
                    await context.read<DataProvider>().updateItem(updatedItem);
                  } catch (e) {
                    // エラーが発生した場合は元に戻す
                    if (shopIndex != -1) {
                      final revertedItems = shop.items.map((shopItem) {
                        return shopItem.id == updatedItem.id
                            ? original
                            : shopItem;
                      }).toList();
                      final revertedShop = shop.copyWith(items: revertedItems);
                      dataProvider.shops[shopIndex] = revertedShop;
                      dataProvider.notifyListeners(); // DataProviderに通知
                      setState(() {});
                    }

                    // エラーメッセージを表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text('保存', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMain(context);
  }

  Widget _buildMain(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // 読み込み中の場合はローディング表示
        if (dataProvider.isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: getCurrentTheme().colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'データを読み込み中...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final shops = dataProvider.shops;
        if (shops.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: getCurrentTheme().colorScheme.primary.withOpacity(
                      0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ショップがありません',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'タブを追加してショッピングリストを作成しましょう',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: currentTheme == 'dark'
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: showAddTabDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('ショップを追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getCurrentTheme().colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // TabControllerの長さを更新（必要な場合のみ）
        if (_tabController.length != shops.length) {
          _tabController.dispose();
          _tabController = TabController(length: shops.length, vsync: this);
          _tabController.addListener(() {
            if (mounted) setState(() {});
          });
        }

        final selectedIndex = _tabController.index.clamp(0, shops.length - 1);
        final shop = shops[selectedIndex];

        // アイテムの分類とソートを一度だけ実行
        final incItems = shop.items.where((e) => !e.isChecked).toList()
          ..sort(comparatorFor(incSortMode));
        final comItems = shop.items.where((e) => e.isChecked).toList()
          ..sort(comparatorFor(comSortMode));

        void showSortDialog({required bool isIncomplete}) {
          showDialog(
            context: context,
            builder: (context) {
              final current = isIncomplete ? incSortMode : comSortMode;
              return AlertDialog(
                title: Text(
                  '並び替え',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                    child: Text(
                      '閉じる',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
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
                    color: getCurrentTheme().colorScheme.primary,
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
                        : getCurrentTheme().colorScheme.primary,
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
                          onThemeChanged: (themeKey) {
                            setState(() {
                              currentTheme = themeKey;
                            });
                            // 設定を保存
                            _saveThemeSettings();
                            // main.dartのテーマを更新
                            if (widget.onThemeChanged != null) {
                              // 新しいテーマを作成して即座に反映
                              final newTheme = _createThemeWithColor(themeKey, currentFont, 16.0);
                              widget.onThemeChanged!(newTheme);
                            }
                          },
                          onFontChanged: (fontFamily) {
                            setState(() {
                              currentFont = fontFamily;
                            });
                            // 設定を保存
                            _saveFontSettings();
                            // main.dartのフォントを更新
                            if (widget.onFontChanged != null) {
                              widget.onFontChanged!(fontFamily);
                            }
                            // テーマを更新してフォント変更を反映
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCurrentTheme());
                            }
                          },
                          onFontSizeChanged: (fontSize) {
                            setState(() {
                              currentFontSize = fontSize;
                            });
                            // 設定を保存
                            _saveFontSettings();
                            // main.dartのフォントサイズを更新
                            if (widget.onFontSizeChanged != null) {
                              widget.onFontSizeChanged!(fontSize);
                            }
                          },
                          onCustomThemeChanged: (colors) {
                            setState(() {
                              customColors = colors;
                            });
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCurrentTheme());
                            }
                          },
                          onDarkModeChanged: (isDark) {
                            setState(() {
                              isDarkMode = isDark;
                            });
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCurrentTheme());
                            }
                          },
                          customColors: customColors,
                          isDarkMode: isDarkMode,
                          theme: getCurrentTheme(),
                          globalTheme: widget.globalTheme, // グローバルテーマを渡す
                          currentTheme: currentTheme,
                          currentFont: currentFont,
                          currentFontSize: currentFontSize,
                          detailedColors: detailedColors,
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
                        : getCurrentTheme().colorScheme.primary,
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
                      MaterialPageRoute(
                        builder: (_) => AboutScreen(
                          globalTheme: widget.globalTheme, // グローバルテーマを渡す
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.auto_awesome_rounded,
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : getCurrentTheme().colorScheme.primary,
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
                        builder: (_) => UpcomingFeaturesScreen(
                          globalTheme: widget.globalTheme, // グローバルテーマを渡す
                        ),
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
                            showTabEditDialog(i, shops);
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
                                addAutomaticKeepAlives: false,
                                cacheExtent: 100,
                                itemBuilder: (context, idx) {
                                  final item = incItems[idx];
                                  return ItemRow(
                                    item: item,
                                    onCheckToggle: (checked) async {
                                      final updatedItem = item.copyWith(
                                        isChecked: checked,
                                      );

                                      // 楽観的更新：DataProviderのshopsリストを即座に更新
                                      final dataProvider = context
                                          .read<DataProvider>();
                                      final shopIndex = dataProvider.shops
                                          .indexOf(shop);
                                      if (shopIndex != -1) {
                                        final updatedItems = shop.items.map((
                                          shopItem,
                                        ) {
                                          return shopItem.id == item.id
                                              ? updatedItem
                                              : shopItem;
                                        }).toList();
                                        final updatedShop = shop.copyWith(
                                          items: updatedItems,
                                        );
                                        dataProvider.shops[shopIndex] =
                                            updatedShop;
                                        dataProvider
                                            .notifyListeners(); // DataProviderに通知
                                        setState(() {});
                                      }

                                      // バックグラウンドでDataProviderを更新
                                      try {
                                        await context
                                            .read<DataProvider>()
                                            .updateItem(updatedItem);
                                      } catch (e) {
                                        // エラーが発生した場合は元に戻す
                                        if (shopIndex != -1) {
                                          final revertedItems = shop.items.map((
                                            shopItem,
                                          ) {
                                            return shopItem.id == updatedItem.id
                                                ? item
                                                : shopItem;
                                          }).toList();
                                          final revertedShop = shop.copyWith(
                                            items: revertedItems,
                                          );
                                          dataProvider.shops[shopIndex] =
                                              revertedShop;
                                          dataProvider
                                              .notifyListeners(); // DataProviderに通知
                                          setState(() {});
                                        }

                                        // エラーメッセージを表示
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
                                      showItemEditDialog(
                                        original: item,
                                        shop: shop,
                                      );
                                    },
                                    onDelete: () async {
                                      // 楽観的更新：DataProviderのshopsリストから即座に削除
                                      final dataProvider = context
                                          .read<DataProvider>();
                                      final shopIndex = dataProvider.shops
                                          .indexOf(shop);
                                      if (shopIndex != -1) {
                                        final updatedItems = shop.items
                                            .where(
                                              (shopItem) =>
                                                  shopItem.id != item.id,
                                            )
                                            .toList();
                                        final updatedShop = shop.copyWith(
                                          items: updatedItems,
                                        );
                                        dataProvider.shops[shopIndex] =
                                            updatedShop;
                                        dataProvider
                                            .notifyListeners(); // DataProviderに通知
                                        setState(() {});
                                      }

                                      // バックグラウンドでDataProviderから削除
                                      try {
                                        await context
                                            .read<DataProvider>()
                                            .deleteItem(item.id);
                                      } catch (e) {
                                        // エラーが発生した場合は削除を取り消し
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
                                          dataProvider
                                              .notifyListeners(); // DataProviderに通知
                                          setState(() {});
                                        }

                                        // エラーメッセージを表示
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
                                addAutomaticKeepAlives: false,
                                cacheExtent: 100,
                                itemBuilder: (context, idx) {
                                  final item = comItems[idx];
                                  return ItemRow(
                                    item: item,
                                    onCheckToggle: (checked) async {
                                      final updatedItem = item.copyWith(
                                        isChecked: checked,
                                      );

                                      // 楽観的更新：DataProviderのshopsリストを即座に更新
                                      final dataProvider = context
                                          .read<DataProvider>();
                                      final shopIndex = dataProvider.shops
                                          .indexOf(shop);
                                      if (shopIndex != -1) {
                                        final updatedItems = shop.items.map((
                                          shopItem,
                                        ) {
                                          return shopItem.id == item.id
                                              ? updatedItem
                                              : shopItem;
                                        }).toList();
                                        final updatedShop = shop.copyWith(
                                          items: updatedItems,
                                        );
                                        dataProvider.shops[shopIndex] =
                                            updatedShop;
                                        dataProvider
                                            .notifyListeners(); // DataProviderに通知
                                        setState(() {});
                                      }

                                      // バックグラウンドでDataProviderを更新
                                      try {
                                        await context
                                            .read<DataProvider>()
                                            .updateItem(updatedItem);
                                      } catch (e) {
                                        // エラーが発生した場合は元に戻す
                                        if (shopIndex != -1) {
                                          final revertedItems = shop.items.map((
                                            shopItem,
                                          ) {
                                            return shopItem.id == updatedItem.id
                                                ? item
                                                : shopItem;
                                          }).toList();
                                          final revertedShop = shop.copyWith(
                                            items: revertedItems,
                                          );
                                          dataProvider.shops[shopIndex] =
                                              revertedShop;
                                          dataProvider
                                              .notifyListeners(); // DataProviderに通知
                                          setState(() {});
                                        }

                                        // エラーメッセージを表示
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
                                    onEdit: null,
                                    onDelete: () async {
                                      // 楽観的更新：DataProviderのshopsリストから即座に削除
                                      final dataProvider = context
                                          .read<DataProvider>();
                                      final shopIndex = dataProvider.shops
                                          .indexOf(shop);
                                      if (shopIndex != -1) {
                                        final updatedItems = shop.items
                                            .where(
                                              (shopItem) =>
                                                  shopItem.id != item.id,
                                            )
                                            .toList();
                                        final updatedShop = shop.copyWith(
                                          items: updatedItems,
                                        );
                                        dataProvider.shops[shopIndex] =
                                            updatedShop;
                                        dataProvider
                                            .notifyListeners(); // DataProviderに通知
                                        setState(() {});
                                      }

                                      // バックグラウンドでDataProviderから削除
                                      try {
                                        await context
                                            .read<DataProvider>()
                                            .deleteItem(item.id);
                                      } catch (e) {
                                        // エラーが発生した場合は削除を取り消し
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
                                          dataProvider
                                              .notifyListeners(); // DataProviderに通知
                                          setState(() {});
                                        }

                                        // エラーメッセージを表示
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
            onBudgetClick: () => showBudgetDialog(shop),
            onFab: () => showItemEditDialog(shop: shop),
          ),
          // floatingActionButtonは削除
        );
      },
    );
  }
}
