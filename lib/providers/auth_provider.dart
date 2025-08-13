// 認証状態をアプリ全体に提供し、DonationManager への連携も担う
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/donation_manager.dart';

/// 認証状態の Provider。
/// - 初期化時に現在ユーザー/監視をセットアップ
/// - ログイン/ログアウト時のローディング制御
/// - DonationManager にユーザーIDを伝播
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DonationManager _donationManager = DonationManager();
  User? _user;

  /// 画面表示制御用のローディングフラグ（初期化完了まで true）
  bool _isLoading = true; // 初期化中はtrueに変更

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get canUseApp => isLoggedIn; // ログイン必須に変更

  AuthProvider() {
    _init();
  }

  /// 認証状態の初期化と監視登録
  void _init() async {
    try {
      // 初期ユーザー状態を設定
      _user = _authService.currentUser;

      // 初期ユーザーIDをDonationManagerに設定
      _donationManager.setCurrentUserId(_user?.uid);

      // 認証状態の変更を監視
      _authService.authStateChanges.listen((User? user) async {
        _user = user;
        // ユーザーIDの変更をDonationManagerに通知
        _donationManager.setCurrentUserId(user?.uid);

        // ユーザーがログインした場合、寄付状態をチェックしてテーマ・フォントをリセット
        // 一時的に無効化してテーマ保存の問題を調査
        // if (user != null) {
        //   await _checkAndResetThemeIfNeeded();
        // }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('認証プロバイダー初期化エラー: $e');
      // Firebase初期化に失敗した場合はローカルモードで動作
      debugPrint('ローカルモードで認証を初期化します');
      _user = null;
    } finally {
      // 初期化完了
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      _setLoading(false);
      return userCredential != null;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ローディング状態の更新（UI再描画のトリガー）
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ユーザー情報を取得
  String? get userDisplayName => _user?.displayName;
  String? get userEmail => _user?.email;
  String? get userPhotoURL => _user?.photoURL;
  String get userId => _user?.uid ?? '';
}
