import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import '../ad/interstitial_ad_service.dart';
import '../drawer/settings/settings_persistence.dart';
import '../widgets/welcome_dialog.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../widgets/item_row.dart';

import '../ad/ad_banner.dart';
import '../drawer/settings/settings_screen.dart';
import '../drawer/about_screen.dart';
import '../drawer/upcoming_features_screen.dart';
import '../drawer/donation_screen.dart';
import '../drawer/feedback_screen.dart';
import '../drawer/usage_screen.dart';
import '../drawer/calculator_screen.dart';
import '../drawer/settings/settings_theme.dart';
=======
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'main_screen_extensions.dart';
import 'main_screen_body.dart';
import '../services/interstitial_ad_service.dart';
import 'settings_persistence.dart';
import '../widgets/welcome_dialog.dart';
>>>>>>> 837e556c6d4cb9933dab52bcd30391ef216afe69

class MainScreen extends StatefulWidget {
  final void Function(ThemeData)? onThemeChanged;
  final void Function(String)? onFontChanged;
  final void Function(double)? onFontSizeChanged;
  final String? initialTheme;
  final String? initialFont;
  final double? initialFontSize;
  const MainScreen({
    super.key,
    this.onThemeChanged,
    this.onFontChanged,
    this.onFontSizeChanged,
    this.initialTheme,
    this.initialFont,
    this.initialFontSize,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

<<<<<<< HEAD
class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
=======
class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, MainScreenLogicMixin {
>>>>>>> 837e556c6d4cb9933dab52bcd30391ef216afe69
  late TabController _tabController;
  int selectedTabIndex = 0;
  @override
  late String currentTheme;
  @override
  late String currentFont;
  @override
  late double currentFontSize;
  @override
  Map<String, Color> customColors = {
    'primary': Color(0xFFFFB6C1),
    'secondary': Color(0xFFB5EAD7),
    'surface': Color(0xFFFFF1F8),
  };
  @override
  String nextShopId = '1';
  @override
  String nextItemId = '0';
  @override
  @override
  bool includeTax = false;
  @override
  bool isDarkMode = false;

<<<<<<< HEAD
  ThemeData getCustomTheme() {
    return SettingsTheme.generateTheme(
      selectedTheme: currentTheme,
      selectedFont: currentFont,
      detailedColors: customColors,
      fontSize: currentFontSize,
    );
  }

  void showAddTabDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '新しいショッピングを追加',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'ショッピング名',
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

                if (!context.mounted) return;
                Navigator.of(context).pop();

                // インタースティシャル広告の表示を試行
                InterstitialAdService().incrementOperationCount();
                await InterstitialAdService().showAdIfReady();
              },
              child: Text('追加', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        );
      },
    );
  }

  void showBudgetDialog(Shop shop) {
    showDialog(
      context: context,
      builder: (context) => _BudgetDialog(shop: shop),
    );
  }

  void showTabEditDialog(int tabIndex, List<Shop> shops) {
    final controller = TextEditingController(text: shops[tabIndex].name);
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: getCustomTheme(),
          child: AlertDialog(
            title: Text(
              'ショッピング編集',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'ショッピング名',
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

                    if (!context.mounted) return;
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

                  if (!context.mounted) return;
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
      text: original?.quantity.toString() ?? '1',
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      if (newValue.text.startsWith('0') &&
                          newValue.text.length > 1) {
                        return TextEditingValue(
                          text: newValue.text.substring(1),
                          selection: TextSelection.collapsed(
                            offset: newValue.text.length - 1,
                          ),
                        );
                      }
                      return newValue;
                    }),
                  ],
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: '単価',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      if (newValue.text.startsWith('0') &&
                          newValue.text.length > 1) {
                        return TextEditingValue(
                          text: newValue.text.substring(1),
                          selection: TextSelection.collapsed(
                            offset: newValue.text.length - 1,
                          ),
                        );
                      }
                      return newValue;
                    }),
                  ],
                ),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(
                    labelText: '割引(%)',
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) return newValue;
                      if (newValue.text.startsWith('0') &&
                          newValue.text.length > 1) {
                        return TextEditingValue(
                          text: newValue.text.substring(1),
                          selection: TextSelection.collapsed(
                            offset: newValue.text.length - 1,
                          ),
                        );
                      }
                      return newValue;
                    }),
                  ],
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
                  final prefs = await SharedPreferences.getInstance();
                  final isAutoCompleteEnabled =
                      prefs.getBool('auto_complete_on_price_input') ?? false;
                  final shouldAutoComplete = isAutoCompleteEnabled && price > 0;

                  final newItem = Item(
                    id: '',
                    name: name,
                    quantity: qty,
                    price: price,
                    discount: discount,
                    shopId: shop.id,
                    isChecked: shouldAutoComplete,
                  );

                  if (!context.mounted) return;
                  final dataProvider = context.read<DataProvider>();
                  try {
                    await dataProvider.addItem(newItem);
                    if (!context.mounted) return;

                    InterstitialAdService().incrementOperationCount();
                    await InterstitialAdService().showAdIfReady();
                  } catch (e) {
                    if (!context.mounted) return;
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
                  final prefs = await SharedPreferences.getInstance();
                  if (!context.mounted) return;

                  final isAutoCompleteEnabled =
                      prefs.getBool('auto_complete_on_price_input') ?? false;

                  final shouldAutoCompleteOnEdit =
                      isAutoCompleteEnabled &&
                      (original.price == 0) &&
                      (price > 0) &&
                      !original.isChecked;

                  final updatedItem = original.copyWith(
                    name: name,
                    quantity: qty,
                    price: price,
                    discount: discount,
                    isChecked: shouldAutoCompleteOnEdit
                        ? true
                        : original.isChecked,
                  );

                  if (!context.mounted) return;
                  final dataProvider = context.read<DataProvider>();
                  try {
                    await dataProvider.updateItem(updatedItem);
                    if (!context.mounted) return;

                    InterstitialAdService().incrementOperationCount();
                    await InterstitialAdService().showAdIfReady();
                  } catch (e) {
                    if (!context.mounted) return;
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
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: Text('保存', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        );
      },
    );
  }

  void showSortDialog(bool isIncomplete, int selectedTabIndex) {
    final dataProvider = context.read<DataProvider>();
    if (dataProvider.shops.isEmpty) return;

    final currentShopIndex = selectedTabIndex < dataProvider.shops.length
        ? selectedTabIndex
        : 0;
    final currentShop = dataProvider.shops[currentShopIndex];
    final current = isIncomplete
        ? currentShop.incSortMode
        : currentShop.comSortMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('並び替え', style: Theme.of(context).textTheme.titleLarge),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: SortMode.values.map((mode) {
                return ListTile(
                  title: Text(mode.label),
                  trailing: mode == current ? const Icon(Icons.check) : null,
                  enabled: mode != current,
                  onTap: mode == current
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);

                          final updatedShop = currentShop.copyWith(
                            incSortMode: isIncomplete
                                ? mode
                                : currentShop.incSortMode,
                            comSortMode: isIncomplete
                                ? currentShop.comSortMode
                                : mode,
                          );

                          await dataProvider.updateShop(updatedShop);

                          navigator.pop();

                          InterstitialAdService().incrementOperationCount();
                          await InterstitialAdService().showAdIfReady();
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('閉じる', style: Theme.of(context).textTheme.bodyLarge),
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

  void showBulkDeleteDialog(Shop shop, bool isIncomplete) {
    final itemsToDelete = isIncomplete
        ? shop.items.where((item) => !item.isChecked).toList()
        : shop.items.where((item) => item.isChecked).toList();

    if (itemsToDelete.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('削除するアイテムがありません'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isIncomplete ? '未完了アイテムを一括削除' : '完了済みアイテムを一括削除',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            '${itemsToDelete.length}個のアイテムを削除しますか？\nこの操作は取り消せません。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final dataProvider = context.read<DataProvider>();
                try {
                  final itemIds = itemsToDelete.map((item) => item.id).toList();
                  await dataProvider.deleteItems(itemIds);

                  if (!context.mounted) return;

                  InterstitialAdService().incrementOperationCount();
                  await InterstitialAdService().showAdIfReady();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('削除'),
            ),
          ],
        );
      },
    );
  }

  // ソートモードの比較関数
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

=======
>>>>>>> 837e556c6d4cb9933dab52bcd30391ef216afe69
  @override
  void initState() {
    super.initState();
    currentTheme = widget.initialTheme ?? 'pink';
    currentFont = widget.initialFont ?? 'nunito';
    currentFontSize = widget.initialFontSize ?? 16.0;
    _tabController = TabController(length: 0, vsync: this);

    // 初回起動時にウェルカムダイアログを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcomeDialog();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // インタースティシャル広告の破棄
    InterstitialAdService().dispose();
    super.dispose();
  }

  // 初回起動時にウェルカムダイアログを表示するメソッド
  Future<void> _checkAndShowWelcomeDialog() async {
    final isFirstLaunch = await SettingsPersistence.isFirstLaunch();

    if (isFirstLaunch && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeDialog(),
      );
    }
  }

  // TabControllerの変更を処理するメソッド
  void _onTabChanged() {
    if (mounted && _tabController.length > 0) {
      setState(() {});
    }
  }

  // 認証状態の変更を監視してテーマとフォントを更新
  void _updateThemeAndFontIfNeeded(AuthProvider authProvider) {
    // 認証状態が変更された際に、保存されたテーマとフォントを読み込む
    if (authProvider.isLoggedIn) {
      _loadSavedThemeAndFont();
    }
  }

  // 保存されたテーマとフォントを読み込む
  Future<void> _loadSavedThemeAndFont() async {
    try {
      final savedTheme = await SettingsPersistence.loadTheme();
      final savedFont = await SettingsPersistence.loadFont();

      if (mounted) {
        setState(() {
          currentTheme = savedTheme;
          currentFont = savedFont;
        });
      }
    } catch (e) {
      debugPrint('テーマ・フォント読み込みエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, AuthProvider>(
      builder: (context, dataProvider, authProvider, child) {
        // 認証状態の変更を監視してテーマとフォントを更新
        _updateThemeAndFontIfNeeded(authProvider);

        // TabControllerの長さを更新（必要な場合のみ）
        if (_tabController.length != dataProvider.shops.length) {
          final oldLength = _tabController.length;
          final newLength = dataProvider.shops.length;

          _tabController.dispose();

          // 安全な初期インデックスを計算
          int initialIndex = 0;
          if (newLength > 0) {
            if (newLength > oldLength) {
              // 新しいタブが追加された場合
              initialIndex = newLength - 1;
            } else {
              // タブが削除された場合、現在のインデックスを調整
              initialIndex = selectedTabIndex.clamp(0, newLength - 1);
            }
          }

          _tabController = TabController(
            length: dataProvider.shops.length,
            vsync: this,
            initialIndex: initialIndex,
          );
          // リスナーを追加
          _tabController.addListener(_onTabChanged);
        }

        // shopsが空の場合は0を返す
        final selectedIndex = dataProvider.shops.isEmpty
            ? 0
            : (_tabController.index >= 0 &&
                  _tabController.index < dataProvider.shops.length)
            ? _tabController.index
            : 0;

<<<<<<< HEAD
        // データプロバイダーのローディング状態を取得（Consumerで最適化）
        final isDataLoading = dataProvider.isLoading;

        // ローディング中またはデータがまだ読み込まれていない場合
        if (isDataLoading || dataProvider.shops.isEmpty) {
          return Scaffold(
            backgroundColor: getCustomTheme().colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: getCustomTheme().colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'データを読み込み中...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : getCustomTheme().colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // shopsが空でないことを確認してからshopを初期化
        final shop = dataProvider.shops.isEmpty
            ? null
            : dataProvider.shops[selectedIndex.clamp(
                0,
                dataProvider.shops.length - 1,
              )];

        // アイテムの分類とソートを一度だけ実行
        final incItems = shop?.items.where((e) => !e.isChecked).toList() ?? []
          ..sort(comparatorFor(shop?.incSortMode ?? SortMode.dateNew));
        final comItems = shop?.items.where((e) => e.isChecked).toList() ?? []
          ..sort(comparatorFor(shop?.comSortMode ?? SortMode.dateNew));

        return Scaffold(
          backgroundColor: getCustomTheme().colorScheme.surface,
          appBar: AppBar(
            title: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dataProvider.shops.length,
                  itemBuilder: (context, index) {
                    final shop = dataProvider.shops[index];
                    final isSelected = index == selectedIndex;

                    return GestureDetector(
                      onLongPress: () {
                        showTabEditDialog(index, dataProvider.shops);
                      },
                      onTap: () {
                        if (dataProvider.shops.isNotEmpty &&
                            index < dataProvider.shops.length) {
                          if (dataProvider.shops.isNotEmpty &&
                              index >= 0 &&
                              index < dataProvider.shops.length &&
                              _tabController.length > 0 &&
                              index < _tabController.length) {
                            if (mounted) {
                              setState(() {
                                _tabController.index = index;
                              });
                            }
                          }
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
                              ? (currentTheme == 'custom' &&
                                        customColors.containsKey('tabColor')
                                    ? customColors['tabColor']
                                    : (currentTheme == 'light'
                                          ? Color(0xFF9E9E9E)
                                          : currentTheme == 'dark'
                                          ? Colors.white
                                          : getCustomTheme()
                                                .colorScheme
                                                .primary))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (currentTheme == 'dark'
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
                                        (currentTheme == 'custom' &&
                                                    customColors.containsKey(
                                                      'tabColor',
                                                    )
                                                ? customColors['tabColor']!
                                                : (currentTheme == 'light'
                                                      ? Color(0xFF9E9E9E)
                                                      : currentTheme == 'dark'
                                                      ? Colors.white
                                                      : getCustomTheme()
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
                                  ? (currentTheme == 'light'
                                        ? Colors.black87
                                        : currentTheme == 'dark'
                                        ? Colors.black87
                                        : Colors.white)
                                  : (currentTheme == 'dark'
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
            backgroundColor: getCustomTheme().colorScheme.surface,
            foregroundColor: currentTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: (currentTheme == 'dark' || currentTheme == 'light')
                      ? Colors.white
                      : Theme.of(context).iconTheme.color,
                ),
                onPressed: () => showAddTabDialog(),
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
                    color: getCustomTheme().colorScheme.primary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_basket_rounded,
                        size: 48,
                        color: currentTheme == 'lemon'
                            ? Color(0xFF8B6914)
                            : (currentTheme == 'light'
                                  ? Colors.black87
                                  : Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'まいカゴ',
                        style: TextStyle(
                          fontSize: 22,
                          color: currentTheme == 'lemon'
                              ? Color(0xFF8B6914)
                              : (currentTheme == 'light'
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
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    'アプリについて',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
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
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    '使い方',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
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
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    '簡単電卓',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CalculatorScreen(
                          currentTheme: currentTheme,
                          theme: getCustomTheme(),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.favorite_rounded,
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    '寄付',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
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
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    '今後の新機能',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
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
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    'フィードバック',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
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
                    color: currentTheme == 'dark'
                        ? Colors.white
                        : (currentTheme == 'light'
                              ? Colors.black87
                              : getCustomTheme().colorScheme.primary),
                  ),
                  title: Text(
                    '設定',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: currentTheme == 'dark'
                          ? Colors.white
                          : (currentTheme == 'light' ? Colors.black87 : null),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          currentTheme: currentTheme,
                          currentFont: currentFont,
                          currentFontSize: currentFontSize,
                          onThemeChanged: (themeKey) async {
                            if (mounted) {
                              setState(() {
                                currentTheme = themeKey;
                              });
                            }
                            await SettingsPersistence.saveTheme(themeKey);
                            updateGlobalTheme(themeKey);
                          },
                          onFontChanged: (font) async {
                            if (mounted) {
                              setState(() {
                                currentFont = font;
                              });
                            }
                            await SettingsPersistence.saveFont(font);
                            if (widget.onFontChanged != null) {
                              widget.onFontChanged!(font);
                            }
                            updateGlobalFont(font);
                          },
                          onFontSizeChanged: (fontSize) async {
                            if (mounted) {
                              setState(() {
                                currentFontSize = fontSize;
                              });
                            }
                            await SettingsPersistence.saveFontSize(fontSize);
                            if (widget.onFontSizeChanged != null) {
                              widget.onFontSizeChanged!(fontSize);
                            }
                            updateGlobalFontSize(fontSize);
                          },
                          onCustomThemeChanged: (colors) {
                            if (mounted) {
                              setState(() {
                                customColors = colors;
                              });
                            }
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCustomTheme());
                            }
                          },
                          onDarkModeChanged: (isDark) {
                            if (mounted) {
                              setState(() {
                                isDarkMode = isDark;
                              });
                            }
                            if (widget.onThemeChanged != null) {
                              widget.onThemeChanged!(getCustomTheme());
                            }
                          },
                          customColors: customColors,
                          isDarkMode:
                              getCustomTheme().brightness == Brightness.dark,
                          theme: getCustomTheme(),
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
                                color: currentTheme == 'dark'
                                    ? Colors.white
                                    : getCustomTheme().colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: () {
                                showSortDialog(true, selectedIndex);
                              },
                              tooltip: '未購入アイテムの並び替え',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep),
                              onPressed: () {
                                if (shop != null) {
                                  showBulkDeleteDialog(shop, true);
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
                            color: getCustomTheme().colorScheme.surface,
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
                                        debugPrint('アイテムチェック処理開始');
                                        debugPrint(
                                          '更新前のショップ予算: ${shop.budget}',
                                        );

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
                                          );
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
                                            return;
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
                                          showItemEditDialog(
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

                                          InterstitialAdService()
                                              .incrementOperationCount();
                                          await InterstitialAdService()
                                              .showAdIfReady();
                                        } catch (e) {
                                          if (!context.mounted) {
                                            return;
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
                Container(width: 1, color: getCustomTheme().dividerColor),
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
                                color: currentTheme == 'dark'
                                    ? Colors.white
                                    : getCustomTheme().colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.sort),
                              onPressed: () {
                                showSortDialog(false, selectedIndex);
                              },
                              tooltip: '購入済みアイテムの並び替え',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep),
                              onPressed: () {
                                if (shop != null) {
                                  showBulkDeleteDialog(shop, false);
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
                            color: getCustomTheme().colorScheme.surface,
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
                                        debugPrint('購入済みアイテムチェック処理開始');
                                        debugPrint(
                                          '更新前のショップ予算: ${shop.budget}',
                                        );

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
                                          );
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
                                            return;
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
                                          showItemEditDialog(
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

                                          InterstitialAdService()
                                              .incrementOperationCount();
                                          await InterstitialAdService()
                                              .showAdIfReady();
                                        } catch (e) {
                                          if (!context.mounted) {
                                            return;
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
                      color: getCustomTheme().colorScheme.surface,
                      child: const AdBanner(),
                    ),
                    // ボトムサマリー
                    BottomSummary(
                      shop: shop,
                      onBudgetClick: () => showBudgetDialog(shop),
                      onFab: () => showItemEditDialog(shop: shop),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // バナー広告（ショップがない場合も表示）
                    Container(
                      width: double.infinity,
                      color: getCustomTheme().colorScheme.surface,
                      child: const AdBanner(),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// 予算変更ダイアログ
class _BudgetDialog extends StatefulWidget {
  final Shop shop;

  const _BudgetDialog({required this.shop});

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late TextEditingController _controller;
  bool _isLoading = true;
  bool _isBudgetSharingEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.shop.budget?.toString() ?? '',
    );
    _loadBudgetSharingSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBudgetSharingSettings() async {
    final currentBudget = await SettingsPersistence.getCurrentBudget(
      widget.shop.id,
    );
    final budgetSharingEnabled =
        await SettingsPersistence.loadBudgetSharingEnabled();

    debugPrint('=== _loadBudgetSharingSettings ===');
    debugPrint('現在の予算: $currentBudget');
    debugPrint('ショップID: ${widget.shop.id}');
    debugPrint('共有モード読み込み結果: $budgetSharingEnabled');

    setState(() {
      if (currentBudget != null) {
        _controller.text = currentBudget.toString();
      }
      _isBudgetSharingEnabled = budgetSharingEnabled;
      _isLoading = false;
    });

    debugPrint('setState後の共有モード: $_isBudgetSharingEnabled');
  }

  Future<void> _saveBudget() async {
    final budgetText = _controller.text.trim();
    int? finalBudget;

    if (budgetText.isEmpty) {
      finalBudget = null;
    } else {
      final budget = int.tryParse(budgetText);
      if (budget == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('有効な数値を入力してください'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      finalBudget = budget == 0 ? null : budget;
    }

    final dataProvider = context.read<DataProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // 共有設定を保存
      await SettingsPersistence.saveBudgetSharingEnabled(
        _isBudgetSharingEnabled,
      );
      debugPrint('共有設定を保存: $_isBudgetSharingEnabled');

      // 予算を保存（共有モードまたは個別モード）
      await SettingsPersistence.saveCurrentBudget(widget.shop.id, finalBudget);
      debugPrint('予算を保存: $finalBudget (ショップID: ${widget.shop.id})');

      // 共有モードの場合、共有予算を明示的に設定
      if (_isBudgetSharingEnabled) {
        // 共有予算を明示的に設定
        await SettingsPersistence.saveSharedBudget(finalBudget);
        debugPrint('共有予算を明示的に設定: $finalBudget');

        await dataProvider.initializeSharedModeIfNeeded();
        debugPrint('共有モード初期化完了');

        // 共有予算変更を全タブに通知
        DataProvider.notifySharedBudgetChanged(finalBudget);
      } else {
        // 個別モードの場合、現在のショップの予算を即座に更新
        final updatedShop = finalBudget == null
            ? widget.shop.copyWith(clearBudget: true)
            : widget.shop.copyWith(budget: finalBudget);
        await dataProvider.updateShop(updatedShop);

        // 個別予算変更を通知
        DataProvider.notifyIndividualBudgetChanged(widget.shop.id, finalBudget);
      }

      dataProvider.clearDisplayTotalCache();

      if (!context.mounted) return;
      navigator.pop();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text(
        widget.shop.budget != null ? '予算を変更' : '予算を設定',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.shop.budget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '現在の予算: ¥${widget.shop.budget}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: '金額 (¥)',
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              helperText: '0を入力すると予算を未設定にできます',
              helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                if (newValue.text == '0') return newValue;
                if (newValue.text.startsWith('0') && newValue.text.length > 1) {
                  return TextEditingValue(
                    text: newValue.text.substring(1),
                    selection: TextSelection.collapsed(
                      offset: newValue.text.length - 1,
                    ),
                  );
                }
                return newValue;
              }),
            ],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text(
              'すべてのショッピングで予算と合計金額を共有する',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              _isBudgetSharingEnabled
                  ? '全ショッピングで同じ予算・合計が表示されます'
                  : 'ショッピングごとに個別の予算・合計が表示されます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: _isBudgetSharingEnabled,
            onChanged: (bool value) {
              setState(() {
                _isBudgetSharingEnabled = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル', style: Theme.of(context).textTheme.bodyLarge),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          child: Text('保存', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

/// ボトムサマリーウィジェット
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
=======
        return MainScreenBody(
          isLoading: dataProvider.isLoading,
          shops: dataProvider.shops,
          currentTheme: currentTheme,
          currentFont: currentFont, // currentFontを追加
          currentFontSize: currentFontSize,
          customColors: customColors,

          theme: getCustomTheme(),
          showAddTabDialog: showAddTabDialog,
          showTabEditDialog: (index, shops) => showTabEditDialog(index, shops),
          showBudgetDialog: showBudgetDialog,
          showItemEditDialog: showItemEditDialog,
          showBulkDeleteDialog: showBulkDeleteDialog,
          showSortDialog: (isIncomplete, selectedTabIndex) =>
              showSortDialog(isIncomplete, selectedTabIndex),
          calcTotal: calcTotal,
          onTabChanged: (index) {
            if (dataProvider.shops.isNotEmpty &&
                index >= 0 &&
                index < dataProvider.shops.length &&
                _tabController.length > 0 &&
                index < _tabController.length) {
              if (mounted) {
                setState(() {
                  _tabController.index = index;
                });
              }
            }
          },
          onThemeChanged: (themeKey) async {
            if (mounted) {
              setState(() {
                currentTheme = themeKey;
              });
            }
            await SettingsPersistence.saveTheme(themeKey);
            updateGlobalTheme(themeKey);
          },
          onFontChanged: (font) async {
            if (mounted) {
              setState(() {
                currentFont = font;
              });
            }
            await SettingsPersistence.saveFont(font);
            if (widget.onFontChanged != null) {
              widget.onFontChanged!(font);
            }
            // グローバルフォント更新関数を呼び出し
            updateGlobalFont(font);
          },
          onFontSizeChanged: (fontSize) async {
            if (mounted) {
              setState(() {
                currentFontSize = fontSize;
              });
            }
            await SettingsPersistence.saveFontSize(fontSize);
            if (widget.onFontSizeChanged != null) {
              widget.onFontSizeChanged!(fontSize);
            }
            // グローバルフォントサイズ更新関数を呼び出し
            updateGlobalFontSize(fontSize);
          },
          onCustomThemeChanged: (colors) {
            if (mounted) {
              setState(() {
                customColors = colors;
              });
            }
            if (widget.onThemeChanged != null) {
              widget.onThemeChanged!(getCustomTheme());
            }
          },
          onDarkModeChanged: (isDark) {
            if (mounted) {
              setState(() {
                isDarkMode = isDark;
              });
            }
            if (widget.onThemeChanged != null) {
              widget.onThemeChanged!(getCustomTheme());
            }
          },
          selectedTabIndex: selectedIndex, // selectedTabIndexを渡す
>>>>>>> 837e556c6d4cb9933dab52bcd30391ef216afe69
        );
      },
    );
  }
<<<<<<< HEAD

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
=======
>>>>>>> 837e556c6d4cb9933dab52bcd30391ef216afe69
}
