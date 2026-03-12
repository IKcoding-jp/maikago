# テスト計画

## テスト戦略

### ユニットテスト
- `test/services/one_time_purchase_service_test.dart`（既存テストの確認 + 追加）
  - `resetForLogout()` 呼び出し後に `isPremiumUnlocked` が `false` を返す
  - `resetForLogout()` 後に `_currentUserId` が空文字になる
  - リセット後に `initialize(userId: uid)` で正しく復元される

### 手動テスト
- プレミアムアカウントでログイン → ログアウト → プレミアム機能が無効になることを確認
- ログアウト後にゲストモードで広告が表示されることを確認
- 再ログインでプレミアム機能が復活することを確認

## テスト実行コマンド
```bash
flutter test
flutter test test/services/one_time_purchase_service_test.dart
```
