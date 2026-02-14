# タスクリスト

## フェーズ1: ThemeProvider作成
- [ ] `lib/providers/theme_provider.dart`を新規作成
- [ ] `selectedTheme`, `selectedFont`, `fontSize`プロパティ定義
- [ ] `ValueNotifier<ThemeData>`を内部管理
- [ ] `updateTheme()`, `updateFont()`, `updateFontSize()`メソッド実装
- [ ] `SettingsPersistence`との連携（load/save）
- [ ] 初期化ロジック（`initFromPersistence()`）

## フェーズ2: main.dart統合
- [ ] MultiProviderに`ThemeProvider`を追加
- [ ] グローバル変数（`currentGlobalFont`等）を削除
- [ ] グローバル関数（`updateGlobalTheme`等）を削除
- [ ] `late final`の例外キャッチパターンをProvider初期化に置換
- [ ] `safeThemeNotifier`を`ThemeProvider`経由に変更
- [ ] `ValueListenableBuilder`を`Consumer<ThemeProvider>`に変更

## フェーズ3: 参照箇所の更新
- [ ] `lib/drawer/settings/settings_theme.dart`の参照変更
- [ ] `lib/drawer/settings/settings_font.dart`の参照変更
- [ ] その他テーマ/フォントを参照する画面の更新（Grepで`currentGlobal`を検索）

## フェーズ4: 動作確認
- [ ] テーマ変更が即時反映されることを確認
- [ ] フォント変更が即時反映されることを確認
- [ ] アプリ再起動後に設定が復元されることを確認
- [ ] `flutter analyze`でエラーがないことを確認

## 依存関係
- フェーズ1 → フェーズ2 → フェーズ3 → フェーズ4（順次実行）
