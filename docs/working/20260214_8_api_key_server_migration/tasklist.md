# タスクリスト: APIキーのサーバー側移行

## Issue情報
- **Issue番号**: #8
- **作成日**: 2026-02-14
- **担当者**: [未割当]
- **期限**: [未設定]

## タスク概要
APIキーをクライアント側からサーバー側（Firebase Cloud Functions）に移行し、セキュリティを強化します。

---

## フェーズ1: 準備・環境構築

### TASK-1.1: Firebase Console での環境変数設定
**優先度**: 高
**所要時間**: 15分
**前提条件**: なし

**手順**:
1. Firebase Console にログイン
2. プロジェクト `maikago2` を選択
3. `Functions` → `Configuration` に移動
4. 環境変数を追加:
   - `GOOGLE_VISION_API_KEY`: `[現在のenv.jsonの値]`
   - `OPENAI_API_KEY`: `[現在のenv.jsonの値]`
5. 設定を保存

**完了基準**:
- [ ] Firebase Console で環境変数が設定されている
- [ ] `firebase functions:config:get` コマンドで確認可能

---

### TASK-1.2: ローカル開発環境の設定
**優先度**: 高
**所要時間**: 10分
**前提条件**: TASK-1.1

**手順**:
1. `functions/.env` ファイルを作成（.gitignoreに既に含まれている）
2. 以下の内容を記述:
   ```
   GOOGLE_VISION_API_KEY=AIza...
   OPENAI_API_KEY=sk-...
   ```
3. `functions/.gitignore` に `.env` が含まれていることを確認

**完了基準**:
- [ ] `functions/.env` ファイルが作成されている
- [ ] `.env` が `.gitignore` に含まれている

---

## フェーズ2: Cloud Functions の改修

### TASK-2.1: analyzeImage 関数の動作確認
**優先度**: 高
**所要時間**: 20分
**前提条件**: TASK-1.1, TASK-1.2

**手順**:
1. `functions/index.js` の `analyzeImage` 関数を確認
2. 既存の実装が要件を満たしているか検証:
   - Vision API 呼び出し（DOCUMENT_TEXT_DETECTION）
   - OpenAI API 呼び出し（商品情報抽出）
   - エラーハンドリング
   - 認証チェック（`context.auth`）
3. 必要に応じて修正

**完了基準**:
- [ ] `analyzeImage` 関数が認証チェックを実装している
- [ ] Vision APIとOpenAI APIを正しく呼び出している
- [ ] エラーハンドリングが適切

---

### TASK-2.2: Cloud Functions のローカルテスト
**優先度**: 高
**所要時間**: 30分
**前提条件**: TASK-2.1

**手順**:
1. Functions Emulator を起動: `firebase emulators:start --only functions`
2. テスト用のFlutterコードを一時的に作成し、エミュレータに接続
3. 実際の画像データで `analyzeImage` を呼び出し
4. レスポンスとログを確認

**完了基準**:
- [ ] ローカル環境で `analyzeImage` が正常に動作
- [ ] Vision API と OpenAI API が正しく呼び出される
- [ ] 正しいレスポンスが返される

---

### TASK-2.3: Cloud Functions のデプロイ
**優先度**: 高
**所要時間**: 15分
**前提条件**: TASK-2.2

**手順**:
1. `cd functions`
2. `firebase deploy --only functions:analyzeImage`
3. デプロイログでエラーがないことを確認
4. Firebase Console で関数の状態を確認

**完了基準**:
- [ ] Cloud Functions が正常にデプロイされている
- [ ] Firebase Console で関数が有効になっている
- [ ] 環境変数が正しく設定されている

---

## フェーズ3: Flutter アプリの改修

### TASK-3.1: vision_ocr_service.dart の改修
**優先度**: 高
**所要時間**: 45分
**前提条件**: TASK-2.3

**手順**:
1. `lib/services/vision_ocr_service.dart` を開く
2. `detectItemFromImage` メソッドを以下のように変更:
   - 画像の前処理（`_resizeImage`）は継続
   - Vision API への直接呼び出しを削除
   - Cloud Functions `analyzeImage` を呼び出すように変更
   - `firebase_functions` パッケージの `HttpsCallable` を使用
3. エラーハンドリングを実装:
   - ネットワークエラー
   - タイムアウト（30秒）
   - Cloud Functionsのエラーレスポンス
4. 進捗コールバック (`OcrProgressCallback`) を維持

**完了基準**:
- [ ] Vision API への直接呼び出しが削除されている
- [ ] Cloud Functions `analyzeImage` を呼び出している
- [ ] エラーハンドリングが適切
- [ ] 進捗コールバックが機能している

---

### TASK-3.2: chatgpt_service.dart の整理
**優先度**: 中
**所要時間**: 30分
**前提条件**: TASK-3.1

