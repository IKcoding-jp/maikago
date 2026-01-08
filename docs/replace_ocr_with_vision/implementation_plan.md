# 実装計画 - OCRをOpenAI Visionに置き換え

## 目的
現在のGoogle Vision APIとテキスト解析の組み合わせでは、「115.45円」のような価格表記を「11545円」と誤認識したり、税込・税抜の区別が曖昧になる問題が発生しています。
この問題を解決するため、OpenAI Vision (GPT-4o-mini) を導入し、画像そのものをAIに視覚的に解釈させることで、値札の構造や価格フォーマット（小数点や端数）を正しく認識できるようにします。

## ユーザーレビュー確認事項
> [!IMPORTANT]
> `HybridOcrService` のロジックを変更し、`VisionOcrService` (Google Vision) の代わりに `ChatGptService` の画像解析機能を呼び出すようにします。
> `OPENAI_API_KEY` が設定されており、GPT-4o-mini (Vision) が利用可能であることを確認してください。

## 変更内容

### Services

#### [MODIFY] [chatgpt_service.dart](file:///d:/Dev/maikago/lib/services/chatgpt_service.dart)
- `Future<OcrItemResult?> extractProductInfoFromImage(File image)` メソッドを追加します。
- 画像をBase64エンコードし、OpenAI Chat Completion APIの `image_url` を使用して送信する処理を実装します。
- 画像から「商品名」と「税込価格」を抽出するための、視覚情報に特化したプロンプトを実装します（小数点の扱いや「税込」表示の優先などを指示）。

#### [MODIFY] [hybrid_ocr_service.dart](file:///d:/Dev/maikago/lib/services/hybrid_ocr_service.dart)
- `detectItemFromImageFast` メソッドを更新し、`_visionService` ではなく `_chatGptService.extractProductInfoFromImage(image)` を呼び出すように変更します。
- このフローでの `VisionOcrService` の使用を削除または無効化します。

#### [MODIFY] [vision_ocr_service.dart](file:///d:/Dev/maikago/lib/services/vision_ocr_service.dart)
- （任意）このサービスは現状のOCRフローでは使用されなくなりますが、他の用途のためにコード自体は保持します（将来的には削除検討）。

## 検証計画

### 手動検証
1. アプリを起動する。
2. カメラ/スキャン機能を開く。
3. 「115.45円」のような複雑な価格表記のある値札をスキャンする。
4. 認識された価格が正しいこと（例：11545円ではなく、税込計算後の適切な価格であること）を確認する。
5. 税抜価格よりも税込価格が優先して採用されることを確認する。
