import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/donation_manager.dart';
import '../drawer/settings/settings_persistence.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DonationManager _donationManager = DonationManager();
  User? _user;
  bool _isLoading = true; // 初期化中はtrueに変更

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get canUseApp => isLoggedIn; // ログイン必須に変更

  AuthProvider() {
    _init();
  }

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
        if (user != null) {
          await _checkAndResetThemeIfNeeded();
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('認証プロバイダー初期化エラー: $e');
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 寄付状態をチェックして、必要に応じてテーマとフォントをデフォルトにリセット
  Future<void> _checkAndResetThemeIfNeeded() async {
    try {
      // 少し待機してDonationManagerの状態が更新されるのを待つ
      await Future.delayed(const Duration(milliseconds: 500));

      // 現在のテーマとフォントを取得
      final currentTheme = await SettingsPersistence.loadTheme();
      final currentFont = await SettingsPersistence.loadFont();

      // 寄付状態をチェック
      final isDonated = _donationManager.isDonated;

      // サポーターでないユーザーが、サポーター専用のテーマを使用している場合
      if (!isDonated) {
        bool needsReset = false;

        // デフォルト以外のテーマを使用している場合
        if (currentTheme != 'pink') {
          await SettingsPersistence.saveTheme('pink');
          needsReset = true;
        }

        // デフォルト以外のフォントを使用している場合
        if (currentFont != 'nunito') {
          await SettingsPersistence.saveFont('nunito');
          needsReset = true;
        }

        if (needsReset) {
          debugPrint('サポーターでないユーザーのため、テーマとフォントをデフォルトにリセットしました');
        }
      }
    } catch (e) {
      debugPrint('テーマ・フォントリセットエラー: $e');
    }
  }

  // ユーザー情報を取得
  String? get userDisplayName => _user?.displayName;
  String? get userEmail => _user?.email;
  String? get userPhotoURL => _user?.photoURL;
  String get userId => _user?.uid ?? '';
}
