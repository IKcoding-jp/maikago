import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transmission_provider.dart';

/// リアルタイム通知ウィジェット
class RealtimeNotificationWidget extends StatefulWidget {
  const RealtimeNotificationWidget({super.key});

  @override
  State<RealtimeNotificationWidget> createState() =>
      _RealtimeNotificationWidgetState();
}

class _RealtimeNotificationWidgetState
    extends State<RealtimeNotificationWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransmissionProvider>(
      builder: (context, transmissionProvider, child) {
        // 初期化中は何も表示しない
        if (!transmissionProvider.isRealtimeConnected) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<bool>(
          stream: transmissionProvider.connectionStateStream,
          builder: (context, snapshot) {
            final isConnected = snapshot.data ?? false;

            return Column(
              children: [
                // 接続状態インジケーター
                if (transmissionProvider.isRealtimeConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConnected ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected ? Icons.wifi : Icons.wifi_off,
                          size: 16,
                          color: isConnected ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'リアルタイム接続中' : '接続を確認中...',
                          style: TextStyle(
                            fontSize: 12,
                            color: isConnected ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // リアルタイム受信コンテンツの通知（安全な条件チェック）
                if (transmissionProvider.realtimeReceivedContents.isNotEmpty)
                  _buildRealtimeContentNotification(transmissionProvider),

                // リアルタイム同期データの通知（安全な条件チェック）
                if (transmissionProvider.realtimeSyncDataList.isNotEmpty)
                  _buildRealtimeSyncNotification(transmissionProvider),

                // リアルタイム通知の表示（安全な条件チェック）
                if (transmissionProvider.realtimeNotifications.isNotEmpty)
                  _buildRealtimeNotifications(transmissionProvider),
              ],
            );
          },
        );
      },
    );
  }

  /// リアルタイム受信コンテンツ通知
  Widget _buildRealtimeContentNotification(
    TransmissionProvider transmissionProvider,
  ) {
    final latestContent = transmissionProvider.realtimeReceivedContents.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          '新しい共有コンテンツ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(latestContent.title, style: const TextStyle(fontSize: 12)),
            Text(
              '送信者: ${latestContent.sharedByName}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _viewContent(latestContent),
              child: const Text('確認', style: TextStyle(fontSize: 12)),
            ),
            IconButton(
              onPressed: () => _dismissNotification(''),
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// リアルタイム同期データ通知
  Widget _buildRealtimeSyncNotification(
    TransmissionProvider transmissionProvider,
  ) {
    final latestSyncData = transmissionProvider.realtimeSyncDataList.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.sync, color: Colors.green, size: 20),
        ),
        title: Text(
          '新しい同期データ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(latestSyncData.title, style: const TextStyle(fontSize: 12)),
            Text(
              '${latestSyncData.items.length}個のアイテム',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _viewSyncData(latestSyncData),
              child: const Text('確認', style: TextStyle(fontSize: 12)),
            ),
            IconButton(
              onPressed: () => _dismissNotification(''),
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// コンテンツを確認
  void _viewContent(dynamic content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${content.title}」を確認しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 同期データを確認
  void _viewSyncData(dynamic syncData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${syncData.title}」を確認しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// リアルタイム通知の表示
  Widget _buildRealtimeNotifications(
    TransmissionProvider transmissionProvider,
  ) {
    final notifications = transmissionProvider.realtimeNotifications;

    return Column(
      children: notifications.map((notification) {
        final type = notification['type'] as String? ?? '';
        final title = notification['title'] as String? ?? '';
        final sharedByName = notification['sharedByName'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type == 'new_content' ? Icons.notifications_active : Icons.sync,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              type == 'new_content' ? '新しい共有コンテンツ' : '新しい同期データ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                Text(
                  '送信者: $sharedByName',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _viewNotification(notification),
                  child: const Text('確認', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  onPressed: () =>
                      _dismissNotification(notification['id'] as String),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 通知を確認
  void _viewNotification(Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? '';

    // 通知を既読にする
    final transmissionProvider = Provider.of<TransmissionProvider>(
      context,
      listen: false,
    );
    transmissionProvider.markNotificationAsRead(notification['id'] as String);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「$title」を確認しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 通知を閉じる
  void _dismissNotification(String notificationId) {
    final transmissionProvider = Provider.of<TransmissionProvider>(
      context,
      listen: false,
    );
    transmissionProvider.deleteNotification(notificationId);
  }
}
