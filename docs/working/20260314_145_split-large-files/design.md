# 設計書

## 対象ファイルの構造分析

### 1. release_history_screen.dart（517行）

#### クラス構成

| クラス | 行範囲 | 行数 | 責務 |
|--------|--------|------|------|
| `ReleaseHistoryScreen` (StatefulWidget) | 9-23 | 15 | Widget定義 |
| `_ReleaseHistoryScreenState` | 25-148 | 124 | 画面本体（AppBar, Body, EmptyState） |
| `_TimelineEntry` (StatelessWidget) | 151-379 | 229 | タイムラインの1エントリ（カード表示） |
| `_CategorySection` (StatelessWidget) | 382-517 | 136 | カテゴリセクション（アイコン・色・アイテム一覧） |

#### メソッド一覧

**_ReleaseHistoryScreenState:**
- `_loadCurrentVersion()` — アプリバージョン取得（35-48行）
- `_primaryColor` / `_onPrimaryColor` — getter（50-53行）
- `build()` — Scaffold構築（56-79行）
- `_buildBody()` — ListView.builder（81-109行）
- `_buildEmptyState()` — 空状態表示（112-147行）

**_TimelineEntry:**
- `build()` — タイムライン行（IntrinsicHeight + Row）（169-223行）
- `_buildCard()` — カード本体（Container + BoxDecoration）（225-265行）
- `_buildHeader()` — ヘッダー行（バージョン + バッジ + 日付）（267-305行）
- `_buildPill()` — ピルバッジ（307-323行）
- `_buildChanges()` — 変更内容のカテゴリ分け表示（325-345行）
- `_buildComment()` — 開発者コメント（347-374行）
- `_formatDate()` — 日付フォーマット（376-378行）

**_CategorySection:**
- `build()` — カテゴリラベル + アイテム一覧（392-429行）
- `_buildItem()` — 個別の変更アイテム（431-463行）
- `_getCategoryColor()` — カテゴリの色（ライト/ダーク対応）（466-481行）
- `_getCategoryBgColor()` — カテゴリの背景色（484-502行）
- `_getCategoryIcon()` — カテゴリのアイコン（505-516行）

---

### 2. main_screen.dart（505行）

#### クラス構成

| クラス | 行範囲 | 行数 | 責務 |
|--------|--------|------|------|
| `MainScreen` (StatefulWidget) | 35-40 | 6 | Widget定義 |
| `_MainScreenState` | 42-505 | 464 | 画面全体の状態管理 + UI構築 |

#### メソッド一覧（責務分類）

**ダイアログ表示系（薄いラッパー）:**
- `showAddTabDialog()` — タブ追加（68-96行）29行
- `showBudgetDialog()` — 予算設定（98-100行）3行
- `showTabEditDialog()` — タブ編集（102-109行）8行
- `showItemEditDialog()` — アイテム編集（111-118行）8行
- `showSortDialog()` — ソート（120-134行）15行
- `showBulkDeleteDialog()` — 一括削除（136-154行）19行

**タブ管理系:**
- `onTabChanged()` — タブ変更イベント（271-296行）26行
- `loadSavedTabIndex()` — 保存タブ復元（298-311行）14行
- `_handleTabTap()` — タブタップ処理（319-334行）16行
- `_onDataProviderChanged()` — DataProvider変更検知（217-222行）6行
- `_recreateTabControllerIfNeeded()` — TabController再作成（225-260行）36行

**アイテム操作系（委譲済み）:**
- `_reorderItems()` — 並べ替え（156-169行）14行
- `_reorderIncItems()` / `_reorderComItems()` — 委譲（171-175行）5行
- `_handleCheckToggle()` — チェック切替（336-343行）8行
- `_handleDelete()` — 削除（346-347行）2行
- `_handleUpdate()` — 更新（350-351行）2行

**ライフサイクル:**
- `initState()` — 初期化（178-192行）15行
- `dispose()` — 後片付け（203-214行）12行
- `_loadStrikethroughSetting()` — 取り消し線設定読込（194-201行）8行
- `_checkForVersionUpdate()` — バージョン更新チェック（65-66行）2行
- `checkAndShowWelcomeDialog()` — ウェルカム表示（262-269行）8行

**その他:**
- `updateCustomColors()` — カスタムカラー更新（313-317行）5行

**build():**
- `build()` — Scaffold構築（354-504行）151行

#### 既存の分割済みファイル

main_screen.dart は既に大規模な分割が行われている:

| ファイル | 行数 | 役割 |
|---------|------|------|
| `main/widgets/main_app_bar.dart` | 237行 | AppBar |
| `main/widgets/main_drawer.dart` | 235行 | ドロワー |
| `main/widgets/item_list_section.dart` | 206行 | アイテムリスト |
| `main/widgets/bottom_summary_widget.dart` | 255行 | ボトムサマリー |
| `main/utils/startup_helpers.dart` | 289行 | 起動時ヘルパー |
| `main/utils/item_operations.dart` | 217行 | アイテム操作 |
| `main/utils/ui_calculations.dart` | 73行 | UI計算 |
| `main/dialogs/` (6ファイル) | - | 各種ダイアログ |

---

## 分割方針

### B1: release_history_screen.dart の分割

**方針**: `_TimelineEntry` と `_CategorySection` はそれぞれ独立した StatelessWidget であり、画面本体の `_ReleaseHistoryScreenState` とは疎結合。Widget を別ファイルに抽出する。

#### 分割案

| 分割先ファイル | 移動するクラス | 行数（概算） | 理由 |
|--------------|--------------|-------------|------|
| `release_history/widgets/timeline_entry.dart` | `TimelineEntry`（旧 `_TimelineEntry`） | ~230行 | タイムラインの1エントリ表示。カード・ヘッダー・ピル・コメント等の描画を担当 |
| `release_history/widgets/category_section.dart` | `CategorySection`（旧 `_CategorySection`） | ~140行 | カテゴリ別セクション表示。色・アイコン定義を含む |

