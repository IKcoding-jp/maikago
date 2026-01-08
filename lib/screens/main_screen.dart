import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

import 'package:maikago/services/hybrid_ocr_service.dart';
import 'package:maikago/screens/enhanced_camera_screen.dart';

import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import '../ad/interstitial_ad_service.dart';
import '../drawer/settings/settings_persistence.dart';
import '../widgets/welcome_dialog.dart';
import '../models/list.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../models/shared_group_icons.dart';
import '../utils/tab_sorter.dart';
import '../widgets/list_edit.dart';

import '../ad/ad_banner.dart';
import '../drawer/settings/settings_screen.dart';
import '../drawer/about_screen.dart';
import '../drawer/upcoming_features_screen.dart';
import '../drawer/donation_screen.dart';
import '../drawer/feedback_screen.dart';
import '../drawer/usage_screen.dart';
import '../drawer/calculator_screen.dart';
import '../drawer/settings/settings_theme.dart';
import '../drawer/maikago_premium.dart';
import 'release_history_screen.dart';

import '../services/one_time_purchase_service.dart';
// import '../services/subscription_service.dart';
import '../widgets/image_analysis_progress_dialog.dart';
import '../widgets/version_update_dialog.dart';
import '../services/version_notification_service.dart';
import '../models/release_history.dart';
import 'main/dialogs/budget_dialog.dart';
import 'main/dialogs/sort_dialog.dart';
import 'main/dialogs/item_edit_dialog.dart';
// vision_ocr_service is not used in this file; import removed to fix linter warning

