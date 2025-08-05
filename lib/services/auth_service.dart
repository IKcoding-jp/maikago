import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-Inの設定を改善
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // タイムアウト設定を追加
    hostedDomain: '',
    // サーバークライアントIDを一時的に削除してFirebaseの自動設定を使用
    // serverClientId:
    //     '885657104780-i86iq3v2thhgid8b3f0nm1jbsmuci511.apps.googleusercontent.com',
  );

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Googleアカウントでログイン
  Future<String?> signInWithGoogle() async {
    try {
      debugPrint('=== Google Sign-In 開始 ===');
      debugPrint('ビルドタイプ: ${kReleaseMode ? "リリース" : "デバッグ"}');
      debugPrint('パッケージ名: com.ikcoding.maikago.v2');
      debugPrint(
        'サーバークライアントID: 885657104780-i86iq3v2thhgid8b3f0nm1jbsmuci511.apps.googleusercontent.com',
      );
      debugPrint('SHA-1 (デバッグ): 33b446e0ecc4ae2bd47ae5a3b8d58710d2194183');
      debugPrint('SHA-1 (リリース): 9c3b9fb466ed12f974f5bf1b3db9d98476b624c7');

      // Google Sign-Inの設定を確認
      debugPrint('Google Sign-In設定確認中...');
      debugPrint('Scopes: ${_googleSignIn.scopes}');
      debugPrint('Server Client ID: ${_googleSignIn.serverClientId}');

      // 既存のサインインをクリア
      debugPrint('既存のサインインをクリア中...');
      await _googleSignIn.signOut();
      debugPrint('既存のサインインをクリアしました');

      // Google Sign-Inを開始（タイムアウト処理付き）
      debugPrint('Google Sign-In開始...');
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Google Sign-In タイムアウト');
              throw Exception('Google Sign-In タイムアウト');
            },
          );
      debugPrint('Google Sign-In結果: ${googleUser != null ? "成功" : "失敗"}');

      if (googleUser == null) {
        debugPrint('ユーザーがサインインをキャンセルしました');
        return null;
      }

      debugPrint('ユーザー情報: ${googleUser.email}');
      debugPrint('ユーザーID: ${googleUser.id}');
      debugPrint('表示名: ${googleUser.displayName}');
      debugPrint('写真URL: ${googleUser.photoUrl}');

      // 認証情報を取得（タイムアウト処理付き）
      debugPrint('Google認証情報を取得中...');
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Google認証情報取得 タイムアウト');
              throw Exception('Google認証情報取得 タイムアウト');
            },
          );
      debugPrint('Google認証情報を取得しました');
      debugPrint(
        'Access Token: ${googleAuth.accessToken != null ? "取得済み" : "null"}',
      );
      debugPrint('ID Token: ${googleAuth.idToken != null ? "取得済み" : "null"}');
      debugPrint(
        'Server Auth Code: ${googleUser.serverAuthCode != null ? "取得済み" : "null"}',
      );

      if (googleAuth.idToken == null) {
        debugPrint('ID Tokenがnullです。OAuth同意画面の設定を確認してください。');
        debugPrint('Access Token: ${googleAuth.accessToken}');
        debugPrint('Server Auth Code: ${googleUser.serverAuthCode}');
        throw Exception('ID Tokenが取得できませんでした');
      }

      // Firebase認証情報を作成
      debugPrint('Firebase認証情報を作成中...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('Firebase認証情報を作成しました');

      // Firebaseにサインイン（タイムアウト処理付き）
      debugPrint('Firebaseにサインイン中...');
      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Firebaseサインイン タイムアウト');
              throw Exception('Firebaseサインイン タイムアウト');
            },
          );
      debugPrint('Firebaseサインイン成功: ${userCredential.user?.email}');
      debugPrint('Firebase UID: ${userCredential.user?.uid}');
      debugPrint('=== Google Sign-In 完了 ===');

      return 'success';
    } catch (e) {
      debugPrint('=== Google Sign-In エラー ===');
      debugPrint('エラー内容: $e');
      debugPrint('エラータイプ: ${e.runtimeType}');
      debugPrint('エラーの詳細: ${e.toString()}');

      // エラーの詳細をログ出力
      if (e is PlatformException) {
        debugPrint('PlatformException コード: ${e.code}');
        debugPrint('PlatformException メッセージ: ${e.message}');
        debugPrint('PlatformException 詳細: ${e.details}');

        // エラー12500の詳細な対処法をログ出力
        if (e.message?.contains('12500') == true) {
          debugPrint('=== エラー12500 対処法 ===');
          debugPrint('1. Google Cloud ConsoleでOAuth同意画面を確認');
          debugPrint('2. テストユーザーが追加されているか確認');
          debugPrint('3. Google Sign-In APIが有効か確認');
          debugPrint('4. ネットワーク接続を確認');
          debugPrint('5. Google Play Servicesが最新版か確認');
        }

        // 特定のエラーコードに対する処理
        switch (e.code) {
          case 'sign_in_failed':
            debugPrint('サインイン失敗: 設定を確認してください');
            debugPrint('確認事項:');
            debugPrint('1. Firebase ConsoleでGoogle認証が有効か');
            debugPrint('2. Google Cloud ConsoleでOAuth 2.0クライアントIDが正しく設定されているか');
            debugPrint('3. SHA-1証明書フィンガープリントが正しいか');
            debugPrint('4. パッケージ名が一致しているか');
            debugPrint('5. OAuth同意画面でテストユーザーが追加されているか');
            debugPrint('6. Google Play Servicesが最新版か');
            debugPrint('7. ネットワーク接続が正常か');
            return e.code;
          case 'sign_in_canceled':
            debugPrint('サインインがキャンセルされました');
            return e.code;
          case 'network_error':
            debugPrint('ネットワークエラーが発生しました');
            return e.code;
          case 'DEVELOPER_ERROR':
            debugPrint('開発者エラー: OAuth設定に問題があります');
            debugPrint('- OAuth同意画面の設定を確認してください');
            debugPrint('- テストユーザーが追加されているか確認してください');
            return e.code;
          case 'INVALID_ACCOUNT':
            debugPrint('無効なアカウント: アカウントに問題があります');
            return e.code;
          default:
            debugPrint('その他のエラー: ${e.code}');
            return e.code;
        }
      } else if (e is FirebaseAuthException) {
        debugPrint('FirebaseAuthException コード: ${e.code}');
        debugPrint('FirebaseAuthException メッセージ: ${e.message}');
        debugPrint('FirebaseAuthException 詳細: ${e.email}');
        return e.code;
      }
      return 'unknown_error'; // その他のエラー
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      debugPrint('ログアウトを開始します...');
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      debugPrint('ログアウトが完了しました');
    } catch (e) {
      debugPrint('ログアウトエラー: $e');
      // エラーログは本番環境では削除
    }
  }

  // ユーザー情報を取得
  User? getUser() {
    return _auth.currentUser;
  }

  // ユーザーがログインしているかチェック
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }
}
