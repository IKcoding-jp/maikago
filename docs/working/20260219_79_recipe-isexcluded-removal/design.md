# 設計書

## 実装方針

### 変更対象ファイル

#### 1. `functions/index.js` — プロンプト修正
**変更箇所**: L585-607 の systemプロンプト

変更前（ルール5を含む）:
```
5. 買い物に不要そうなもの（水、油、塩、胡椒などの基本調味料）は isExcluded を true にする。
```

変更後: ルール5を削除し、出力JSON例からも `isExcluded` フィールドを除去。
ルール番号を4までに振り直す。

#### 2. `lib/screens/recipe_confirm_screen.dart` — スキップ処理削除
**変更箇所**: `_onAdd()` メソッド内（L163付近）

変更前:
```dart
if (ingredient.isExcluded) continue;
```

変更後: この行を削除。

#### 3. `lib/services/recipe_parser_service.dart` — モデル維持（変更なし）
`isExcluded` フィールドは後方互換性のためそのまま残す。
Cloud Functions が返さなくなった場合、`fromJson` のデフォルト値 `false` が使われるため問題なし。

### 新規作成ファイル
なし

## 影響範囲
- `functions/index.js` — Cloud Function のGPTプロンプトのみ。他のFunction には影響なし
- `lib/screens/recipe_confirm_screen.dart` — `_onAdd()` の1行削除のみ。UI表示ロジックへの影響なし
- `lib/services/recipe_parser_service.dart` — 変更なし（`isExcluded` はデフォルト `false` で残存）

## Flutter固有の注意点
- Provider依存関係: 影響なし
- プラットフォーム分岐（kIsWeb）: 影響なし
- data_provider.dart への影響: なし
