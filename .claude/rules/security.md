---
paths:
  - "lib/**/*.dart"
  - "functions/**/*.js"
  - "firestore.rules"
---

# セキュリティルール

## APIキー

- クライアントコード（lib/）にAPIキーをハードコードしない
- Cloud Functions + Secret Manager（`defineSecret()`）で管理
- `env.dart` の `Env` クラスは `--dart-define` 経由の値のみ使用

## ログ出力

- `debugPrint` にユーザーデータ、トークン、APIキーを含めない
- 本番ビルドでは `kDebugMode` ガードを使用

## Firestoreルール

- 変更時は最小権限の原則を確認
- ユーザーは自分のデータのみ読み書き可能にすること
- `request.auth != null` を必ず含めること
