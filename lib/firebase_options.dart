// Firebase設定ファイル
// Web版でFirebaseを使用するために必要な設定
// 環境変数から読み込む方式を採用

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Web版のFirebase設定
/// 環境変数から読み込む
class FirebaseOptionsWeb {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web版の設定を環境変数から読み込む
      // 環境変数が設定されていない場合は、デフォルト値（開発用）を使用
      return FirebaseOptions(
        apiKey: const String.fromEnvironment(
          'FIREBASE_API_KEY',
          defaultValue: 'AIzaSyC-DgEFp7H0a6J9mFSE8_BUy1BNZ4ucgzU',
        ),
        appId: const String.fromEnvironment(
          'FIREBASE_APP_ID',
          defaultValue: '1:885657104780:web:143f6d8a69a45d6a0126a9',
        ),
        messagingSenderId: const String.fromEnvironment(
          'FIREBASE_MESSAGING_SENDER_ID',
          defaultValue: '885657104780',
        ),
        projectId: const String.fromEnvironment(
          'FIREBASE_PROJECT_ID',
          defaultValue: 'maikago2',
        ),
        authDomain: const String.fromEnvironment(
          'FIREBASE_AUTH_DOMAIN',
          defaultValue: 'maikago2.firebaseapp.com',
        ),
        storageBucket: const String.fromEnvironment(
          'FIREBASE_STORAGE_BUCKET',
          defaultValue: 'maikago2.firebasestorage.app',
        ),
        measurementId: const String.fromEnvironment(
          'FIREBASE_MEASUREMENT_ID',
          defaultValue: 'G-HKV91ZG078',
        ),
      );
    }
    // Web以外のプラットフォームでは空の設定を返す
    // （ネイティブプラットフォームではgoogle-services.jsonやGoogleService-Info.plistを使用）
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        );
    }
  }
}
