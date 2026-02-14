# 設計書

## Issue情報
- **Issue番号**: #5
- **タイトル**: main_screen.dartの責務分割
- **作成日**: 2026-02-14

## アーキテクチャ概要

### 設計方針

1. **単一責任の原則**: 各ファイル/クラスは1つの明確な責任のみを持つ
2. **関心の分離**: UI、ビジネスロジック、状態管理を分離
3. **再利用性**: 汎用的なコンポーネントは他の画面でも使用可能に
4. **テスタビリティ**: 各コンポーネントを独立してテスト可能に
5. **段階的移行**: 既存機能を維持しながら段階的にリファクタリング

### 分割戦略

```
main_screen.dart (2085行)
↓
main_screen.dart (メイン画面の組み立て、約400行)
├── widgets/ (UIコンポーネント)
│   ├── main_app_bar.dart (AppBar、約250行)
│   ├── main_drawer.dart (Drawer、約200行)
│   ├── item_list_section.dart (アイテムリスト、約300行)
│   └── bottom_summary_widget.dart (既存、687行)
├── dialogs/ (ダイアログ)
│   ├── budget_dialog.dart (既存)
│   ├── item_edit_dialog.dart (既存)
│   ├── sort_dialog.dart (既存)
│   ├── tab_edit_dialog.dart (既存)
│   ├── tab_add_dialog.dart (新規、約200行)
│   ├── item_rename_dialog.dart (新規、約100行)
│   └── bulk_delete_dialog.dart (新規、約150行)
├── mixins/ (ビジネスロジック)
│   ├── item_operations_mixin.dart (アイテム操作、約200行)
│   └── initialization_mixin.dart (初期化、約150行)
└── utils/ (ユーティリティ)
    └── ui_calculations.dart (UI計算、約100行)
```

## 詳細設計

### 1. main_screen.dart（メインファイル）

**責務**:
- 画面全体の構成（Scaffold）
- ウィジェット/Mixinの組み立て
- Provider接続
- TabController管理

**主要メソッド**:
```dart
class MainScreen extends StatefulWidget {
  final void Function(ThemeData)? onThemeChanged;
  final void Function(String)? onFontChanged;
  final void Function(double)? onFontSizeChanged;

  const MainScreen({
    super.key,
    this.onThemeChanged,
    this.onFontChanged,
    this.onFontSizeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, ItemOperationsMixin, InitializationMixin {

  // TabController
  late TabController tabController;
  int selectedTabIndex = 0;
  String? selectedTabId;

  @override
  void initState() {
    super.initState();
    initializeScreen(); // InitializationMixinから
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, AuthProvider>(
      builder: (context, dataProvider, authProvider, child) {
        final sortedShops = TabSorter.sortShopsBySharedGroups(dataProvider.shops);
        final shop = _getCurrentShop(sortedShops);

        return Scaffold(
          backgroundColor: getCustomTheme().scaffoldBackgroundColor,
          appBar: MainAppBar(
            shops: sortedShops,
            selectedIndex: selectedTabIndex,
            tabController: tabController,
            onTabChanged: onTabChanged,
            onAddTab: () => showAddTabDialog(),
          ),
          drawer: MainDrawer(
            currentTheme: currentTheme,
            onNavigate: _handleDrawerNavigation,
          ),
          body: ItemListSection(
            shop: shop,
            incItems: _getIncompleteItems(shop),
            comItems: _getCompletedItems(shop),
            onCheckToggle: handleCheckToggle, // ItemOperationsMixinから
            onReorderInc: handleReorderInc,    // ItemOperationsMixinから
            onReorderCom: handleReorderCom,    // ItemOperationsMixinから
            onEdit: (item) => showItemEditDialog(original: item, shop: shop),
            onDelete: handleDelete,            // ItemOperationsMixinから
            onRename: (item) => showRenameDialog(item),
            onSort: (isIncomplete) => showSortDialog(isIncomplete, shop),
            onBulkDelete: (isIncomplete) => showBulkDeleteDialog(shop, isIncomplete),
          ),
          bottomNavigationBar: shop != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AdBanner(),
                    BottomSummaryWidget(
                      shop: shop,
                      onBudgetClick: () => showBudgetDialog(shop),
                      onFab: () => showItemEditDialog(shop: shop),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [AdBanner()],
                ),
        );
      },
    );
  }
}
```

