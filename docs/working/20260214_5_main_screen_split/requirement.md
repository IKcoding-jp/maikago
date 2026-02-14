# 要件定義書

## Issue情報
- **Issue番号**: #5
- **タイトル**: main_screen.dartの責務分割
- **ラベル**: refactor, critical
- **作成日**: 2026-02-14

## 背景

`lib/screens/main_screen.dart`は現在2085行の巨大ファイルとなっており、以下の問題を抱えています:

1. **可読性の低下**: 1つのファイルに多くの機能が詰め込まれているため、コードの理解が困難
2. **保守性の低下**: 変更時の影響範囲が把握しづらく、バグ混入のリスクが高い
3. **テスタビリティの低下**: 単一の巨大クラスのため、ユニットテスト作成が困難
4. **再利用性の低下**: 特定の機能を他の画面で再利用することが困難
5. **チーム開発の障害**: 複数人が同時に編集する際のコンフリクトリスクが高い

## 現状分析

### ファイル構成
- **行数**: 2085行
- **主要クラス**:
  - `MainScreen` (StatefulWidget)
  - `_MainScreenState` (State)

### 現在の責務
1. **UI構築**
   - AppBar（タブ表示、タブ追加ボタン）
   - Drawer（サイドメニュー）
   - Body（未購入/購入済みアイテムリスト）
   - BottomNavigationBar（広告 + ボトムサマリー）

2. **状態管理**
   - タブ選択状態（TabController）
   - テーマ/フォント設定
   - カスタムカラー設定
   - 各種ID（nextShopId, nextItemId）
   - includeTax, isDarkMode等のフラグ

3. **ダイアログ表示**
   - タブ追加ダイアログ (`_showAddTabDialogWithProviders`)
   - タブ編集ダイアログ (`showTabEditDialog`)
   - 予算設定ダイアログ (`showBudgetDialog`)
   - アイテム編集ダイアログ (`showItemEditDialog`)
   - ソートダイアログ (`showSortDialog`)
   - 一括削除ダイアログ (`showBulkDeleteDialog`)
   - 名前変更ダイアログ (`_showRenameDialog`)
   - バージョン更新ダイアログ (`_showVersionUpdateDialog`)

4. **ビジネスロジック**
   - アイテムの並べ替え（`_reorderIncItems`, `_reorderComItems`）
   - バージョン更新チェック (`_checkForVersionUpdate`)
   - テーマ/フォント更新 (`updateThemeAndFontIfNeeded`, `updateCustomColors`)
   - タブ変更ハンドリング (`onTabChanged`)
   - ハイブリッドOCR初期化 (`_initializeHybridOcr`)
   - 広告表示 (`_showInterstitialAdSafely`)

5. **UI計算ロジック**
   - タブ高さ計算 (`_calculateTabHeight`)
   - タブパディング計算 (`_calculateTabPadding`)
   - タブ最大行数計算 (`_calculateMaxLines`)

### 既存の分割状況
- **Dialogs** (`lib/screens/main/dialogs/`):
  - `budget_dialog.dart` - 予算設定ダイアログ
  - `item_edit_dialog.dart` - アイテム編集ダイアログ
  - `sort_dialog.dart` - ソートダイアログ
  - `tab_edit_dialog.dart` - タブ編集ダイアログ

- **Widgets** (`lib/screens/main/widgets/`):
  - `bottom_summary_widget.dart` - ボトムサマリー（予算・合計表示、カメラ、レシピ、追加ボタン）

## 要件

### 機能要件

#### FR-1: 既存機能の維持
すべての既存機能は分割後も完全に動作すること:
- タブ切り替え
- アイテムの追加/編集/削除
- 並べ替え（手動/自動）
- 予算管理
- テーマ/フォント変更
- OCR機能
- 広告表示
- 共有グループ機能

#### FR-2: UI/UXの維持
分割前と完全に同じUI/UXを提供すること:
- レイアウト
- アニメーション
- ユーザーインタラクション
- パフォーマンス

### 非機能要件

#### NFR-1: 保守性
- 各ファイルは300行以下を目標とする
- 単一責任の原則に従う
- 適切な命名規則を使用する

#### NFR-2: 可読性
- 各ウィジェット/クラスの責務を明確にする
- コメントで各コンポーネントの役割を記述する
- ディレクトリ構造で機能を整理する

#### NFR-3: テスタビリティ
- 各コンポーネントを独立してテスト可能にする
- Providerへの依存を適切に管理する
- モックやスタブを使用可能な設計にする

#### NFR-4: 再利用性
- 汎用的なウィジェットは他の画面でも使用可能にする
- ビジネスロジックとUIを分離する

#### NFR-5: パフォーマンス
- 不必要な再ビルドを避ける
- 適切なキャッシング戦略を維持する
- メモリ使用量を最適化する

## 制約条件

### 技術的制約
1. Flutter/Dart言語を使用
2. Provider パターンを維持
3. 既存の依存関係（Firebase, 広告SDK等）を維持
4. マルチプラットフォーム対応を維持（iOS, Android, Web, Windows）

### ビジネス的制約
1. 既存ユーザーへの影響を最小限にする
2. リリーススケジュールに影響を与えない
3. バージョン互換性を維持する

### 開発プロセス的制約
1. 段階的にリファクタリングを進める
2. 各段階で動作確認を行う
3. Git履歴を適切に管理する

## 成功基準

### 定量的基準
- [ ] main_screen.dartの行数を500行以下に削減
- [ ] 新規作成ファイルは各300行以下
- [ ] すべての既存テストがパスする
- [ ] 静的分析（flutter analyze）でエラーゼロ

### 定性的基準
- [ ] コードレビューで可読性の向上が確認される
- [ ] 新しいディレクトリ構造が論理的である
- [ ] 各コンポーネントの責務が明確である
- [ ] 開発者が変更箇所を容易に特定できる

## リスク管理

### 高リスク
- **リスク**: リファクタリング中のバグ混入
- **対策**: 段階的な分割、各段階でのテスト実施、ペアプログラミング

### 中リスク
- **リスク**: Provider依存の複雑化
- **対策**: Consumer/Providerの適切な配置、依存関係の可視化

### 低リスク
- **リスク**: パフォーマンスの低下
- **対策**: ベンチマーク測定、プロファイリング

## 参考資料

- Flutter公式ドキュメント: https://docs.flutter.dev/
- Provider パッケージ: https://pub.dev/packages/provider
- Clean Architecture in Flutter: https://resocoder.com/flutter-clean-architecture/
- プロジェクトのCLAUDE.md
