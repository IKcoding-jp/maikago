# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

日本語で返答してください。

## プロジェクト概要

**まいカゴ** — 買いすぎ防止のための買い物リスト管理アプリ（Flutter マルチプラットフォーム）。
バージョンは `pubspec.yaml` の `version` フィールドを参照。Dart SDK: >=3.0.0 <4.0.0

対応プラットフォーム: iOS, Android, Web
テーマ: 14種（pink, light, dark, orange, green, blue, beige, mint, lavender, purple, teal, amber, indigo, soda, coral）

## よく使うコマンド

```bash
flutter pub get                       # 依存関係
flutter analyze                       # 静的分析
flutter test                          # 全テスト実行
flutter test test/path/to_test.dart   # 単一テスト実行
flutter build web                     # Web
flutter build windows                 # Windows
flutter build apk --debug            # Android APK

# Firebase Cloud Functions
cd functions && npm install && firebase deploy --only functions
```

## アーキテクチャ

### Flutter アプリ（`lib/`）

Provider パターンによる状態管理。画面 → Provider → Service → Firestore の層構造。

- **`main.dart`** — エントリーポイント。Firebase初期化、Provider設定（`MultiProvider`で`AuthProvider`, `DataProvider`, `OneTimePurchaseService`, `DonationService`, `FeatureAccessControl`, `DebugService`を注入）
- **`router.dart`** — ルート定義の一元管理（go_router）。認証リダイレクト。画面遷移は`context.push()`/`context.go()`
- **`providers/`** — 状態管理層
  - `data_provider.dart` — ファサード。各Repository/Managerに委譲（変更時は適切なサブモジュールを特定すること）
  - `repositories/` — アイテムCRUD（`item_repository.dart`）、ショップCRUD（`shop_repository.dart`）
  - `managers/` — キャッシュ管理、リアルタイム同期、共有グループ管理
- **`services/`** — ビジネスロジック層。認証、Firestore操作、OCR、ChatGPT連携、レシピ解析、課金、カメラ
  - `settings_theme.dart` — テーマ設定・カラー定義。`SettingsTheme.generateTheme()`でテーマ生成
- **`screens/`** — UI画面。`main_screen.dart`がメイン。`main/dialogs/`にダイアログ群
- **`widgets/`** — 再利用可能なウィジェット。`common_dialog.dart`が共通ダイアログ基盤
- **`utils/`** — ユーティリティ（`snackbar_utils.dart`, `input_formatters.dart`, `dialog_utils.dart`等）

### Firebase Cloud Functions（`functions/`）

Node.js 20 / Firebase Functions v2 API。`index.js`にOCR・画像解析。Firebase Project ID: `maikago2`

### 環境変数

`lib/env.dart`の`Env`クラスで管理。`--dart-define`（CI/CD用）を優先し、`env.json`にフォールバック。
`env.json`は廃止済み（`--dart-define`に移行）。ローカル開発用は`env.json.example`を参照。

## CI/CD

- **Codemagic**（`codemagic.yaml`）: iOS Simulator Test, Android Build, iOS Release（TestFlight配信）
- **GitHub Actions**（`.github/workflows/`）: Firebase Hosting デプロイ（mainマージ時＋PRプレビュー）

## コード規約

- Lint: `flutter_lints`（`analysis_options.yaml`）
- `use_build_context_synchronously`は有効（非同期処理後の`BuildContext`使用に注意）
- Web対応コードでは`kIsWeb`で分岐。Web時の横幅は800pxに制限

### 色の使用（重要）

**ハードコード色は原則禁止。** テーマ変数を使うこと:

| 用途 | 使うべき変数 | 禁止パターン |
|------|------------|------------|
| エラー/削除 | `colorScheme.error` | `Colors.red` |
| テキスト | `colorScheme.onSurface` | `Colors.black87`, `Colors.black54` |
| サブテキスト | `colorScheme.onSurface.withValues(alpha: 0.6)` | `Colors.white70` |
| 背景 | `theme.cardColor` or `colorScheme.surface` | `Colors.white`, `Colors.grey[800]` |
| 区切り線 | `theme.dividerColor` | `Colors.grey.shade300` |

- ダークモード分岐（`isDark ? X : Y`）はテーマ側で吸収する。色のために分岐を書かない
- 新画面追加時はライトモード＋ダークモードの両方で確認すること

### 共通コンポーネント（必須）

新規実装時は既存の共通コンポーネントを必ず使用すること:

- **ダイアログ** → `CommonDialog`（`lib/widgets/common_dialog.dart`）
  - 表示: `CommonDialog.show()` / ボタン: `.primaryButton` / `.cancelButton` / `.destructiveButton`
  - TextField: `.textFieldDecoration()` / ローディング: `.loading()`
  - デザイン定数: ダイアログ角丸20px、カード14px、TextField12px、ボタン20px
- **SnackBar** → `lib/utils/snackbar_utils.dart` 経由（`ScaffoldMessenger` 直接構築禁止）
  - `showErrorSnackBar`, `showSuccessSnackBar`, `showInfoSnackBar`, `showWarningSnackBar`
- **数値入力** → `lib/utils/input_formatters.dart` の `noLeadingZeroFormatter`
- **ダイアログ表示** → `lib/utils/dialog_utils.dart` の `showConstrainedDialog`（Web横幅制限付き）

### コード構造

- 1ファイル500行を超えたら責務分割を検討
- 同じロジックが2箇所以上で使われたら `lib/utils/` に共通化
- 標準的なUI機能（コーチマーク等）は既存パッケージの採用を第一に検討
- 機能廃止時はコード・テスト・ドキュメントを全て削除し、中途半端に残さない

### セキュリティ

- APIキーはクライアントコード（`lib/`）に含めない。Cloud Functions + Secret Manager で管理
- `debugPrint` にユーザーデータ、トークン、APIキーを含めない
- Firestoreルール変更時は最小権限の原則を確認（`request.auth != null` 必須）

### 非同期処理・状態管理

- Firestoreへの書き込みは楽観的更新パターン（UI即座クローズ → バックグラウンド書き込み）
- `context.pop()` 後の非同期処理では `mounted` チェック必須
- リアルタイム同期のStream購読中はバッチ更新でUI更新を抑制

## 注意事項

- マネタイズ機能（課金・広告）は`OneTimePurchaseService`と`FeatureAccessControl`で制御。プレミアム状態で広告非表示
- 過去の修正パターン分析は `docs/past-fix-analysis.md` を参照
