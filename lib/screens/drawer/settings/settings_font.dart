import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// フォント設定を管理するクラス
class FontSettings {
  /// フォントに基づいてテキストテーマを取得
  static TextTheme getTextTheme(String selectedFont, double fontSize) {
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
}
