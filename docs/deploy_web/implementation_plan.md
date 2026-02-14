# Flutter Web デプロイ計画

Flutter Web アプリケーションをビルドし、Firebase Hosting (`maikago2` プロジェクト) にデプロイします。

## 実施内容

### 1. ビルド
以下のコマンドで Flutter Web のリリースビルドを行います。
```powershell
flutter build web --release
```
- `firebase.json` の設定に従い、`build/web` ディレクトリがデプロイ対象となります。

### 2. デプロイ
Firebase CLI を使用して Hosting へアップロードします。
```powershell
firebase deploy --only hosting
```

## 検証計画

### 手動確認
1. デプロイ完了後に表示される Hosting の URL にブラウザでアクセスします。
2. アプリが正常にロードされ、ログイン画面またはメイン画面が表示されることを確認します。
3. 基本的な機能（アイテムの表示など）が動作することを確認します。
