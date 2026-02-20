# 要件定義: セキュリティ強化（Firestoreルール・APIキー管理・Cloud Functions）

Issue: #87
作成日: 2026-02-20
ステータス: 作業中

## 背景

バイブコーディングによるコードレビューで、セキュリティ脆弱性が複数発見された。
特に以下の3つの領域で改善が必要:

1. **Firestoreルール** — バリデーション不足、過剰な権限付与
2. **APIキー管理** — env.jsonによるアプリバンドル同梱（キー露出リスク）
3. **Cloud Functions** — v1 API使用、Secret Manager未使用、レート制限なし

## 要件一覧

### Critical

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| CR-1 | env.jsonのアプリバンドル同梱をやめ、`--dart-define`によるビルド時注入に一本化 | `env.json`, `lib/env.dart`, `pubspec.yaml`, `lib/firebase_options.dart`, CI/CD設定 |

### High

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| HI-1 | anonymousコレクションのルールにUID紐づけ追加 | `firestore.rules:212-223` |
| HI-2 | familiesのcreateルールにフィールドバリデーション追加（ownerId必須化） | `firestore.rules:67` |
| HI-3 | Firebase Functions v2移行 + `defineSecret()`によるSecret Manager使用 | `functions/index.js`, `functions/package.json` |

### Medium

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| MD-1 | Firestoreルール全体にスキーマバリデーション追加（フィールド型・サイズ制限） | `firestore.rules` |
| MD-2 | analyzeImageにユーザーあたりのレート制限追加 | `functions/index.js:30-189` |
| MD-3 | 体験期間（Trial）の検証をサーバーサイドに移行 | `lib/services/one_time_purchase_service.dart`, `functions/index.js` |
| MD-4 | sharedWithフィールドの変更を送信者のみに制限 | `firestore.rules:149-184` |
| MD-5 | donationsルールとdonation_service.dartの整合性修正 | `firestore.rules:51-55`, `lib/services/donation_service.dart` |

### Low

| ID | 要件 | 対象ファイル |
|----|------|-------------|
| LO-1 | プレミアム状態の保存にflutter_secure_storage検討 | `lib/services/one_time_purchase_service.dart` |
| LO-2 | レシピ入力テキストの長さ制限追加 | `lib/services/recipe_parser_service.dart`, `functions/index.js` |
| LO-3 | notifications作成ルールにファミリーオーナー確認追加 | `firestore.rules:203` |

## 現状分析

### env.json の現状
- `pubspec.yaml` で Flutter アセットとして登録（`- env.json`）
- `lib/env.dart` が `rootBundle.loadString('env.json')` でランタイム読み込み
- Web版ビルド成果物 `build/web/assets/env.json` から平文取得可能
- 現在含まれるキー: AdMob広告ID×3、Firebase Web設定×7
- 既に `--dart-define` のフォールバック機構あり（`lib/config.dart`）
- GitHub Actions: `secrets.ENV_JSON` から生成（Web デプロイ用）
- Codemagic: env.json の生成記述なし（ネイティブビルドでは不要の可能性）

### Firestoreルール の現状
- anonymousコレクション: `request.auth != null` のみ → 他ユーザーのセッションに介入可能
- families create: `request.auth != null` のみ → ownerId なしで作成可能
- transmissions/syncData: sharedWith に含まれるユーザーが write 権限を持つ → sharedWith 自体を改ざん可能
- donations: `allow write: if false` → クライアントの `_saveToFirestore()` がブロックされている（不整合）
- notifications: family_dissolved 通知の作成にファミリーオーナー確認なし

### Cloud Functions の現状
- firebase-functions v4 (v1 API) を使用
- `process.env.OPENAI_API_KEY` で環境変数直接参照
- analyzeImage にレート制限なし → 大量呼び出しでコスト増のリスク

## 非機能要件
- 既存機能への影響を最小限にする
- CI/CDパイプラインが正常に動作すること
- テストが通ること
