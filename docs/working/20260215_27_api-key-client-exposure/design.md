# 設計書: Issue #27 - APIキーのクライアント露出

## 修正対象ファイル

### 1. `env.json`（アセットファイル）

**変更前**: 18項目（APIキー含む）
**変更後**: 11項目（Firebase設定 + AdMob IDのみ）

削除する項目:
- `OPENAI_API_KEY`
- `GOOGLE_VISION_API_KEY`
- `MAIKAGO_SPECIAL_DONOR_EMAIL`
- `MAIKAGO_ENABLE_DEBUG_MODE`
- `MAIKAGO_SECURITY_LEVEL`
- `MAIKAGO_ALLOW_CLIENT_DONATION_WRITE`

残す項目:
- `FIREBASE_*` (7項目) - Web版のFirebase初期化に必要
- `ADMOB_*` (3項目) - 広告表示に必要
- `GOOGLE_WEB_CLIENT_ID` - 存在しない場合はEnv.dartのフォールバック使用

### 2. `lib/env.dart`（Envクラス）

**削除するゲッター:**
```
specialDonorEmail    → config.dart の specialDonorEmail で代替済み
enableDebugMode      → config.dart の configEnableDebugMode で代替済み
securityLevel        → config.dart の securityLevel で代替済み
allowClientDonationWrite → config.dart の allowClientDonationWrite で代替済み
```

**変更するゲッター:**
```
googleWebClientId → デフォルト値を空文字に変更（ハードコード排除）
```

## 影響なし（変更不要）

- `lib/config.dart` - ビルド時定数。env.jsonとは独立
- `lib/firebase_options.dart` - `Env.firebase*` ゲッターは維持
- `functions/index.js` - `process.env.OPENAI_API_KEY` で読み込み。env.jsonとは無関係
- `lib/services/auth_service.dart` - `Env.googleWebClientId` を使用（維持）

## セキュリティ考慮事項

### 残すキーのリスク評価

| キー | リスク | 理由 |
|------|--------|------|
| `FIREBASE_API_KEY` | 低 | Firebaseの公開キー。セキュリティルールで保護 |
| `ADMOB_*` | 低 | 広告ユニットID。悪用リスクは限定的 |
| `GOOGLE_WEB_CLIENT_ID` | 低 | OAuth Client ID。公開情報として設計されている |
