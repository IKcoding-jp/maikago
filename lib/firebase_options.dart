// Firebase設定ファイル
// Web版でFirebaseを使用するために必要な設定
// env.jsonから読み込む方式を採用

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:maikago/env.dart';

/// Web版のFirebase設定
/// env.jsonから読み込む
class FirebaseOptionsWeb {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web版の設定をenv.jsonから読み込む
      return FirebaseOptions(
        apiKey: Env.firebaseApiKey,
        appId: Env.firebaseAppId,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        authDomain: Env.firebaseAuthDomain,
        storageBucket: Env.firebaseStorageBucket,
        measurementId: Env.firebaseMeasurementId,
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
        return const FirebaseOptions(
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
