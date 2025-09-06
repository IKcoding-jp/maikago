import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント管理'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authProvider.isLoggedIn) {
            return _buildUserProfile(context, authProvider);
          } else {
            return _buildLoginSection(context);
          }
        },
      ),
    );
  }

  Widget _buildLoginSection(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: MediaQuery.of(context).padding.bottom + 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.account_circle_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Googleアカウントでログイン',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ログインすると、お買い物リストが\nクラウドに自動保存されます',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (255 * 0.7).round(),
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Googleでログイン'),
                onPressed: () => _handleGoogleSignIn(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: MediaQuery.of(context).padding.bottom + 24.0,
      ),
      child: Column(
        children: [
          // ユーザー情報セクション
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withAlpha(
                    (255 * 0.1).round(),
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: authProvider.userPhotoURL != null
                      ? NetworkImage(authProvider.userPhotoURL!)
                      : null,
                  backgroundColor: theme.colorScheme.primary,
                  child: authProvider.userPhotoURL == null
                      ? Icon(
                          Icons.account_circle_rounded,
                          size: 80,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.userDisplayName ?? 'ユーザー',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.userEmail ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(
                      (255 * 0.7).round(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 同期状態セクション
          Consumer<DataProvider>(
            builder: (context, dataProvider, _) {
              final isSynced = dataProvider.isSynced;
              final statusColor = isSynced ? Colors.green : Colors.orange;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withAlpha((255 * 0.3).round()),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSynced ? Icons.cloud_done : Icons.cloud_off,
                      color: statusColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSynced ? 'クラウド同期済み' : 'クラウド未同期',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            isSynced ? 'データは安全に保存されています' : 'ログインしてデータを同期してください',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(
                                (255 * 0.7).round(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Spacer(),

          // ログアウトボタン
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('ログアウト'),
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final success = await context.read<AuthProvider>().signInWithGoogle();
      if (success && context.mounted) {
        // ログイン成功時にデータを読み込み
        await context.read<DataProvider>().loadData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログインしました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインエラー: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？\nローカルデータは保持されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // データをクリア
        context.read<DataProvider>().clearData();
        // ログアウト
        await context.read<AuthProvider>().signOut();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログアウトしました'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ログアウトエラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
