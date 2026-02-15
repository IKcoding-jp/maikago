# タスクリスト

## Issue情報
- **Issue番号**: #5
- **タイトル**: main_screen.dartの責務分割
- **作成日**: 2026-02-14
- **ステータス**: 完了
- **完了日**: 2026-02-15

## 実装サマリー

main_screen.dart（1,896行）を9ファイルに分割し、481行に削減。

### 作成ファイル

| ファイル | 行数 | 役割 |
|---------|------|------|
| `utils/ui_calculations.dart` | ~75行 | タブ高さ・パディング計算、ソートcomparator |
| `utils/item_operations.dart` | ~240行 | チェック切替、削除、更新、並べ替え |
| `utils/startup_helpers.dart` | ~80行 | バージョン更新・ウェルカムダイアログ |
| `dialogs/tab_add_dialog.dart` | ~115行 | タブ追加ダイアログ |
| `dialogs/item_rename_dialog.dart` | ~80行 | リネームダイアログ |
| `dialogs/bulk_delete_dialog.dart` | ~90行 | 一括削除ダイアログ |
| `widgets/main_app_bar.dart` | ~210行 | AppBar+タブリスト |
| `widgets/main_drawer.dart` | ~260行 | ドロワーメニュー |
| `widgets/item_list_section.dart` | ~180行 | 未購入/購入済み左右分割リスト |

### 検証結果
- [x] flutter analyze: No issues found
- [x] flutter test: 180テスト全通過
- [x] Chrome動作確認: OK
- [x] コードレビュー: No issues found