**手順**:
1. `lib/services/chatgpt_service.dart` を確認
2. 現在の使用箇所を調査:
   - `VisionOcrService` から呼び出されているか？
   - 他の箇所で使用されているか？
3. 対応方針の決定:
   - **案A**: 完全削除（Cloud Functionsに統合）
   - **案B**: 直接API呼び出しを残す（レシピ解析など他の用途がある場合）
   - **案C**: Cloud Functions経由に変更
4. 決定した方針に従って実装

**完了基準**:
- [ ] `chatgpt_service.dart` の使用箇所を特定
- [ ] 方針を決定し実装
- [ ] OpenAI APIへの直接呼び出しが削除されている（案Aの場合）

---

### TASK-3.3: env.dart と config.dart の修正
**優先度**: 高
**所要時間**: 20分
**前提条件**: TASK-3.1, TASK-3.2

**手順**:
1. `lib/env.dart` を修正:
   - `googleVisionApiKey` getterを削除
   - `openAIApiKey` getterを削除
   - `_googleVisionApiKeyEnv` と `_openAIApiKeyEnv` を削除
   - `debugApiKeyStatus()` から該当行を削除
2. `lib/config.dart` を修正:
   - `googleVisionApiKey` getterを削除（93行目）
   - `openAIApiKey` getterを削除（96行目）
3. コンパイルエラーがないことを確認

**完了基準**:
- [ ] `lib/env.dart` からAPIキー関連getterが削除されている
- [ ] `lib/config.dart` からAPIキー関連getterが削除されている
- [ ] コンパイルエラーがない

---

### TASK-3.4: env.json の更新
**優先度**: 高
**所要時間**: 5分
**前提条件**: TASK-3.3

**手順**:
1. `env.json` を開く
2. 以下のキーを削除:
   - `GOOGLE_VISION_API_KEY`
   - `OPENAI_API_KEY`
3. `env.json.example` も同様に更新

**完了基準**:
- [ ] `env.json` からAPIキーが削除されている
- [ ] `env.json.example` も更新されている
- [ ] 他のキー（AdMob等）は維持されている

---

## フェーズ4: テストと検証

### TASK-4.1: ユニットテストの更新
**優先度**: 中
**所要時間**: 30分
**前提条件**: TASK-3.4

**手順**:
1. `test/` ディレクトリ内のテストファイルを確認
2. `VisionOcrService` のテストがあれば更新:
   - モックCloud Functionsを使用
   - APIキーの直接テストを削除
3. 必要に応じて新規テストを作成

**完了基準**:
- [ ] 既存のテストが全て通過
- [ ] モックCloud Functionsを使用している
- [ ] APIキーのハードコードがない

---

### TASK-4.2: 統合テスト（実機）
**優先度**: 高
**所要時間**: 45分
**前提条件**: TASK-4.1

**手順**:
1. デバッグビルドで実機（Android/iOS）にインストール
2. OCR機能をテスト:
   - カメラで商品を撮影
   - 画像から商品情報を抽出
   - 結果が正しく表示されることを確認
3. エラーケースのテスト:
   - ネットワークエラー（機内モード）
   - 認識不可能な画像
   - タイムアウト（大きな画像）
4. ログを確認:
   - Cloud Functionsのログ
   - クライアント側のログ

**完了基準**:
- [ ] OCR機能が正常に動作
- [ ] エラーハンドリングが適切
- [ ] Cloud Functionsのログが記録されている
- [ ] APIキーがログに露出していない

---

### TASK-4.3: セキュリティスキャン
**優先度**: 高
**所要時間**: 20分
**前提条件**: TASK-4.2

**手順**:
1. リリースビルドを作成
2. APK/IPA ファイルを解析:
   - `strings` コマンドで文字列を抽出
   - APIキーの文字列が含まれていないことを確認
3. 静的解析ツールを実行（オプション）:
   - `flutter analyze`
   - セキュリティリンター

**完了基準**:
- [ ] ビルド成果物にAPIキーが含まれていない
- [ ] 静的解析で警告が出ない
- [ ] セキュリティチェックリストを満たしている

---

## フェーズ5: ドキュメント整備とデプロイ

### TASK-5.1: ドキュメント更新
**優先度**: 中
**所要時間**: 30分
**前提条件**: TASK-4.3

**手順**:
1. `CLAUDE.md` を更新:
   - 環境変数の説明を更新
   - デプロイ手順を追加
2. `README.md` を更新（存在する場合）
3. `env.json.example` にコメントを追加

**完了基準**:
- [ ] `CLAUDE.md` が最新の実装を反映
- [ ] デプロイ手順が明記されている
- [ ] 環境変数の設定方法が説明されている

---

