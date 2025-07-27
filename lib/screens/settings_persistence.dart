import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 設定の保存・読み込み機能を管理するクラス
/// SharedPreferencesを使用してテーマ、フォント、フォントサイズ、カスタムテーマを永続化
class SettingsPersistence {
  static const String _themeKey = 'selected_theme';
  static const String _fontKey = 'selected_font';
  static const String _fontSizeKey = 'selected_font_size';
  static const String _customThemesKey = 'custom_themes';

  /// テーマを保存
  static Future<void> saveTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// フォントを保存
  static Future<void> saveFont(String font) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontKey, font);
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// フォントサイズを保存
  static Future<void> saveFontSize(double fontSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, fontSize);
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// カスタムテーマを保存
  static Future<void> saveCustomTheme(Map<String, Color> detailedColors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customThemesJson = prefs.getString(_customThemesKey);
      Map<String, Map<String, dynamic>> customThemes = {};

      if (customThemesJson != null) {
        customThemes = Map<String, Map<String, dynamic>>.from(
          json.decode(customThemesJson),
        );
      }

      final themeName = 'カスタム${customThemes.length + 1}';
      customThemes[themeName] = detailedColors.map(
        (k, v) => MapEntry(
          k,
          (((v.a.toInt()) << 24) |
              (v.r.toInt() << 16) |
              (v.g.toInt() << 8) |
              v.b.toInt()),
        ),
      );

      await prefs.setString(_customThemesKey, json.encode(customThemes));
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// テーマを読み込み
  static Future<String> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey) ?? 'pink';
    } catch (e) {
      return 'pink';
    }
  }

  /// フォントを読み込み
  static Future<String> loadFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fontKey) ?? 'nunito';
    } catch (e) {
      return 'nunito';
    }
  }

  /// フォントサイズを読み込み
  static Future<double> loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_fontSizeKey) ?? 16.0;
    } catch (e) {
      return 16.0;
    }
  }

  /// カスタムテーマを読み込み
  static Future<Map<String, Map<String, Color>>> loadCustomThemes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customThemesJson = prefs.getString(_customThemesKey);

      if (customThemesJson != null) {
        final customThemes = Map<String, Map<String, dynamic>>.from(
          json.decode(customThemesJson),
        );

        return customThemes.map(
          (name, colors) => MapEntry(
            name,
            colors.map((key, value) => MapEntry(key, Color(value as int))),
          ),
        );
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  /// すべての設定を読み込み
  static Future<Map<String, dynamic>> loadAllSettings() async {
    final theme = await loadTheme();
    final font = await loadFont();
    final fontSize = await loadFontSize();
    final customThemes = await loadCustomThemes();

    return {
      'theme': theme,
      'font': font,
      'fontSize': fontSize,
      'customThemes': customThemes,
    };
  }
}