class MainScreen extends StatefulWidget {
  final void Function(ThemeData)? onThemeChanged;
  final void Function(String)? onFontChanged;
  final void Function(double)? onFontSizeChanged;
  final void Function(Map<String, Color>)? onCustomColorsChanged;
  final String? initialTheme;
  final String? initialFont;
  final double? initialFontSize;
  const MainScreen({
    super.key,
    this.onThemeChanged,
    this.onFontChanged,
    this.onFontSizeChanged,
    this.onCustomColorsChanged,
    this.initialTheme,
    this.initialFont,
    this.initialFontSize,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController tabController;
  int selectedTabIndex = 0;
  String? selectedTabId;
  late String currentTheme;
  late String currentFont;
  late double currentFontSize;
  Map<String, Color> customColors = {
    'primary': const Color(0xFFFFB6C1),
    'secondary': const Color(0xFFB5EAD7),
    'surface': const Color(0xFFFFF1F8),
  };
  String nextShopId = '1';
  String nextItemId = '0';
  bool includeTax = false;
  bool isDarkMode = false;

  // ハイブリッドOCRサービス
  final HybridOcrService _hybridOcrService = HybridOcrService();

  ThemeData getCustomTheme() {
    return SettingsTheme.generateTheme(
      selectedTheme: currentTheme,
      selectedFont: currentFont,
      fontSize: currentFontSize,
    );
  }

  /// バージョン更新通知をチェック
  Future<void> _checkForVersionUpdate() async {
    try {
      final shouldShow =
          await VersionNotificationService.shouldShowVersionNotification();
      if (shouldShow && mounted) {
        final latestRelease = VersionNotificationService.getLatestReleaseNote();
        if (latestRelease != null) {
          _showVersionUpdateDialog(latestRelease);
        }
      }
    } catch (e) {
      // エラーが発生してもアプリの動作には影響しない
      debugPrint('バージョン更新チェックエラー: $e');
    }
  }

  /// バージョン更新ダイアログを表示
  void _showVersionUpdateDialog(ReleaseNote latestRelease) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VersionUpdateDialog(
        latestRelease: latestRelease,
        currentTheme: currentTheme,
        currentFont: currentFont,
        currentFontSize: currentFontSize,
        onViewDetails: () {
          Navigator.of(context).pop(); // ダイアログを閉じる
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReleaseHistoryScreen(
                currentTheme: currentTheme,
                currentFont: currentFont,
                currentFontSize: currentFontSize,
              ),
            ),
          );
        },
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void showAddTabDialog() {
    final dataProvider = context.read<DataProvider>();
    final purchaseService = context.read<OneTimePurchaseService>();
    _showAddTabDialogWithProviders(dataProvider, purchaseService);
  }

  void _showAddTabDialogWithProviders(
    DataProvider dataProvider,
    OneTimePurchaseService purchaseService,
  ) {
    final controller = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '新しいタブを追加',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'タブ名',
                  labelStyle: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
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

                try {
                  // DataProviderを使用してクラウドに保存
                  await dataProvider.addShop(newShop);

                  setState(() {
                    nextShopId = (int.parse(nextShopId) + 1).toString();
                  });

                  // インタースティシャル広告の表示を試行
                  await _showInterstitialAdSafely();

                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                } catch (e) {
                  if (!mounted) return;

                  // エラーダイアログを表示
                  Navigator.of(this.context).pop(); // タブ作成ダイアログを閉じる
                  showDialog(
                    context: this.context,
                    builder: (context) => AlertDialog(
                      title: const Text('エラー'),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('追加', style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        );
      },
    );
  }

  void showBudgetDialog(Shop shop) {
    BudgetDialog.show(context, shop);
  }

  void showTabEditDialog(int tabIndex, List<Shop> shops) {
    final controller = TextEditingController(text: shops[tabIndex].name);
    final currentShop = shops[tabIndex];
    final otherShops =
        shops.where((shop) => shop.id != currentShop.id).toList();
    Set<String> selectedTabIds = Set<String>.from(currentShop.sharedTabs);

    // 共有グループアイコンの選択状態を管理
    String? selectedIconName = currentShop.sharedGroupIcon;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: getCustomTheme(),
              child: AlertDialog(
                title:
                    Text('タブ編集', style: Theme.of(context).textTheme.titleLarge),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'タブ名',
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (otherShops.isNotEmpty) ...[
                        Text(
                          '共有するタブを選択',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...otherShops.map((shop) {
                          return CheckboxListTile(
                            title: Text(shop.name),
                            value: selectedTabIds.contains(shop.id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedTabIds.add(shop.id);
                                } else {
                                  selectedTabIds.remove(shop.id);
                                }
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                        if (selectedTabIds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '共有したいタブを選択すると共有が有効になります。',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ),
                        // 共有マーク選択UI（共有タブが選択されている場合のみ表示）
                        if (selectedTabIds.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            '共有マークを選択',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: SharedGroupIcons.presets.map((preset) {
                                final isSelected =
                                    selectedIconName == preset.name;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedIconName = preset.name;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.grey.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        preset.icon,
                                        size: 20,
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context).iconTheme.color,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                      if (otherShops.isEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '共有できる他のタブがありません。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
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

                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                      },
                      child:
                          const Text('削除', style: TextStyle(color: Colors.red)),
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

                      // 共有処理と名前更新を同時に行う
                      if (selectedTabIds.isNotEmpty) {
                        await context.read<DataProvider>().updateSharedGroup(
                              currentShop.id,
                              selectedTabIds.toList(),
                              name: name, // 名前も渡す
                              sharedGroupIcon: selectedIconName, // 選択されたアイコンも渡す
                            );
                      } else if (currentShop.sharedGroupId != null ||
                          currentShop.sharedTabs.isNotEmpty) {
                        await context
                            .read<DataProvider>()
                            .removeFromSharedGroup(
                              currentShop.id,
                              originalSharedGroupId: currentShop.sharedGroupId,
                              name: name, // 名前も渡す
                            );
                      } else {
                        // 共有なしで名前だけ変更する場合
                        final updatedShop = currentShop.copyWith(name: name);
                        await context
                            .read<DataProvider>()
                            .updateShop(updatedShop);
                      }

                      if (!mounted) return;
                      Navigator.of(this.context).pop();
                    },
                    child: Text('保存',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(ListItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: getCustomTheme(),
          child: AlertDialog(
            title: const Text('名前を変更'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'アイテム名',
                hintText: '新しい名前を入力してください',
              ),
              autofocus: true,
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

                  try {
                    await context.read<DataProvider>().updateItem(
                          item.copyWith(name: name),
                        );
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
  }

  void showItemEditDialog({ListItem? original, required Shop shop}) {
    ItemEditDialog.show(
      context,
      original: original,
      shop: shop,
      onItemSaved: () async {
        await _showInterstitialAdSafely();
      },
    );
  }

  void showSortDialog(bool isIncomplete, Shop shop) {
    final dataProvider = context.read<DataProvider>();
    if (dataProvider.shops.isEmpty) return;

    SortDialog.show(
      context,
      shop: shop,
      isIncomplete: isIncomplete,
      onSortChanged: () async {
        // 並べ替えモード変更後にUIを強制的に再描画
        if (mounted) {
          setState(() {});
        }
        await _showInterstitialAdSafely();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('削除するアイテムがありません'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
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
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final dataProvider = context.read<DataProvider>();
                try {
                  final itemIds = itemsToDelete.map((item) => item.id).toList();
                  await dataProvider.deleteItems(itemIds);

                  if (!mounted) return;

                  await _showInterstitialAdSafely();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Theme.of(this.context).colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  // ソートモードの比較関数
  int Function(ListItem, ListItem) comparatorFor(SortMode mode) {
    switch (mode) {
      case SortMode.manual:
        // sortOrderが同じ場合はidで安定ソート
        return (a, b) {
          final orderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (orderCompare != 0) return orderCompare;
          return a.id.compareTo(b.id);
        };
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

  /// 安全なインタースティシャル広告表示
  Future<void> _showInterstitialAdSafely() async {
    try {
      debugPrint('🎬 安全なインタースティシャル広告表示を開始');
      InterstitialAdService().incrementOperationCount();
      await InterstitialAdService().showAdIfReady();
      debugPrint('✅ 安全なインタースティシャル広告表示完了');
    } catch (e) {
      debugPrint('❌ インタースティシャル広告表示中にエラーが発生: $e');
      // エラーが発生してもアプリの動作を継続
    }
  }

  /// 未購入リストの並べ替え処理
  Future<void> _reorderIncItems(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final dataProvider = context.read<DataProvider>();
    final shops = dataProvider.shops;
    if (shops.isEmpty) {
      debugPrint('❌ 未購入並べ替え中断: shopsが空のため処理を停止します');
      return;
    }

    Shop? shop;
    if (selectedTabId != null) {
      final matchedIndex = shops.indexWhere((s) => s.id == selectedTabId);
      if (matchedIndex != -1) {
        shop = shops[matchedIndex];
        selectedTabIndex = matchedIndex;
      } else {
        shop = shops[selectedTabIndex.clamp(0, shops.length - 1)];
        selectedTabId = shop.id;
      }
    } else {
      var safeIndex = selectedTabIndex;
      if (safeIndex < 0 || safeIndex >= shops.length) {
        debugPrint(
            '⚠️ 未購入並べ替え: selectedTabIndex=$safeIndex が範囲外。shops.length=${shops.length}');
        safeIndex = safeIndex.clamp(0, shops.length - 1);
        selectedTabIndex = safeIndex;
      }
      shop = shops[selectedTabIndex];
      selectedTabId = shop.id;
    }

    // UIの表示順序と一致させるため、手動並べ替えモード時はsortOrder順にソート
    var incItems = shop.items.where((e) => !e.isChecked).toList();
    if (shop.incSortMode == SortMode.manual) {
      incItems.sort(comparatorFor(SortMode.manual));
    }

    debugPrint(
        '🔄 並べ替え開始: oldIndex=$oldIndex, newIndex=$newIndex, リスト長=${incItems.length}');

    // 範囲チェック（調整前）
    if (oldIndex < 0 ||
        oldIndex >= incItems.length ||
        newIndex < 0 ||
        newIndex > incItems.length) {
      debugPrint(
          '❌ インデックスが範囲外: oldIndex=$oldIndex, newIndex=$newIndex, リスト長=${incItems.length}');
      return;
    }

    // newIndexを調整（ReorderableListViewの仕様）
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 調整後の範囲チェック
    if (newIndex < 0 || newIndex >= incItems.length) {
      debugPrint(
          '❌ 調整後のnewIndexが範囲外: newIndex=$newIndex, リスト長=${incItems.length}');
      return;
    }

    debugPrint('✅ 調整後: oldIndex=$oldIndex, newIndex=$newIndex');

    // 並び替え処理（リスト要素を確実に更新するため新しいリストを作成）
    final reorderedIncItems = List<ListItem>.from(incItems);
    final item = reorderedIncItems[oldIndex];
    reorderedIncItems.removeAt(oldIndex);
    reorderedIncItems.insert(newIndex, item);

    // sortOrderを更新（未購入リストのみを0から連番で振り直し）
    final updatedIncItems = <ListItem>[];
    for (int i = 0; i < reorderedIncItems.length; i++) {
      updatedIncItems.add(reorderedIncItems[i].copyWith(sortOrder: i));
    }

    // 購入済みリストは既存の状態を保持（変更なし）
    final comItems = shop.items.where((e) => e.isChecked).toList();

    // ショップを更新
    final updatedShop = shop.copyWith(
      items: [...updatedIncItems, ...comItems],
      incSortMode: SortMode.manual,
    );

    // Provider経由で更新（楽観的更新を含む）
    // 新しいreorderItemsメソッドを使用して、バッチ更新を行う
    try {
      await dataProvider.reorderItems(updatedShop, updatedIncItems);
    } catch (e) {
      debugPrint('❌ 未購入リスト並べ替えエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '並べ替えの保存に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 購入済みリストの並べ替え処理
  Future<void> _reorderComItems(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final dataProvider = context.read<DataProvider>();
    final shops = dataProvider.shops;
    if (shops.isEmpty) {
      debugPrint('❌ 購入済み並べ替え中断: shopsが空のため処理を停止します');
      return;
    }

    Shop? shop;
    if (selectedTabId != null) {
      final matchedIndex = shops.indexWhere((s) => s.id == selectedTabId);
      if (matchedIndex != -1) {
        shop = shops[matchedIndex];
        selectedTabIndex = matchedIndex;
      } else {
        shop = shops[selectedTabIndex.clamp(0, shops.length - 1)];
        selectedTabId = shop.id;
      }
    } else {
      var safeIndex = selectedTabIndex;
      if (safeIndex < 0 || safeIndex >= shops.length) {
        debugPrint(
            '⚠️ 購入済み並べ替え: selectedTabIndex=$safeIndex が範囲外。shops.length=${shops.length}');
        safeIndex = safeIndex.clamp(0, shops.length - 1);
        selectedTabIndex = safeIndex;
      }
      shop = shops[selectedTabIndex];
      selectedTabId = shop.id;
    }

    // UIの表示順序と一致させるため、手動並べ替えモード時はsortOrder順にソート
    var comItems = shop.items.where((e) => e.isChecked).toList();
    if (shop.comSortMode == SortMode.manual) {
      comItems.sort(comparatorFor(SortMode.manual));
    }

    debugPrint(
        '🔄 購入済み並べ替え開始: oldIndex=$oldIndex, newIndex=$newIndex, リスト長=${comItems.length}');

    // 範囲チェック（調整前）
    if (oldIndex < 0 ||
        oldIndex >= comItems.length ||
        newIndex < 0 ||
        newIndex > comItems.length) {
      debugPrint(
          '❌ インデックスが範囲外: oldIndex=$oldIndex, newIndex=$newIndex, リスト長=${comItems.length}');
      return;
    }

    // newIndexを調整（ReorderableListViewの仕様）
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 調整後の範囲チェック
    if (newIndex < 0 || newIndex >= comItems.length) {
      debugPrint(
          '❌ 調整後のnewIndexが範囲外: newIndex=$newIndex, リスト長=${comItems.length}');
      return;
    }

    debugPrint('✅ 調整後: oldIndex=$oldIndex, newIndex=$newIndex');

    // 並び替え処理（リスト要素を確実に更新するため新しいリストを作成）
    final reorderedComItems = List<ListItem>.from(comItems);
    final item = reorderedComItems[oldIndex];
    reorderedComItems.removeAt(oldIndex);
    reorderedComItems.insert(newIndex, item);

    // sortOrderを更新（購入済みリストのみを10000から連番で振り直し、オフセット使用）
    final updatedComItems = <ListItem>[];
    for (int i = 0; i < reorderedComItems.length; i++) {
      updatedComItems.add(reorderedComItems[i].copyWith(sortOrder: 10000 + i));
    }

    // 未購入リストは既存の状態を保持（変更なし）
    final incItems = shop.items.where((e) => !e.isChecked).toList();

    // ショップを更新
    final updatedShop = shop.copyWith(
      items: [...incItems, ...updatedComItems],
      comSortMode: SortMode.manual,
    );

    // Provider経由で更新（楽観的更新を含む）
    // 新しいreorderItemsメソッドを使用して、バッチ更新を行う
    try {
      await dataProvider.reorderItems(updatedShop, updatedComItems);
    } catch (e) {
      debugPrint('❌ 購入済みリスト並べ替えエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '並べ替えの保存に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    currentTheme = widget.initialTheme ?? 'pink';
    currentFont = widget.initialFont ?? 'nunito';
    currentFontSize = widget.initialFontSize ?? 16.0;

    // TabController は length>=1 必須。初期はダミーで1にしておく
    tabController = TabController(length: 1, vsync: this);

    // 初回起動時にウェルカムダイアログを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowWelcomeDialog();
      _checkForVersionUpdate();
      // 保存された設定を読み込む
      loadSavedThemeAndFont();
      // 保存されたタブインデックスを読み込む
      loadSavedTabIndex();

      // DataProviderに認証プロバイダーを設定
      final dataProvider = context.read<DataProvider>();
      final authProvider = context.read<AuthProvider>();
      dataProvider.setAuthProvider(authProvider);

      // ハイブリッドOCRサービスの初期化
      _initializeHybridOcr();
    });
  }

  /// ハイブリッドOCRサービスの初期化
  Future<void> _initializeHybridOcr() async {
    try {
      await _hybridOcrService.initialize();
    } catch (e) {
      debugPrint('❌ ハイブリッドOCR初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    // インタースティシャル広告の破棄
    InterstitialAdService().dispose();
    // ハイブリッドOCRサービスの破棄
    _hybridOcrService.dispose();
    super.dispose();
  }

  // 初回起動時にウェルカムダイアログを表示するメソッド
  Future<void> checkAndShowWelcomeDialog() async {
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
  void onTabChanged() {
    if (tabController.indexIsChanging) {
      return;
    }
    if (mounted && tabController.length > 0) {
      final dataProvider = context.read<DataProvider>();
      final sortedShops = TabSorter.sortShopsBySharedGroups(
        dataProvider.shops,
      );

      final newIndex = tabController.index;
      final safeIndex = newIndex.clamp(0, sortedShops.length - 1);
      final newTabId =
          sortedShops.isNotEmpty ? sortedShops[safeIndex].id : null;

      setState(() {
        selectedTabIndex = newIndex;
        selectedTabId = newTabId;
      });

      SettingsPersistence.saveSelectedTabIndex(newIndex);
      if (newTabId != null) {
        SettingsPersistence.saveSelectedTabId(newTabId);
      }
    }
  }

  // 認証状態の変更を監視してテーマとフォントを更新
  void updateThemeAndFontIfNeeded(AuthProvider authProvider) {
    // 認証状態が変更された際に、保存されたテーマとフォントを読み込む
    if (authProvider.isLoggedIn) {
      loadSavedThemeAndFont();

      // DataProviderに認証プロバイダーを設定（初回のみ）
      final dataProvider = context.read<DataProvider>();
      dataProvider.setAuthProvider(authProvider);
    }
  }

  // 保存されたテーマとフォントを読み込む
  Future<void> loadSavedThemeAndFont() async {
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
      // テーマ・フォント読み込みエラーは無視
    }
  }

  // 保存されたタブインデックスを読み込む
  Future<void> loadSavedTabIndex() async {
    try {
      final savedIndex = await SettingsPersistence.loadSelectedTabIndex();
      final savedId = await SettingsPersistence.loadSelectedTabId();
      if (mounted) {
        setState(() {
          selectedTabIndex = savedIndex;
          selectedTabId = (savedId == null || savedId.isEmpty) ? null : savedId;
        });
      }
    } catch (e) {
      // タブインデックス読み込みエラーは無視
    }
  }

  // カスタムカラー変更を処理
  void updateCustomColors(Map<String, Color> colors) {
    setState(() {
      customColors = Map<String, Color>.from(colors);
    });
    widget.onCustomColorsChanged?.call(customColors);
  }

  // タブの高さを動的に計算するメソッド
  double _calculateTabHeight() {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    // フォントサイズに基づいてタブの高さを計算
    // 基本高さ（パディング含む）+ フォントサイズに応じた追加高さ
    const baseHeight = 24.0; // 基本のパディングとボーダー分（32.0から24.0に縮小）
    final fontHeight = fontSize * 1.2; // フォントサイズの1.2倍を高さとして使用（1.5から1.2に縮小）
    final totalHeight = baseHeight + fontHeight;

    // 最小高さと最大高さを設定（範囲も縮小）
    return totalHeight.clamp(32.0, 60.0);
  }

  // タブのパディングを動的に計算するメソッド
  double _calculateTabPadding() {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    // フォントサイズに基づいてパディングを計算
    // フォントサイズが大きいほどパディングも大きくする
    const basePadding = 6.0; // 基本パディングを8.0から6.0に縮小
    final additionalPadding =
        (fontSize - 16.0) * 0.25; // 追加パディングの係数を0.3から0.25に縮小
    final totalPadding = basePadding + additionalPadding;

    // 最小パディングと最大パディングを設定（範囲も縮小）
    return totalPadding.clamp(6.0, 16.0);
  }

  // タブ内のテキストの最大行数を計算するメソッド
  int _calculateMaxLines() {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    // フォントサイズが大きいほど行数を減らす
    if (fontSize > 20) {
      return 1; // フォントサイズが大きい場合は1行のみ
    } else if (fontSize > 18) {
      return 1; // 中程度のフォントサイズも1行
    } else {
      return 2; // 小さいフォントサイズは2行まで
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, AuthProvider>(
      builder: (context, dataProvider, authProvider, child) {
        // 認証状態の変更を監視してテーマとフォントを更新
        updateThemeAndFontIfNeeded(authProvider);

        // 共有グループごとにタブを並び替え
        final sortedShops =
            TabSorter.sortShopsBySharedGroups(dataProvider.shops);

        // TabControllerの長さを更新（sortedShopsが存在する場合のみ）
        if (sortedShops.isNotEmpty &&
            tabController.length != sortedShops.length) {
          final newLength = sortedShops.length;

          tabController.dispose();

          // 安全な初期インデックスを計算
          int initialIndex = 0;
          if (newLength > 0) {
            if (selectedTabId != null) {
              final restoredIndex =
                  sortedShops.indexWhere((shop) => shop.id == selectedTabId);
              if (restoredIndex != -1) {
                initialIndex = restoredIndex;
              } else {
                initialIndex = selectedTabIndex.clamp(0, newLength - 1);
              }
            } else {
              initialIndex = selectedTabIndex.clamp(0, newLength - 1);
            }
          }

          tabController = TabController(
            length: sortedShops.length,
            vsync: this,
            initialIndex: initialIndex,
          );
          selectedTabIndex = initialIndex;
          selectedTabId =
              sortedShops.isNotEmpty ? sortedShops[initialIndex].id : null;
          // リスナーを追加
          tabController.addListener(onTabChanged);
        }

        // shopsが空の場合は0を返す
        final selectedIndex = sortedShops.isEmpty
            ? 0
            : (tabController.index >= 0 &&
                    tabController.index < sortedShops.length)
                ? tabController.index
                : 0;

        // ローディング中の場合
        if (dataProvider.isLoading) {
          return Scaffold(
            backgroundColor: getCustomTheme().scaffoldBackgroundColor,
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
        final shop = sortedShops.isEmpty
            ? null
            : sortedShops[selectedIndex.clamp(
                0,
                sortedShops.length - 1,
              )];
        if (shop != null) {
          selectedTabId = shop.id;
        }

        // アイテムの分類とソートを一度だけ実行
        // 手動並べ替えモードの場合はsortOrder順、それ以外はソートモード順
        final incItems = shop?.items.where((e) => !e.isChecked).toList() ?? [];
        if (shop == null || shop.incSortMode == SortMode.manual) {
          incItems.sort(comparatorFor(SortMode.manual));
        } else {
          debugPrint(
              '📊 未購入リスト ソートモード: ${shop.incSortMode.label} (アイテム数: ${incItems.length})');
          incItems.sort(comparatorFor(shop.incSortMode));
        }

        final comItems = shop?.items.where((e) => e.isChecked).toList() ?? [];
        if (shop == null || shop.comSortMode == SortMode.manual) {
          comItems.sort(comparatorFor(SortMode.manual));
        } else {
          debugPrint(
              '📊 購入済みリスト ソートモード: ${shop.comSortMode.label} (アイテム数: ${comItems.length})');
          comItems.sort(comparatorFor(shop.comSortMode));
        }

        return Scaffold(
          backgroundColor: getCustomTheme().scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  currentTheme == 'dark' ? Brightness.light : Brightness.dark,
              systemNavigationBarIconBrightness:
                  currentTheme == 'dark' ? Brightness.light : Brightness.dark,
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: _calculateTabHeight(),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedShops.length,
                  itemBuilder: (context, index) {
                    final shop = sortedShops[index];
                    final isSelected = index == selectedIndex;

                    return GestureDetector(
                      onLongPress: () {
                        // 元のインデックスを取得して編集ダイアログを表示
                        final originalIndex = dataProvider.shops
                            .indexWhere((s) => s.id == shop.id);
                        if (originalIndex != -1) {
                          showTabEditDialog(originalIndex, dataProvider.shops);
                        }
                      },
                      onTap: () {
                        if (sortedShops.isNotEmpty &&
                            index < sortedShops.length) {
                          if (sortedShops.isNotEmpty &&
                              index >= 0 &&
                              index < sortedShops.length &&
                              tabController.length > 0 &&
                              index < tabController.length) {
                            if (mounted) {
                              setState(() {
                                tabController.index = index;
                                selectedTabIndex = index;
                                selectedTabId = sortedShops[index].id;
                              });
                              // タブインデックスを保存
                              SettingsPersistence.saveSelectedTabIndex(index);
                              final tabId = sortedShops[index].id;
                              if (tabId.isNotEmpty) {
                                SettingsPersistence.saveSelectedTabId(tabId);
                              }
                            }
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: _calculateTabPadding(),
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (currentTheme == 'custom' &&
                                      customColors.containsKey('tabColor')
                                  ? customColors['tabColor']
                                  : (currentTheme == 'light'
                                      ? const Color(0xFF9E9E9E)
                                      : currentTheme == 'dark'
                                          ? Colors.grey[600]
                                          : getCustomTheme()
                                              .colorScheme
                                              .primary))
                              : (shop.sharedGroupId != null
                                  ? (currentTheme == 'dark'
                                      ? getCustomTheme()
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.2)
                                      : getCustomTheme()
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1))
                                  : (currentTheme == 'dark'
                                      ? Colors.black
                                      : Colors.white)),
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
                            width: shop.sharedGroupId != null
                                ? 2
                                : 1, // 共有タブは枠線を太く
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (currentTheme == 'custom' &&
                                                customColors.containsKey(
                                                  'tabColor',
                                                )
                                            ? customColors['tabColor']!
                                            : (currentTheme == 'light'
                                                ? const Color(0xFF9E9E9E)
                                                : currentTheme == 'dark'
                                                    ? Colors.grey[600]!
                                                    : getCustomTheme()
                                                        .colorScheme
                                                        .primary))
                                        .withAlpha((255 * 0.3).round()),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                shop.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (currentTheme == 'dark'
                                          ? Colors.white70
                                          : Colors.black54),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.fontSize ??
                                      16.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: _calculateMaxLines(),
                                textAlign: TextAlign.center,
                              ),
                              if (shop.sharedGroupId != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  SharedGroupIcons.getIconFromName(
                                      shop.sharedGroupIcon),
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : (currentTheme == 'custom' &&
                                              customColors
                                                  .containsKey('primary')
                                          ? customColors['primary']!
                                          : getCustomTheme()
                                              .colorScheme
                                              .primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor:
                currentTheme == 'dark' ? Colors.white : Colors.black87,
            elevation: 0,
            actions: [
              Consumer2<DataProvider, OneTimePurchaseService>(
                builder: (context, dataProvider, purchaseService, _) {
                  return IconButton(
                    icon: Icon(
                      Icons.add,
                      color: (currentTheme == 'dark' || currentTheme == 'light')
                          ? Colors.white
                          : Theme.of(context).iconTheme.color,
                    ),
                    onPressed: () {
                      _showAddTabDialogWithProviders(
                        dataProvider,
                        purchaseService,
                      );
                    },
                    tooltip: 'タブ追加',
                  );
                },
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
                        color: currentTheme == 'light'
                            ? Colors.white
                            : Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'まいカゴ',
                        style: TextStyle(
                          fontSize: 22,
                          color: currentTheme == 'light'
                              ? Colors.white
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 無料トライアル残り日数表示
                      Consumer<OneTimePurchaseService>(
                        builder: (context, purchaseService, child) {
                          if (purchaseService.isTrialActive) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '無料体験残り${purchaseService.trialRemainingDuration?.inDays ?? 0}日',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.info_outline_rounded,
                            color: currentTheme == 'dark'
                                ? Colors.white
                                : (currentTheme == 'light'
                                    ? Colors.black87
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            'アプリについて',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen()),
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
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '使い方',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UsageScreen()),
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
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '簡単電卓',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
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
                            Icons.palette_rounded,
                            color: currentTheme == 'dark'
                                ? Colors.white
                                : (currentTheme == 'light'
                                    ? Colors.black87
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '広告非表示\nテーマ・フォント解禁',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            );
                          },
                        ),

                        // `QRコードで参加` は削除されました。
                        ListTile(
                          leading: Icon(
                            Icons.favorite_rounded,
                            color: currentTheme == 'dark'
                                ? Colors.white
                                : (currentTheme == 'light'
                                    ? Colors.black87
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '寄付',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DonationScreen()),
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
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '今後の新機能',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
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
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            'フィードバック',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FeedbackScreen()),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.history_rounded,
                            color: currentTheme == 'dark'
                                ? Colors.white
                                : (currentTheme == 'light'
                                    ? Colors.black87
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '更新履歴',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReleaseHistoryScreen(
                                  currentTheme: currentTheme,
                                  currentFont: currentFont,
                                  currentFontSize: currentFontSize,
                                ),
                              ),
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
                                    : (currentTheme == 'lemon'
                                        ? Colors.black
                                        : getCustomTheme()
                                            .colorScheme
                                            .primary)),
                          ),
                          title: Text(
                            '設定',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentTheme == 'dark'
                                  ? Colors.white
                                  : (currentTheme == 'light'
                                      ? Colors.black87
                                      : (currentTheme == 'lemon'
                                          ? Colors.black
                                          : null)),
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
                                    // 先にテーマを即時反映（クロスフェードを避ける）
                                    updateGlobalTheme(themeKey);
                                    await SettingsPersistence.saveTheme(
                                        themeKey);
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
                                    await SettingsPersistence.saveFontSize(
                                        fontSize);
                                    if (widget.onFontSizeChanged != null) {
                                      widget.onFontSizeChanged!(fontSize);
                                    }
                                    updateGlobalFontSize(fontSize);
                                  },
                                  onCustomThemeChanged: (colors) {
                                    updateCustomColors(colors);
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
                                  isDarkMode: getCustomTheme().brightness ==
                                      Brightness.dark,
                                  theme: getCustomTheme(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 32.0, 8.0, 8.0),
            child: Row(
              children: [
                // 未完了セクション（左側）
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 24.0),
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
                                if (shop != null) {
                                  showSortDialog(true, shop);
                                }
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
                        child: ClipRect(
                          child: incItems.isEmpty
                              ? const SizedBox.shrink()
                              : ReorderableListView.builder(
                                  padding: EdgeInsets.only(
                                    left: 4,
                                    right: 4,
                                    top: 8,
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                            8,
                                  ),
                                  itemCount: incItems.length,
                                  onReorder: _reorderIncItems,
                                  cacheExtent: 50,
                                  physics: const ClampingScrollPhysics(),
                                  clipBehavior: Clip.hardEdge,
                                  itemBuilder: (context, idx) {
                                    final item = incItems[idx];
                                    return ListEdit(
                                      key: ValueKey(item.id),
                                      item: item,
                                      onCheckToggle: (checked) async {
                                        if (shop == null) return;

                                        final dataProvider =
                                            context.read<DataProvider>();
                                        final shopIndex =
                                            dataProvider.shops.indexOf(shop);
                                        if (shopIndex != -1) {
                                          // 共有グループの合計を更新
                                          if (shop.sharedGroupId != null) {
                                            dataProvider.notifyDataChanged();
                                          }
                                        }

                                        try {
                                          // チェック時は購入済みリストの末尾に追加
                                          final dataProvider =
                                              context.read<DataProvider>();
                                          final shop = selectedTabId != null
                                              ? dataProvider.shops.firstWhere(
                                                  (s) => s.id == selectedTabId,
                                                  orElse: () => dataProvider
                                                          .shops[
                                                      selectedTabIndex.clamp(
                                                          0,
                                                          dataProvider.shops
                                                                  .length -
                                                              1)],
                                                )
                                              : dataProvider.shops[
                                                  selectedTabIndex.clamp(
                                                      0,
                                                      dataProvider
                                                              .shops.length -
                                                          1)];
                                          final comItems = shop.items
                                              .where((e) => e.isChecked)
                                              .toList();
                                          // チェック状態に応じて適切なsortOrderを設定
                                          final newSortOrder = checked
                                              ? 10000 +
                                                  comItems.length // 購入済みリストの末尾
                                              : incItems.length; // 未購入リストの末尾

                                          await dataProvider.updateItem(
                                            item.copyWith(
                                              isChecked: checked,
                                              sortOrder: newSortOrder,
                                            ),
                                          );

                                          // 共有グループの合計を更新
                                          if (shop.sharedGroupId != null) {
                                            dataProvider.notifyDataChanged();
                                          }
                                        } catch (e) {
                                          final shopIndex =
                                              dataProvider.shops.indexOf(shop);
                                          if (shopIndex != -1) {
                                            final revertedItems =
                                                shop.items.map((shopItem) {
                                              return shopItem.id == item.id
                                                  ? item.copyWith(
                                                      isChecked: !checked,
                                                    )
                                                  : shopItem;
                                            }).toList();
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
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
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

                                          await _showInterstitialAdSafely();
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
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onRename: () {
                                        if (shop != null) {
                                          _showRenameDialog(item);
                                        }
                                      },
                                      onUpdate: (updatedItem) async {
                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .updateItem(updatedItem);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                    'Exception: ', ''),
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              duration:
                                                  const Duration(seconds: 3),
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
                Container(
                  width: 1,
                  height: 600,
                  margin: const EdgeInsets.only(top: 50),
                  color: getCustomTheme().dividerColor,
                ),
                // 完了済みセクション（右側）
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 24.0),
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
                                if (shop != null) {
                                  showSortDialog(false, shop);
                                }
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
                        child: ClipRect(
                          child: comItems.isEmpty
                              ? const SizedBox.shrink()
                              : ReorderableListView.builder(
                                  padding: EdgeInsets.only(
                                    left: 4,
                                    right: 4,
                                    top: 8,
                                    bottom:
                                        MediaQuery.of(context).padding.bottom +
                                            8,
                                  ),
                                  itemCount: comItems.length,
                                  onReorder: _reorderComItems,
                                  cacheExtent: 50,
                                  physics: const ClampingScrollPhysics(),
                                  clipBehavior: Clip.hardEdge,
                                  itemBuilder: (context, idx) {
                                    final item = comItems[idx];
                                    return ListEdit(
                                      key: ValueKey(item.id),
                                      item: item,
                                      onCheckToggle: (checked) async {
                                        if (shop == null) return;

                                        final dataProvider =
                                            context.read<DataProvider>();
                                        final shopIndex =
                                            dataProvider.shops.indexOf(shop);
                                        if (shopIndex != -1) {
                                          // 共有グループの合計を更新
                                          if (shop.sharedGroupId != null) {
                                            dataProvider.notifyDataChanged();
                                          }
                                        }

                                        try {
                                          // アンチェック時は未購入リストの末尾に追加
                                          final dataProvider =
                                              context.read<DataProvider>();
                                          final shop = selectedTabId != null
                                              ? dataProvider.shops.firstWhere(
                                                  (s) => s.id == selectedTabId,
                                                  orElse: () => dataProvider
                                                          .shops[
                                                      selectedTabIndex.clamp(
                                                          0,
                                                          dataProvider.shops
                                                                  .length -
                                                              1)],
                                                )
                                              : dataProvider.shops[
                                                  selectedTabIndex.clamp(
                                                      0,
                                                      dataProvider
                                                              .shops.length -
                                                          1)];
                                          final incItems = shop.items
                                              .where((e) => !e.isChecked)
                                              .toList();
                                          // チェック状態に応じて適切なsortOrderを設定
                                          final newSortOrder = checked
                                              ? 10000 +
                                                  comItems.length // 購入済みリストの末尾
                                              : incItems.length; // 未購入リストの末尾

                                          await dataProvider.updateItem(
                                            item.copyWith(
                                              isChecked: checked,
                                              sortOrder: newSortOrder,
                                            ),
                                          );

                                          // 共有グループの合計を更新
                                          if (shop.sharedGroupId != null) {
                                            dataProvider.notifyDataChanged();
                                          }
                                        } catch (e) {
                                          final shopIndex =
                                              dataProvider.shops.indexOf(shop);
                                          if (shopIndex != -1) {
                                            final revertedItems =
                                                shop.items.map((shopItem) {
                                              return shopItem.id == item.id
                                                  ? item.copyWith(
                                                      isChecked: !checked)
                                                  : shopItem;
                                            }).toList();
                                            final revertedShop = shop.copyWith(
                                                items: revertedItems);
                                            dataProvider.shops[shopIndex] =
                                                revertedShop;
                                          }

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                    'Exception: ', ''),
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              duration:
                                                  const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                      onEdit: () {
                                        if (shop != null) {
                                          showItemEditDialog(
                                              original: item, shop: shop);
                                        }
                                      },
                                      onDelete: () async {
                                        if (shop == null) return;

                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .deleteItem(item.id);
                                          await _showInterstitialAdSafely();
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                    'Exception: ', ''),
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              duration:
                                                  const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                      onRename: () {
                                        if (shop != null) {
                                          _showRenameDialog(item);
                                        }
                                      },
                                      onUpdate: (updatedItem) async {
                                        try {
                                          await context
                                              .read<DataProvider>()
                                              .updateItem(updatedItem);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceAll(
                                                    'Exception: ', ''),
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              duration:
                                                  const Duration(seconds: 3),
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
                      color: getCustomTheme().scaffoldBackgroundColor,
                      child: const AdBanner(),
                    ),
                    // ボトムサマリー
                    Container(
                      margin: const EdgeInsets.only(top: 0.0),
                      child: BottomSummary(
                        shop: shop,
                        onBudgetClick: () => showBudgetDialog(shop),
                        onFab: () => showItemEditDialog(shop: shop),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // バナー広告（ショップがない場合も表示）
                    Container(
                      width: double.infinity,
                      color: getCustomTheme().scaffoldBackgroundColor,
                      child: const AdBanner(),
                    ),
                  ],
                ),
        );
      },
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
  int? _cachedCurrentTabTotal;
  bool _cacheInitialized = false;
  String? _cachedSharedGroupId;

  // ハイブリッドOCRサービス
  final HybridOcrService _hybridOcrService = HybridOcrService();

  @override
  void initState() {
    super.initState();
    _refreshData();

    // ハイブリッドOCRサービスの初期化
    _initializeHybridOcr();
  }

  /// ハイブリッドOCRサービスの初期化
  Future<void> _initializeHybridOcr() async {
    try {
      await _hybridOcrService.initialize();
    } catch (e) {
      debugPrint('❌ ハイブリッドOCR初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    // ハイブリッドOCRサービスの破棄
    _hybridOcrService.dispose();
    super.dispose();
  }

  Future<void> _onImageAnalyzePressed() async {
    try {
      debugPrint('📷 統合カメラ画面で追加フロー開始');

      // 値札撮影カメラ画面を表示
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => EnhancedCameraScreen(
            onImageCaptured: (File image) {
              Navigator.of(context).pop({'type': 'image', 'data': image});
            },
          ),
        ),
      );

      if (result == null) {
        debugPrint('ℹ️ カメラをキャンセルしました');
        return;
      }

      if (!mounted) return;

      // 値札撮影結果の処理
      if (result['type'] == 'image') {
        final imageFile = result['data'] as File;
        await _handleImageCaptured(imageFile);
      }
    } catch (e) {
      debugPrint('❌ カメラ処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
          _cachedSharedGroupId = sharedGroupId;
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
            await dataProvider.getSharedGroupTotal(widget.shop.sharedGroupId!);
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

        return {'total': total, 'budget': budget, 'isSharedMode': false};
      }
    } catch (e) {
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
          final previousSharedGroupId = _cachedSharedGroupId;
          final currentSharedGroupId = widget.shop.sharedGroupId;

          _currentShopId = widget.shop.id;

          // 共有グループIDが変わった場合のみキャッシュをクリア
          if (previousSharedGroupId != currentSharedGroupId) {
            _cacheInitialized = false;
            _cachedTotal = null;
            _cachedBudget = null;
            _cachedSharedMode = null;
            _cachedCurrentTabTotal = null;
            _cachedSharedGroupId = currentSharedGroupId;
          }

          _refreshData(); // データを再取得
        } else {
          // 同じショップでもデータが変更された場合は再計算
          _refreshData();
        }

        // キャッシュされたデータがあるかチェック
        int displayTotal;
        int? budget;
        bool isSharedMode = false;
        int? currentTabTotal;

        final currentSharedGroupId = widget.shop.sharedGroupId;

        if (_cacheInitialized &&
            _cachedSharedMode != null &&
            _cachedSharedGroupId == currentSharedGroupId) {
          // キャッシュされたデータを使用
          displayTotal = _cachedTotal ?? _calculateCurrentShopTotal();
          budget = _cachedBudget;
          isSharedMode = _cachedSharedMode!;
          currentTabTotal = _cachedCurrentTabTotal;
        } else {
          // キャッシュがない場合は即座計算値を使用
          isSharedMode = currentSharedGroupId != null;
          if (isSharedMode) {
            // 共有モードの場合：
            // displayTotal は後で _refreshData で更新されるため、一時的に現在のタブの合計を使用
            currentTabTotal = _calculateCurrentShopTotal();
            displayTotal = currentTabTotal; // 一時的な値
            budget = widget.shop.budget;
          } else {
            // 個別モードの場合
            displayTotal = _calculateCurrentShopTotal();
            budget = widget.shop.budget;
            currentTabTotal = null;
          }

          // キャッシュを初期化（_refreshData で正しい値に更新される）
          _cachedTotal = displayTotal;
          _cachedBudget = budget;
          _cachedSharedMode = isSharedMode;
          _cachedCurrentTabTotal = currentTabTotal;
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
          currentTabTotal,
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
    int? currentTabTotal,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
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
                  child: const Text(
                    '予算変更',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: _onImageAnalyzePressed,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text(
                    'カメラで追加',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(90, 40),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton(
                  onPressed: widget.onFab,
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                  child: const Icon(Icons.add),
                ),
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
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
                        // 合計金額表示
                        Expanded(
                          child: isSharedMode && currentTabTotal != null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // 1行目: 現在のタブの合計
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '現在のタブ',
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
                                        const SizedBox(width: 8),
                                        Text(
                                          '¥$currentTabTotal',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
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
                                        const SizedBox(width: 8),
                                        Text(
                                          '¥$total',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '合計金額',
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
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥$total',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(BottomSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id) {
      _refreshData();
    }
  }

  /// 値札撮影結果の処理
  Future<void> _handleImageCaptured(File imageFile) async {
    try {
      debugPrint('📸 値札画像処理開始');
      // 広告がWebViewレンダラーを使用しているため、OCR実行中は
      // インタースティシャル広告リソースを解放して競合を避ける
      try {
        InterstitialAdService().dispose();
      } catch (_) {}

      // 改善されたローディングダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ImageAnalysisProgressDialog(),
      );

      // Cloud Functionsのみを使用した高速OCR解析
      var res = await _hybridOcrService.detectItemFromImageFast(
        imageFile,
        onProgress: (step, message) {
          debugPrint('📊 OCR進行状況(Cloud Functions): $step - $message');
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // ローディング閉じる

      // OCR完了後は広告サービスを再初期化（非同期で安全に）
      try {
        InterstitialAdService().resetSession();
      } catch (_) {}

      if (res == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: const Text('読み取りに失敗しました'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
        return;
      }

      // データプロバイダーを取得
      final dataProvider = context.read<DataProvider>();

      final item = ListItem(
        id: '', // IDはDataProviderで生成されるため空
        name: res.name,
        quantity: 1,
        price: res.price,
        shopId: widget.shop.id,
        timestamp: DateTime.now(),
      );

      // データプロバイダーに追加
      await dataProvider.addItem(item);

      if (!mounted) return;

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${res.name} を追加しました'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      debugPrint('✅ 値札画像処理完了');
    } catch (e) {
      debugPrint('❌ 値札画像処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('値札の読み取りに失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
