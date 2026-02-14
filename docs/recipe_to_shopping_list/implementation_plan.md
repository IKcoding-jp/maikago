# レシピ入力UIの改善とレシピ名保存機能の実装

レシピ入力機能におけるUIの不備（Androidナビゲーションバーとの重なり）を修正し、各アイテムに具体的な「レシピ名」を紐付けて保存・表示できるように拡張します。

## ユーザーレビューが必要な項目
> [!IMPORTANT]
> **Androidの3ボタンナビゲーションバーの問題**: `SafeArea` を適切に配置し、ボタンがシステムUIに隠れないようにしました。
> **レシピ名の保存不備**: `ListItem` の `toJson`/`toMap` に `recipeName` を追加し、データの永続化を確実にしました。
> **デザインの不調和**: バッジの色をアプリのテーマカラー（`colorScheme`）と同期させました。

## 予定されている変更

### データモデル (Models)
#### [MODIFY] [list.dart](file:///d:/Dev/maikago/lib/models/list.dart)
- `ListItem` クラスに `recipeName` (String?) フィールドを追加。
- `toJson`, `toMap`, `fromJson`, `fromMap` すべてのシリアライズ処理に `recipeName` を含める。 [完了]

### サービス層 (Services)
#### [MODIFY] [recipe_parser_service.dart](file:///d:/Dev/maikago/lib/services/recipe_parser_service.dart)
- AIへのプロンプトを更新し、材料リストだけでなく「レシピのタイトル」も抽出するように変更。 [完了]
- `parseRecipe` の戻り値を, タイトルと材料リストを含む構造体に変更。 [完了]

### UI層 (Screens/Widgets)
#### [MODIFY] [recipe_confirm_screen.dart](file:///d:/Dev/maikago/lib/screens/recipe_confirm_screen.dart)
- 画面上部に「レシピ名」の入力フィールドを追加し、AIが抽出したタイトルを確認・編集できるように変更。 [完了]
- アイテム追加時に、このレシピ名を `ListItem` にセットするように修正。 [完了]
- フッターを `SafeArea` で囲み、Androidナビゲーションバーとの重なりを防止。 [完了]
- **[NEW] 追加ロジックの修正**: 
    - `name` を `"${ingredient.name} (${ingredient.quantity})"` 形式に変更。
    - `quantity` (個数) を一律 `1` に固定。

#### [MODIFY] [list_edit.dart](file:///d:/Dev/maikago/lib/widgets/list_edit.dart)
- アイテムカードに表示されるタグを、具体的な「レシピ名」に変更。 [完了]
- バッジの色をテーマカラー（`secondary`/`primary`）に同期。 [完了]

#### [MODIFY] [recipe_import_bottom_sheet.dart](file:///d:/Dev/maikago/lib/widgets/recipe_import_bottom_sheet.dart)
- キーボード表示時のスクロール調整と、`SafeArea` によるレイアウト修正。 [完了]

## 検証計画

### 自動テスト
- `dart test` によるモデルのシリアライズテスト（任意）

### 手動確認
- [x] レシピを貼り付け、料理名が正しく抽出されるか確認。
- [x] Androidエミュレータ/実機で、ボタンがナビゲーションバーに隠れないか確認。
- [x] アプリ再起動後も、買い物リストのアイテムにレシピ名が表示され続けているか確認。
- [x] テーマ（ピンク、ブルー、ミント等）を切り替えた際、バッジの色が追随するか確認。
