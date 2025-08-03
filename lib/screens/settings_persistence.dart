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
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _budgetSharingEnabledKey = 'budget_sharing_enabled';

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

  /// 初回起動かどうかを確認
  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isFirstLaunchKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  /// 初回起動フラグを設定（初回起動完了後）
  static Future<void> setFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstLaunchKey, false);
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// 予算共有設定を保存
  static Future<void> saveBudgetSharingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_budgetSharingEnabledKey, enabled);
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// 予算共有設定を読み込み
  static Future<bool> loadBudgetSharingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_budgetSharingEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// タブ別予算を保存
  static Future<void> saveTabBudget(String tabId, int? budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'budget_$tabId';
      if (budget != null) {
        await prefs.setInt(key, budget);
        debugPrint('saveTabBudget: $tabId -> $budget (キー: $key)');
      } else {
        await prefs.remove(key);
        debugPrint('saveTabBudget: $tabId -> null (削除) (キー: $key)');
      }
    } catch (e) {
      debugPrint('saveTabBudget エラー: $e');
      // エラーハンドリング
    }
  }

  /// タブ別予算を読み込み
  static Future<int?> loadTabBudget(String tabId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'budget_$tabId';
      final result = prefs.getInt(key);
      debugPrint('loadTabBudget: $tabId -> $result (キー: $key)');
      return result;
    } catch (e) {
      debugPrint('loadTabBudget エラー: $e');
      return null;
    }
  }

  /// タブ別合計を保存
  static Future<void> saveTabTotal(String tabId, int total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'total_$tabId';
      await prefs.setInt(key, total);
      debugPrint('saveTabTotal: $tabId -> $total (キー: $key)');
    } catch (e) {
      debugPrint('saveTabTotal エラー: $e');
      // エラーハンドリング
    }
  }

  /// タブ別合計を読み込み
  static Future<int> loadTabTotal(String tabId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'total_$tabId';
      final result = prefs.getInt(key) ?? 0;
      debugPrint('loadTabTotal: $tabId -> $result (キー: $key)');
      return result;
    } catch (e) {
      debugPrint('loadTabTotal エラー: $e');
      return 0;
    }
  }

  /// 現在の予算を取得（共有モードまたは個別モード）
  static Future<int?> getCurrentBudget(String tabId) async {
    final isSharedMode = await loadBudgetSharingEnabled();

    if (isSharedMode) {
      final result = await loadTabBudget(tabId);
      return result;
    } else {
      final result = await loadTabBudget(tabId);
      return result;
    }
  }

  /// 現在の合計を取得（共有モードまたは個別モード）
  static Future<int> getCurrentTotal(String tabId) async {
    final isSharedMode = await loadBudgetSharingEnabled();

    if (isSharedMode) {
      final result = await loadTabTotal(tabId);
      return result;
    } else {
      final result = await loadTabTotal(tabId);
      return result;
    }
  }

  /// 現在の予算を保存（共有モードまたは個別モード）
  static Future<void> saveCurrentBudget(String tabId, int? budget) async {
    final isSharedMode = await loadBudgetSharingEnabled();

    if (isSharedMode) {
      await saveTabBudget(tabId, budget);
    } else {
      await saveTabBudget(tabId, budget);
    }
  }

  /// 現在の合計を保存（共有モードまたは個別モード）
  static Future<void> saveCurrentTotal(String tabId, int total) async {
    final isSharedMode = await loadBudgetSharingEnabled();

    if (isSharedMode) {
      await saveTabTotal(tabId, total);
    } else {
      await saveTabTotal(tabId, total);
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
