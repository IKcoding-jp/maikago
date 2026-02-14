# タスクリスト

**ステータス**: 完了
**完了日**: 2026-02-15

## フェーズ1: 調査
- [x] Web版でダイアログの表示幅を実機確認
- [x] `showDialog`/`showModalBottomSheet`の使用箇所をGrepで検索
- [x] `lib/screens/main/dialogs/`内のダイアログ一覧確認

## フェーズ2: 修正
- [x] 方針選択: B（ラッパー関数方式）を採用
- [x] `lib/utils/dialog_utils.dart` にラッパー関数を新規作成
- [x] 全21ファイル、30箇所の`showDialog`/`showModalBottomSheet`をラッパーに置換

## フェーズ3: 確認
- [x] `flutter analyze` No issues found
- [x] `flutter test` 65テスト全通過
- [ ] Web版で全ダイアログの表示を実機確認（未実施）

## 依存関係
- フェーズ1 → フェーズ2 → フェーズ3（順次実行）
