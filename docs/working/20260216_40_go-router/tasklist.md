# タスクリスト: ナビゲーション管理の導入（go_router）

**ステータス**: 実装完了
**Issue**: #40

## Phase 1: 基盤構築

- [x] 1.1 `go_router` パッケージを追加（`flutter pub add go_router`）
- [x] 1.2 `lib/router.dart` を作成し、全ルートを定義
- [x] 1.3 認証リダイレクトロジックを実装（AuthProvider連携）
- [x] 1.4 `lib/main.dart` を `MaterialApp.router` に変更
- [x] 1.5 `SplashWrapper` / `AuthWrapper` を go_router redirect に統合

## Phase 2: 画面遷移の移行

- [x] 2.1 `main_drawer.dart` の7箇所を `context.push()` に変更
- [x] 2.2 `settings_screen.dart` の7箇所を `context.push()` に変更
- [x] 2.3 `bottom_summary_widget.dart` のカメラ遷移を変更
- [x] 2.4 `settings_font.dart` の SubscriptionScreen 遷移を変更
- [x] 2.5 `startup_helpers.dart` の ReleaseHistoryScreen 遷移を変更
- [x] 2.6 `recipe_import_bottom_sheet.dart` の遷移を変更
- [x] 2.7 `upgrade_promotion_widget.dart` の遷移を変更
- [x] 2.8 `settings_theme.dart` の SubscriptionScreen 遷移を変更

## Phase 3: 戻り値・ポップ処理の移行

- [x] 3.1 ダイアログ内の `Navigator.pop()` / `Navigator.of(context).pop()` はそのまま維持（ダイアログはgo_router管轄外）
- [x] 3.2 カメラフローの戻り値ハンドリングを `context.pop()` に移行
- [x] 3.3 画面レベルのpopはgo_routerのAppBar自動戻りボタンで対応

## Phase 4: 検証

- [x] 4.1 `flutter analyze` でLintエラーなし確認
- [x] 4.2 `flutter test` で全テスト(180件)通過確認
- [x] 4.3 不要になったインポート・コードの削除
