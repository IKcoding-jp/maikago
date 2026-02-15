# タスクリスト

**ステータス**: 完了
**完了日**: 2026-02-15

## フェーズ1: ThemeProvider作成
- [x] `lib/providers/theme_provider.dart`を新規作成
- [x] `selectedTheme`, `selectedFont`, `fontSize`プロパティ定義
- [x] `ThemeData`を内部管理（`_rebuildThemeData`で再構築）
- [x] `updateTheme()`, `updateFont()`, `updateFontSize()`メソッド実装
- [x] `SettingsPersistence`との連携（load/save）
- [x] 初期化ロジック（`initFromPersistence()`）

## フェーズ2: main.dart統合 + Singleton削除 + DI統一（#6, #31, #32統合）
- [x] MultiProviderに`ThemeProvider`を追加
- [x] グローバル変数（`currentGlobalFont`等）を削除
- [x] グローバル関数（`updateGlobalTheme`等）を削除
- [x] `late final`の例外キャッチパターンをProvider初期化に置換
- [x] `safeThemeNotifier`を`ThemeProvider`経由に変更
- [x] `ValueListenableBuilder`を`Consumer<ThemeProvider>`に変更
- [x] `OneTimePurchaseService`, `FeatureAccessControl`, `DonationService`のSingleton削除
- [x] `AuthProvider`のコンストラクタDI化
- [x] `AppOpenAdManager`, `InterstitialAdService`のDI化
- [x] `DebugService`はSingleton維持、MultiProviderからは削除

## フェーズ3: 参照箇所の更新
- [x] `lib/drawer/settings/settings_theme.dart`の参照変更
- [x] `lib/drawer/settings/settings_font.dart`の参照変更
- [x] `lib/screens/main_screen.dart`のテーマ/フォント参照変更
- [x] `lib/screens/main/widgets/bottom_summary_widget.dart`の参照変更
- [x] `lib/ad/ad_banner.dart`のProvider参照変更

## フェーズ4: テスト・検証
- [x] `test/providers/theme_provider_test.dart`作成（17テスト）
- [x] `flutter analyze`でエラーがないことを確認
- [x] `flutter test`で全87テスト通過
- [x] 手動動作確認OK
