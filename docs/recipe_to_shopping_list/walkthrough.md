# レシピから買い物リスト追加機能の実装完了

レシピテキストを貼り付けるだけで、材料と分量をAIが自動抽出し、既存の買い物リストに賢く追加・統合する機能を実装しました。

## 概要
- **AI解析**: GPT-4o-miniを使用して、不規則なレシピテキストから純粋な材料名と分量を抽出。
- **名寄せ・統合**: 既存のリストアイテムと名前が似ている場合、合算するか別々に残すかを選択可能。
- **レシピタグ**: レシピから追加されたアイテムには「レシピ由来」のバッジが表示され、区別が容易になります。

## 実施した変更

### 1. データモデルの拡張
- [list.dart](file:///d:/Dev/maikago/lib/models/list.dart)
    - `ListItem` クラスに `isRecipeOrigin` (bool) および `recipeName` (String?) フィールドを追加しました。これにより、具体的なレシピ名をアイテムごとに保存可能になります。

### 2. AI抽出サービスの実装
- [recipe_parser_service.dart](file:///d:/Dev/maikago/lib/services/recipe_parser_service.dart)
    - レシピテキストから、材料リストだけでなく「レシピのタイトル」も自動抽出するようにプロンプトとロジックを強化しました。

### 3. UIコンポーネントの追加
- [recipe_import_bottom_sheet.dart](file:///d:/Dev/maikago/lib/widgets/recipe_import_bottom_sheet.dart)
    - テキスト入力エリアと解析ボタンを備えたボトムシートを実装。
- [recipe_confirm_screen.dart](file:///d:/Dev/maikago/lib/screens/recipe_confirm_screen.dart)
    - 解析結果のプレビュー画面に「レシピ名」の編集フィールドを追加しました。
    - **追加ロジックの改善**: 買い物リストの数量を「1」に固定し、レシピの分量を商品名（例: "豚肉 (150g)"）に含めるように変更しました。これにより、分量の「数値」が「個数」と混同される問題を解消しました。
    - ここで入力・確認された名前が、各アイテムの `recipeName` として買い物リストに保存されます。

### 4. 既存画面への統合
- [bottom_summary_widget.dart](file:///d:/Dev/maikago/lib/screens/main/widgets/bottom_summary_widget.dart)
    - 「カメラ」および「レシピ」ボタンをアイコンのみのコンパクトなデザインに変更し、中央に配置しました。
- [list_edit.dart](file:///d:/Dev/maikago/lib/widgets/list_edit.dart)
    - アイテムカードのタグに、固定の「レシピ由来」ではなく、具体的な「レシピ名（肉じゃが 等）」を表示するように変更しました。
    - また、レシピ名が空や未設定の場合でも適切にフォールバック表示されるように修正しました。
    - **デザイン調整**: バッジの色を固定のオレンジから、アプリ全体のテーマ（セカンダリカラー）に同期するように変更し、視覚的な統一感を高めました。
- [list.dart](file:///d:/Dev/maikago/lib/models/list.dart)
    - **バグ修正**: `toJson` および `toMap` に `recipeName` が含まれていなかったため、Firestoreへ保存されない問題を修正しました。

### 5. レイアウトの修正 (Android対応)
- [recipe_import_bottom_sheet.dart](file:///d:/Dev/maikago/lib/widgets/recipe_import_bottom_sheet.dart)
    - **ナビゲーションバー対応**: `SafeArea` を導入し、Androidの3ボタンナビゲーションと重ならないように調整。
    - **キーボード対応**: `SingleChildScrollView` と `viewInsets` によるパディング調整を加え、キーボード表示時に画面が崩れる（オーバーフロー）問題を解決しました。
- [recipe_confirm_screen.dart](file:///d:/Dev/maikago/lib/screens/recipe_confirm_screen.dart)
    - **フッター対応**: 確認画面の「戻る」「追加する」ボタンのあるフッター部分に `SafeArea` を追加し、ナビゲーションバーとの重なりを解消しました。

## 動作確認内容
- [x] レシピを貼り付けた際、適切なタイトル（料理名）が自動抽出されること。
- [x] 商品名に分量が自動的に含まれること（例: "豚肉 (150g)"）。
- [x] 追加されたアイテムの数量（個数）が「1」で固定されていること。
- [x] アイテムリストに具体的な「レシピ名」バッジが表示されること。

## 今後の展望
- [ ] 画像解析(OCR)によるレシピ取り込みの検討
- [ ] 分量の数値変換精度の更なる向上（現在は正規表現による簡易抽出）
- [ ] 調味料の除外リストのUIによるカスタマイズ設定
