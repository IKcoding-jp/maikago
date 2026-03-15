# タスクリスト

**ステータス**: 未着手
**作成日**: 2026-03-14

## フェーズ1: B1 -- release_history_screen.dart の分割

### 1-1: ディレクトリ・ファイル作成
- [ ] `lib/screens/release_history/widgets/` ディレクトリ作成
- [ ] `timeline_entry.dart` 作成（`_TimelineEntry` を移動、public化）
- [ ] `category_section.dart` 作成（`_CategorySection` を移動、public化）

### 1-2: 本体ファイル修正
- [ ] `release_history_screen.dart` から `_TimelineEntry` クラス削除（150-379行）
- [ ] `release_history_screen.dart` から `_CategorySection` クラス削除（381-517行）
- [ ] `release_history_screen.dart` に import 追加（`timeline_entry.dart`, `category_section.dart`）
- [ ] `_TimelineEntry` → `TimelineEntry` の参照更新（`_buildBody` メソッド内）

### 1-3: 分割先ファイルの import 整理
- [ ] `timeline_entry.dart` に必要な import 追加（`flutter/material.dart`, `release_history.dart`, `theme_utils.dart`, `category_section.dart`）
- [ ] `category_section.dart` に必要な import 追加（`flutter/material.dart`, `release_history.dart`）

### 1-4: 検証
- [ ] `flutter analyze` がエラーなし
- [ ] `release_history_screen.dart` が500行以下であること確認
- [ ] 各分割先ファイルが500行以下であること確認

## フェーズ2: B2 -- main_screen.dart の分割

### 2-1: dialog_handlers.dart 作成
- [ ] `lib/screens/main/utils/dialog_handlers.dart` 作成
- [ ] `showAddTabDialog()` を `DialogHandlers.showAddTabDialog()` として移動
- [ ] `showBudgetDialog()` を `DialogHandlers.showBudgetDialog()` として移動
- [ ] `showTabEditDialog()` を `DialogHandlers.showTabEditDialog()` として移動
- [ ] `showItemEditDialog()` を `DialogHandlers.showItemEditDialog()` として移動
- [ ] `showSortDialog()` を `DialogHandlers.showSortDialog()` として移動
- [ ] `showBulkDeleteDialog()` を `DialogHandlers.showBulkDeleteDialog()` として移動
- [ ] 必要な import 追加

### 2-2: tab_management.dart 作成
- [ ] `lib/screens/main/utils/tab_management.dart` 作成
- [ ] `_recreateTabControllerIfNeeded()` を `TabManagement.recreateTabControllerIfNeeded()` として移動
- [ ] `onTabChanged()` のロジックを `TabManagement.handleTabChanged()` として移動
- [ ] `loadSavedTabIndex()` を `TabManagement.loadSavedTabIndex()` として移動
- [ ] `_handleTabTap()` のロジックを `TabManagement.handleTabTap()` として移動
- [ ] 必要な import 追加

### 2-3: 本体ファイル修正
- [ ] `main_screen.dart` からダイアログ表示メソッド6つを削除し、`DialogHandlers` 呼び出しに置換
- [ ] `main_screen.dart` からタブ管理メソッド4つを削除し、`TabManagement` 呼び出しに置換
- [ ] `main_screen.dart` に import 追加（`dialog_handlers.dart`, `tab_management.dart`）

### 2-4: 検証
- [ ] `flutter analyze` がエラーなし
- [ ] `main_screen.dart` が500行以下であること確認
- [ ] 各分割先ファイルが500行以下であること確認

## フェーズ3: 最終検証

- [ ] `flutter analyze` がエラーなし
- [ ] `flutter test` が全パス
- [ ] 全対象ファイルの行数が500行以下であること確認
- [ ] `router.dart` からの参照が変更なし（`ReleaseHistoryScreen`, `MainScreen`）
- [ ] 手動動作確認（更新履歴画面、メイン画面）

## 依存関係
- フェーズ1, 2 は並行実行可能（独立したファイルの分割）
- フェーズ3 はフェーズ1, 2 の両方が完了後
