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



### 👨‍👩‍👧‍👦 家族共有機能
- 家族や友達とのリスト共有
- リアルタイム共有機能
- 複数のタブやリストを同時に共有
- QRコードによる簡単な家族招待
- 送信・受信履歴の管理

### 💳 サブスクリプションシステム
- **フリープラン**: 基本的な機能を無料で利用（リスト10個、タブ3個まで）
- **ベーシックプラン**: 広告非表示、リスト50個、タブ12個まで（月額240円/年額2,160円）
- **プレミアムプラン**: 無制限利用、テーマ・フォントカスタマイズ（月額480円/年額4,320円）
- **ファミリープラン**: プレミアム機能 + 家族共有（月額720円/年額6,480円）

### ☁️ クラウド同期
- Googleアカウントでのログイン
- Firebase Firestoreによるデータ永続化
- 複数デバイス間でのデータ同期
- リアルタイムデータ更新

### 💝 寄付機能
- 開発者を応援するための任意の寄付
- 300円から10,000円までの選択肢
- Google Play課金システムによる安全な決済
- 開発者からの感謝メッセージ

### 🎨 カスタマイズ機能
- テーマカスタマイズ（プレミアムプラン）
- フォントカスタマイズ（プレミアムプラン）
- パステルカラーの統一感
- Chrome風のタブ管理
- 詳細設定によるカスタマイズ機能

## 🛠️ 技術スタック

- **フレームワーク**: Flutter 3.8.1+
- **認証**: Firebase Authentication + Google Sign-In
- **データベース**: Cloud Firestore
- **状態管理**: Provider
- **音声認識**: speech_to_text
- **QRコード**: qr_flutter, mobile_scanner
- **アプリ内購入**: in_app_purchase
- **広告**: google_mobile_ads
- **プラットフォーム**: Android, iOS, Web

## 📋 セットアップ方法

### 前提条件
- Flutter SDK (3.8.1以上)
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
2. Android設定: `google-services.json`を`android/app/`に配置
3. iOS設定: `GoogleService-Info.plist`を`ios/Runner/`に配置
   - Firebase Console → プロジェクト設定 → iOS アプリ → `GoogleService-Info.plist`をダウンロード
   - または、テンプレートファイル`ios/Runner/GoogleService-Info.plist.template`を参考に作成
4. Firestoreデータベースを作成
5. セキュリティルールを設定（`firestore.rules`を参照）

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

### 🔒 セキュリティ監査機能

アプリには**セキュリティ監査機能**が組み込まれており、以下の項目を自動監視します：

- **APIキーの設定状況**
- **API使用回数の追跡**
- **セキュリティリスクの検出**
- **環境別の設定確認**

#### セキュリティ監査の確認方法
1. アプリ内でデバッグパネルを開く（デバッグモード時のみ）
2. 「セキュリティ監査」セクションで現在の状況を確認
3. 検出されたリスクがあれば推奨対応を実施

