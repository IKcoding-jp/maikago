# タスク: OCRをOpenAI Visionに置き換え

## ステータス定義
- [ ] 未着手
- [/] 進行中
- [x] 完了

## タスク
- [x] 実装計画の作成
- [x] `ChatGptService` の修正
    - [x] `extractProductInfoFromImage(File image)` メソッドの追加
    - [x] 画像エンコードとOpenAI Vision API呼び出しの実装
    - [x] 価格（税込優先）と商品名を正確に抽出するためのプロンプト作成
- [x] `HybridOcrService` の修正
    - [x] `detectItemFromImageFast` を `ChatGptService.extractProductInfoFromImage` を使うように変更
    - [x] `VisionOcrService` (Google Vision) 呼び出しの削除/バイパス
- [x] 変更の検証
    - [x] 実機での動作確認（またはユーザーによる検証）
    - [x] 「115.45円」問題が解決しているか確認