### TASK-5.2: コミットとプルリクエスト
**優先度**: 高
**所要時間**: 15分
**前提条件**: TASK-5.1

**手順**:
1. 変更をコミット:
   ```bash
   git add .
   git commit -m "security: migrate API keys to Cloud Functions (fix #8)"
   ```
2. プルリクエストを作成
3. レビュー依頼

**完了基準**:
- [ ] 全ての変更がコミットされている
- [ ] プルリクエストが作成されている
- [ ] コミットメッセージが明確

---

### TASK-5.3: 本番デプロイ
**優先度**: 高
**所要時間**: 30分
**前提条件**: TASK-5.2（レビュー完了後）

**手順**:
1. Cloud Functions を本番環境にデプロイ:
   ```bash
   cd functions
   firebase deploy --only functions:analyzeImage --project maikago2
   ```
2. アプリをビルド:
   ```bash
   flutter build appbundle --release  # Android
   flutter build ios --release         # iOS
   ```
3. ストアにアップロード:
   - Google Play Console（Android）
   - App Store Connect（iOS via TestFlight）
4. 段階的ロールアウト（10% → 50% → 100%）

**完了基準**:
- [ ] Cloud Functions が本番環境にデプロイされている
- [ ] アプリが正常にビルドされている
- [ ] ストアにアップロード完了
- [ ] 段階的ロールアウト開始

---

## フェーズ6: 監視と改善

### TASK-6.1: 監視設定
**優先度**: 中
**所要時間**: 20分
**前提条件**: TASK-5.3

**手順**:
1. Firebase Console でアラート設定:
   - Cloud Functions のエラー率
   - 呼び出し回数の急増
   - タイムアウト率
2. Cloud Functions の使用状況を監視
3. Vision API と OpenAI API の使用量を監視

**完了基準**:
- [ ] Firebase アラートが設定されている
- [ ] ダッシュボードで使用状況を確認できる
- [ ] 異常検知時の通知先が設定されている

---

### TASK-6.2: ユーザーフィードバック収集
**優先度**: 低
**所要時間**: 継続的
**前提条件**: TASK-5.3

**手順**:
1. アプリ内フィードバック機能を確認
2. ユーザーレビューを監視
3. エラーレポートを収集（Crashlytics等）

**完了基準**:
- [ ] フィードバック収集の仕組みが動作している
- [ ] 重大な問題が報告されていない

---

## 進捗トラッキング

| フェーズ | タスク | 担当者 | 状態 | 開始日 | 完了日 |
|---------|--------|--------|------|--------|--------|
| 1 | TASK-1.1 | - | 未着手 | - | - |
| 1 | TASK-1.2 | - | 未着手 | - | - |
| 2 | TASK-2.1 | - | 未着手 | - | - |
| 2 | TASK-2.2 | - | 未着手 | - | - |
| 2 | TASK-2.3 | - | 未着手 | - | - |
| 3 | TASK-3.1 | - | 未着手 | - | - |
| 3 | TASK-3.2 | - | 未着手 | - | - |
| 3 | TASK-3.3 | - | 未着手 | - | - |
| 3 | TASK-3.4 | - | 未着手 | - | - |
| 4 | TASK-4.1 | - | 未着手 | - | - |
| 4 | TASK-4.2 | - | 未着手 | - | - |
| 4 | TASK-4.3 | - | 未着手 | - | - |
| 5 | TASK-5.1 | - | 未着手 | - | - |
| 5 | TASK-5.2 | - | 未着手 | - | - |
| 5 | TASK-5.3 | - | 未着手 | - | - |
| 6 | TASK-6.1 | - | 未着手 | - | - |
| 6 | TASK-6.2 | - | 未着手 | - | - |

---

## リスク管理

| リスク | 発生確率 | 影響度 | 対策 |
|--------|----------|--------|------|
| 環境変数設定ミス | 中 | 高 | 手順書の整備、検証スクリプト |
| Cloud Functions の課金増加 | 低 | 中 | 使用量監視、割当量設定 |
| 既存ユーザーへの影響 | 低 | 中 | 段階的ロールアウト |
| ローカル開発環境の問題 | 中 | 低 | `.env` ファイルの整備 |

---

## 注意事項
1. **APIキーのバックアップ**: `env.json` から削除する前に、安全な場所にバックアップを保存
2. **段階的デプロイ**: アプリのロールアウトは段階的に実施（10% → 50% → 100%）
3. **ロールバック準備**: 問題発生時のロールバック手順を事前に確認
4. **監視強化**: デプロイ後1週間は使用量とエラー率を重点的に監視

---

## 完了条件
- [ ] 全タスクが完了している
- [ ] セキュリティスキャンで問題が検出されない
- [ ] OCR機能が正常に動作している
- [ ] 本番環境で1週間以上安定稼働している
- [ ] ドキュメントが更新されている
