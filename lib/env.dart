import 'package:flutter/foundation.dart';

class Env {
  static const String googleVisionApiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: '',
  );

  static const String openAIApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String _googleWebClientIdEnv = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleWebClientId = _googleWebClientIdEnv != ''
      ? _googleWebClientIdEnv
      : '885657104780-i86iq3v2thhgid8b3f0nm1jbsmuci511.apps.googleusercontent.com';

  static void debugApiKeyStatus() {
    String mask(String value) {
      if (value.isEmpty) return '未設定';
      if (value.length <= 6) return '${value.substring(0, 1)}***';
      return '${value.substring(0, 3)}***${value.substring(value.length - 2)}';
    }

    debugPrint('🔑 GOOGLE_VISION_API_KEY: ${mask(googleVisionApiKey)}');
    debugPrint('🔑 OPENAI_API_KEY: ${mask(openAIApiKey)}');
  }
}