**想定行数**: 約400行

---

### 2. widgets/main_app_bar.dart

**責務**:
- AppBarのUI構築
- タブ表示（横スクロール可能なタブリスト）
- タブ選択処理
- タブ追加ボタン
- タブ高さ/パディング/行数の計算

**主要クラス**:
```dart
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Shop> shops;
  final int selectedIndex;
  final TabController tabController;
  final VoidCallback onTabChanged;
  final VoidCallback onAddTab;

  const MainAppBar({
    super.key,
    required this.shops,
    required this.selectedIndex,
    required this.tabController,
    required this.onTabChanged,
    required this.onAddTab,
  });

  @override
  Size get preferredSize => Size.fromHeight(_calculateTabHeight() + 16);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _calculateTabHeight() + 16,
      title: _buildTabList(context),
      actions: [_buildAddTabButton(context)],
      // ... その他のAppBar設定
    );
  }

  Widget _buildTabList(BuildContext context) {
    return SizedBox(
      height: _calculateTabHeight(),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shops.length,
        itemBuilder: (context, index) => _buildTabItem(context, index),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index) {
    final shop = shops[index];
    final isSelected = index == selectedIndex;
    // タブアイテムのUI構築（共有グループ判定、ボーダーラディウス等）
    // ...
  }

  double _calculateTabHeight() {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    const baseHeight = 24.0;
    final fontHeight = fontSize * 1.2;
    final totalHeight = baseHeight + fontHeight;
    return totalHeight.clamp(32.0, 60.0);
  }

  double _calculateTabPadding() {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    const basePadding = 6.0;
    final additionalPadding = (fontSize - 16.0) * 0.25;
    final totalPadding = basePadding + additionalPadding;
    return totalPadding.clamp(6.0, 16.0);
  }

  int _calculateMaxLines() {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    if (fontSize > 20) return 1;
    if (fontSize > 18) return 1;
    return 2;
  }
}
```

**想定行数**: 約250行

---

### 3. widgets/main_drawer.dart

**責務**:
- Drawerのサイドメニュー構築
- DrawerHeaderの表示
- メニューアイテムの表示
- 各画面への遷移処理
- トライアル残り日数表示

**主要クラス**:
```dart
class MainDrawer extends StatelessWidget {
  final String currentTheme;
  final void Function(String destination) onNavigate;

  const MainDrawer({
    super.key,
    required this.currentTheme,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'アプリについて',
                    onTap: () => onNavigate('about'),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: '使い方',
                    onTap: () => onNavigate('usage'),
                  ),
                  // ... その他のメニューアイテム
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: getCustomTheme().colorScheme.primary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_basket_rounded, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          const Text('まいカゴ', style: TextStyle(fontSize: 22, color: Colors.white)),
          const SizedBox(height: 12),
          _buildTrialBadge(context),
        ],
      ),
    );
  }

  Widget _buildTrialBadge(BuildContext context) {
    return Consumer<OneTimePurchaseService>(
      builder: (context, purchaseService, child) {
        if (!purchaseService.isTrialActive) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                '無料体験残り${purchaseService.trialRemainingDuration?.inDays ?? 0}日',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _getIconColor()),
      title: Text(title, style: TextStyle(color: _getTextColor())),
      onTap: onTap,
    );
  }
}
```

**想定行数**: 約200行

---

### 4. widgets/item_list_section.dart

