# まいカゴ (Maikago)

## 📱 アプリ概要

「まいカゴ」は、主婦向けの買い物リスト管理アプリです。商品ごとに個数、単価、割引率を入力し、合計金額を自動計算することで、お買い物をもっと便利にします。

## ✨ 主な機能

### 🛒 買い物リスト管理
- 商品の個数、単価、割引率を入力
- 合計金額の自動計算
- 複数のショップリスト管理
- 予算設定とオーバー警告
- 購入済み商品の取り消し線表示設定
- 割引商品の視覚的表示（元価格に取り消し線、割引価格を赤色）
- 柔軟な並び替えオプション（追加順、価格順、名前順）

### ☁️ クラウド同期
- Googleアカウントでのログイン
- Firebase Firestoreによるデータ永続化
- 複数デバイス間でのデータ同期
- リアルタイムデータ更新

### 💝 寄付・サポート機能
- アプリの開発をサポートする寄付機能
- 寄付者限定のテーマ・フォント
- 寄付特典の復元機能
- アカウント管理と寄付状態の同期

### 🎨 ユーザーフレンドリーなUI
- おしゃれで可愛いデザイン
- パステルカラーの統一感
- 直感的な操作性
- レスポンシブデザイン
- カスタマイズ可能なテーマ・フォント
- Chrome風のタブ管理
- 詳細設定によるカスタマイズ機能

## 🛠️ 技術スタック

- **フレームワーク**: Flutter
- **認証**: Firebase Authentication + Google Sign-In
- **データベース**: Cloud Firestore
- **状態管理**: Provider
- **プラットフォーム**: Android, iOS, Web

## 📋 セットアップ方法

### 前提条件
- Flutter SDK (最新版)
- Android Studio / VS Code
- Firebase プロジェクト
- Google Cloud Console の設定

### 1. リポジトリのクローン
```bash
git clone https://github.com/IKcoding-jp/maikago.git
cd maikago
```

### 2. 依存関係のインストール
```bash
flutter pub get
```

### 3. Firebase設定
1. Firebase Consoleでプロジェクトを作成
2. `google-services.json`を`android/app/`に配置
3. Firestoreデータベースを作成
4. セキュリティルールを設定（`firestore.rules`を参照）

### 3.1 環境変数（dart-define）
広告ユニットIDなどの秘匿値はリポジトリにハードコードしません。ビルド時に注入してください。

```bash
flutter run --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-xxx/yyy \
           --dart-define=ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-xxx/zzz \
           --dart-define=MAIKAGO_ALLOW_CLIENT_DONATION_WRITE=false
```

本番ビルド例（Windows PowerShell）:

```powershell
flutter build apk --release `
  --dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-xxx/yyy `
  --dart-define=ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-xxx/zzz `
  --dart-define=MAIKAGO_ALLOW_CLIENT_DONATION_WRITE=false
