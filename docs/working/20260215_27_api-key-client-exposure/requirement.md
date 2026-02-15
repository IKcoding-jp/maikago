# 要件定義: Issue #27 - APIキーのクライアント露出

## 概要

`env.json` に含まれるAPIキー（OpenAI, Google Vision等）がFlutterアセットとしてビルドに含まれ、
Web版では `build/web/assets/env.json` から平文で取得可能な状態を修正する。

## 現状分析

### env.json に含まれるキー（全18項目）

| キー | クライアント使用 | 深刻度 | 対応 |
|------|:---:|:---:|------|
| `OPENAI_API_KEY` | 未使用 | Critical | **削除** |
| `GOOGLE_VISION_API_KEY` | 未使用 | High | **削除** |
| `MAIKAGO_SPECIAL_DONOR_EMAIL` | 未使用（Env経由） | Medium | **削除** |
| `MAIKAGO_ENABLE_DEBUG_MODE` | 未使用（Env経由） | Low | **削除** |
| `MAIKAGO_SECURITY_LEVEL` | 未使用（Env経由） | Low | **削除** |
| `MAIKAGO_ALLOW_CLIENT_DONATION_WRITE` | 未使用（Env経由） | Low | **削除** |
| `FIREBASE_*` (7項目) | Web版で使用 | - | 維持 |
| `ADMOB_*` (3項目) | 使用 | - | 維持 |

### env.dart の未使用ゲッター

以下は `config.dart` のビルド時定数と重複しており、コードから参照されていない:
- `Env.specialDonorEmail`
- `Env.enableDebugMode`
- `Env.securityLevel`
- `Env.allowClientDonationWrite`

### env.dart のハードコード問題

- `Env.googleWebClientId` のデフォルト値にOAuth Client IDがハードコード（line 38）

## 要件

### R1: 不要なAPIキーの削除
- env.json から `OPENAI_API_KEY`, `GOOGLE_VISION_API_KEY` を削除
- Cloud Functionsでは既に `process.env` で読み込んでおり影響なし

### R2: 不要な設定値の削除
- env.json から `MAIKAGO_SPECIAL_DONOR_EMAIL`, `MAIKAGO_ENABLE_DEBUG_MODE`, `MAIKAGO_SECURITY_LEVEL`, `MAIKAGO_ALLOW_CLIENT_DONATION_WRITE` を削除
- これらは `config.dart` の `String.fromEnvironment` / `bool.fromEnvironment` で管理済み

### R3: env.dart のクリーンアップ
- 未使用ゲッター（specialDonorEmail, enableDebugMode, securityLevel, allowClientDonationWrite）を削除
- ハードコードされたOAuth Client IDのデフォルト値を空文字に変更

### R4: キーローテーションの案内
- ユーザーにOpenAI APIキーのローテーション（無効化+再生成）を案内
- Google Vision APIキーの制限設定を案内

## 影響範囲

- `env.json` - アセットファイル
- `lib/env.dart` - Envクラス
- Cloud Functions - 影響なし（process.env使用）
- config.dart - 影響なし（変更不要）
- firebase_options.dart - 影響なし（Env.firebase*は維持）
