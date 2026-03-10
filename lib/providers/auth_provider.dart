// 認証状態をアプリ全体に提供する
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:maikago/services/auth_service.dart';
import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/donation_service.dart';
import 'package:maikago/services/debug_service.dart';
// PaymentServiceは削除されました

/// 認証状態の Provider。
/// - 初期化時に現在ユーザー/監視をセットアップ
/// - ログイン/ログアウト時のローディング制御
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required OneTimePurchaseService purchaseService,
    required FeatureAccessControl featureControl,
    required DonationService donationService,
  })  : _purchaseService = purchaseService,
        _featureControl = featureControl,
        _donationService = donationService {
    // コンストラクタで非同期メソッドを呼び出す際は、例外を適切に処理する
    try {
      _init();
    } catch (e) {
      // コンストラクタでの例外をキャッチして、ローカルモードで初期化
      DebugService().log('❌ AuthProviderコンストラクタエラー: $e');
      DebugService().log('⚠️ ローカルモードで認証を初期化します');
      _user = null;
      _isLoading = false;
      // 初期化完了を通知（非同期で実行）
      Future.microtask(() => notifyListeners());
    }
  }

  final AuthService _authService = AuthService();
  final OneTimePurchaseService _purchaseService;
  final FeatureAccessControl _featureControl;
  final DonationService _donationService;
  StreamSubscription<User?>? _authStateSubscription;
  User? _user;
  bool _isGuestMode = false;

  /// ゲスト→ログイン時のデータマイグレーションコールバック（DataProviderから設定）
  Future<void> Function()? _onGuestDataMigration;

  /// 画面表示制御用のローディングフラグ（初期化完了まで true）
  bool _isLoading = true; // 初期化中はtrueに変更

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isGuestMode => _isGuestMode;
  bool get canUseApp => isLoggedIn || _isGuestMode;

  /// 認証状態の初期化と監視登録
  Future<void> _init() async {
    try {
      DebugService().log('🔐 AuthProvider初期化開始');

      if (!_checkFirebaseInitialized()) return;

      _loadCurrentUser();
      await _initializeServices();
      _startAuthStateListener();
    } catch (e) {
      DebugService().log('❌ AuthProvider初期化エラー: $e');
      DebugService().log('⚠️ ローカルモードで認証を初期化します');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      DebugService().log('✅ AuthProvider初期化完了');
    }
  }

  /// Firebaseの初期化状態を確認。未初期化の場合はローカルモードに移行。
  bool _checkFirebaseInitialized() {
    bool isFirebaseInitialized = false;
    try {
      isFirebaseInitialized = Firebase.apps.isNotEmpty;
    } catch (e) {
      const platform = kIsWeb ? '（Web）' : '';
      DebugService().log('⚠️ Firebase初期化確認エラー$platform: $e。ローカルモードで動作します。');
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (!isFirebaseInitialized) {
      const platform = kIsWeb ? '（Web）' : '';
      DebugService().log('⚠️ Firebaseが初期化されていません$platform。ローカルモードで動作します。');
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    return true;
  }

  /// 現在のユーザー状態を取得
  void _loadCurrentUser() {
    try {
      _user = _authService.currentUser;
      DebugService().log('👤 初期ユーザー: ${_user?.uid ?? "未ログイン"}');
      DebugService().log('🔐 ログイン状態: ${_user != null ? "ログイン済み" : "未ログイン"}');
    } catch (e) {
      DebugService().log('❌ 初期ユーザー取得エラー: $e');
      _user = null;
    }
  }

  /// サービス群の初期化
  Future<void> _initializeServices() async {
    try {
      _updateServicesForUser(_user);
      await _featureControl.initialize(_purchaseService);
      DebugService().log('✅ サービス初期化完了');
    } catch (e) {
      DebugService().log('❌ サービス初期化エラー: $e');
    }
  }

  /// ユーザー変更時のサービス更新
  void _updateServicesForUser(User? user) {
    if (user?.uid != null) {
      unawaited(_purchaseService.initialize(userId: user!.uid));
      _donationService.handleAccountSwitch(user.uid);
    } else {
      _donationService.handleAccountSwitch('');
    }
  }

  /// 認証状態の変更を監視
  void _startAuthStateListener() {
    try {
      _authStateSubscription = _authService.authStateChanges.listen(
        (User? user) {
          DebugService().log('🔄 認証状態変更: ${user?.uid ?? "未ログイン"}');
          DebugService().log('🔐 ログイン状態変更: ${user != null ? "ログイン済み" : "未ログイン"}');
          _user = user;

          try {
            _updateServicesForUser(user);
          } catch (e) {
            DebugService().log('❌ 認証状態変更時のサービス更新エラー: $e');
          }

          notifyListeners();
        },
        onError: (error) {
          DebugService().log('❌ 認証状態監視エラー: $error');
        },
      );
    } catch (e) {
      DebugService().log('❌ 認証状態監視の設定エラー: $e');
    }
  }

  /// ゲスト→ログイン時のデータマイグレーションコールバックを設定
  /// （DataProviderのsetAuthProviderから呼ばれる）
  void setGuestDataMigrationCallback(Future<void> Function() callback) {
    _onGuestDataMigration = callback;
  }

  /// ゲストモードに入る（ログインせずにアプリを使用）
  void enterGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  /// ゲストモードを終了する（ログイン時に呼ばれる）
  void _exitGuestMode() {
    _isGuestMode = false;
  }

  Future<String?> signInWithGoogle() async {
    _setLoading(true);

    try {
      final wasGuestMode = _isGuestMode;
      final result = await _authService.signInWithGoogle();

      // ゲストモードからのログイン時：ローカルデータをFirestoreへマイグレーション
      if (wasGuestMode && _onGuestDataMigration != null) {
        try {
          DebugService().log('🔄 ゲストデータのマイグレーション開始');
          await _onGuestDataMigration!();
          DebugService().log('✅ ゲストデータのマイグレーション完了');
        } catch (e) {
          // マイグレーション失敗してもログイン自体は成功させる
          DebugService().log('⚠️ ゲストデータのマイグレーション失敗（ログインは継続）: $e');
        }
      }

      _exitGuestMode();
      _setLoading(false);
      return result;
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

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // ユーザー情報を取得
  String? get userDisplayName => _user?.displayName;
  String? get userEmail => _user?.email;
  String? get userPhotoURL => _user?.photoURL;
  String get userId => _user?.uid ?? '';
}
