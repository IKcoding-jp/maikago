## まいカゴ AIコーディング運用ガイド (CLAUDE.md)

本ドキュメントは、AI（Claude / ChatGPT など）を活用したペアプログラミング/ライブコーディングで「まいカゴ」アプリを継続開発するための運用ガイドです。開発時の前提・流れ・品質基準・依頼テンプレートをまとめています。

### 目的

- **開発速度の最大化**: 小さな改善を高速に回す
- **品質の担保**: 破壊的変更やセキュリティ事故の予防
- **知識の集約**: 決定と背景をドキュメント化

### 前提（技術スタック）

- Flutter (Dart sdk: `^3.8.1`)
- 状態管理: `provider`
- 認証: `firebase_auth` + `google_sign_in`
- データ: `cloud_firestore`
- 広告: `google_mobile_ads`
- 課金: `in_app_purchase`
- 追加ツール: `shared_preferences`, `url_launcher`, `package_info_plus`, `http`
- Lint: `flutter_lints`（`analysis_options.yaml` 参照）

### 作業の進め方（AIとのループ）

1) 目的の確認と前提の明文化（要件・影響範囲・UI/UX）
2) コードベースの調査（関連ファイルの読解・影響箇所の洗い出し）
3) 提案（方針・代替案・リスク・スコープ）
4) 実装（小さく安全に、差分を明確に。不要なフォーマット変更を避ける）
5) 検証（`flutter analyze` / 実機/エミュレータでの動作確認）
6) 要約（変更点・影響・次アクション）

### コーディング規約（要点）

- 変数・関数名は**意味のある英語**で記述（省略形は避ける）
- 早期リターンでネストを浅く、エラーと境界条件を先に処理
- コメントは「なぜ」を短く。自明な説明は不要
- `flutter_lints` に準拠。`flutter analyze` で警告ゼロを維持
- テストがある場合は追加・更新を優先
- 破壊的変更を避け、既存 API は互換を保つ（必要なら段階的移行）

### Flutter/Dart の方針

- Null安全を徹底。`late`/`!` は最小化。
- 非同期は `async`/`await` を基本に、UI スレッドをブロックしない。
- 例外は握りつぶさず、ユーザー向けに必要十分なエラーハンドリング（トースト/ダイアログ）を用意。
- Firestore の読み書きは Provider 経由のサービス層（`services/` → `providers/` → `widgets/` の順で依存）。

### ディレクトリと責務（抜粋）

- `models/`: ドメインモデル（`item.dart`, `shop.dart`, `sort_mode.dart`）
- `services/`: 外部サービス境界（`auth_service.dart`, `data_service.dart`, `donation_manager.dart` など）
- `providers/`: アプリ状態（`auth_provider.dart`, `data_provider.dart`）
- `screens/`: 画面 UI（`login_screen.dart`, `main_screen.dart`, `splash_screen.dart`）
- `widgets/`: 再利用可能 UI（`item_row.dart`, `welcome_dialog.dart`）
- `ad/`: 広告関連（`interstitial_ad_service.dart` など）

### ビルド/実行/検証コマンド（Windows PowerShell）

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
# リリースビルド（一例）
flutter build apk --release
```

### Firebase/広告/課金の注意

- `android/app/google-services.json` は秘匿。公開禁止。
- Firestore ルールは `firestore.rules` に準拠。ユーザー ID でスコープ。
- 広告はテストデバイス設定で検証。本番配信前にポリシーチェック。
- 課金はストアのサンドボックスで検証。`donation_manager` の復元動作を必ず確認。

### セキュリティと秘密情報

- API キーやサービスアカウントはリポジトリに置かない。
- `.env` 相当はビルド時注入を検討（Flutter 用の代替戦略を採用）。
- デバッグログに個人情報を出力しない。

### コミット/PR ルール

- 1 変更 1 コミットを基本に、小さく意味のある粒度で。
- コミットメッセージは Conventional Commits を推奨：
  - `feat: ～` 機能追加
  - `fix: ～` バグ修正
  - `refactor: ～` 挙動不変の整理
  - `docs: ～` ドキュメント変更
  - `chore: ～` 付帯作業
- PR では下記を記載：目的、変更点、スクショ（UI 変更時）、検証手順、影響範囲、リスク/ロールバック方法

### 依頼（プロンプト）テンプレート

- バグ修正:
  - 現象: 何をしたらどうなったか
  - 期待: 本来どうあるべきか
  - ログ/スクショ: あれば添付
  - 影響: 端末/OS/環境

- 機能追加:
  - 目的/ユーザーストーリー
  - 画面/UI 変更（モック可）
  - データ構造・Firestore 変更の有無
  - 受付/完了条件（Definition of Done）

- リファクタ/パフォーマンス改善:
  - 痛点/ボトルネック
  - 対象ファイル/関数
  - 計測方法（前後での差分指標）

- ドキュメント/設計:
  - 問題設定
  - 代替案と選定理由（トレードオフ）

### レビュー観点チェックリスト

- 仕様どおり／UI 崩れなし／アクセシビリティ配慮
- 例外・エラー処理が十分でユーザー影響が最小
- 非同期処理でメモリリーク/重複リスナーがない
- Firestore/課金/広告の利用規約・ルールに合致
- `flutter analyze` に問題なし、不要 import/print なし
- ログは本番想定で適切なレベル

### よく使うコマンド（補足）

```powershell
flutter pub outdated
flutter pub upgrade --major-versions
flutter clean; flutter pub get
```

### 連絡事項（運用）

- コミュニケーションは日本語。コード/識別子は英語。
- 方針不明な点は AI 側から前提確認→提案→実装の順で進める。
- 重要な決定は本ファイル or `README.md` に反映。

以上。AI を活用して、安全かつ素早く「まいカゴ」を育てていきましょう。


