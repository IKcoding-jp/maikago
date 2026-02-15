# タスクリスト: Issue #27 - APIキーのクライアント露出

**ステータス**: 進行中
**開始日**: 2026-02-15

## Phase 1: env.json のクリーンアップ

- [x] 1.1 `OPENAI_API_KEY` を env.json から削除
- [x] 1.2 `GOOGLE_VISION_API_KEY` を env.json から削除
- [x] 1.3 `MAIKAGO_SPECIAL_DONOR_EMAIL` を env.json から削除
- [x] 1.4 `MAIKAGO_ENABLE_DEBUG_MODE` を env.json から削除
- [x] 1.5 `MAIKAGO_SECURITY_LEVEL` を env.json から削除
- [x] 1.6 `MAIKAGO_ALLOW_CLIENT_DONATION_WRITE` を env.json から削除

## Phase 2: env.dart のクリーンアップ

- [x] 2.1 `Env.specialDonorEmail` ゲッターを削除
- [x] 2.2 `Env.enableDebugMode` ゲッターを削除
- [x] 2.3 `Env.securityLevel` ゲッターを削除
- [x] 2.4 `Env.allowClientDonationWrite` ゲッターを削除
- [x] 2.5 `Env.googleWebClientId` のハードコードされたデフォルト値を空文字に変更

## Phase 3: 検証

- [x] 3.1 `flutter analyze` 通過
- [x] 3.2 `flutter test` 通過
- [x] 3.3 env.json にAPIキーが含まれていないことを確認