#### 分割後の構成

```
lib/screens/
  release_history_screen.dart               (~150行: Screen本体)
  release_history/
    widgets/
      timeline_entry.dart                   (~230行: タイムラインエントリ)
      category_section.dart                 (~140行: カテゴリセクション)
```

#### 変更点
- `_TimelineEntry` → `TimelineEntry`（private を解除）
- `_CategorySection` → `CategorySection`（private を解除）
- `release_history_screen.dart` は import を追加し、クラス定義を削除
- `TimelineEntry` は `CategorySection` を使用するため、import が必要
- 外部からの import パス（`router.dart`）に変更なし

---

### B2: main_screen.dart の分割

**方針**: main_screen.dart は既にウィジェット・ダイアログ・ユーティリティが大幅に分割済み。残る505行は `_MainScreenState` の状態管理とイベントハンドラが中心。ダイアログ表示メソッド群（82行）とタブ管理ロジック（98行）を抽出する。

#### 分割案

| 分割先ファイル | 移動する内容 | 行数（概算） | 理由 |
|--------------|------------|-------------|------|
| `main/utils/dialog_handlers.dart` | ダイアログ表示メソッド群 | ~100行 | 6つのダイアログ表示メソッドは独立した処理で、State 本体から分離可能 |
| `main/utils/tab_management.dart` | タブ管理ロジック | ~110行 | TabController 再作成、タブ変更イベント、タブインデックス保存/復元 |

#### 分割後の構成

```
lib/screens/
  main_screen.dart                          (~340行: Screen本体)
  main/
    utils/
      dialog_handlers.dart                  (~100行: ダイアログ表示)  ← 新規
      tab_management.dart                   (~110行: タブ管理)      ← 新規
      ui_calculations.dart                  (73行: 既存)
      item_operations.dart                  (217行: 既存)
      startup_helpers.dart                  (289行: 既存)
    widgets/                                (既存のまま)
    dialogs/                                (既存のまま)
```

#### dialog_handlers.dart の設計

`DialogHandlers` クラスに静的メソッドとして抽出。`BuildContext` と必要なパラメータを受け取る形にする:

```dart
class DialogHandlers {
  /// タブ追加ダイアログ（ショップ数制限チェック含む）
  static void showAddTabDialog(
    BuildContext context, {
    required String nextShopId,
    required ValueChanged<String> onNextShopIdChanged,
  });

  /// 予算設定ダイアログ
  static void showBudgetDialog(BuildContext context, Shop shop);

  /// タブ編集ダイアログ
  static void showTabEditDialog(
    BuildContext context, {
    required int tabIndex,
    required List<Shop> shops,
  });

  /// アイテム編集ダイアログ
  static void showItemEditDialog(
    BuildContext context, {
    ListItem? original,
    required Shop shop,
  });

  /// ソートダイアログ
  static void showSortDialog(
    BuildContext context, {
    required bool isIncomplete,
    required Shop shop,
    required VoidCallback onSortChanged,
  });

  /// 一括削除ダイアログ
  static void showBulkDeleteDialog(
    BuildContext context, {
    required Shop shop,
    required bool isIncomplete,
  });
}
```

#### tab_management.dart の設計

`TabManagement` クラスに静的メソッドとして抽出。タブ関連のロジックを集約:

```dart
class TabManagement {
  /// DataProvider変更時にTabControllerを再作成する必要があるか判定し、再作成する
  static TabController? recreateTabControllerIfNeeded({
    required TabController currentController,
    required List<Shop> sortedShops,
    required String? selectedTabId,
    required int selectedTabIndex,
    required TickerProvider vsync,
    required VoidCallback onTabChanged,
  });

  /// タブ変更イベントの処理
  static ({int tabIndex, String? tabId})? handleTabChanged({
    required TabController tabController,
    required List<Shop> sortedShops,
  });

  /// 保存されたタブインデックスの復元
  static Future<({int tabIndex, String? tabId})> loadSavedTabIndex();

  /// タブタップ処理
  static ({int tabIndex, String? tabId})? handleTabTap({
    required int index,
    required List<Shop> sortedShops,
    required TabController tabController,
  });
}
```

#### 変更点
- `_MainScreenState` からダイアログ表示メソッド6つを `DialogHandlers` に移動
- `_MainScreenState` からタブ管理メソッド4つを `TabManagement` に移動
- `_MainScreenState` は各メソッドを呼び出す薄いラッパーとして残すか、直接委譲
- 外部からの import パス（`router.dart`）に変更なし

---

## 影響範囲

| 影響 | B1 | B2 |
|------|----|----|
| 本体ファイル | `release_history_screen.dart` | `main_screen.dart` |
| 新規ファイル | 2ファイル | 2ファイル |
| 外部参照 | 変更なし | 変更なし |
| ロジック変更 | なし | なし |
| テスト影響 | なし（既存テストなし） | なし（既存テストなし） |

## Flutter 固有の注意点

- `_TimelineEntry` / `_CategorySection` は private Widget のため、別ファイルに移動する際は public に変更する必要がある
- `_MainScreenState` のメソッドは `mounted` チェックや `setState()` を使用しているため、抽出時に State への依存を適切に処理する
- `TabController` の再作成は `TickerProvider` (vsync) に依存するため、`TabManagement` は vsync を引数で受け取る設計とする
- `showAddTabDialog` 内の `context.read<FeatureAccessControl>()` 等の Provider 参照は、`BuildContext` 経由で引き続きアクセスできるため問題なし