**責務**:
- 未購入/購入済みアイテムリストの表示
- ReorderableListViewの構築
- ソート・一括削除ボタンの表示
- アイテムコールバックの伝播

**主要クラス**:
```dart
class ItemListSection extends StatelessWidget {
  final Shop? shop;
  final List<ListItem> incItems;
  final List<ListItem> comItems;
  final void Function(ListItem, bool) onCheckToggle;
  final Future<void> Function(int, int) onReorderInc;
  final Future<void> Function(int, int) onReorderCom;
  final void Function(ListItem) onEdit;
  final Future<void> Function(ListItem) onDelete;
  final void Function(ListItem) onRename;
  final Future<void> Function(ListItem) onUpdate;
  final void Function(bool) onSort;
  final void Function(bool) onBulkDelete;

  const ItemListSection({
    super.key,
    required this.shop,
    required this.incItems,
    required this.comItems,
    required this.onCheckToggle,
    required this.onReorderInc,
    required this.onReorderCom,
    required this.onEdit,
    required this.onDelete,
    required this.onRename,
    required this.onUpdate,
    required this.onSort,
    required this.onBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Row(
        children: [
          // 未購入セクション
          Expanded(
            flex: 1,
            child: _buildIncompleteSection(context),
          ),
          // 境界線
          Container(
            width: 1,
            height: 600,
            margin: const EdgeInsets.only(top: 50),
            color: Theme.of(context).dividerColor,
          ),
          // 購入済みセクション
          Expanded(
            flex: 1,
            child: _buildCompletedSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: '未購入',
          onSort: () => onSort(true),
          onBulkDelete: () => onBulkDelete(true),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildReorderableList(
            context,
            items: incItems,
            onReorder: onReorderInc,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedSection(BuildContext context) {
    // 同様に購入済みセクションを構築
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onSort,
    required VoidCallback onBulkDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.sort), onPressed: onSort),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: onBulkDelete),
        ],
      ),
    );
  }

  Widget _buildReorderableList(
    BuildContext context, {
    required List<ListItem> items,
    required Future<void> Function(int, int) onReorder,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 8),
      itemCount: items.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListEdit(
          key: ValueKey(item.id),
          item: item,
          onCheckToggle: (checked) => onCheckToggle(item, checked),
          onEdit: () => onEdit(item),
          onDelete: () => onDelete(item),
          onRename: () => onRename(item),
          onUpdate: onUpdate,
        );
      },
    );
  }
}
```

**想定行数**: 約300行

---

### 5. dialogs/tab_add_dialog.dart（新規）

**責務**:
- タブ追加ダイアログのUI
- タブ名入力
- データ保存処理
- バリデーション

**主要クラス**:
```dart
class TabAddDialog extends StatefulWidget {
  const TabAddDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const TabAddDialog(),
    );
  }

  @override
  State<TabAddDialog> createState() => _TabAddDialogState();
}

class _TabAddDialogState extends State<TabAddDialog> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      // エラー表示
      return;
    }

    final dataProvider = context.read<DataProvider>();
    final newShop = Shop(
      id: const Uuid().v4(),
      name: name,
      items: [],
      budget: null,
      incSortMode: SortMode.manual,
      comSortMode: SortMode.manual,
    );

    await dataProvider.addShop(newShop);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('タブを追加'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: 'タブ名'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('追加'),
        ),
      ],
    );
  }
}
```

**想定行数**: 約200行（プレミアム機能制限含む）

---

### 6. dialogs/item_rename_dialog.dart（新規）

**責務**:
- アイテム名前変更ダイアログのUI
- 名前入力
- データ更新処理

