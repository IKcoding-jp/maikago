# テスト計画

## テスト戦略

### 手動テスト（必須）
Google認証は外部サービス連携のため、手動テストが主体。

#### Android
- [ ] エミュレータまたは実機でアプリ起動
- [ ] LoginScreen → 「Googleアカウントでログイン」タップ
- [ ] Googleアカウント選択画面が表示されること
- [ ] アカウント選択後、メイン画面に遷移すること
- [ ] AccountScreen → ログアウト → 再ログインが動作すること

#### Web（デスクトップ）
- [ ] `flutter run -d chrome` でアプリ起動
- [ ] LoginScreen → ログインボタンタップ
- [ ] Googleポップアップが表示されること
- [ ] 認証後、メイン画面に遷移すること

#### Web（モバイル）
- [ ] モバイルブラウザでアクセス
- [ ] ログインボタンタップ → リダイレクト認証が開始されること
- [ ] 認証後、アプリに戻りメイン画面が表示されること

### エラーケーステスト
- [ ] ログイン中にキャンセル → 「ログインがキャンセルされました」SnackBar表示
- [ ] ネットワーク切断状態でログイン → 適切なエラーメッセージ表示

### 既存テスト
```bash
flutter test
flutter analyze
```
- [ ] 全テストパス
- [ ] 静的分析エラーなし

## テスト実行コマンド
```bash
# 静的分析
flutter analyze

# 全テスト実行
flutter test

# Android実行
flutter run -d <device_id>

# Web実行
flutter run -d chrome
```
