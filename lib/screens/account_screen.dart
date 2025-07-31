import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/donation_manager.dart';

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
          } else if (authProvider.isSkipped) {
            return _buildSkippedSection(context);
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
        padding: const EdgeInsets.all(24.0),
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

  Widget _buildSkippedSection(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 64,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ローカルモード',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ログインせずにアプリを使用中\nデータはローカルにのみ保存されます',
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('ログイン画面に戻る'),
                onPressed: () => _handleResetToLogin(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[400]!),
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // ユーザー情報セクション
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
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
            child: Consumer<DonationManager>(
              builder: (context, donationManager, _) {
                return Column(
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
                    // 寄付者称号の表示
                    if (donationManager.isDonated &&
                        donationManager.donorTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: donationManager.donorTitleColor.withAlpha(
                              (255 * 0.1).round(),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: donationManager.donorTitleColor.withAlpha(
                                (255 * 0.3).round(),
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                donationManager.donorTitleIcon,
                                size: 16,
                                color: donationManager.donorTitleColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                donationManager.donorTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: donationManager.donorTitleColor,
                                ),
                              ),
                            ],
                          ),
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
                );
              },
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
                  color: theme.colorScheme.surface,
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

          // デバッグ用の寄付状態テストボタン（開発時のみ表示）
          if (kDebugMode)
            Consumer<DonationManager>(
              builder: (context, donationManager, _) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      // 現在の寄付状態表示
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withAlpha(100)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'デバッグ情報',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '寄付状態: ${donationManager.isDonated ? "有効" : "無効"}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '総寄付金額: ¥${donationManager.totalDonationAmount}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '称号: ${donationManager.donorTitle.isEmpty ? "なし" : donationManager.donorTitle}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // テストボタン
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _handleTestDonation(context, 300),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('¥300寄付'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _handleTestDonation(context, 1000),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('¥1000寄付'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _handleTestDonation(context, 10000),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('¥10000寄付'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () => _handleResetDonation(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('リセット'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () => _handleEnableDonation(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('強制有効化'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          // 寄付特典の復元ボタン
          Consumer<DonationManager>(
            builder: (context, donationManager, _) {
              if (!donationManager.isDonated) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('寄付特典を復元'),
                      onPressed: donationManager.isRestoring
                          ? null
                          : () => _handleRestoreDonation(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

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
            SnackBar(
              content: const Text('ログインしました'),
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

  void _handleResetToLogin(BuildContext context) {
    // スキップ状態をリセットしてログイン画面に戻る
    context.read<AuthProvider>().resetSkipState();
  }

  Future<void> _handleRestoreDonation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('寄付特典を復元'),
        content: const Text('寄付特典を復元しますか？\nアプリの再起動が必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('復元'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<DonationManager>().restoreDonationStatus();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('寄付特典を復元しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('寄付特典復元エラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<void> _handleTestDonation(BuildContext context, int amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('寄付を追加'),
        content: Text('${amount}円の寄付を追加しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<DonationManager>().addDonation(amount);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${amount}円の寄付を追加しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('寄付追加エラー: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleResetDonation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('寄付状態をリセット'),
        content: const Text('寄付状態をリセットしますか？\nアプリの再起動が必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセット'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<DonationManager>().resetDonationStatus();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('寄付状態をリセットしました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('寄付状態リセットエラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEnableDonation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('寄付状態を強制有効化'),
        content: const Text('寄付状態を強制有効化しますか？\nアプリの再起動が必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('有効化'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<DonationManager>().forceEnableDonation();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('寄付状態を強制有効化しました'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('寄付状態強制有効化エラー: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