**主要クラス**:
```dart
class ItemRenameDialog extends StatefulWidget {
  final ListItem item;

  const ItemRenameDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, ListItem item) {
    return showDialog<void>(
      context: context,
      builder: (context) => ItemRenameDialog(item: item),
    );
  }

  @override
  State<ItemRenameDialog> createState() => _ItemRenameDialogState();
}

class _ItemRenameDialogState extends State<ItemRenameDialog> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = nameController.text.trim();
    if (newName.isEmpty) return;

    final dataProvider = context.read<DataProvider>();
    await dataProvider.updateItem(widget.item.copyWith(name: newName));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('名前を変更'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: '新しい名前'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
```

**想定行数**: 約100行

---

### 7. dialogs/bulk_delete_dialog.dart（新規）

**責務**:
- 一括削除確認ダイアログのUI
- 削除実行処理
- 広告表示

**主要クラス**:
```dart
class BulkDeleteDialog extends StatelessWidget {
  final Shop shop;
  final bool isIncomplete;

  const BulkDeleteDialog({
    super.key,
    required this.shop,
    required this.isIncomplete,
  });

  static Future<void> show(
    BuildContext context, {
    required Shop shop,
    required bool isIncomplete,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BulkDeleteDialog(
        shop: shop,
        isIncomplete: isIncomplete,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final dataProvider = context.read<DataProvider>();
    final itemsToDelete = shop.items
        .where((item) => item.isChecked != isIncomplete)
        .toList();

    for (final item in itemsToDelete) {
      await dataProvider.deleteItem(item.id);
    }

    // 広告表示
    await InterstitialAdService().showAdIfReady();

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${itemsToDelete.length}件のアイテムを削除しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = shop.items
        .where((item) => item.isChecked != isIncomplete)
        .length;

    return AlertDialog(
      title: Text('${isIncomplete ? "未購入" : "購入済み"}アイテムを一括削除'),
      content: Text('$itemCount件のアイテムを削除しますか?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => _handleDelete(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
```

**想定行数**: 約150行

---

### 8. mixins/item_operations_mixin.dart

**責務**:
- アイテム操作ロジック（並べ替え、チェック、削除、更新）
- Provider操作
- エラーハンドリング

**主要クラス**:
```dart
mixin ItemOperationsMixin<T extends StatefulWidget> on State<T> {

  /// 未購入アイテムの並べ替え
  Future<void> handleReorderInc(int oldIndex, int newIndex) async {
    // 現在の実装をコピー
  }

  /// 購入済みアイテムの並べ替え
  Future<void> handleReorderCom(int oldIndex, int newIndex) async {
    // 現在の実装をコピー
  }

  /// チェックトグル処理
  Future<void> handleCheckToggle(
    ListItem item,
    bool checked,
    Shop shop,
  ) async {
    try {
      final dataProvider = context.read<DataProvider>();

      // sortOrder計算
      final comItems = shop.items.where((e) => e.isChecked).toList();
      final incItems = shop.items.where((e) => !e.isChecked).toList();
      final newSortOrder = checked
          ? 10000 + comItems.length
          : incItems.length;

      await dataProvider.updateItem(
        item.copyWith(
          isChecked: checked,
          sortOrder: newSortOrder,
        ),
      );

      // 共有グループの合計更新
      if (shop.sharedGroupId != null) {
        dataProvider.notifyDataChanged();
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  /// 削除処理
  Future<void> handleDelete(ListItem item) async {
    try {
      await context.read<DataProvider>().deleteItem(item.id);
      await _showInterstitialAdSafely();
    } catch (e) {
      _showError(e.toString());
    }
  }

  /// 更新処理
  Future<void> handleUpdate(ListItem item) async {
    try {
      await context.read<DataProvider>().updateItem(item);
    } catch (e) {
      _showError(e.toString());
    }
  }

  /// エラー表示
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 広告表示（安全版）
  Future<void> _showInterstitialAdSafely() async {
    try {
      await InterstitialAdService().showAdIfReady();
    } catch (e) {
      debugPrint('広告表示エラー: $e');
    }
  }
}
```

**想定行数**: 約200行

---

### 9. mixins/initialization_mixin.dart

