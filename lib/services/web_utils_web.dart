/// Webプラットフォーム用の実装
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

/// モバイルWebかどうかを判定
bool isMobileWeb() {
  try {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('android') ||
        userAgent.contains('mobile');
  } catch (e) {
    return false;
  }
}
