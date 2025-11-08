// Firebase 認証と Google Sign-In を使ったログイン/ログアウトを提供
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';

/// 認証関連のユースケースを集約したサービス。
/// - Google でのサインイン
/// - 認証状態監視
/// - サインアウト
class AuthService {
  /// Firebase 認証のシングルトン（Firebaseが初期化されていない場合はnull）
  FirebaseAuth? get _auth {
    // Firebase.appsへのアクセスを完全にtry-catchで保護
    // WebプラットフォームではFirebase.appsにアクセスするだけで例外が発生する可能性がある
    bool isFirebaseInitialized = false;
    try {
      isFirebaseInitialized = Firebase.apps.isNotEmpty;
    } catch (e) {
      // Firebase.appsにアクセスできない場合は初期化されていないと判断
      // Webプラットフォームでは特に例外が発生しやすい
      if (kIsWeb) {
        debugPrint('Firebase.appsアクセスエラー（Web）: $e。ローカルモードで動作します。');
      } else {
        debugPrint('Firebase.appsアクセスエラー: $e');
      }
      return null;
    }

    if (!isFirebaseInitialized) {
      if (kIsWeb) {
        debugPrint('Firebaseが初期化されていません（Web）。ローカルモードで動作します。');
      }
      return null;
    }

    // FirebaseAuth.instanceへのアクセスも完全にtry-catchで保護
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth取得エラー: $e');
      return null;
    }
  }

  // Google Sign-Inの設定を改善
  /// Google サインインのクライアント（Firebase未初期化時も安全に取得）
  ///
  /// google_sign_in パッケージのバージョン7.0.0以降では、名前なしコンストラクタが削除され、
  /// GoogleSignIn.instance シングルトンを使用する必要があります。
  /// Webプラットフォームでは、web/index.htmlの<meta name="google-signin-client_id">タグから
  /// clientIdが自動的に読み込まれます。
  GoogleSignIn get _googleSignIn {
    try {
      // すべてのプラットフォームでGoogleSignIn.instanceを使用
      // Webプラットフォームでは、web/index.htmlのメタタグからclientIdが自動的に読み込まれる
      return GoogleSignIn.instance;
    } catch (e) {
      debugPrint('Google Sign-In取得エラー: $e');
      // エラー時もGoogleSignIn.instanceを返す（後続処理でエラーハンドリング）
      // GoogleSignIn.instanceはシングルトンなので、再試行しても安全
      return GoogleSignIn.instance;
    }
  }

  /// 現在のユーザーを取得
  User? get currentUser {
    try {
      final auth = _auth;
      if (auth == null) {
        return null;
      }
      return auth.currentUser;
    } catch (e) {
      debugPrint('Firebase認証エラー: $e');
      return null;
    }
  }

  /// 認証状態の変更を監視するストリーム
  Stream<User?> get authStateChanges {
    try {
      final auth = _auth;
      if (auth == null) {
        // Firebaseが初期化されていない場合は空のストリームを返す
        return Stream.value(null);
      }
      return auth.authStateChanges();
    } catch (e) {
      debugPrint('Firebase認証ストリームエラー: $e');
      // エラー時は空のストリームを返す
      return Stream.value(null);
    }
  }

  /// Googleアカウントでログインを実行。
  /// 成功時は 'success'、キャンセル時は null、失敗時はエラーコードを返す。
  Future<String?> signInWithGoogle() async {
    try {
      final auth = _auth;
      if (auth == null) {
        debugPrint('Firebaseが初期化されていません。ログインをスキップします。');
        return 'firebase_not_initialized';
      }

      debugPrint('Googleサインイン開始');

      UserCredential userCredential;

      if (kIsWeb) {
        // Webプラットフォームでは、Firebase AuthのsignInWithPopupを直接使用
        // google_sign_inパッケージのauthenticate()はWebでサポートされていない
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await auth.signInWithPopup(googleProvider);
      } else {
        // ネイティブプラットフォームでは、google_sign_inパッケージを使用
        final googleSignIn = _googleSignIn;
        await googleSignIn.initialize();

        // 既存のサインインをクリア
        await googleSignIn.signOut();

        // Google Sign-Inを開始
        final GoogleSignInAccount? googleUser =
            await googleSignIn.authenticate();

        // ユーザーがキャンセルした場合
        if (googleUser == null) {
          debugPrint('Googleサインインがキャンセルされました');
          return 'sign_in_canceled';
        }

        // 認証情報を取得
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        if (googleAuth.idToken == null) {
          debugPrint('ID Tokenがnullです。OAuth同意画面の設定を確認してください。');
          throw Exception('認証に失敗しました。設定を確認してください。');
        }

        // Firebase認証情報を作成
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Firebaseにサインイン
        userCredential = await auth.signInWithCredential(credential);
      }

      // ユーザー情報をFirestoreに保存
      if (userCredential.user != null) {
        await _saveUserProfile(userCredential.user!);
      }

      // PII（メールアドレス等）をログに出さない
      debugPrint('Googleサインイン成功: uid=${userCredential.user?.uid}');
      return 'success';
    } catch (e) {
      debugPrint('Google Sign-Inエラー: $e');

      // エラーの詳細をログ出力
      if (e is PlatformException) {
        // 特定のエラーコードに対する処理
        switch (e.code) {
          case 'sign_in_failed':
            debugPrint('サインイン失敗: 設定を確認してください');
            return 'sign_in_failed';
          case 'sign_in_canceled':
            debugPrint('サインインがキャンセルされました');
            return 'sign_in_canceled';
          case 'network_error':
            debugPrint('ネットワークエラーが発生しました');
            return 'network_error';
          case 'DEVELOPER_ERROR':
            debugPrint('開発者エラー: OAuth設定に問題があります');
            return 'developer_error';
          case 'INVALID_ACCOUNT':
            debugPrint('無効なアカウント: アカウントに問題があります');
            return 'invalid_account';
          default:
            debugPrint('その他のエラー: ${e.code}');
            return 'unknown_error';
        }
      } else if (e is FirebaseAuthException) {
        debugPrint('Firebase認証例外: ${e.code}');
        return e.code;
      }
      return 'unknown_error'; // その他のエラー
    }
  }

  /// ログアウト（Firebase/Google の両方）
  Future<void> signOut() async {
    try {
      final auth = _auth;
      final googleSignIn = _googleSignIn;
      if (auth != null) {
        await Future.wait([auth.signOut(), googleSignIn.signOut()]);
        debugPrint('ログアウト完了');
      } else {
        await googleSignIn.signOut();
        debugPrint('ログアウト完了（Firebase未初期化）');
      }
    } catch (e) {
      debugPrint('ログアウトエラー: $e');
    }
  }

  /// 現在のユーザー情報を取得
  User? getUser() {
    final auth = _auth;
    if (auth == null) {
      return null;
    }
    return auth.currentUser;
  }

  /// ユーザープロフィールをFirestoreに保存
  Future<void> _saveUserProfile(User user) async {
    try {
      // Firebaseが初期化されているか確認（完全にtry-catchで保護）
      bool isFirebaseInitialized = false;
      try {
        isFirebaseInitialized = Firebase.apps.isNotEmpty;
      } catch (e) {
        debugPrint('Firebase.appsアクセスエラー（プロフィール保存）: $e');
        return;
      }

      if (!isFirebaseInitialized) {
        debugPrint('Firebaseが初期化されていないため、ユーザープロフィールの保存をスキップします。');
        return;
      }

      final userDoc = {
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'lastSignInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userDoc, SetOptions(merge: true));

      debugPrint('ユーザープロフィールを保存しました: ${user.uid}');
    } catch (e) {
      debugPrint('ユーザープロフィール保存エラー: $e');
    }
  }
}