**責務**:
- 画面初期化処理
- TabController初期化
- ハイブリッドOCR初期化
- バージョンチェック
- テーマ/フォント復元

**主要クラス**:
```dart
mixin InitializationMixin<T extends StatefulWidget> on State<T> {

  /// 画面初期化
  Future<void> initializeScreen() async {
    await _initializeTabController();
    await _initializeHybridOcr();
    await _checkForVersionUpdate();
    await _restoreThemeAndFont();
  }

  /// TabController初期化
  Future<void> _initializeTabController() async {
    final savedIndex = await SettingsPersistence.loadSelectedTabIndex();
    final savedId = await SettingsPersistence.loadSelectedTabId();

    // TabController作成
    // ...
  }

  /// ハイブリッドOCR初期化
  Future<void> _initializeHybridOcr() async {
    try {
      await HybridOcrService().initialize();
    } catch (e) {
      debugPrint('❌ ハイブリッドOCR初期化エラー: $e');
    }
  }

  /// バージョンチェック
  Future<void> _checkForVersionUpdate() async {
    try {
      final service = VersionNotificationService();
      final latestRelease = await service.checkForUpdate();

      if (latestRelease != null && mounted) {
        _showVersionUpdateDialog(latestRelease);
      }
    } catch (e) {
      debugPrint('バージョンチェックエラー: $e');
    }
  }

  /// テーマ/フォント復元
  Future<void> _restoreThemeAndFont() async {
    final theme = await SettingsPersistence.loadTheme();
    final font = await SettingsPersistence.loadFont();
    final fontSize = await SettingsPersistence.loadFontSize();

    if (mounted) {
      setState(() {
        currentTheme = theme ?? 'pink';
        currentFont = font ?? 'nunito';
        currentFontSize = fontSize ?? 16.0;
      });
    }
  }

  void _showVersionUpdateDialog(ReleaseNote latestRelease) {
    // バージョン更新ダイアログ表示
  }
}
```

**想定行数**: 約150行

---

### 10. utils/ui_calculations.dart

**責務**:
- UIサイズ計算ユーティリティ
- タブ高さ/パディング/行数計算

**主要クラス**:
```dart
class UiCalculations {
  /// タブの高さを計算
  static double calculateTabHeight(double fontSize) {
    const baseHeight = 24.0;
    final fontHeight = fontSize * 1.2;
    final totalHeight = baseHeight + fontHeight;
    return totalHeight.clamp(32.0, 60.0);
  }

  /// タブのパディングを計算
  static double calculateTabPadding(double fontSize) {
    const basePadding = 6.0;
    final additionalPadding = (fontSize - 16.0) * 0.25;
    final totalPadding = basePadding + additionalPadding;
    return totalPadding.clamp(6.0, 16.0);
  }

  /// タブ内のテキストの最大行数を計算
  static int calculateMaxLines(double fontSize) {
    if (fontSize > 20) return 1;
    if (fontSize > 18) return 1;
    return 2;
  }
}
```

**想定行数**: 約100行

---

## ディレクトリ構造

```
lib/screens/
├── main_screen.dart (約400行) ← メインファイル
├── main/
│   ├── widgets/
│   │   ├── main_app_bar.dart (約250行) ← AppBar
│   │   ├── main_drawer.dart (約200行) ← Drawer
│   │   ├── item_list_section.dart (約300行) ← アイテムリスト
│   │   └── bottom_summary_widget.dart (既存687行) ← ボトムサマリー
│   ├── dialogs/
│   │   ├── budget_dialog.dart (既存) ← 予算設定
│   │   ├── item_edit_dialog.dart (既存) ← アイテム編集
│   │   ├── sort_dialog.dart (既存) ← ソート
│   │   ├── tab_edit_dialog.dart (既存) ← タブ編集
│   │   ├── tab_add_dialog.dart (約200行) ← タブ追加（新規）
│   │   ├── item_rename_dialog.dart (約100行) ← 名前変更（新規)
│   │   └── bulk_delete_dialog.dart (約150行) ← 一括削除（新規）
│   ├── mixins/
│   │   ├── item_operations_mixin.dart (約200行) ← アイテム操作
│   │   └── initialization_mixin.dart (約150行) ← 初期化
│   └── utils/
│       └── ui_calculations.dart (約100行) ← UI計算
```

