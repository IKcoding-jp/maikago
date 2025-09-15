// 認証状態をアプリ全体に提供する
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/subscription_integration_service.dart';
import '../services/feature_access_control.dart';
// PaymentServiceは削除されました

/// 認証状態の Provider。
/// - 初期化時に現在ユーザー/監視をセットアップ
/// - ログイン/ログアウト時のローディング制御
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SubscriptionIntegrationService _subscriptionService =
      SubscriptionIntegrationService();
  final FeatureAccessControl _featureControl = FeatureAccessControl();
  // PaymentServiceは削除されました
  User? _user;

  /// 画面表示制御用のローディングフラグ（初期化完了まで true）
  bool _isLoading = true; // 初期化中はtrueに変更

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get canUseApp => _user != null; // ログイン必須に変更

  AuthProvider() {
    _init();
  }

  /// 認証状態の初期化と監視登録
  void _init() async {
    try {
      debugPrint('🔐 AuthProvider初期化開始');

      // 初期ユーザー状態を設定
      _user = _authService.currentUser;
      debugPrint('👤 初期ユーザー: ${_user?.uid ?? "未ログイン"}');
      debugPrint('🔐 ログイン状態: ${_user != null ? "ログイン済み" : "未ログイン"}');

      // 初期ユーザーIDをSubscriptionServiceに設定
      try {
        if (_user?.uid != null) {
          _subscriptionService.setCurrentUserId(_user!.uid);
        }
        _featureControl.initialize(_subscriptionService);
        // PaymentServiceは削除されました
        debugPrint('✅ サービス初期化完了');
      } catch (e) {
        debugPrint('❌ サービス初期化エラー: $e');
        // サービス初期化に失敗しても認証は継続する
      }

      // 認証状態の変更を監視
      _authService.authStateChanges.listen((User? user) async {
        debugPrint('🔄 認証状態変更: ${user?.uid ?? "未ログイン"}');
        debugPrint('🔐 ログイン状態変更: ${user != null ? "ログイン済み" : "未ログイン"}');
        _user = user;

        try {
          // ユーザーIDの変更をSubscriptionServiceに通知
          if (user?.uid != null) {
            _subscriptionService.setCurrentUserId(user!.uid);
          }
          // PaymentServiceは削除されました
        } catch (e) {
          debugPrint('❌ 認証状態変更時のサービス更新エラー: $e');
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ AuthProvider初期化エラー: $e');
      // Firebase初期化に失敗した場合はローカルモードで動作
      debugPrint('⚠️ ローカルモードで認証を初期化します');
      _user = null;
    } finally {
      // 初期化完了
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ AuthProvider初期化完了');
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
