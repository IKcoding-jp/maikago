# 設計書

## 実装方針

### 新規作成ファイル
- `lib/providers/theme_provider.dart` - テーマ状態管理Provider

### 変更対象ファイル
- `lib/main.dart` - グローバル変数削除、Provider追加、ValueListenableBuilder→Consumer変更
- `lib/drawer/settings/settings_theme.dart` - テーマ変更時の呼び出し元変更
- `lib/drawer/settings/settings_font.dart` - フォント変更時の呼び出し元変更
- その他`currentGlobalTheme`等を参照する全ファイル

### ThemeProvider設計

```dart
class ThemeProvider extends ChangeNotifier {
  String _selectedTheme = 'pink';
  String _selectedFont = 'nunito';
  double _fontSize = 16.0;
  ThemeData _themeData;

  // Getters
  String get selectedTheme => _selectedTheme;
  String get selectedFont => _selectedFont;
  double get fontSize => _fontSize;
  ThemeData get themeData => _themeData;

  // 初期化（SettingsPersistenceからロード）
  Future<void> initFromPersistence() async { ... }

  // 更新メソッド（notify + persist）
  void updateTheme(String theme) { ... }
  void updateFont(String font) { ... }
  void updateFontSize(double size) { ... }
}
```

### main.dartの変更
- `MultiProvider`に`ChangeNotifierProvider(create: (_) => ThemeProvider())`追加
- `ValueListenableBuilder<ThemeData>`を`Consumer<ThemeProvider>`に置換
- `runApp`前に`ThemeProvider().initFromPersistence()`を呼び出し

## 影響範囲
- テーマ/フォントを参照する全画面（`context.read<ThemeProvider>()`経由に変更）
- `SettingsTheme`, `SettingsFont`画面

## Flutter固有の注意点
- Provider依存関係: ThemeProviderは他のProviderに依存しない（独立）
- `MaterialApp`の`theme`プロパティに`ThemeProvider.themeData`を渡す
- `google_fonts`パッケージとの連携を維持
