import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../providers/data_provider.dart';
import 'main_screen.dart';

mixin MainScreenLogicMixin on State<MainScreen> {
  // _MainScreenStateのプロパティにアクセスできるようにする
  abstract String currentTheme;
  abstract String currentFont;
  abstract double currentFontSize;
  abstract Map<String, Color> customColors;
  abstract String nextShopId;
  abstract String nextItemId;
  abstract SortMode incSortMode;
  abstract SortMode comSortMode;
  abstract bool includeTax;
  abstract bool isDarkMode;

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
          data: getCustomTheme(),
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

  void showSortDialog(bool isIncomplete) {
    showDialog(
      context: context,
      builder: (context) {
        final current = isIncomplete ? incSortMode : comSortMode;
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
}
