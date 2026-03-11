import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/widgets/common_dialog.dart';
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
    return CommonDialog.show(
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

    return CommonDialog(
      title: isIncomplete ? '未完了アイテムを一括削除' : '完了済みアイテムを一括削除',
      content: Text(
        '${itemsToDelete.length}個のアイテムを削除しますか？\nこの操作は取り消せません。',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        CommonDialog.cancelButton(context),
        CommonDialog.destructiveButton(
          context,
          label: '削除',
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
              showErrorSnackBar(context, e);
            }
          },
        ),
      ],
    );
  }
}
