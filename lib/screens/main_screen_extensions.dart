import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../providers/data_provider.dart';
import '../services/interstitial_ad_service.dart';
import 'main_screen.dart';
import 'settings_persistence.dart';

mixin MainScreenLogicMixin on State<MainScreen> {
  // _MainScreenStateのプロパティにアクセスできるようにする
  abstract String currentTheme;
  abstract String currentFont;
  abstract double currentFontSize;
  abstract Map<String, Color> customColors;
  abstract String nextShopId;
  abstract String nextItemId;
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
          primary = Color(0xFF9E9E9E); // より薄いグレー
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
          secondary = Color(0xFFA8E6CF); // ミントグリーン
          surface = Color(0xFFE0F7FA);
          break;
        case 'lavender':
          primary = Color(0xFFB39DDB);
          secondary = Color(0xFFD1C4E9); // ラベンダー
          surface = Color(0xFFF3E5F5);
          break;
        case 'lemon':
          primary = Color(0xFFFFF176);
          secondary = Color(0xFFFFF59D); // レモンイエロー
          surface = Color(0xFFFFFDE7);
          break;
        case 'soda':
          primary = Color(0xFF81D4FA);
          secondary = Color(0xFFB3E5FC); // ソーダブルー
          surface = Color(0xFFE1F5FE);
          break;
        case 'coral':
          primary = Color(0xFFFFAB91);
          secondary = Color(0xFFFFCCBC); // コーラル
          surface = Color(0xFFFFF3E0);
          break;
        case 'orange':
          primary = Color(0xFFFFC107);
          secondary = Color(0xFFFFE082); // オレンジ
          surface = Color(0xFFFFF8E1);
          break;
        case 'green':
          primary = Color(0xFF8BC34A);
          secondary = Color(0xFFC5E1A5); // グリーン
          surface = Color(0xFFF1F8E9);
          break;
        case 'blue':
          primary = Color(0xFF2196F3);
          secondary = Color(0xFF90CAF9); // ブルー
          surface = Color(0xFFE3F2FD);
          break;
        case 'gray':
          primary = Color(0xFF90A4AE);
          secondary = Color(0xFFCFD8DC); // グレー
          surface = Color(0xFFF5F5F5);
          break;
        case 'beige':
          primary = Color(0xFFFFE0B2);
          secondary = Color(0xFFFFECB3); // ベージュ
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
    TextTheme baseTextTheme;
    switch (currentFont) {
      case 'sawarabi':
        baseTextTheme = GoogleFonts.sawarabiMinchoTextTheme();
        break;
      case 'mplus':
        baseTextTheme = GoogleFonts.mPlus1pTextTheme();
        break;
      case 'zenmaru':
        baseTextTheme = GoogleFonts.zenMaruGothicTextTheme();
        break;
      case 'yuseimagic':
        baseTextTheme = GoogleFonts.yuseiMagicTextTheme();
        break;
      case 'yomogi':
        baseTextTheme = GoogleFonts.yomogiTextTheme();
        break;
      default:
        baseTextTheme = GoogleFonts.nunitoTextTheme();
    }

    // フォントサイズを明示的に指定
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: currentFontSize + 10,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: currentFontSize + 6,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: currentFontSize + 2,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: currentFontSize + 4,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: currentFontSize + 2,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: currentFontSize,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: currentFontSize),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: currentFontSize - 2,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: currentFontSize - 4,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: currentFontSize),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: currentFontSize - 2,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: currentFontSize - 4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: currentFontSize - 2,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: currentFontSize - 4,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: currentFontSize - 6,
      ),
    );

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: isDarkMode ? Colors.black : Colors.white,
        surface: surface,
        onSurface: onSurface, // 背景上のテキスト色
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: _getBackgroundColor(currentTheme),
      useMaterial3: true,
    );
  }

  Color _getBackgroundColor(String theme) {
    switch (theme) {
      case 'light':
        return Color(0xFFFAFAFA); // より薄いグレー
      case 'dark':
        return Color(0xFF111111); // 黒
      case 'mint':
        return Color(0xFFE0F7FA); // ミントグリーン
      case 'lavender':
        return Color(0xFFF3E5F5); // ラベンダー
      case 'lemon':
        return Color(0xFFFFFDE7); // レモンイエロー
      case 'soda':
        return Color(0xFFE1F5FE); // ソーダブルー
      case 'coral':
        return Color(0xFFFFF3E0); // コーラル
      case 'orange':
        return Color(0xFFFFF8E1); // オレンジ
      case 'green':
        return Color(0xFFF1F8E9); // グリーン
      case 'blue':
        return Color(0xFFE3F2FD); // ブルー
      case 'gray':
        return Color(0xFFFAFAFA); // より薄いグレー
      case 'beige':
        return Color(0xFFFFF8E1); // ベージュ
      default:
        return Color(0xFFFAFAFA); // デフォルトも薄いグレー
    }
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    // 先頭の0を制限するカスタムフォーマッター
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // 空文字列の場合はそのまま
                      if (newValue.text.isEmpty) return newValue;

                      // 先頭が0で、2文字以上の場合（例: 01）は先頭の0を削除
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
                    // 先頭の0を制限するカスタムフォーマッター
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // 空文字列の場合はそのまま
                      if (newValue.text.isEmpty) return newValue;

                      // 先頭が0で、2文字以上の場合（例: 0100）は先頭の0を削除
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
                    // 先頭の0を制限するカスタムフォーマッター
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // 空文字列の場合はそのまま
                      if (newValue.text.isEmpty) return newValue;

                      // 先頭が0で、2文字以上の場合（例: 05）は先頭の0を削除
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
                  // 自動完了設定を確認
                  final prefs = await SharedPreferences.getInstance();
                  final isAutoCompleteEnabled =
                      prefs.getBool('auto_complete_on_price_input') ?? false;
                  final shouldAutoComplete = isAutoCompleteEnabled && price > 0;

                  // 新しいアイテムを追加
                  final newItem = Item(
                    id: '', // IDはDataProviderで生成される
                    name: name,
                    quantity: qty,
                    price: price,
                    discount: discount,
                    shopId: shop.id, // ショップIDを設定
                    isChecked:
                        shouldAutoComplete, // 自動完了が有効で金額が入力されている場合はチェック済みにする
                  );

                  // DataProviderを使用してアイテムを追加
                  if (!context.mounted) return;
                  final dataProvider = context.read<DataProvider>();
                  try {
                    await dataProvider.addItem(newItem);
                    if (!context.mounted) return;

                    // インタースティシャル広告の表示を試行
                    InterstitialAdService().incrementOperationCount();
                    await InterstitialAdService().showAdIfReady();
                  } catch (e) {
                    // エラーメッセージを表示
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
                  // 自動完了設定を確認（編集時）
                  final prefs = await SharedPreferences.getInstance();
                  if (!context.mounted) return;

                  final isAutoCompleteEnabled =
                      prefs.getBool('auto_complete_on_price_input') ?? false;

                  // 編集前の価格が0で、編集後の価格が0より大きい場合に自動完了
                  final shouldAutoCompleteOnEdit =
                      isAutoCompleteEnabled &&
                      (original.price == 0) &&
                      (price > 0) &&
                      !original.isChecked;

                  // 既存のアイテムを更新
                  final updatedItem = original.copyWith(
                    name: name,
                    quantity: qty,
                    price: price,
                    discount: discount,
                    isChecked: shouldAutoCompleteOnEdit
                        ? true
                        : original.isChecked,
                  );

                  // DataProviderを使用してアイテムを更新
                  if (!context.mounted) return;
                  final dataProvider = context.read<DataProvider>();
                  try {
                    await dataProvider.updateItem(updatedItem);
                    if (!context.mounted) return;

                    // インタースティシャル広告の表示を試行
                    InterstitialAdService().incrementOperationCount();
                    await InterstitialAdService().showAdIfReady();
                  } catch (e) {
                    // エラーメッセージを表示
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
    // 現在のショップを取得
    final dataProvider = context.read<DataProvider>();
    if (dataProvider.shops.isEmpty) return;

    // selectedTabIndexを使用して現在のショップを取得
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
                          // context を事前に取得
                          final navigator = Navigator.of(context);

                          // ショップの並べ替え設定を更新
                          final updatedShop = currentShop.copyWith(
                            incSortMode: isIncomplete
                                ? mode
                                : currentShop.incSortMode,
                            comSortMode: isIncomplete
                                ? currentShop.comSortMode
                                : mode,
                          );

                          // DataProviderを使用してクラウドに保存
                          await dataProvider.updateShop(updatedShop);

                          navigator.pop();

                          // インタースティシャル広告の表示を試行
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

                // 一括削除を実行
                final dataProvider = context.read<DataProvider>();
                try {
                  final itemIds = itemsToDelete.map((item) => item.id).toList();
                  await dataProvider.deleteItems(itemIds);

                  if (!context.mounted) return;

                  // インタースティシャル広告の表示を試行
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
