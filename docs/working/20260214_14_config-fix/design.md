# 設計書: config.dartの設定値修正

## 変更対象ファイル

### 1. `lib/config.dart`

- **行101**: `defaultValue: 'gpt-5-nano'` → `defaultValue: 'gpt-4o-mini'`
- `gpt-4o-mini` はOpenAI の軽量・低コストモデルで、JSONモード対応
- コメントも合わせて修正

### 2. `lib/main.dart`

- **行192**: `Duration(milliseconds: 10000)` → `Duration(milliseconds: 3000)`
- 10秒は過剰。アプリのUI描画・スプラッシュ画面が完了するまでの猶予として3秒で十分
- 遅延の理由をコメントで明記（UIレンダリング完了を待つため）

### 3. `lib/services/product_name_summarizer_service.dart`

- **行57**: コメント `// GPT-5-nanoを使用` の修正

## 影響範囲

- `chatgpt_service.dart` (行313, 732): `openAIModel` を参照 → 定数値の変更のみで参照箇所の修正不要
- `product_name_summarizer_service.dart` (行57): コメントのみ修正
- 広告初期化: 遅延短縮によりアプリ起動後の広告表示が早くなる（UX改善）
