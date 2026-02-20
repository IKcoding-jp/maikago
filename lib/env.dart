import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/debug_service.dart';

class Env {
  // env.json からの値（ローカル開発用フォールバック）
  static Map<String, dynamic> _config = {};
  static bool _isLoaded = false;

  // --dart-define によるビルド時注入（CI/CD 用。こちらが優先）
  static const String _dartDefineGoogleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
  static const String _dartDefineAdmobInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_AD_UNIT_ID', defaultValue: '');
  static const String _dartDefineAdmobBanner =
      String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID', defaultValue: '');
  static const String _dartDefineAdmobAppOpen =
      String.fromEnvironment('ADMOB_APP_OPEN_AD_UNIT_ID', defaultValue: '');
  static const String _dartDefineFirebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String _dartDefineFirebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String _dartDefineFirebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String _dartDefineFirebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String _dartDefineFirebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String _dartDefineFirebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String _dartDefineFirebaseMeasurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: '');

  /// env.json を読み込む（ローカル開発用フォールバック）
  /// --dart-define で値が注入されている場合はそちらが優先される
  static Future<void> load() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('env.json');
      _config = json.decode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
      DebugService().log('env.json読み込み完了（フォールバック用）');
    } catch (e) {
      DebugService().log('env.json読み込みスキップ: $e');
      _isLoaded = true;
    }
  }

  /// --dart-define の値を優先し、空なら env.json からフォールバック
  static String _get(String dartDefineValue, String jsonKey) {
    if (dartDefineValue.isNotEmpty) return dartDefineValue;
    return _config[jsonKey]?.toString() ?? '';
  }

  // 公開API
  static String get googleWebClientId =>
      _get(_dartDefineGoogleWebClientId, 'GOOGLE_WEB_CLIENT_ID');

  static String get admobInterstitialAdUnitId {
    final value = _get(_dartDefineAdmobInterstitial, 'ADMOB_INTERSTITIAL_AD_UNIT_ID');
    return value.isNotEmpty ? value : adInterstitialUnitId;
  }

  static String get admobBannerAdUnitId {
    final value = _get(_dartDefineAdmobBanner, 'ADMOB_BANNER_AD_UNIT_ID');
    return value.isNotEmpty ? value : adBannerUnitId;
  }

  static String get admobAppOpenAdUnitId {
    final value = _get(_dartDefineAdmobAppOpen, 'ADMOB_APP_OPEN_AD_UNIT_ID');
    return value.isNotEmpty ? value : adAppOpenUnitId;
  }

  static String get firebaseApiKey =>
      _get(_dartDefineFirebaseApiKey, 'FIREBASE_API_KEY');
  static String get firebaseAppId =>
      _get(_dartDefineFirebaseAppId, 'FIREBASE_APP_ID');
  static String get firebaseMessagingSenderId =>
      _get(_dartDefineFirebaseMessagingSenderId, 'FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseProjectId =>
      _get(_dartDefineFirebaseProjectId, 'FIREBASE_PROJECT_ID');
  static String get firebaseAuthDomain =>
      _get(_dartDefineFirebaseAuthDomain, 'FIREBASE_AUTH_DOMAIN');
  static String get firebaseStorageBucket =>
      _get(_dartDefineFirebaseStorageBucket, 'FIREBASE_STORAGE_BUCKET');
  static String get firebaseMeasurementId =>
      _get(_dartDefineFirebaseMeasurementId, 'FIREBASE_MEASUREMENT_ID');

  static void debugApiKeyStatus() {
    String mask(String value) {
      if (value.isEmpty) return '未設定';
      if (value.length <= 6) return '${value.substring(0, 1)}***';
      return '${value.substring(0, 3)}***${value.substring(value.length - 2)}';
    }

    DebugService().log('🔑 GOOGLE_WEB_CLIENT_ID: ${mask(googleWebClientId)}');
  }
}
