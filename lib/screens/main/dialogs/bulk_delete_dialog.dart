import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/models/shop.dart';
import 'package:go_router/go_router.dart';

/// 一括削除ダイアログ
class BulkDeleteDialog extends StatelessWidget {
  const BulkDeleteDialog({
    super.key,
    required this.shop,
    required this.isIncomplete,
    this.onDeleted,
  });

  final Shop shop;
  final bool isIncomplete;
  final Future<void> Function()? onDeleted;

  static Future<void> show(
    BuildContext context, {
    required Shop shop,
    required bool isIncomplete,
    Future<void> Function()? onDeleted,
  }) {
    return showConstrainedDialog<void>(
      context: context,
      builder: (context) => BulkDeleteDialog(
        shop: shop,
        isIncomplete: isIncomplete,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsToDelete = isIncomplete
        ? shop.items.where((item) => !item.isChecked).toList()
        : shop.items.where((item) => item.isChecked).toList();

    return AlertDialog(
      title: Text(
        isIncomplete ? '未完了アイテムを一括削除' : '完了済みアイテムを一括削除',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Text(
        '${itemsToDelete.length}個のアイテムを削除しますか？\nこの操作は取り消せません。',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () async {
            context.pop();

            try {
              final dataProvider = context.read<DataProvider>();
              final itemIds = itemsToDelete.map((item) => item.id).toList();
              await dataProvider.deleteItems(itemIds);

              if (onDeleted != null) {
                await onDeleted!();
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('削除'),
        ),
      ],
    );
  }
}
