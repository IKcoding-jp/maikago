# 実装計画: ログインプロセスの安定化とAPI設定の修正

## 1. 現状分析
- **エラー1**: `MissingPluginException`. ネイティブプラグインとFlutterのチャネル接続が切れている。
- **エラー2**: ログイン処理の中断。アカウント選択後に広告が表示され、UIの状態がリセットされている。
- **エラー3**: `ApiException: 10`. OAuthクライアントIDの設定不備またはSHA-1の未登録。

## 2. 修正方針
- プラグインのクリーンビルドとバージョンの適正化。
- `main.dart` のライフサイクルイベントにおいて、未ログイン時は広告表示を抑制するガードを追加。
- `AuthService` において `serverClientId` を明示的に指定するように変更。
- デバッグ用の SHA-1 証明書を特定し、Firebase側での設定を促す。

## 3. 修正対象ファイル
- `pubspec.yaml`: プラグインバージョンの調整
- `lib/main.dart`: 広告表示の条件分岐追加
- `lib/env.dart`: ウェブクライアントID定数の追加
- `lib/services/auth_service.dart`: GoogleSignInの初期化パラメータ修正
