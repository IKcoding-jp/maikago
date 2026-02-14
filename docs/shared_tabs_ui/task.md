# タスク: 共有タブの視覚的グループ化

## Planning
- [/] 実装計画の作成と承認 `docs/shared_tabs_ui/implementation_plan.md`

## Implementation
- [/] `MainScreen`のタブ描画ロジックの修正
    - [x] 隣接するタブのグループID比較ロジックの実装
    - [x] `BorderRadius`の動的変更（左端、中間、右端、単独）
    - [x] `Margin`の動的変更（グループ内は隙間なし、グループ間は隙間あり）
    - [x] 視覚的な微調整（ボーダーの太さや重なりなど）
    - [x] 不要になった共有アイコン表示の削除
    - [ ] タブ編集ダイアログから「共有マーク選択」UIを削除

## Verification
- [x] ビルド確認
- [x] UI動作確認（脳内シミュレーションおよびコードレビュー）
- [x] Walkthroughの作成 `docs/shared_tabs_ui/walkthrough.md`