**合計**: 約2,737行（分割前: 2,085行）
**main_screen.dart**: 約400行（目標500行以下達成）

## データフロー

```
User Interaction
     ↓
MainScreen (Scaffold組み立て)
     ↓
┌────┴────┬─────────┬─────────────┐
│         │         │             │
AppBar   Drawer   Body   BottomNavigationBar
│         │         │             │
│         │   ItemListSection     │
│         │         │             │
└─────────┴─────────┴─────────────┘
     ↓
ItemOperationsMixin (ビジネスロジック)
     ↓
DataProvider (状態管理)
     ↓
Firebase/ローカルストレージ
```

## Provider依存関係

### Consumer箇所
- `MainScreen.build`: `Consumer2<DataProvider, AuthProvider>`
- `MainDrawer._buildTrialBadge`: `Consumer<OneTimePurchaseService>`
- `MainAppBar._buildAddTabButton`: `Consumer2<DataProvider, OneTimePurchaseService>`
- `BottomSummaryWidget`: 既存のConsumer構造を維持

### context.read箇所
- `ItemOperationsMixin`: `context.read<DataProvider>()`
- 各ダイアログ: `context.read<DataProvider>()`

## テスト戦略

### 単体テスト
- `UiCalculations`: 各計算メソッドのテスト
- `ItemOperationsMixin`: モックProviderを使用したロジックテスト
- `InitializationMixin`: モック初期化テスト

### ウィジェットテスト
- `MainAppBar`: タブ表示・選択のテスト
- `MainDrawer`: メニュー項目のテスト
- `ItemListSection`: リスト表示・並べ替えのテスト
- 各ダイアログ: UI表示・入力・保存のテスト

### 統合テスト
- `MainScreen`: 全体フローのテスト
- タブ切り替え → アイテム追加 → チェック → 削除のフロー

## マイグレーション手順

1. **Phase 1**: ユーティリティ分離（`ui_calculations.dart`）
2. **Phase 2**: Mixin分離（`item_operations_mixin.dart`, `initialization_mixin.dart`）
3. **Phase 3**: ダイアログ分離（`tab_add_dialog.dart`, `item_rename_dialog.dart`, `bulk_delete_dialog.dart`）
4. **Phase 4**: ウィジェット分離（`main_app_bar.dart`, `main_drawer.dart`, `item_list_section.dart`）
5. **Phase 5**: `main_screen.dart`再構成
6. **Phase 6**: テスト・検証

各フェーズで動作確認を行い、問題があれば前のフェーズに戻す。

## パフォーマンス考慮事項

1. **不要な再ビルド防止**:
   - `const`コンストラクタの活用
   - `ValueKey`の適切な使用
   - Consumer範囲の最小化

2. **メモリ管理**:
   - TextEditingControllerの適切なdispose
   - リスナーの適切な削除
   - キャッシュの適切な管理

3. **レンダリング最適化**:
   - ReorderableListViewのcacheExtent設定
   - ClipBehaviorの適切な設定
   - 不要なStackの削減

## 注意事項

1. **既存機能の維持**: すべての既存機能が正常に動作することを確認
2. **UI/UXの一貫性**: 分割前と同じ見た目・操作感を維持
3. **段階的移行**: 一度に全てを変更せず、段階的にリファクタリング
4. **テストの充実**: 各段階で十分なテストを実施
5. **ドキュメント更新**: 変更内容をCLAUDE.mdに反映
