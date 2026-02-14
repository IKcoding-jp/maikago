# 要件定義書: APIキーのサーバー側移行

## Issue情報
- **Issue番号**: #8
- **作成日**: 2026-02-14
- **ラベル**: security, critical
- **優先度**: 高

## 概要
現在、Google Cloud Vision APIとOpenAI APIのAPIキーがクライアント側（Flutter アプリ）に露出している状態です。これはセキュリティ上の重大なリスクであり、APIキーの不正利用やコスト増加につながる可能性があります。本施策では、これらのAPIキーをサーバー側（Firebase Cloud Functions）に移行し、クライアントからは完全に削除します。

## 背景と問題点

### 現状の実装
1. **クライアント側での直接API呼び出し**
   - `lib/services/vision_ocr_service.dart` (61行目): Vision APIに直接HTTPリクエスト
   - `lib/services/chatgpt_service.dart` (51行目): OpenAI APIに直接HTTPリクエスト
   - APIキーは `env.json` から読み込まれ、アプリバンドルに含まれる

2. **APIキーの管理**
   - `env.json`: アセットファイルとして配布される（.gitignoreに含まれているがビルド成果物には含まれる）
   - `lib/env.dart`: `env.json` からAPIキーを読み込むユーティリティクラス
   - `lib/config.dart`: `Env.googleVisionApiKey` と `Env.openAIApiKey` を参照

3. **既存のCloud Functions**
   - `functions/index.js` の `analyzeImage` 関数: 既にVision APIとOpenAI APIを呼び出す実装が存在
   - しかし、現在はクライアント側が直接APIを呼び出しており、Cloud Functionsは使用されていない可能性

### セキュリティリスク
1. **APIキーの露出**: クライアントアプリを解析することでAPIキーが取得可能
2. **不正利用のリスク**: 抽出されたAPIキーで第三者が無制限にAPI呼び出し可能
3. **コスト爆発のリスク**: 不正利用により予期しない課金が発生
4. **監査の困難性**: クライアント側からの直接呼び出しではユーザー認証・ログ追跡が不十分

## 目標
1. **APIキーの完全なサーバー側移行**: Vision APIとOpenAI APIのキーをCloud Functionsの環境変数に移動
2. **クライアント側の完全削除**: `env.json`, `lib/env.dart`, `lib/config.dart` からAPIキー参照を削除
3. **既存機能の維持**: OCR機能（画像から商品情報抽出）は現状と同じUXを提供
4. **認証の強化**: Firebase AuthenticationによるユーザーID検証を実装
5. **エラーハンドリングの改善**: タイムアウト、APIエラーの適切な処理

## 対象範囲

### 修正対象ファイル
1. **Cloud Functions (サーバー側)**
   - `functions/index.js`: `analyzeImage` 関数の改修（既存実装の活用）
   - `functions/package.json`: 依存関係の確認（既に必要なパッケージは導入済み）

2. **Flutter アプリ (クライアント側)**
   - `lib/services/vision_ocr_service.dart`: Cloud Functions呼び出しに変更
   - `lib/services/chatgpt_service.dart`: Cloud Functions経由に変更（または削除検討）
   - `lib/env.dart`: APIキー関連getterの削除
   - `lib/config.dart`: APIキー参照の削除

3. **環境設定**
   - `env.json`: GOOGLE_VISION_API_KEYとOPENAI_API_KEYの削除
   - `env.json.example`: サンプルファイルの更新
   - Firebase Console: Cloud Functionsの環境変数設定

### 非対象
- AdMob関連のAPIキー（広告IDはクライアント側での管理が一般的なため対象外）
- `GOOGLE_WEB_CLIENT_ID` (OAuth認証に必要なためクライアント側保持)

## 機能要件

### FR-1: Cloud Functionsでの画像解析API
- **FR-1.1**: `analyzeImage` 関数は認証されたユーザーのみ呼び出し可能
- **FR-1.2**: base64エンコードされた画像データを受け取る
- **FR-1.3**: Vision APIで文字認識（DOCUMENT_TEXT_DETECTION）を実行
- **FR-1.4**: OpenAI APIで商品名と税込価格を抽出
- **FR-1.5**: `{ success: true, name: string, price: number }` 形式でレスポンス
- **FR-1.6**: エラー時は `{ success: false, error: string }` を返却

### FR-2: クライアント側の変更
- **FR-2.1**: `VisionOcrService.detectItemFromImage()` はCloud Functionsを呼び出す
- **FR-2.2**: 画像の前処理（リサイズ、グレースケール、コントラスト調整）はクライアント側で継続
- **FR-2.3**: 進捗状況コールバック (`OcrProgressCallback`) は維持
- **FR-2.4**: タイムアウト処理（30秒）を実装

### FR-3: 環境変数管理
- **FR-3.1**: Cloud Functionsの環境変数に `GOOGLE_VISION_API_KEY` を設定
- **FR-3.2**: Cloud Functionsの環境変数に `OPENAI_API_KEY` を設定
- **FR-3.3**: クライアント側の `env.json` からAPIキーを削除

## 非機能要件

### NFR-1: セキュリティ
- **NFR-1.1**: APIキーはサーバー側の環境変数でのみ管理
- **NFR-1.2**: Firebase Authentication による認証必須
- **NFR-1.3**: ユーザーIDのログ記録（監査証跡）

### NFR-2: パフォーマンス
- **NFR-2.1**: Cloud Functionsのタイムアウトは30秒以内
- **NFR-2.2**: 既存のOCR処理時間と同等またはそれ以下

### NFR-3: 可用性
- **NFR-3.1**: エラー時の適切なメッセージ表示
- **NFR-3.2**: ネットワークエラー、APIエラーの区別

### NFR-4: 保守性
- **NFR-4.1**: Cloud Functionsのログで処理状況を追跡可能
- **NFR-4.2**: エラーの詳細情報をログに記録

## 制約事項
1. **既存のCloud Functions実装を最大限活用**: `functions/index.js` の `analyzeImage` は既に実装済み
2. **Firebase Console での手動設定が必要**: 環境変数の設定はデプロイスクリプトでは対応不可
3. **ローカル開発環境**: Functions Emulatorでのテスト時は `.env` ファイルで環境変数を管理

## 成功基準
1. クライアント側のコードから全てのAPIキーが削除されていること
2. OCR機能が正常に動作すること（既存テストケースが全て通過）
3. Cloud Functionsのログで全API呼び出しが追跡可能なこと
4. セキュリティスキャンツールでAPIキーが検出されないこと

## リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| Cloud Functionsの課金増加 | 中 | 呼び出し回数の監視、割当量の設定 |
| レスポンス時間の増加 | 低 | 画像サイズの最適化は継続、タイムアウト設定 |
| 既存ユーザーへの影響 | 低 | アプリ更新のみで対応可能（バックエンド互換） |
| 環境変数設定ミス | 中 | デプロイ手順書の整備、検証スクリプト |

## 参考資料
- Firebase Cloud Functions ドキュメント: https://firebase.google.com/docs/functions
- Google Cloud Vision API ドキュメント: https://cloud.google.com/vision/docs
- OpenAI API ドキュメント: https://platform.openai.com/docs/api-reference

## 承認
- **作成者**: Claude Code
- **レビュー**: [保留]
- **承認日**: [保留]
