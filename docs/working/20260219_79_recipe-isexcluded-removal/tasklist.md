# タスクリスト

## フェーズ1: Cloud Functions プロンプト修正
- [x] `functions/index.js:585-607` のシステムプロンプトからルール5（isExcluded 除外ルール）を削除
- [x] 出力JSON例から `isExcluded` フィールドを除去
- [x] ルール番号を振り直す（1-4）

## フェーズ2: Flutter側の isExcluded スキップ処理削除
- [x] `lib/screens/recipe_confirm_screen.dart:170` の `if (ingredient.isExcluded) continue;` を削除

## フェーズ3: RecipeIngredient モデル整理（オプション）
- [x] `lib/services/recipe_parser_service.dart` の `isExcluded` フィールドをデフォルト `false` のまま維持（後方互換性のため削除しない）
- [x] `fromJson` での `isExcluded` パースは残す（古いレスポンスとの互換性）

## フェーズ4: 動作確認
- [x] `flutter analyze` でエラーなし
- [x] レシピテキスト入力 → 調味料を含む全材料が確認画面に表示されること
- [x] 「追加する」で全材料が買い物リストに追加されること

**ステータス**: 完了
**完了日**: 2026-02-19

## 依存関係
- フェーズ1 → フェーズ2（独立して実行可能）
- フェーズ3 → フェーズ2の後（任意）
- フェーズ4 → フェーズ1,2完了後