```

### 4. Google Sign-In設定
1. Google Cloud ConsoleでOAuth 2.0クライアントIDを設定
2. `android/app/build.gradle.kts`の設定を確認

### 5. アプリの実行
```bash
flutter run
```

## セキュリティ設定

### 環境変数による設定

本アプリケーションは、セキュリティを重視した設計となっており、機密情報は環境変数で管理します。

#### 必須設定
- `ADMOB_INTERSTITIAL_AD_UNIT_ID`: AdMobインタースティシャル広告ID
- `ADMOB_BANNER_AD_UNIT_ID`: AdMobバナー広告ID

#### セキュリティ設定
- `MAIKAGO_ALLOW_CLIENT_DONATION_WRITE`: クライアントからの寄付データ書き込み許可（本番環境では`false`）
- `MAIKAGO_SPECIAL_DONOR_EMAIL`: 特別寄付者のメールアドレス（本番環境では空文字列）
- `MAIKAGO_ENABLE_DEBUG_MODE`: デバッグモード有効化（本番環境では`false`）
- `MAIKAGO_SECURITY_LEVEL`: セキュリティレベル（`strict`/`normal`/`relaxed`）

#### 本番環境での推奨設定
```bash
MAIKAGO_ALLOW_CLIENT_DONATION_WRITE=false
MAIKAGO_SPECIAL_DONOR_EMAIL=""
MAIKAGO_ENABLE_DEBUG_MODE=false
MAIKAGO_SECURITY_LEVEL=strict
```

### セキュリティ機能

1. **Firestoreセキュリティルール**: ユーザー固有のデータアクセス制御
2. **PII保護**: メールアドレス等の個人情報のログ出力制限
3. **匿名セッション制限**: クライアントからの匿名データアクセス禁止
4. **寄付データ保護**: クライアントからの寄付状態書き込み制限
5. **環境別設定**: 開発・本番環境での異なるセキュリティレベル

## Firestoreセキュリティルール

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId; // 自分のデータのみ
      
      match /items/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId; // 自分のアイテムのみ
      }
      
      match /shops/{shopId} {
        allow read, write: if request.auth != null && request.auth.uid == userId; // 自分のショップのみ
      }

      match /donations/{donationId} {
        allow read: if request.auth != null && request.auth.uid == userId; // 読み取りのみ
        allow write: if false; // クライアント書き込み禁止（Functions等でのみ）
      }
    }

    // 匿名コレクションはクライアントから禁止
    match /anonymous/{sessionId} {
      allow read, write: if false;
      match /items/{itemId} { allow read, write: if false; }
      match /shops/{shopId} { allow read, write: if false; }
    }

    match /{document=**} { allow read, write: if false; }
  }
}
```

## 📁 プロジェクト構造

```
lib/
├── constants/
│   └── colors.dart          # アプリカラー定義
├── models/
│   ├── item.dart           # 商品モデル
│   ├── shop.dart           # ショップモデル
│   └── sort_mode.dart      # ソートモード
├── providers/
│   ├── auth_provider.dart  # 認証状態管理
│   └── data_provider.dart  # データ状態管理
├── screens/
│   ├── about_screen.dart   # アプリについて
│   ├── account_screen.dart # アカウント管理
│   ├── login_screen.dart   # ログイン画面
│   ├── main_screen.dart    # メイン画面
│   └── settings_screen.dart # 設定画面
├── services/
│   ├── auth_service.dart   # 認証サービス
│   └── data_service.dart   # データサービス
├── widgets/
│   ├── bottom_summary.dart # 合計表示
│   └── item_row.dart       # 商品行
└── main.dart               # エントリーポイント
```

## 🚀 リリース履歴

### v0.4.4 (2024-12-19)
- ✅ 新しい並び替えオプション（追加が新しい順・古い順）
- ✅ 購入済み商品の取り消し線設定
- ✅ 割引商品の表示改善
- ✅ テーマ・フォント選択機能の改善
- ✅ タブ追加順序の変更（Chrome風）
- ✅ 各種バグ修正と安定性向上
- ✅ 寄付機能の完全実装

### v0.4.3 (2024-12-18)
- ✅ 寄付機能の実装
- ✅ テーマ・フォント選択機能
- ✅ アカウント管理機能

### v0.4.2 (2024-12-17)
- ✅ Firebase認証機能
- ✅ データ同期機能

### v0.4.1 (2024-12-16)
- ✅ 基本的な買い物リスト機能
- ✅ 商品の追加・削除・編集機能

### v0.4.0 (2024-12-15)
- ✅ プロジェクトの初期設定
- ✅ 基本的なFlutterアプリ構造

## 👨‍💻 開発者

**開発者**: IK

### 開発者の思い
スーパーで買い物をしているとき、いつもメモに買いたいものを書いておいて、それを見ながら電卓で計算して...という行ったり来たりがめんどくさくて、自分が欲しかったからこのアプリを作りました。

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 🤝 コントリビューション

プルリクエストやイシューの報告を歓迎します！

## 📞 サポート

問題や質問がある場合は、GitHubのイシューを作成してください。
