# 要件定義: Lint設定の強化（#44 + #48）

## 概要
`analysis_options.yaml` のlintルールを強化し、コード品質を向上させる。

## 要件

### Issue #44: use_build_context_synchronously有効化
- `use_build_context_synchronously: ignore` を削除し、warningに戻す
- async gap後のBuildContext使用箇所に `mounted` チェックを追加
- 既に対応済みの箇所は確認のみ

### Issue #48: Lint設定の強化
- 推奨lintルールを追加
- 追加ルールによる既存コードの違反を修正

## 制約
- 既存の動作を変更しない（lint修正のみ）
- `flutter analyze` が警告なしで通ること
- `flutter test` が全て通ること
