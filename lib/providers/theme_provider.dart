import 'package:flutter/material.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'package:maikago/drawer/settings/settings_theme.dart';

/// テーマ/フォント/フォントサイズの状態を一元管理するProvider
class ThemeProvider extends ChangeNotifier {
  String _selectedTheme = 'pink';
  String _selectedFont = 'nunito';
  double _fontSize = 16.0;
  ThemeData _themeData = SettingsTheme.generateTheme(
    selectedTheme: 'pink',
    selectedFont: 'nunito',
    fontSize: 16.0,
  );

  String get selectedTheme => _selectedTheme;
  String get selectedFont => _selectedFont;
  double get fontSize => _fontSize;
  ThemeData get themeData => _themeData;

  /// SettingsPersistenceから保存済み設定を読み込んで初期化
  Future<void> initFromPersistence() async {
    try {
      _selectedTheme = await SettingsPersistence.loadTheme();
      _selectedFont = await SettingsPersistence.loadFont();
      _fontSize = await SettingsPersistence.loadFontSize();
      _rebuildThemeData();
    } catch (_) {
      // デフォルト値のまま使用
    }
  }

  void updateTheme(String theme) {
    _selectedTheme = theme;
    _rebuildThemeData();
    SettingsPersistence.saveTheme(theme);
  }

  void updateFont(String font) {
    _selectedFont = font;
    _rebuildThemeData();
    SettingsPersistence.saveFont(font);
  }

  void updateFontSize(double size) {
    _fontSize = size;
    _rebuildThemeData();
    SettingsPersistence.saveFontSize(size);
  }

  void _rebuildThemeData() {
    _themeData = SettingsTheme.generateTheme(
      selectedTheme: _selectedTheme,
      selectedFont: _selectedFont,
      fontSize: _fontSize,
    );
    notifyListeners();
  }
}
