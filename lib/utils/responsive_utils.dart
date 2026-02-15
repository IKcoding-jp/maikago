import 'package:flutter/material.dart';
import 'package:maikago/services/debug_service.dart';

/// レスポンシブデザインのためのユーティリティクラス
class ResponsiveUtils {
  /// デバイスの画面サイズに基づいて適切なパディングを計算
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // 画面サイズに基づく基本パディング
    double horizontalPadding;
    double verticalPadding;

    if (screenSize.width < 400) {
      // 小さい画面
      horizontalPadding = 12.0;
      verticalPadding = 16.0;
    } else if (screenSize.width < 600) {
      // 中程度の画面
      horizontalPadding = 16.0;
      verticalPadding = 20.0;
    } else {
      // 大きい画面
      horizontalPadding = 24.0;
      verticalPadding = 24.0;
    }

    return EdgeInsets.only(
      left: horizontalPadding,
      right: horizontalPadding,
      top: verticalPadding,
      bottom: padding.bottom + verticalPadding,
    );
  }

  /// スクロール可能なウィジェット用のパディングを計算
  static EdgeInsets getScrollablePadding(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final screenSize = MediaQuery.of(context).size;

    // 画面サイズに基づく基本パディング
    double horizontalPadding;
    double bottomPadding;

    if (screenSize.width < 400) {
      horizontalPadding = 12.0;
      bottomPadding = 16.0;
    } else if (screenSize.width < 600) {
      horizontalPadding = 16.0;
      bottomPadding = 20.0;
    } else {
      horizontalPadding = 24.0;
      bottomPadding = 24.0;
    }

    return EdgeInsets.only(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: padding.bottom + bottomPadding,
    );
  }

  /// ナビゲーションバーを考慮したボトムパディングを取得
  static double getBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 画面サイズに基づいて適切なフォントサイズを計算
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final screenSize = MediaQuery.of(context).size;
    final textScaler = MediaQuery.of(context).textScaler;

    // 画面サイズに基づくスケールファクター
    double scaleFactor = 1.0;
    if (screenSize.width < 400) {
      scaleFactor = 0.9; // 小さい画面では少し小さく
    } else if (screenSize.width > 600) {
      scaleFactor = 1.1; // 大きい画面では少し大きく
    }

    return baseFontSize * scaleFactor * textScaler.scale(1.0);
  }

  /// 画面サイズに基づいて適切なアイコンサイズを計算
  static double getResponsiveIconSize(
      BuildContext context, double baseIconSize) {
    final screenSize = MediaQuery.of(context).size;

    if (screenSize.width < 400) {
      return baseIconSize * 0.9;
    } else if (screenSize.width > 600) {
      return baseIconSize * 1.1;
    }

    return baseIconSize;
  }

  /// 画面が小さいかどうかを判定
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }

  /// 画面が大きいかどうかを判定
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// 画面が中程度のサイズかどうかを判定
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 400 && width <= 600;
  }

  /// デバイスの向きを取得
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// 縦向きかどうかを判定
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }

  /// 横向きかどうかを判定
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }

  /// 安全な表示領域を考慮したサイズを計算
  static Size getSafeAreaSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;

    return Size(
      mediaQuery.size.width - padding.left - padding.right,
      mediaQuery.size.height - padding.top - padding.bottom,
    );
  }

  /// デバッグ用：デバイス情報を出力
  static void printDeviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;

    DebugService().log('📱 デバイス情報:');
    DebugService().log('   画面サイズ: ${size.width.toInt()} x ${size.height.toInt()}');
    DebugService().log('   向き: ${getOrientation(context)}');
    DebugService().log(
        '   パディング: top=${padding.top}, bottom=${padding.bottom}, left=${padding.left}, right=${padding.right}');
    DebugService().log(
        '   安全領域サイズ: ${getSafeAreaSize(context).width.toInt()} x ${getSafeAreaSize(context).height.toInt()}');
    DebugService().log(
        '   画面サイズ分類: ${isSmallScreen(context) ? '小' : isMediumScreen(context) ? '中' : '大'}');
  }
}
