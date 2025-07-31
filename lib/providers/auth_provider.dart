import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true; // 初期化中はtrueに変更
  bool _isSkipped = false; // スキップ状態を追加
  static const String _skipKey = 'auth_skipped'; // 永続化用のキー

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isSkipped => _isSkipped; // スキップ状態のgetterを追加
  bool get canUseApp => isLoggedIn || isSkipped; // アプリ使用可能状態を追加

  AuthProvider() {
    _init();
  }

  void _init() async {
    try {
      // 初期ユーザー状態を設定
      _user = _authService.currentUser;

      // 永続化されたスキップ状態を読み込み
      await _loadSkipState();

      // 認証状態の変更を監視
      _authService.authStateChanges.listen((User? user) {
        _user = user;
        // ユーザーがログインした場合、スキップ状態をリセット
        if (user != null) {
          _isSkipped = false;
          _saveSkipState(false);
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

  // 永続化されたスキップ状態を読み込み
  Future<void> _loadSkipState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSkipped = prefs.getBool(_skipKey) ?? false;
    } catch (e) {
      debugPrint('スキップ状態の読み込みエラー: $e');
    }
  }

  // スキップ状態を永続化
  Future<void> _saveSkipState(bool isSkipped) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_skipKey, isSkipped);
    } catch (e) {
      debugPrint('スキップ状態の保存エラー: $e');
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

  // スキップ機能を追加
  void skipLogin() {
    _isSkipped = true;
    _saveSkipState(true);
    notifyListeners();
  }

  // スキップ状態をリセット（ログアウト時など）
  void resetSkipState() {
    _isSkipped = false;
    _saveSkipState(false);
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      // ログアウト時にスキップ状態もリセット
      _isSkipped = false;
      _saveSkipState(false);
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

  // ユーザー情報を取得
  String? get userDisplayName => _user?.displayName;
  String? get userEmail => _user?.email;
  String? get userPhotoURL => _user?.photoURL;
  String get userId => _user?.uid ?? '';
}
