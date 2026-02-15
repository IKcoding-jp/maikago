# テスト計画: Firebase Hostingキャッシュ設定・Firestoreオフライン設定

## テスト種別

### 自動テスト
- `flutter analyze`: Lint エラーがないこと
- `flutter test`: 既存テストが全て通ること

### 手動テスト（任意）
- Web版をビルドして Firebase Hosting にデプロイ後、ブラウザの DevTools > Network タブでキャッシュヘッダーを確認
- オフライン状態でのデータ表示を確認

## テスト対象外
- 設定ファイルの変更とFirestore初期化設定のみのため、新規ユニットテストの追加は不要
