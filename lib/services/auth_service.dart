import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Googleアカウントでログイン
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 既存のサインインをクリア
      await _googleSignIn.signOut();

      // Googleサインインのフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Googleサインインがキャンセルされました');
        return null; // ユーザーがサインインをキャンセル
      }

      // Google認証情報を取得
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase認証情報を作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseでサインイン
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Googleサインインエラー: $e');
      rethrow; // エラーを再スローして呼び出し元で処理
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      print('ログアウトエラー: $e');
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
