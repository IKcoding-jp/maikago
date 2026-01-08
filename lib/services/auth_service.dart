// Firebase 認証と Google Sign-In を使ったログイン/ログアウトを提供
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import '../env.dart';

/// 認証関連のユースケースを集約したサービス。
/// - Google でのサインイン
/// - 認証状態監視
/// - サインアウト
class AuthService {
  /// Firebase 認証のシングルトン
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not initialized');
    }
    return FirebaseAuth.instance;
  }

  /// Google サインインのクライアント
  /// Androidでは serverClientId が必要。Webでは通常 index.html 側で設定。
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: Env.googleWebClientId,
  );

  /// 現在のユーザーを取得
  User? get currentUser {
    try {
      if (Firebase.apps.isEmpty) return null;
      return _auth.currentUser;
    } catch (e) {
      debugPrint('Firebase認証エラー: $e');
      return null;
    }
  }

  /// 認証状態の変更を監視するストリーム
  Stream<User?> get authStateChanges {
    try {
      if (Firebase.apps.isEmpty) return Stream.value(null);
      return _auth.authStateChanges();
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
      debugPrint('Googleサインイン開始');

      UserCredential userCredential;

      if (kIsWeb) {
        // Webプラットフォームでは、Firebase AuthのsignInWithPopupを直接使用
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // ネイティブプラットフォーム（Android/iOS）
        // 既存のサインインをクリア
        await _googleSignIn.signOut();

        // Google Sign-Inを開始
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('Googleサインインがキャンセルされました');
          return 'sign_in_canceled';
        }

        // 認証情報を取得
        final googleAuth = await googleUser.authentication;

        if (googleAuth.idToken == null) {
          debugPrint('ID Tokenがnullです。OAuth同意画面の設定を確認してください。');
          throw Exception('認証に失敗しました。ID Tokenが取得できませんでした。');
        }

        // Firebase認証情報を作成
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Firebaseにサインイン
        userCredential = await _auth.signInWithCredential(credential);
      }

      // ユーザー情報をFirestoreに保存
      if (userCredential.user != null) {
        await _saveUserProfile(userCredential.user!);
      }

      debugPrint('Googleサインイン成功: uid=${userCredential.user?.uid}');
      return 'success';
    } catch (e) {
      debugPrint('Google Sign-Inエラー: $e');

      if (e is PlatformException) {
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
          default:
            return 'unknown_error';
        }
      } else if (e is FirebaseAuthException) {
        debugPrint('Firebase認証例外: ${e.code}');
        return e.code;
      }
      return 'unknown_error';
    }
  }

  /// ログアウト（Firebase/Google の両方）
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      debugPrint('ログアウト完了');
    } catch (e) {
      debugPrint('ログアウトエラー: $e');
    }
  }

  /// 現在のユーザー情報を取得
  User? getUser() {
    return _auth.currentUser;
  }

  /// ユーザープロフィールをFirestoreに保存
  Future<void> _saveUserProfile(User user) async {
    try {
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
