# 設計書

## 実装方針

### 変更対象ファイル

#### 1. `lib/screens/main/widgets/bottom_summary_widget.dart`
- **変更内容**: 共有モード時の2段表示を廃止
- `_buildSharedModeTotalDisplay()` メソッドを削除または不使用に
- 共有モード・非共有モードともに同一の表示ロジックを使用
- ラベルは「合計金額」に統一
- 金額は `_calculateCurrentShopTotal()` の値を使用（現在のタブのみ）
- `_cachedSharedMode` 等の共有合計キャッシュ変数は、タブバー側で必要な場合は残す

#### 2. `lib/screens/main/widgets/main_app_bar.dart`
- **変更内容**: 共有グループの端タブに共有合計金額を表示
- `_buildTabItem()` 内で、共有グループの最初or最後のタブかを判定
- 該当タブに共有合計金額をサブテキストとして表示
- `SharedGroupManager.getSharedGroupTotal()` を非同期で取得
- タブの高さ調整が必要な場合は `calculateTabHeight` に反映

### 新規作成ファイル
- なし

## 影響範囲
- `BottomSummaryWidget` - サマリー表示の簡素化
- `MainAppBar` - タブに金額表示追加
- `SharedGroupManager` - 変更なし（既存の `getSharedGroupTotal()` を利用）
- `DataProvider` - 変更なし
- 予算機能・進捗バー - 影響なし（ボトムサマリー内の予算表示は別ロジック）

## Flutter固有の注意点
- `MainAppBar` は `StatelessWidget` だが、共有合計の非同期取得が必要
  - `FutureBuilder` を使うか、`StatefulWidget` に変更する必要あり
  - または `DataProvider` から同期的にキャッシュ値を取得する方法を検討
- Provider依存関係: `context.read<DataProvider>()` は既に使用中
- タブの高さ変更時は `preferredSize` も調整が必要
