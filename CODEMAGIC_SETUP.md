# Codemagic iOSビルド設定 🚀

## 概要
Windows環境からiOSアプリをビルドするためのCodemagic設定です。

## 必要なもの
- Windows PC
- Flutterアプリのリポジトリ（GitHub/GitLab等）
- Codemagicのアカウント（無料で登録可能）

## セットアップ手順

### 1. Codemagicアカウント作成
1. [Codemagic](https://codemagic.io/start/)にアクセス
2. GitHub/GitLabで認証
3. 無料プランでアカウント作成

### 2. リポジトリ連携
1. Codemagicで「Add Application」を選択
2. このリポジトリを選択
3. 自動的にcodemagic.yamlが検出されます

### 3. 環境変数の設定
Codemagicのダッシュボードで以下の環境変数を設定：

```
DEV_EMAIL = your-email@example.com
```

### 4. 初回ビルド実行
1. Codemagicダッシュボードで「Start new build」をクリック
2. 「ios-simulator-test」ワークフローを選択
3. ビルドを開始

## ワークフロー説明

### iOS Simulator Test
- **目的**: iOSシミュレーター向けアプリのビルド
- **環境**: Flutter stable + Xcode latest
- **成果物**: .appファイルとデバッグシンボル

### Android Build
- **目的**: Androidアプリのビルド
- **環境**: Flutter stable
- **成果物**: APKとApp Bundle

## ビルド成果物の確認
ビルド完了後、以下のファイルがダウンロード可能：
- `Runner.app` (iOSシミュレーター用)
- `app-debug.apk` (Android用)
- デバッグシンボルファイル

## トラブルシューティング

### よくある問題
1. **Pod install エラー**
   - iOS依存関係の解決に失敗
   - 解決策: Podfileの確認、依存関係の更新

2. **Firebase設定エラー**
   - GoogleService-Info.plistが見つからない
   - 解決策: Firebase設定ファイルの追加

3. **署名エラー**
   - コード署名証明書の問題
   - 解決策: --no-codesignフラグの使用（シミュレーター用）

### ログの確認方法
1. Codemagicダッシュボードでビルドを選択
2. 「Build logs」タブで詳細ログを確認
3. エラーメッセージを確認して対応

## 注意事項
- 無料プランでは月間ビルド時間に制限があります
- iOSシミュレーター用ビルドは実機では動作しません
- 実機テストにはApple Developer Programが必要です

## 次のステップ
1. 初回ビルドの実行
2. ビルド成果物のダウンロード
3. ローカルでのテスト実行
4. 必要に応じて設定の調整

## サポート
問題が発生した場合は：
1. Codemagicのドキュメントを確認
2. Flutter公式ドキュメントを参照
3. GitHub Issuesで報告
