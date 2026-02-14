# タスクリスト: APIキーのサーバー側移行

**ステータス**: 完了
**完了日**: 2026-02-14

## Issue情報
- **Issue番号**: #8
- **作成日**: 2026-02-14
- **PR**: #18

## 実施内容まとめ

### フェーズ1: 準備・環境構築
- [x] TASK-1.1: functions/.env でOPENAI_API_KEY設定
- [x] TASK-1.2: .gitignore にnode_modules追加

### フェーズ2: Cloud Functions の改修
- [x] TASK-2.1: analyzeImage関数に認証チェック追加
- [x] TASK-2.2: parseRecipe, summarizeProductName, checkIngredientSimilarity関数を新規作成
- [x] TASK-2.3: Cloud Functions デプロイ完了（Node.js 20）、IAM権限設定

### フェーズ3: Flutter アプリの改修
- [x] TASK-3.1: vision_ocr_service.dart をCloud Functions経由に書き換え
- [x] TASK-3.2: chatgpt_service.dart を削除（1473行）、全機能をCloud Functionsに統合
- [x] TASK-3.3: env.dart/config.dart からAPIキーゲッター削除、Firebase Web設定ゲッター追加
- [x] TASK-3.4: firebase_options.dart をenv.jsonランタイム読み込みに変更

### フェーズ4: テストと検証
- [x] TASK-4.1: flutter analyze 通過
- [x] TASK-4.2: レシピ解析（Cloud Functions経由）動作確認済み、Firebase Webログイン確認済み

### フェーズ5: コミットとPR
- [x] TASK-5.2: PR #18 作成・プッシュ完了
