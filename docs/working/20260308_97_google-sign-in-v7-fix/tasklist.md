# タスクリスト

## フェーズ1: 原因特定
- [x] google_sign_in v7.2.0 の正式APIドキュメントを精査
- [x] `authenticate()` メソッドの戻り値・パラメータを確認
- [x] `GoogleSignInAccount.authentication` プロパティの v7 での仕様を確認
- [x] `initialize()` に必要なパラメータを確認（clientId / serverClientId）
- [x] Web版の認証パス（Firebase Auth直接）の問題を切り分け
- [x] google_sign_in_web 1.1.1 retracted の影響を確認

## フェーズ2: 修正実装
- [x] `lib/services/auth_service.dart` の signInWithGoogle() を v7 正式APIに修正
- [x] `_ensureGoogleSignInInitialized()` のパラメータを修正
- [x] `pubspec.yaml` / `pubspec.lock` の google_sign_in_web を更新
- [x] エラーハンドリングの v7 対応（GoogleSignInException等）
- [x] signOut() の v7 API対応を確認

## フェーズ3: 動作検証
- [ ] Android実機/エミュレータでログイン動作を確認
- [ ] Web（デスクトップブラウザ）でログイン動作を確認
- [ ] Web（モバイルブラウザ）でリダイレクト認証を確認
- [ ] AccountScreen からのログイン/ログアウトを確認
- [ ] flutter analyze パス確認
- [ ] 既存テスト実行・パス確認

## 依存関係
- フェーズ1 → フェーズ2（原因特定後に修正）
- フェーズ2 → フェーズ3（修正後に検証）
