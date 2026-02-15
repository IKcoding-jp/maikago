# タスクリスト: #36 build()内副作用除去 + #37 エラーハンドリング統一

**ステータス**: 未着手
**作成日**: 2026-02-15

## Phase 1: #37 エラーハンドリング基盤（先に実施）

エラーハンドリングの基盤を先に整備することで、#36の修正時にも統一パターンを適用できる。

- [ ] 1.1 カスタム例外クラスを作成 (`lib/utils/exceptions.dart`)
  - AppException, NotFoundError, PermissionDeniedError, NetworkError
  - Firebase例外変換ヘルパー関数
- [ ] 1.2 `settings_persistence.dart` の空catchブロック修正
  - 全メソッドにDebugService.log()追加
  - save系メソッドの一貫性確保
- [ ] 1.3 `auth_provider.dart` のStreamSubscription管理追加
  - `_authStateSubscription`フィールド追加
  - dispose()でcancel()
- [ ] 1.4 `auth_provider.dart` の5重ネストtry-catch整理
  - 初期化ロジックを個別メソッドに分割
- [ ] 1.5 Service/Repository層の文字列ベースエラー判定をカスタム例外に変換
  - `item_repository.dart` (6箇所)
  - `shop_repository.dart` (2箇所)
  - `data_service.dart` (4箇所)
  - `item_service.dart` (2箇所)
  - `shop_service.dart` (2箇所)

## Phase 2: #36 パフォーマンス改善

- [ ] 2.1 `main_screen.dart`: build()内のgetCustomTheme()をキャッシュ化
  - build()先頭で1回取得 → 変数で参照
  - computeLuminance()もキャッシュ
- [ ] 2.2 `main_screen.dart`: updateThemeAndFontIfNeeded()をbuild()外に移動
- [ ] 2.3 `main_screen.dart`: TabController再生成ロジックをbuild()外に移動
- [ ] 2.4 `list_edit.dart`: SharedPreferences個別読み込み廃止
  - 取り消し線設定をパラメータとして受け取る方式に変更
  - 呼び出し元での設定値提供
- [ ] 2.5 `ad_banner.dart` + `one_time_purchase_service.dart`: busy-wait → Completer

## Phase 3: テスト・検証

- [ ] 3.1 既存テストの確認・修正（変更による影響）
- [ ] 3.2 `flutter analyze` 通過
- [ ] 3.3 `flutter test` 全件通過
