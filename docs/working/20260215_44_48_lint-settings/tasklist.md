# タスクリスト: Lint設定の強化（#44 + #48）

**ステータス**: 完了
**開始日**: 2026-02-15
**完了日**: 2026-02-15

## フェーズ1: use_build_context_synchronously有効化（#44）
- [x] `analysis_options.yaml` から `use_build_context_synchronously: ignore` を削除
- [x] `flutter analyze` で警告箇所を確認（0件）
- [x] 各警告箇所に `mounted` チェックを追加（既に対応済み）
- [x] `flutter analyze` で警告なしを確認

## フェーズ2: Lint設定の強化（#48）
- [x] 追加lintルールを `analysis_options.yaml` に設定（7ルール）
- [x] `flutter analyze` で違反箇所を確認（328件）
- [x] 違反箇所を修正（328件全て修正）
- [x] `flutter analyze` で警告なしを確認

## フェーズ3: 検証
- [x] `flutter analyze` 通過
- [x] `flutter test` 通過（65 tests passed）
