# テスト計画: Issue #27 - APIキーのクライアント露出

## テスト方針

この修正はキーの削除とデッドコード除去が中心のため、
既存テストの通過と静的解析による検証を主とする。

## テスト項目

### 1. 静的解析
- [ ] `flutter analyze` が警告・エラーなしで通過
- [ ] 削除したゲッターへの参照がないことを確認

### 2. 既存テスト
- [ ] `flutter test` が全テスト通過

### 3. 手動確認
- [ ] env.json に `OPENAI_API_KEY` が含まれていない
- [ ] env.json に `GOOGLE_VISION_API_KEY` が含まれていない
- [ ] env.json に `MAIKAGO_SPECIAL_DONOR_EMAIL` が含まれていない
- [ ] env.dart に未使用ゲッターが残っていない

## リグレッションリスク

- **低リスク**: 削除するキー/ゲッターはすべてクライアントコードで未使用であることを確認済み
- **注意点**: `Env.googleWebClientId` のデフォルト値変更により、env.jsonに `GOOGLE_WEB_CLIENT_ID` が設定されていない場合に `--dart-define` フォールバックが使用される
