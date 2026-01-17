/// Webプラットフォーム用の実装
library;

import 'package:web/web.dart' as web;

/// モバイルWebかどうかを判定
bool isMobileWeb() {
  try {
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('android') ||
        userAgent.contains('mobile');
  } catch (e) {
    return false;
  }
}
