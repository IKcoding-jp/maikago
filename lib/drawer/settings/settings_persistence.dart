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
  static const String _defaultShopDeletedKey = 'default_shop_deleted';
  static const String _cameraGuidelinesShownKey = 'camera_guidelines_shown';
  static const String _cameraGuidelinesDontShowAgainKey =
      'camera_guidelines_dont_show_again';

  /// テーマを保存
  static Future<void> saveTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
    } catch (e, stackTrace) {
      debugPrint('❌ SettingsPersistence: テーマ保存エラー: $e');
      debugPrint('📚 スタックトレース: $stackTrace');
      // iOS固有のSharedPreferencesエラー可能性
      rethrow;
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

  /// 現在のカスタムテーマを読み込み
  static Future<Map<String, Color>> loadCurrentCustomTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCustomThemeJson = prefs.getString('current_custom_theme');

      if (currentCustomThemeJson != null) {
        final currentCustomTheme = Map<String, dynamic>.from(
          json.decode(currentCustomThemeJson),
        );

        return currentCustomTheme.map(
          (key, value) => MapEntry(key, Color(value as int)),
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

  /// 現在の予算を取得（個別モード）
  static Future<int?> getCurrentBudget(String tabId) async {
    return await loadTabBudget(tabId);
  }

  /// 現在の合計を取得（個別モード）
  static Future<int> getCurrentTotal(String tabId) async {
    return await loadTabTotal(tabId);
  }

  /// 現在の予算を保存（個別モード）
  static Future<void> saveCurrentBudget(String tabId, int? budget) async {
    await saveTabBudget(tabId, budget);
  }

  /// 現在の合計を保存（個別モード）
  static Future<void> saveCurrentTotal(String tabId, int total) async {
    await saveTabTotal(tabId, total);
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

  /// 選択されたタブインデックスを保存
  static Future<void> saveSelectedTabIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'selected_tab_index';
      await prefs.setInt(key, index);
      debugPrint('選択タブインデックス保存: $index');
    } catch (e) {
      debugPrint('saveSelectedTabIndex エラー: $e');
    }
  }

  /// 選択されたタブインデックスを読み込み
  static Future<int> loadSelectedTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'selected_tab_index';
      final result = prefs.getInt(key) ?? 0;
      debugPrint('選択タブインデックス読み込み: $result');
      return result;
    } catch (e) {
      debugPrint('loadSelectedTabIndex エラー: $e');
      return 0;
    }
  }

  /// デフォルトショップの削除状態を保存
  static Future<void> saveDefaultShopDeleted(bool deleted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_defaultShopDeletedKey, deleted);
      debugPrint('デフォルトショップ削除状態保存: $deleted');
    } catch (e) {
      debugPrint('saveDefaultShopDeleted エラー: $e');
    }
  }

  /// デフォルトショップの削除状態を読み込み
  static Future<bool> loadDefaultShopDeleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = prefs.getBool(_defaultShopDeletedKey) ?? false;
      debugPrint('デフォルトショップ削除状態読み込み: $result');
      return result;
    } catch (e) {
      debugPrint('loadDefaultShopDeleted エラー: $e');
      return false;
    }
  }

  /// カメラガイドラインを表示すべきかチェック
  static Future<bool> shouldShowCameraGuidelines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dontShowAgain =
          prefs.getBool(_cameraGuidelinesDontShowAgainKey) ?? false;
      final hasShown = prefs.getBool(_cameraGuidelinesShownKey) ?? false;

      // 「二度と表示しない」がチェックされている場合は表示しない
      if (dontShowAgain) {
        debugPrint('カメラガイドライン: 「二度と表示しない」が設定されているため非表示');
        return false;
      }

      // 初回のみ表示
      if (hasShown) {
        debugPrint('カメラガイドライン: 既に表示済みのため非表示');
        return false;
      }

      debugPrint('カメラガイドライン: 初回表示のため表示');
      return true;
    } catch (e) {
      debugPrint('shouldShowCameraGuidelines エラー: $e');
      return true; // エラーの場合は安全のため表示
    }
  }

  /// カメラガイドライン表示済みとしてマーク
  static Future<void> markCameraGuidelinesAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cameraGuidelinesShownKey, true);
      debugPrint('カメラガイドライン: 表示済みとしてマーク');
    } catch (e) {
      debugPrint('markCameraGuidelinesAsShown エラー: $e');
    }
  }

  /// カメラガイドラインを「二度と表示しない」として設定
  static Future<void> setCameraGuidelinesDontShowAgain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cameraGuidelinesDontShowAgainKey, true);
      await prefs.setBool(_cameraGuidelinesShownKey, true);
      debugPrint('カメラガイドライン: 「二度と表示しない」として設定');
    } catch (e) {
      debugPrint('setCameraGuidelinesDontShowAgain エラー: $e');
    }
  }
}
