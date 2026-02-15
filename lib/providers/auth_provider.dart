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
  AuthProvider() {
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
  final OneTimePurchaseService _purchaseService = OneTimePurchaseService();
  final FeatureAccessControl _featureControl = FeatureAccessControl();
  final DonationService _donationService = DonationService();
  // PaymentServiceは削除されました
  User? _user;

  /// 画面表示制御用のローディングフラグ（初期化完了まで true）
  bool _isLoading = true; // 初期化中はtrueに変更

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get canUseApp => _user != null; // ログイン必須に変更

  /// 認証状態の初期化と監視登録
  Future<void> _init() async {
    try {
      DebugService().log('🔐 AuthProvider初期化開始');

      // Firebaseが初期化されているか確認
      // WebプラットフォームではFirebase.appsにアクセスするだけで例外が発生する可能性がある
      bool isFirebaseInitialized = false;
      try {
        isFirebaseInitialized = Firebase.apps.isNotEmpty;
      } catch (e) {
        // Firebase.appsにアクセスできない場合は初期化されていないと判断
        // Webプラットフォームでは特に例外が発生しやすい
        if (kIsWeb) {
          DebugService().log('⚠️ Firebase初期化確認エラー（Web）: $e。ローカルモードで動作します。');
        } else {
          DebugService().log('⚠️ Firebase初期化確認エラー: $e。ローカルモードで動作します。');
        }
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (!isFirebaseInitialized) {
        if (kIsWeb) {
          DebugService().log('⚠️ Firebaseが初期化されていません（Web）。ローカルモードで動作します。');
        } else {
          DebugService().log('⚠️ Firebaseが初期化されていません。ローカルモードで動作します。');
        }
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 初期ユーザー状態を設定（Firebase未初期化時はnullを返す）
      try {
        _user = _authService.currentUser;
        DebugService().log('👤 初期ユーザー: ${_user?.uid ?? "未ログイン"}');
        DebugService().log('🔐 ログイン状態: ${_user != null ? "ログイン済み" : "未ログイン"}');
      } catch (e) {
        DebugService().log('❌ 初期ユーザー取得エラー: $e');
        _user = null;
      }

      // 初期ユーザーIDをSubscriptionServiceに設定
      try {
        if (_user?.uid != null) {
          unawaited(_purchaseService.initialize(userId: _user!.uid));
          // DonationServiceに初期ユーザーIDを通知
          _donationService.handleAccountSwitch(_user!.uid);
        } else {
          // 未ログイン時は空のユーザーIDを通知
          _donationService.handleAccountSwitch('');
        }
        _featureControl.initialize(_purchaseService);
        // PaymentServiceは削除されました
        DebugService().log('✅ サービス初期化完了');
      } catch (e) {
        DebugService().log('❌ サービス初期化エラー: $e');
        // サービス初期化に失敗しても認証は継続する
      }

      // 認証状態の変更を監視（Firebase未初期化時はスキップ）
      try {
        _authService.authStateChanges.listen((User? user) async {
          DebugService().log('🔄 認証状態変更: ${user?.uid ?? "未ログイン"}');
          DebugService().log('🔐 ログイン状態変更: ${user != null ? "ログイン済み" : "未ログイン"}');
          _user = user;

          try {
            // ユーザーIDの変更をOneTimePurchaseServiceに通知
            if (user?.uid != null) {
              unawaited(_purchaseService.initialize(userId: user!.uid));
              // DonationServiceに新しいユーザーIDを通知（アカウント切り替え処理）
              _donationService.handleAccountSwitch(user.uid);
            } else {
              // ログアウト時は空のユーザーIDを通知
              _donationService.handleAccountSwitch('');
            }
            // PaymentServiceは削除されました
          } catch (e) {
            DebugService().log('❌ 認証状態変更時のサービス更新エラー: $e');
          }

          notifyListeners();
        }, onError: (error) {
          DebugService().log('❌ 認証状態監視エラー: $error');
          // エラーが発生してもアプリは継続する
        });
      } catch (e) {
        DebugService().log('❌ 認証状態監視の設定エラー: $e');
        // Firebase未初期化時は監視をスキップ
      }
    } catch (e) {
      DebugService().log('❌ AuthProvider初期化エラー: $e');
      // Firebase初期化に失敗した場合はローカルモードで動作
      DebugService().log('⚠️ ローカルモードで認証を初期化します');
      _user = null;
    } finally {
      // 初期化完了
      _isLoading = false;
      notifyListeners();
      DebugService().log('✅ AuthProvider初期化完了');
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