#### 監視されるリスク
- **Critical**: 本番環境でのAPIキー未設定
- **Warning**: 開発環境でのAPIキー露出、異常なAPI使用量
- **Info**: 一般的なセキュリティ情報

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

    // ファミリー共有機能
    match /families/{familyId} {
      allow read, write: if request.auth != null && 
        resource.data.members[request.auth.uid] != null;
    }

    // 送信型共有機能
    match /transmissions/{transmissionId} {
      allow create: if request.auth != null && 
        request.resource.data.sharedBy == request.auth.uid;
      allow read, write: if request.auth != null && (
        resource.data.sharedBy == request.auth.uid ||
        request.auth.uid in resource.data.sharedWith
      );
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
├── ad/                          # 広告関連
│   ├── ad_banner.dart
│   └── interstitial_ad_service.dart
├── config/                      # 設定関連
│   └── config.dart
├── drawer/                      # ドロワーメニュー関連
│   ├── about_screen.dart
│   ├── calculator_screen.dart
│   ├── donation_screen.dart
│   ├── feedback_screen.dart
│   ├── settings/               # 設定画面
│   │   ├── account_screen.dart
│   │   ├── advanced_settings_screen.dart
│   │   ├── excluded_words_screen.dart
│   │   ├── privacy_policy_screen.dart
│   │   ├── settings_font.dart
│   │   ├── settings_persistence.dart
│   │   ├── settings_screen.dart
│   │   ├── settings_theme.dart
│   │   └── terms_of_service_screen.dart
│   ├── upcoming_features_screen.dart
│   └── usage_screen.dart
├── l10n/                       # 国際化
│   ├── app_en.arb
│   ├── app_ja.arb
│   ├── app_localizations_en.dart
│   ├── app_localizations_ja.dart
│   ├── app_localizations.dart
│   └── app.pot
├── models/                     # データモデル
│   ├── family_member.dart
│   ├── item.dart
│   ├── shared_content.dart
│   ├── shop.dart
│   ├── sort_mode.dart
│   ├── subscription_plan.dart
│   └── sync_data.dart
├── providers/                  # 状態管理
│   ├── auth_provider.dart
│   ├── data_provider.dart
│   └── transmission_provider.dart
├── screens/                    # 画面
│   ├── family_sharing_screen.dart
│   ├── login_screen.dart
│   ├── main_screen.dart
│   ├── splash_screen.dart
│   ├── store_preparation_screen.dart
│   └── subscription_screen.dart
├── services/                   # サービス
│   ├── app_info_service.dart
│   ├── auth_service.dart
│   ├── data_service.dart
│   ├── debug_service.dart
│   ├── feature_access_control.dart
│   ├── realtime_sharing_service.dart
│   ├── store_preparation_service.dart
│   ├── subscription_integration_service.dart
│   ├── subscription_service.dart
│   ├── transmission_service.dart
│   └── voice_parser.dart
├── widgets/                    # ウィジェット
│   ├── debug_info_widget.dart
│   ├── family_member_list_widget.dart
│   ├── feature_limit_widget.dart
│   ├── item_row.dart
│   ├── realtime_notification_widget.dart
│   ├── share_content_dialog.dart
│   ├── store_checklist_widget.dart
│   ├── store_export_widget.dart
│   ├── store_status_widget.dart
│   ├── subscription_activation_widget.dart
│   ├── upgrade_promotion_widget.dart
│   ├── voice_input_button.dart
│   └── welcome_dialog.dart
└── main.dart                   # エントリーポイント
```

## 🚀 リリース履歴

### v0.8.0 (2025-8-24) - カメラで商品を撮影して自動追加！
- ✅ **📸 カメラ機能が新登場**
  - 商品の値札を撮影するだけで買い物リストに自動追加
  - ズーム機能で商品の文字をくっきり撮影
  - スマートフォンに最適化された縦画面撮影
- ✅ **🤖 AIが商品情報を自動認識**
  - 商品名と価格を自動で読み取り
  - 税込価格を優先して正確に認識
  - 複雑な価格表示（カンマ区切りなど）も自動解析
  - 日本語の商品名をきれいに整形
- ✅ **⚡ 撮影から追加までワンタッチ**
  - カメラボタンを押して商品を撮影
  - AIが自動で商品名と価格を認識
  - すぐに買い物リストに追加完了

### v0.7.1 (2024-12-XX)
- ✅ 音声入力機能の改善
- ✅ ファミリー共有機能の安定性向上
- ✅ サブスクリプションシステムの最適化
- ✅ 全体的なパフォーマンス向上

### v0.7.0 (2024-12-XX) - 大型アップデート
- ✅ サブスクリプションシステムの導入（寄付特典から変更）
- ✅ ファミリー共有機能の実装
- ✅ 音声入力機能の追加
- ✅ 詳細設定画面の改善
- ✅ UI/UXの大幅改善

### v0.4.7 (2024-12-XX)
- ✅ 新しい並び替えオプション（追加が新しい順・古い順）
- ✅ 購入済み商品の取り消し線設定
- ✅ 割引商品の表示改善
- ✅ テーマ・フォント選択機能の改善
- ✅ タブ追加順序の変更（Chrome風）
- ✅ 各種バグ修正と安定性向上

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

## 💝 寄付機能の設定手順

### Google Play Consoleでの課金アイテム設定

1. **Google Play Consoleにアクセス**
   - [Google Play Console](https://play.google.com/console/)にログイン

2. **課金アイテムを作成**
   - 左メニューから「収益化」→「製品」→「アプリ内課金」を選択
   - 「課金アイテムを作成」をクリック

3. **プロダクトIDと価格を設定**
   以下のプロダクトIDで課金アイテムを作成してください：

   | プロダクトID | 価格（日本円） | 説明 |
   |-------------|---------------|------|
   | `donation_300` | 300円 | 300円の寄付 |
   | `donation_500` | 500円 | 500円の寄付 |
   | `donation_1000` | 1,000円 | 1,000円の寄付 |
   | `donation_2000` | 2,000円 | 2,000円の寄付 |
   | `donation_5000` | 5,000円 | 5,000円の寄付 |
   | `donation_10000` | 10,000円 | 10,000円の寄付 |

4. **課金アイテムの詳細設定**
   - 名前: 「開発者応援寄付 - [金額]円」
   - 説明: 「まいカゴ開発者を応援するための寄付です」
   - 価格: 各金額に対応する価格を設定
   - ステータス: アクティブ

5. **アプリの公開**
   - 課金アイテムを有効にするにはアプリの公開が必要です

### 注意事項

- 課金アイテムが設定されていない場合、アプリでは「商品が見つかりません」というメッセージが表示されます
- テスト環境ではGoogle Playのテスト用課金システムが使用されます
- 本番環境では実際の課金が発生します
