# テスト計画

## テスト戦略

### 全体方針
- 本リファクタはファイル分割のみでロジック変更なし
- 既存テスト（`flutter test`）の全パスをもって品質を担保する
- release_history_screen / main_screen ともに専用テストファイルは現時点で存在しない
- 静的分析（`flutter analyze`）でコンパイルエラー・lint違反がないことを確認する

## 自動テスト

### 既存テスト実行
```bash
# 全テスト実行（リグレッション確認）
flutter test

# 静的分析
flutter analyze
```

### 確認観点
- [ ] 全テストがパスすること（分割による参照エラーがないこと）
- [ ] `flutter analyze` がエラー・警告なしであること
- [ ] 分割で public 化した Widget のアクセス修飾子が適切であること

## 手動テスト

### B1: 更新履歴画面

| No | テストケース | 確認ポイント |
|----|------------|------------|
| 1 | 更新履歴画面を開く | タイムラインが正しく表示される |
| 2 | 現在のバージョンの表示 | 「現在のバージョン」バッジが正しい位置に表示される |
| 3 | 最新バージョンの表示 | 最初のエントリにドットが強調表示される |
| 4 | カテゴリ表示 | 新機能・バグ修正・改善点・その他のラベル/色/アイコンが正しい |
| 5 | 開発者コメント | コメント付きリリースノートで吹き出しが表示される |
| 6 | ダークモード | ライト/ダーク切替でカテゴリ色が適切に変化する |
| 7 | スクロール | 全リリースノートをスクロールして表示確認 |

### B2: メイン画面

| No | テストケース | 確認ポイント |
|----|------------|------------|
| 1 | アプリ起動 | メイン画面が正常に表示される |
| 2 | タブ追加 | ダイアログが開き、ショップが追加される |
| 3 | タブ切替 | タブをタップして切り替えができる |
| 4 | タブ編集 | タブ長押しで編集ダイアログが開く |
| 5 | アイテム追加 | FABからアイテム追加ダイアログが開く |
| 6 | アイテム編集 | アイテムタップで編集ダイアログが開く |
| 7 | ソート | ソートダイアログが開き、並び替えが機能する |
| 8 | 一括削除 | 一括削除ダイアログが開き、削除が機能する |
| 9 | 予算設定 | 予算ダイアログが開き、設定が反映される |
| 10 | タブ復元 | アプリ再起動後に前回選択したタブが復元される |
| 11 | ショップ上限 | 無料版で上限超過時にプレミアムダイアログが表示される |

## 行数検証

```bash
# 分割後の行数確認
wc -l lib/screens/release_history_screen.dart
wc -l lib/screens/release_history/widgets/timeline_entry.dart
wc -l lib/screens/release_history/widgets/category_section.dart
wc -l lib/screens/main_screen.dart
wc -l lib/screens/main/utils/dialog_handlers.dart
wc -l lib/screens/main/utils/tab_management.dart
```

### 期待値

| ファイル | 期待行数 |
|---------|---------|
| `release_history_screen.dart` | ~150行（500行以下） |
| `release_history/widgets/timeline_entry.dart` | ~230行（500行以下） |
| `release_history/widgets/category_section.dart` | ~140行（500行以下） |
| `main_screen.dart` | ~340行（500行以下） |
| `main/utils/dialog_handlers.dart` | ~100行（500行以下） |
| `main/utils/tab_management.dart` | ~110行（500行以下） |

## 検証チェックリスト
- [ ] `flutter test` が全パス
- [ ] `flutter analyze` がエラーなし
- [ ] 全対象ファイルが500行以下
- [ ] `router.dart` の import パスに変更なし
- [ ] 更新履歴画面の表示が分割前と同一
- [ ] メイン画面の全ダイアログが正常に動作
- [ ] メイン画面のタブ管理が正常に動作
