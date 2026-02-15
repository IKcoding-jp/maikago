# タスクリスト: Lint設定の強化（#44 + #48）

**ステータス**: 進行中
**開始日**: 2026-02-15

## フェーズ1: use_build_context_synchronously有効化（#44）
- [ ] `analysis_options.yaml` から `use_build_context_synchronously: ignore` を削除
- [ ] `flutter analyze` で警告箇所を確認
- [ ] 各警告箇所に `mounted` チェックを追加
- [ ] `flutter analyze` で警告なしを確認

## フェーズ2: Lint設定の強化（#48）
- [ ] 追加lintルールを `analysis_options.yaml` に設定
- [ ] `flutter analyze` で違反箇所を確認
- [ ] 違反箇所を修正
- [ ] `flutter analyze` で警告なしを確認

## フェーズ3: 検証
- [ ] `flutter analyze` 通過
- [ ] `flutter test` 通過
