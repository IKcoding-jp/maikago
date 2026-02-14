# 要件定義: デバッグモードデフォルト値変更とAPIキーログ出力削除

## Issue
- **番号**: #10
- **タイトル**: security: デバッグモードデフォルト値変更とAPIキーログ出力削除
- **ラベル**: security, major

## 背景

`config.dart`の`configEnableDebugMode`のデフォルト値が`true`になっており、本番ビルドで`--dart-define`未指定の場合にデバッグログが有効になるリスクがある。また、複数のサービスファイルでAPIキーの先頭10文字がログ出力されており、logcatなどからAPIキー情報が漏洩する可能性がある。

## 要件

### R1: デバッグモードのデフォルト値変更
- `config.dart:38`の`configEnableDebugMode`のデフォルト値を`true`→`false`に変更
- 開発時は`--dart-define=MAIKAGO_ENABLE_DEBUG_MODE=true`で明示的に有効化する運用

### R2: APIキーログ出力の削除
- APIキーの部分文字列をログ出力している箇所をすべて削除またはマスク処理に変更
- 対象ファイル:
  - `lib/services/chatgpt_service.dart` (4箇所)
  - `lib/services/product_name_summarizer_service.dart` (2箇所)

### R3: 他ファイルの機密情報ログ出力チェック
- `lib/services/`配下の全ファイルでAPIキー・トークン等の機密情報がログ出力されていないことを確認

### R4: CI/CD設定の確認
- `codemagic.yaml`および`.github/workflows/`でリリースビルド時にデバッグモードが無効化されていることを確認
- 必要に応じて`--dart-define=MAIKAGO_ENABLE_DEBUG_MODE=false`を追加

## 受け入れ基準
- [ ] `configEnableDebugMode`のデフォルト値が`false`
- [ ] APIキーの先頭文字列がログ出力されない
- [ ] `flutter analyze`が通過
- [ ] `flutter test`が通過
