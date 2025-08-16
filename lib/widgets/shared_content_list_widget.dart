import 'package:flutter/material.dart';
import '../models/shared_content.dart';

/// 共有コンテンツリストの種類
enum SharedContentListType {
  shared, // 共有したもの
  received, // 共有されたもの
}

/// 共有コンテンツリストを表示するウィジェット
class SharedContentListWidget extends StatelessWidget {
  final List<SharedContent> contents;
  final SharedContentListType type;
  final Function(String) onRemoveContent;

  const SharedContentListWidget({
    super.key,
    required this.contents,
    required this.type,
    required this.onRemoveContent,
  });

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == SharedContentListType.shared ? Icons.share : Icons.inbox,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              type == SharedContentListType.shared
                  ? '共有したコンテンツがありません'
                  : '共有されたコンテンツがありません',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        return _buildContentCard(context, contents[index]);
      },
    );
  }

  Widget _buildContentCard(BuildContext context, SharedContent content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == SharedContentListType.shared
              ? Colors.blue.shade100
              : Colors.green.shade100,
          child: Icon(
            type == SharedContentListType.shared ? Icons.share : Icons.inbox,
            color: type == SharedContentListType.shared
                ? Colors.blue
                : Colors.green,
          ),
        ),
        title: Text(
          content.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.description.isNotEmpty) Text(content.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  content.type == SharedContentType.list
                      ? Icons.list
                      : Icons.tab,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  content.type.displayName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  type == SharedContentListType.shared
                      ? '${content.sharedWith.length}人に共有'
                      : content.sharedByName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '共有日: ${_formatDate(content.sharedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: type == SharedContentListType.shared
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => onRemoveContent(content.id),
                tooltip: '共有を削除',
              )
            : null,
        onTap: () {
          // TODO: 共有コンテンツの詳細表示
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${content.title}の詳細を表示')));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
