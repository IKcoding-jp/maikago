# Shorebird設定ガイド

## 概要

ShorebirdはFlutterアプリのホットアップデート機能を提供するサービスです。アプリストアの審査を待たずに、バグ修正や軽微な変更を即座に配信できます。

## 設定手順

### 1. Shorebirdアカウントの作成

1. [Shorebird公式サイト](https://shorebird.dev/)にアクセス
2. GitHubアカウントでサインアップ
3. 新しいプロジェクトを作成

### 2. Shorebirdトークンの取得

1. Shorebirdダッシュボードにログイン
2. プロジェクト設定からAPIトークンを取得
3. トークンを安全に保管

### 3. Codemagicでの環境変数設定

Codemagicのプロジェクト設定で以下の環境変数を追加：

```
SHOREBIRD_TOKEN=your_shorebird_token_here
```

### 4. ローカル開発環境での設定

#### Shorebird CLIのインストール

```bash
# macOS/Linux
curl -s https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh | bash

# Windows (PowerShell)
iwr https://raw.githubusercontent.com/shorebirdtech/install/main/install.ps1 -useb | iex
```

#### プロジェクトの初期化

```bash
# プロジェクトディレクトリで実行
shorebird init
```

#### ログイン

```bash
shorebird login
```

## 使用方法

### ホットアップデートの配信

```bash
# パッチの作成と配信
shorebird patch android
shorebird patch ios
```

### リリースの作成

```bash
# 新しいリリースの作成
shorebird release android
shorebird release ios
```

## 設定ファイル

### shorebird.yaml

プロジェクトルートに`shorebird.yaml`ファイルが作成されます：

```yaml
# Shorebird設定ファイル
project_id: "maikago"
app_id: "com.ikcoding.maikago"

platforms:
  - android
  - ios

build:
  android:
    flavor: "release"
    build_type: "release"
  
  ios:
    flavor: "release"
    build_type: "release"

deploy:
  auto_deploy: false
  run_tests: true
```

## セキュリティ

### トークンの管理

- **絶対に**リポジトリにトークンをコミットしない
- 環境変数またはシークレット管理システムで管理
- 定期的にトークンをローテーション

### 制限事項

- ネイティブコードの変更はホットアップデート不可
- アプリの署名やパッケージ名の変更は不可
- 大幅なUI変更は推奨されない

## トラブルシューティング

### よくある問題

1. **トークンが無効**
   - Shorebirdダッシュボードでトークンを再生成
   - 環境変数を再設定

2. **CLIが見つからない**
   - PATHの設定を確認
   - 再インストールを実行

3. **パッチの適用に失敗**
   - アプリのバージョンを確認
   - 互換性のあるパッチかチェック

## 参考リンク

- [Shorebird公式ドキュメント](https://docs.shorebird.dev/)
- [Shorebird GitHub](https://github.com/shorebirdtech/shorebird)
- [Codemagic Shorebird統合](https://docs.codemagic.io/yaml-publishing/shorebird/)
