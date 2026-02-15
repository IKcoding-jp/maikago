import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/providers/auth_provider.dart';
import 'package:maikago/providers/theme_provider.dart';
import 'package:maikago/services/ad/interstitial_ad_service.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';
import 'package:maikago/utils/tab_sorter.dart';

import 'package:maikago/services/ad/ad_banner.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/screens/main/dialogs/budget_dialog.dart';
import 'package:maikago/screens/main/dialogs/sort_dialog.dart';
import 'package:maikago/screens/main/dialogs/item_edit_dialog.dart';
import 'package:maikago/screens/main/dialogs/tab_edit_dialog.dart';
import 'package:maikago/screens/main/dialogs/tab_add_dialog.dart';
import 'package:maikago/screens/main/dialogs/item_rename_dialog.dart';
import 'package:maikago/screens/main/dialogs/bulk_delete_dialog.dart';
import 'package:maikago/screens/main/widgets/bottom_summary_widget.dart';
import 'package:maikago/screens/main/widgets/main_app_bar.dart';
import 'package:maikago/screens/main/widgets/main_drawer.dart';
import 'package:maikago/screens/main/widgets/item_list_section.dart';
import 'package:maikago/screens/main/utils/ui_calculations.dart';
import 'package:maikago/screens/main/utils/item_operations.dart';
import 'package:maikago/screens/main/utils/startup_helpers.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/services/settings_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController tabController;
  int selectedTabIndex = 0;
  String? selectedTabId;
  Map<String, Color> customColors = {
    'primary': AppColors.primary,
    'secondary': AppColors.secondary,
    'surface': AppColors.surface,
  };
  String nextShopId = '1';
  bool includeTax = false;
  InterstitialAdService? _interstitialAdService;
  bool _strikethroughEnabled = false;

  String get currentTheme => context.read<ThemeProvider>().selectedTheme;
  String get currentFont => context.read<ThemeProvider>().selectedFont;
  double get currentFontSize => context.read<ThemeProvider>().fontSize;

  Future<void> _checkForVersionUpdate() =>
      StartupHelpers.checkForVersionUpdate(context);

  void showAddTabDialog() {
    if (!mounted) return;
    TabAddDialog.show(
      context,
      nextShopId: nextShopId,
      onAdded: (newNextShopId) async {
        setState(() {
          nextShopId = newNextShopId;
        });
        await _showInterstitialAdSafely();
      },
    );
  }

  void showBudgetDialog(Shop shop) {
    BudgetDialog.show(context, shop);
  }

  void showTabEditDialog(int tabIndex, List<Shop> shops) {
    TabEditDialog.show(
      context,
      tabIndex: tabIndex,
      shops: shops,
      customTheme: Theme.of(context),
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

  void showBulkDeleteDialog(Shop shop, bool isIncomplete) {
    final itemsToDelete = isIncomplete
        ? shop.items.where((item) => !item.isChecked).toList()
        : shop.items.where((item) => item.isChecked).toList();

    if (itemsToDelete.isEmpty) {
      if (!mounted) return;
      showInfoSnackBar(context, '削除するアイテムがありません',
          duration: const Duration(seconds: 2));
      return;
    }

    BulkDeleteDialog.show(
      context,
      shop: shop,
      isIncomplete: isIncomplete,
      onDeleted: () async {
        await _showInterstitialAdSafely();
      },
    );
  }

  Future<void> _showInterstitialAdSafely() async {
    if (kIsWeb || _interstitialAdService == null) return;
    try {
      DebugService().log('🎬 安全なインタースティシャル広告表示を開始');
      _interstitialAdService!.incrementOperationCount();
      await _interstitialAdService!.showAdIfReady();
      DebugService().log('✅ 安全なインタースティシャル広告表示完了');
    } catch (e) {
      DebugService().log('❌ インタースティシャル広告表示中にエラーが発生: $e');
      // エラーが発生してもアプリの動作を継続
    }
  }

  Future<void> _reorderItems(int oldIndex, int newIndex, {required bool isIncomplete}) async {
    final result = await ItemOperations.reorderItems(
      context,
      selectedTabId: selectedTabId,
      selectedTabIndex: selectedTabIndex,
      oldIndex: oldIndex,
      newIndex: newIndex,
      isIncomplete: isIncomplete,
    );
    if (result != null) {
      selectedTabIndex = result.tabIndex;
      selectedTabId = result.tabId;
    }
  }

  Future<void> _reorderIncItems(int oldIndex, int newIndex) =>
      _reorderItems(oldIndex, newIndex, isIncomplete: true);

  Future<void> _reorderComItems(int oldIndex, int newIndex) =>
      _reorderItems(oldIndex, newIndex, isIncomplete: false);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        _interstitialAdService = context.read<InterstitialAdService>();
      } catch (_) {}
    }
    tabController = TabController(length: 1, vsync: this);
    _loadStrikethroughSetting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndShowWelcomeDialog();
      _checkForVersionUpdate();
      loadSavedTabIndex();
      final dataProvider = context.read<DataProvider>();
      final authProvider = context.read<AuthProvider>();
      dataProvider.setAuthProvider(authProvider);
    });
  }

  Future<void> _loadStrikethroughSetting() async {
    final enabled = await SettingsPersistence.loadStrikethrough();
    if (mounted) {
      setState(() {
        _strikethroughEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    _interstitialAdService?.dispose();
    super.dispose();
  }

  Future<void> checkAndShowWelcomeDialog() =>
      StartupHelpers.checkAndShowWelcomeDialog(context);

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

  void updateCustomColors(Map<String, Color> colors) {
    setState(() {
      customColors = Map<String, Color>.from(colors);
    });
  }

  void _handleTabTap(int index, List<Shop> sortedShops) {
    if (sortedShops.isEmpty || index < 0 || index >= sortedShops.length) return;
    if (tabController.length <= 0 || index >= tabController.length) return;
    if (!mounted) return;

    setState(() {
      tabController.index = index;
      selectedTabIndex = index;
      selectedTabId = sortedShops[index].id;
    });
    SettingsPersistence.saveSelectedTabIndex(index);
    final tabId = sortedShops[index].id;
    if (tabId.isNotEmpty) {
      SettingsPersistence.saveSelectedTabId(tabId);
    }
  }

  Future<void> _handleCheckToggle(ListItem item, bool checked) =>
      ItemOperations.handleCheckToggle(
        context,
        item: item,
        checked: checked,
        selectedTabId: selectedTabId,
        selectedTabIndex: selectedTabIndex,
      );

  /// アイテム削除処理
  Future<void> _handleDelete(ListItem item) =>
      ItemOperations.deleteItem(context, item: item, onSuccess: _showInterstitialAdSafely);

  /// アイテム更新処理
  Future<void> _handleUpdate(ListItem updatedItem) =>
      ItemOperations.updateItem(context, updatedItem: updatedItem);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBgLuminance =
        theme.scaffoldBackgroundColor.computeLuminance();

    return Consumer2<DataProvider, AuthProvider>(
      builder: (context, dataProvider, authProvider, child) {
        final sortedShops =
            TabSorter.sortShopsBySharedGroups(dataProvider.shops);

        if (sortedShops.isNotEmpty &&
            tabController.length != sortedShops.length) {
          final newLength = sortedShops.length;

          tabController.dispose();
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
          tabController.addListener(onTabChanged);
        }

        final selectedIndex = sortedShops.isEmpty
            ? 0
            : (tabController.index >= 0 &&
                    tabController.index < sortedShops.length)
                ? tabController.index
                : 0;

        if (dataProvider.isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'データを読み込み中...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final shop = sortedShops.isEmpty
            ? null
            : sortedShops[selectedIndex.clamp(
                0,
                sortedShops.length - 1,
              )];
        if (shop != null) {
          selectedTabId = shop.id;
        }

        final incItems = shop?.items.where((e) => !e.isChecked).toList() ?? [];
        if (shop == null || shop.incSortMode == SortMode.manual) {
          incItems.sort(MainScreenCalculations.comparatorFor(SortMode.manual));
        } else {
          incItems.sort(MainScreenCalculations.comparatorFor(shop.incSortMode));
        }

        final comItems = shop?.items.where((e) => e.isChecked).toList() ?? [];
        if (shop == null || shop.comSortMode == SortMode.manual) {
          comItems.sort(MainScreenCalculations.comparatorFor(SortMode.manual));
        } else {
          comItems.sort(MainScreenCalculations.comparatorFor(shop.comSortMode));
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: false,
          appBar: MainAppBar(
            sortedShops: sortedShops,
            selectedIndex: selectedIndex,
            currentTheme: currentTheme,
            customColors: customColors,
            theme: theme,
            scaffoldBgLuminance: scaffoldBgLuminance,
            onTabTap: (index) => _handleTabTap(index, sortedShops),
            onTabLongPress: (originalIndex) {
              showTabEditDialog(originalIndex, dataProvider.shops);
            },
            onAddTab: showAddTabDialog,
          ),
          drawer: MainDrawer(
            theme: theme,
            currentTheme: currentTheme,
            currentFont: currentFont,
            currentFontSize: currentFontSize,
            drawerItemColor: currentTheme == 'dark'
                ? Colors.white
                : (currentTheme == 'light'
                    ? Colors.black87
                    : (currentTheme == 'lemon'
                        ? Colors.black
                        : theme.colorScheme.primary)),
            drawerTextColor: currentTheme == 'dark'
                ? Colors.white
                : (currentTheme == 'light'
                    ? Colors.black87
                    : (currentTheme == 'lemon' ? Colors.black : null)),
            onCustomColorsChanged: updateCustomColors,
            onSettingsReturned: () {},
          ),
          body: ItemListSection(
            shop: shop,
            incItems: incItems,
            comItems: comItems,
            strikethroughEnabled: _strikethroughEnabled,
            theme: theme,
            onCheckToggle: _handleCheckToggle,
            onEdit: (item) {
              if (shop != null) {
                showItemEditDialog(original: item, shop: shop);
              }
            },
            onDelete: _handleDelete,
            onRename: (item) {
              if (shop != null) {
                ItemRenameDialog.show(context, item);
              }
            },
            onUpdate: _handleUpdate,
            onReorderInc: _reorderIncItems,
            onReorderCom: _reorderComItems,
            onSortInc: () {
              if (shop != null) showSortDialog(true, shop);
            },
            onSortCom: () {
              if (shop != null) showSortDialog(false, shop);
            },
            onBulkDeleteInc: () {
              if (shop != null) showBulkDeleteDialog(shop, true);
            },
            onBulkDeleteCom: () {
              if (shop != null) showBulkDeleteDialog(shop, false);
            },
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: theme.scaffoldBackgroundColor,
                child: const AdBanner(),
              ),
              if (shop != null)
                BottomSummaryWidget(
                  shop: shop,
                  onBudgetClick: () => showBudgetDialog(shop),
                  onFab: () => showItemEditDialog(shop: shop),
                ),
            ],
          ),
        );
      },
    );
  }
}
