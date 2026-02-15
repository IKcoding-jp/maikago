import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:maikago/services/debug_service.dart';

class Env {
  static Map<String, dynamic> _config = {};
  static bool _isInitialized = false;

  /// env.jsonから環境変数を読み込む
  /// アプリ起動時に一度呼び出す必要がある
  static Future<void> load() async {
    if (_isInitialized) return;

    try {
      final String jsonString = await rootBundle.loadString('env.json');
      _config = json.decode(jsonString) as Map<String, dynamic>;
      _isInitialized = true;
      DebugService().log('✅ env.json読み込み完了');
    } catch (e) {
      DebugService().log('⚠️ env.json読み込みエラー: $e');
      DebugService().log('⚠️ --dart-defineからの読み込みにフォールバックします');
      _isInitialized = true;
    }
  }

  // dart-defineからの値（フォールバック用）
  static const String _googleWebClientIdEnv = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // 公開API
  static String get googleWebClientId {
    final fromJson = _config['GOOGLE_WEB_CLIENT_ID']?.toString() ?? '';
    if (fromJson.isNotEmpty) return fromJson;
    if (_googleWebClientIdEnv.isNotEmpty) return _googleWebClientIdEnv;
    return '';
  }

  // AdMob関連
  static String get admobInterstitialAdUnitId {
    return _config['ADMOB_INTERSTITIAL_AD_UNIT_ID']?.toString() ?? '';
  }

  static String get admobBannerAdUnitId {
    return _config['ADMOB_BANNER_AD_UNIT_ID']?.toString() ?? '';
  }

  static String get admobAppOpenAdUnitId {
    return _config['ADMOB_APP_OPEN_AD_UNIT_ID']?.toString() ?? '';
  }

  // Firebase Web設定
  static String get firebaseApiKey {
    return _config['FIREBASE_API_KEY']?.toString() ?? '';
  }

  static String get firebaseAppId {
    return _config['FIREBASE_APP_ID']?.toString() ?? '';
  }

  static String get firebaseMessagingSenderId {
    return _config['FIREBASE_MESSAGING_SENDER_ID']?.toString() ?? '';
  }

  static String get firebaseProjectId {
    return _config['FIREBASE_PROJECT_ID']?.toString() ?? '';
  }

  static String get firebaseAuthDomain {
    return _config['FIREBASE_AUTH_DOMAIN']?.toString() ?? '';
  }

  static String get firebaseStorageBucket {
    return _config['FIREBASE_STORAGE_BUCKET']?.toString() ?? '';
  }

  static String get firebaseMeasurementId {
    return _config['FIREBASE_MEASUREMENT_ID']?.toString() ?? '';
  }

  static void debugApiKeyStatus() {
    String mask(String value) {
      if (value.isEmpty) return '未設定';
      if (value.length <= 6) return '${value.substring(0, 1)}***';
      return '${value.substring(0, 3)}***${value.substring(value.length - 2)}';
    }

    DebugService().log('🔑 GOOGLE_WEB_CLIENT_ID: ${mask(googleWebClientId)}');
  }
}
