# リリース署名キーストアについて

## 重要事項

**⚠️ このキーストアファイル（release-key-new.jks）は非常に重要です！**

- このファイルを紛失すると、Google Play Consoleにアプリを更新できなくなります
- バックアップを必ず取ってください
- バージョン管理システム（Git）には含めないでください

## 現在の設定

- **キーストアパスワード**: `maikago2025`
- **キーエイリアス**: `upload`
- **キーパスワード**: `maikago2025`
- **有効期限**: 10,000日（約27年）

## ファイル構成

- `release-key-new.jks` - リリース用の署名キーストア
- `key.properties` - キーストア設定ファイル（プロジェクトルート）
- `set-env.bat` - 環境変数設定スクリプト
- `build.gradle.kts` - ビルド設定（署名設定を含む）

## 使用方法

### 1. 環境変数の設定（オプション）
```bash
# Windows
call android\app\set-env.bat

# または手動で設定
set KEYSTORE_PASSWORD=maikago2025
set KEY_ALIAS=upload
set KEY_PASSWORD=maikago2025
```

### 2. リリースビルドの実行
```bash
# プロジェクトルートで実行
flutter build appbundle --release
```

## バックアップ方法

1. `release-key-new.jks`ファイルを安全な場所にコピー
2. パスワード情報を安全に保管
3. 複数の場所にバックアップを保存

## トラブルシューティング

### パスワードが間違っている場合
キーストアのパスワードを確認：
```bash
keytool -list -v -keystore release-key.jks
```

### 新しいキーストアを作成する場合
既存のキーストアを削除してから再生成：
```bash
keytool -genkeypair -v -keystore release-key.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass maikago2025 -keypass maikago2025 -dname "CN=ikeda, OU=IK, O=IKcoding, L=japan, ST=saitama, C=JP"
```

## Google Play Console アップロード鍵リセット

### 証明書のエクスポート
Google Play Consoleでアップロード鍵をリセットする場合、以下のコマンドで証明書をエクスポート：

```bash
keytool -export -rfc -keystore android/app/release-key.jks -alias upload -file android/app/upload_certificate.pem -storepass maikago2025
```

### リセット手順
1. Google Play Consoleにログイン
2. アプリを選択
3. 「セットアップ」→「アプリの整合性」→「アップロード鍵」を選択
4. 「アップロード鍵をリセット」をクリック
5. リセット理由を選択
6. 上記コマンドで生成した`upload_certificate.pem`ファイルをアップロード
7. 承認を待つ（通常24-48時間）

## セキュリティ注意事項

- 本番環境では、パスワードを環境変数または安全な設定ファイルで管理
- キーストアファイルは絶対にGitにコミットしない
- 定期的にバックアップを更新