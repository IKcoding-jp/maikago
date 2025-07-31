# リリース署名キーストアについて

## 重要事項

**⚠️ このキーストアファイル（release-key.jks）は非常に重要です！**

- このファイルを紛失すると、Google Play Consoleにアプリを更新できなくなります
- バックアップを必ず取ってください
- バージョン管理システム（Git）には含めないでください

## 現在の設定

- **キーストアパスワード**: `maikago2024`
- **キーエイリアス**: `upload`
- **キーパスワード**: `maikago2024`
- **有効期限**: 10,000日（約27年）

## ファイル構成

- `release-key.jks` - リリース用の署名キーストア
- `key.properties` - キーストア設定ファイル（プロジェクトルート）
- `set-env.bat` - 環境変数設定スクリプト
- `build.gradle.kts` - ビルド設定（署名設定を含む）

## 使用方法

### 1. 環境変数の設定（オプション）
```bash
# Windows
call android\app\set-env.bat

# または手動で設定
set KEYSTORE_PASSWORD=maikago2024
set KEY_ALIAS=upload
set KEY_PASSWORD=maikago2024
```

### 2. リリースビルドの実行
```bash
# プロジェクトルートで実行
flutter build appbundle --release
```

## バックアップ方法

1. `release-key.jks`ファイルを安全な場所にコピー
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
keytool -genkeypair -v -keystore release-key.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass maikago2024 -keypass maikago2024 -dname "CN=ikeda, OU=IK, O=IKcoding, L=japan, ST=saitama, C=JP"
```

## セキュリティ注意事項

- 本番環境では、パスワードを環境変数または安全な設定ファイルで管理
- キーストアファイルは絶対にGitにコミットしない
- 定期的にバックアップを更新