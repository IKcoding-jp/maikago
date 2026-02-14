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
      return const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
        appId: String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
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

/// デフォルトのFirebase設定
/// FirebaseOptionsWebのラッパーとして機能
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptionsWeb.currentPlatform;
  }
}