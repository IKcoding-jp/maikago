// Firebase 認証と Google Sign-In を使ったログイン/ログアウトを提供
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 認証関連のユースケースを集約したサービス。
/// - Google でのサインイン
/// - 認証状態監視
/// - サインアウト
class AuthService {
  /// Firebase 認証のシングルトン
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-Inの設定を改善
  /// Google サインインのクライアント
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // タイムアウト設定を追加
    hostedDomain: '',
    // サーバークライアントIDを一時的に削除してFirebaseの自動設定を使用
    // serverClientId:
    //     '885657104780-i86iq3v2thhgid8b3f0nm1jbsmuci511.apps.googleusercontent.com',
  );

  /// 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  /// 認証状態の変更を監視するストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Googleアカウントでログインを実行。
  /// 成功時は 'success'、キャンセル時は null、失敗時はエラーコードを返す。
  /// 各処理に 30 秒のタイムアウトを設定。
  Future<String?> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In開始');

      // 既存のサインインをクリア
      await _googleSignIn.signOut();

      // Google Sign-Inを開始（タイムアウト処理付き）
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Google Sign-In タイムアウト');
              throw Exception('Google Sign-In タイムアウト');
            },
          );

      if (googleUser == null) {
        debugPrint('ユーザーがサインインをキャンセルしました');
        return null;
      }

      // 認証情報を取得（タイムアウト処理付き）
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Google認証情報取得 タイムアウト');
              throw Exception('Google認証情報取得 タイムアウト');
            },
          );

      if (googleAuth.idToken == null) {
        debugPrint('ID Tokenがnullです。OAuth同意画面の設定を確認してください。');
        throw Exception('ID Tokenが取得できませんでした');
      }

      // Firebase認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン（タイムアウト処理付き）
      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Firebaseサインイン タイムアウト');
              throw Exception('Firebaseサインイン タイムアウト');
            },
          );

      debugPrint('Google Sign-In成功: ${userCredential.user?.email}');
      return 'success';
    } catch (e) {
      debugPrint('Google Sign-Inエラー: $e');

      // エラーの詳細をログ出力
      if (e is PlatformException) {
        // 特定のエラーコードに対する処理
        switch (e.code) {
          case 'sign_in_failed':
            debugPrint('サインイン失敗: 設定を確認してください');
            return e.code;
          case 'sign_in_canceled':
            debugPrint('サインインがキャンセルされました');
            return e.code;
          case 'network_error':
            debugPrint('ネットワークエラーが発生しました');
            return e.code;
          case 'DEVELOPER_ERROR':
            debugPrint('開発者エラー: OAuth設定に問題があります');
            return e.code;
          case 'INVALID_ACCOUNT':
            debugPrint('無効なアカウント: アカウントに問題があります');
            return e.code;
          default:
            debugPrint('その他のエラー: ${e.code}');
            return e.code;
        }
      } else if (e is FirebaseAuthException) {
        debugPrint('FirebaseAuthException: ${e.code}');
        return e.code;
      }
      return 'unknown_error'; // その他のエラー
    }
  }

  /// ログアウト（Firebase/Google の両方）
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      debugPrint('ログアウト完了');
    } catch (e) {
      debugPrint('ログアウトエラー: $e');
    }
  }

  /// 現在のユーザー情報を取得
  User? getUser() {
    return _auth.currentUser;
  }
}
