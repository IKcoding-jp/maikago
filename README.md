# まいカゴ (Maikago)

## 📱 アプリ概要

「まいカゴ」は、主婦向けの買い物リスト管理アプリです。商品ごとに個数、単価、割引率を入力し、合計金額を自動計算することで、お買い物をもっと便利にします。

## ✨ 主な機能

### 🛒 買い物リスト管理
- 商品の個数、単価、割引率を入力
- 合計金額の自動計算
- 複数のショップリスト管理
- 予算設定とオーバー警告

### ☁️ クラウド同期
- Googleアカウントでのログイン
- Firebase Firestoreによるデータ永続化
- 複数デバイス間でのデータ同期
- リアルタイムデータ更新

### 🎨 ユーザーフレンドリーなUI
- おしゃれで可愛いデザイン
- パステルカラーの統一感
- 直感的な操作性
- レスポンシブデザイン

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

### 4. Google Sign-In設定
1. Google Cloud ConsoleでOAuth 2.0クライアントIDを設定
2. `android/app/build.gradle.kts`の設定を確認

### 5. アプリの実行
```bash
flutter run
```

## 🔧 セキュリティ設定

### Firestore セキュリティルール
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /items/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /shops/{shopId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /{document=**} {
      allow read, write: if false;
    }
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

### v0.1.0 (2025-01-XX)
- ✅ Firebase統合完了
- ✅ Googleアカウントログイン機能
- ✅ クラウドデータ同期
- ✅ 買い物リスト管理機能
- ✅ 予算管理機能
- ✅ レスポンシブUI
- ✅ セキュリティ設定

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
