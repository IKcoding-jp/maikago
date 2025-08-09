// Google ログインのUIとハンドリングを提供
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../drawer/settings/settings_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  /// Googleでのサインイン処理。成功時に `onLoginSuccess` をコール。
  Future<void> _signInWithGoogle() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential == 'success') {
        widget.onLoginSuccess();
      } else if (userCredential == null) {
        // ユーザーがサインインをキャンセルした場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログインがキャンセルされました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // その他のエラー（エラーコードが返された場合）
        // エラーハンドリングは既にcatch文で処理されているため、
        // ここでは何もしない
      }
    } catch (e) {
      if (!mounted) return;

      // デバッグ情報を出力
      debugPrint('=== ログインエラー詳細 ===');
      debugPrint('エラー内容: $e');
      debugPrint('エラータイプ: ${e.runtimeType}');

      String errorMessage = 'ログインエラーが発生しました';
      String detailedError = '';

      if (e.toString().contains('network_error')) {
        errorMessage = 'ネットワークエラーです。インターネット接続を確認してください。';
        detailedError = 'ネットワーク接続に問題があります。';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'ログインがキャンセルされました';
        detailedError = 'ユーザーがログインをキャンセルしました。';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'ログインに失敗しました。設定を確認してください。';
        detailedError =
            'Google Sign-Inの設定に問題があります。\n\n確認事項:\n1. Firebase ConsoleでGoogle認証が有効か\n2. Google Cloud ConsoleでOAuth 2.0クライアントIDが正しく設定されているか\n3. SHA-1証明書フィンガープリントが正しいか\n4. パッケージ名が一致しているか\n5. OAuth同意画面でテストユーザーが追加されているか';
      } else if (e.toString().contains('invalid_account')) {
        errorMessage = '無効なアカウントです。別のGoogleアカウントをお試しください。';
        detailedError = '使用しているGoogleアカウントが無効です。';
      } else if (e.toString().contains('permission_denied')) {
        errorMessage = '権限が拒否されました。Googleアカウントの設定を確認してください。';
        detailedError = 'Googleアカウントの権限設定に問題があります。';
      } else if (e.toString().contains('ID Tokenが取得できませんでした')) {
        errorMessage = '認証トークンの取得に失敗しました。OAuth同意画面の設定を確認してください。';
        detailedError =
            'OAuth同意画面の設定に問題があります。\n\n確認事項:\n1. Google Cloud Console > OAuth同意画面でテストユーザーが追加されているか\n2. アプリの状態が適切に設定されているか';
      } else {
        detailedError = '予期しないエラーが発生しました。\n\nエラー詳細: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '詳細',
            textColor: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('エラー詳細'),
                  content: SingleChildScrollView(child: Text(detailedError)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withAlpha(25),
              AppColors.secondary.withAlpha(25),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // アプリロゴ・アイコン
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(76),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_basket_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // アプリタイトル
                  Text(
                    'まいカゴ',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // サブタイトル
                  Text(
                    'お買い物リストをクラウドで管理',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // ログインボタン
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/images/google_logo.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.login,
                                  color: Colors.white,
                                  size: 24,
                                );
                              },
                            ),
                      label: Text(
                        _isLoading ? 'ログイン中...' : 'Googleアカウントでログイン',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withAlpha(76),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 説明テキスト
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(204),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary.withAlpha(76),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_sync,
                          color: AppColors.secondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ログインすると、お買い物リストが\nクラウドに自動保存されます',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
