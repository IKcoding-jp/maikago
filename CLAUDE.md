# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

日本語で返答してください。

## プロジェクト概要

**まいカゴ** — 買いすぎ防止のための買い物リスト管理アプリ（Flutter マルチプラットフォーム）。
バージョン: 1.3.1+54 / Dart SDK: >=3.0.0 <4.0.0

対応プラットフォーム: iOS, Android, Web, Windows

## よく使うコマンド

```bash
# 依存関係
flutter pub get

# 静的分析（Lint）
flutter analyze

# テスト
flutter test                          # 全テスト実行
flutter test test/path/to_test.dart   # 単一テスト実行

# ビルド
flutter build apk --debug            # Android APK
flutter build appbundle --debug       # Android App Bundle
flutter build ios --simulator --debug # iOSシミュレーター
flutter build web                     # Web
flutter build windows                 # Windows

# Firebase Cloud Functions（functions/ ディレクトリ）
cd functions && npm install           # 依存関係インストール
firebase deploy --only functions      # Functionsデプロイ

# Firestoreセキュリティルール
./deploy-rules.sh                     # ルールデプロイ

# アイコン生成
flutter pub run flutter_launcher_icons
```

## アーキテクチャ

### Flutter アプリ（`lib/`）

Provider パターンによる状態管理。画面 → Provider → Service → Firestore の層構造。

- **`main.dart`** — エントリーポイント。Firebase初期化、テーマ/フォントのグローバル状態管理、Provider設定（`MultiProvider`で`AuthProvider`, `DataProvider`, `OneTimePurchaseService`, `DonationService`, `FeatureAccessControl`, `DebugService`を注入）
- **`providers/`** — 状態管理層。`DataProvider`（ファサード）と`AuthProvider`
  - `data_provider.dart` — ファサード。外部インターフェースを維持し、各Repository/Managerに委譲
  - `repositories/item_repository.dart` — アイテムCRUD、楽観的更新、バウンス抑止
  - `repositories/shop_repository.dart` — ショップCRUD、デフォルトショップ管理
  - `managers/data_cache_manager.dart` — データ保持、キャッシュTTL管理、データロード
  - `managers/realtime_sync_manager.dart` — Firestore Stream購読、バッチ更新制御
  - `managers/shared_group_manager.dart` — 共有グループCRUD、合計・予算計算
- **`services/`** — ビジネスロジック層。認証、Firestore操作、OCR（Google Vision API）、ChatGPT連携、レシピ解析、課金、カメラ等
  - `ad/` — 広告管理（バナー、インタースティシャル、アプリオープン）
  - `settings_persistence.dart` — 設定永続化（SharedPreferences）
  - `settings_theme.dart` — テーマ設定・カラー定義・テーマ選択UI
- **`screens/`** — UI画面。`main_screen.dart`がメイン。`main/dialogs/`と`main/widgets/`にメイン画面のサブコンポーネント
  - `drawer/` — ドロワーメニュー内の画面群（設定、About、電卓、フィードバック等）。`settings/`にフォント・アカウント設定
- **`models/`** — データモデル（`list.dart`, `shop.dart`, `donation.dart`等）
- **`widgets/`** — 再利用可能なウィジェット
- **`utils/`** — ユーティリティ（レスポンシブ対応等）

### 環境変数

`env.json`（アセット）から読み込み。`lib/env.dart`の`Env`クラスで管理。`--dart-define`へのフォールバックあり。
主要キー: `GOOGLE_VISION_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_WEB_CLIENT_ID`, AdMob関連

### Firebase Cloud Functions（`functions/`）

Node.js 18。`index.js`にOCR・画像解析処理。Firebase Project ID: `maikago2`

## CI/CD

- **Codemagic**（`codemagic.yaml`）: iOS Simulator Test, Android Build, iOS Release（TestFlight配信）
- **GitHub Actions**（`.github/workflows/`）: Firebase Hosting デプロイ（mainマージ時＋PRプレビュー）

## コード規約

- Lint: `flutter_lints`（`analysis_options.yaml`）
- `use_build_context_synchronously`は`ignore`に設定済み
- Web対応コードでは`kIsWeb`で分岐。Web時の横幅は800pxに制限
- テーマは`SettingsTheme.generateTheme()`で生成。デフォルト: pink テーマ、nunito フォント、16.0 サイズ

## 注意事項

- `env.json`はアセットとして含まれるがAPIキーを含むためgit管理に注意
- `data_provider.dart`はファサードパターンで責務分割済み。変更時は適切なRepository/Managerを特定して修正すること
- マネタイズ機能（課金・広告）は`OneTimePurchaseService`と`FeatureAccessControl`で制御。プレミアム状態で広告非表示
