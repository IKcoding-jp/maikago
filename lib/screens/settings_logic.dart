import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 設定項目ごとのロジックを管理するクラス
/// テーマの生成、フォントの設定、ラベルの取得などのロジック
class SettingsLogic {
  /// テーマデータを生成
  static ThemeData generateTheme({
    required String selectedTheme,
    required String selectedFont,
    required Map<String, Color> detailedColors,
    double fontSize = 16.0,
  }) {
    Color primary, secondary, surface;
    Color onPrimary, onSurface;

    if (selectedTheme == 'custom') {
      primary = detailedColors['appBarColor']!;
      secondary = detailedColors['buttonColor']!;
      surface = detailedColors['backgroundColor']!;
    } else {
      switch (selectedTheme) {
        case 'light':
          primary = Color(0xFF757575);
          secondary = Color(0xFFBDBDBD);
          surface = Color(0xFFF5F5F5);
          break;
        case 'dark':
          primary = Color(0xFF2C2C2C);
          secondary = Color(0xFF4A4A4A);
          surface = Color(0xFF1A1A1A);
          break;
        case 'orange':
          primary = Color(0xFFFFC107);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'green':
          primary = Color(0xFF8BC34A);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF1F8E9);
          break;
        case 'blue':
          primary = Color(0xFF2196F3);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE3F2FD);
          break;
        case 'gray':
          primary = Color(0xFF90A4AE);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF5F5F5);
          break;
        case 'beige':
          primary = Color(0xFFFFE0B2);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'mint':
          primary = Color(0xFFB5EAD7);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE0F7FA);
          break;
        case 'lavender':
          primary = Color(0xFFB39DDB);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF3E5F5);
          break;
        case 'lemon':
          primary = Color(0xFFFFF176);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFFDE7);
          break;
        case 'soda':
          primary = Color(0xFF81D4FA);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE1F5FE);
          break;
        case 'coral':
          primary = Color(0xFFFFAB91);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF3E0);
          break;
        default: // pink
          primary = Color(0xFFFFB6C1);
          secondary = Color(0xFFB5EAD7);
          surface = Color(0xFFFFF1F8);
      }
    }

    // テキストカラーの設定
    onPrimary = (selectedTheme == 'lemon' || selectedTheme == 'light')
        ? Colors.black87
        : Colors.white;
    onSurface = selectedTheme == 'dark' ? Colors.white : Colors.black87;

    TextTheme textTheme = _getTextTheme(selectedFont, fontSize);

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: selectedTheme == 'dark'
            ? Brightness.dark
            : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: textTheme.apply(
        bodyColor: selectedTheme == 'dark' ? Colors.white : Colors.black87,
        displayColor: selectedTheme == 'dark' ? Colors.white : Colors.black87,
      ),
      scaffoldBackgroundColor: selectedTheme == 'dark'
          ? Color(0xFF0F0F0F)
          : Color(0xFFFAFAFA),
      cardColor: selectedTheme == 'dark' ? Color(0xFF1A1A1A) : Colors.white,
      dividerColor: selectedTheme == 'dark'
          ? Color(0xFF333333)
          : Colors.grey.withOpacity(0.3),
      useMaterial3: true,
    );
  }

  /// フォントに基づいてテキストテーマを取得
  static TextTheme _getTextTheme(String selectedFont, double fontSize) {
    TextTheme baseTextTheme;
    switch (selectedFont) {
      case 'sawarabi':
        baseTextTheme = GoogleFonts.sawarabiMinchoTextTheme();
        break;
      case 'mplus':
        baseTextTheme = GoogleFonts.mPlus1pTextTheme();
        break;
      case 'zenmaru':
        baseTextTheme = GoogleFonts.zenMaruGothicTextTheme();
        break;
      case 'yuseimagic':
        baseTextTheme = GoogleFonts.yuseiMagicTextTheme();
        break;
      case 'yomogi':
        baseTextTheme = GoogleFonts.yomogiTextTheme();
        break;
      default:
        baseTextTheme = GoogleFonts.nunitoTextTheme();
    }

    // フォントサイズを明示的に指定
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: fontSize + 10,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: fontSize + 6,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: fontSize + 2,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: fontSize + 4,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: fontSize + 2,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: fontSize),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: fontSize),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: fontSize - 2),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: fontSize - 4),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: fontSize),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: fontSize - 2),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: fontSize - 4),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: fontSize - 2),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: fontSize - 4),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: fontSize - 6),
    );
  }

  /// テーマのラベルを取得
  static String getThemeLabel(String key) {
    switch (key) {
      case 'pink':
        return 'デフォルト';
      case 'light':
        return 'ライト';
      case 'dark':
        return 'ダーク';
      case 'lemon':
        return 'レモン';
      case 'orange':
        return 'オレンジ';
      case 'green':
        return 'グリーン';
      case 'soda':
        return 'ソーダ';
      case 'blue':
        return 'ブルー';
      case 'lavender':
        return 'ラベンダー';
      case 'coral':
        return 'コーラル';
      case 'beige':
        return 'ベージュ';
      case 'gray':
        return 'グレー';
      case 'custom':
        return 'カスタム';
      default:
        return 'デフォルト';
    }
  }

  /// フォントのラベルを取得
  static String getFontLabel(String key) {
    switch (key) {
      case 'sawarabi':
        return '明朝体';
      case 'mplus':
        return 'ゴシック体';
      case 'zenmaru':
        return '丸ゴシック体';
      case 'yuseimagic':
        return '毛筆';
      case 'yomogi':
        return 'かわいい';
      case 'nunito':
        return 'デフォルト';
      default:
        return 'デフォルト';
    }
  }

  /// 利用可能なテーマのリストを取得
  static List<Map<String, dynamic>> getAvailableThemes() {
    return [
      {'key': 'pink', 'label': 'デフォルト', 'color': Color(0xFFFFB6C1)},
      {'key': 'light', 'label': 'ライト', 'color': Color(0xFFEEEEEE)},
      {'key': 'orange', 'label': 'オレンジ', 'color': Color(0xFFFFC107)},
      {'key': 'dark', 'label': 'ダーク', 'color': Color(0xFF424242)},
      {'key': 'lemon', 'label': 'レモン', 'color': Color(0xFFFFF176)},
      {'key': 'green', 'label': 'グリーン', 'color': Color(0xFF8BC34A)},
      {'key': 'soda', 'label': 'ソーダ', 'color': Color(0xFF81D4FA)},
      {'key': 'blue', 'label': 'ブルー', 'color': Color(0xFF2196F3)},
      {'key': 'lavender', 'label': 'ラベンダー', 'color': Color(0xFFB39DDB)},
      {'key': 'coral', 'label': 'コーラル', 'color': Color(0xFFFFAB91)},
      {'key': 'beige', 'label': 'ベージュ', 'color': Color(0xFFFFE0B2)},
      {'key': 'gray', 'label': 'グレー', 'color': Color(0xFF90A4AE)},
      {'key': 'mint', 'label': 'ミント', 'color': Color(0xFFB5EAD7)},
    ];
  }

  /// 利用可能なフォントのリストを取得
  static List<Map<String, dynamic>> getAvailableFonts() {
    return [
      {'key': 'nunito', 'label': 'デフォルト', 'style': GoogleFonts.nunito()},
      {
        'key': 'sawarabi',
        'label': '明朝体',
        'style': GoogleFonts.sawarabiMincho(),
      },
      {'key': 'mplus', 'label': 'ゴシック体', 'style': GoogleFonts.mPlus1p()},
      {
        'key': 'zenmaru',
        'label': '丸ゴシック体',
        'style': GoogleFonts.zenMaruGothic(),
      },
      {'key': 'yuseimagic', 'label': '毛筆', 'style': GoogleFonts.yuseiMagic()},
      {'key': 'yomogi', 'label': 'かわいい', 'style': GoogleFonts.yomogi()},
    ];
  }

  /// 背景色に対するコントラスト色を取得
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
