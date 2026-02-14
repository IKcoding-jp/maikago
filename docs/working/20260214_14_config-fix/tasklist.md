# タスクリスト: config.dartの設定値修正

**ステータス**: 完了
**開始日**: 2026-02-14
**完了日**: 2026-02-14

## Phase 1: OpenAIモデル名修正

- [x] `lib/config.dart:101` の `gpt-5-nano` を `gpt-4o-mini` に変更
- [x] コメントを適切に更新
- [x] `product_name_summarizer_service.dart:57` のコメント修正

## Phase 2: 広告初期化遅延の改善

- [x] `lib/main.dart:192` の10秒遅延を3秒に短縮
- [x] コメントで遅延理由を明記

## Phase 3: 検証

- [x] `flutter analyze` 通過
- [x] `flutter test` — テストディレクトリなし（スキップ）
