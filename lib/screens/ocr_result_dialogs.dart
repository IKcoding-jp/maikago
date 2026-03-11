import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/utils/dialog_utils.dart';

/// 既存商品を選択するダイアログを表示
///
/// [currentShop] のアイテム一覧から選択し、選択された [ListItem] を返す。
Future<ListItem?> showSelectExistingItemDialog(
  BuildContext context, {
  required Shop currentShop,
}) {
  return showConstrainedDialog<ListItem>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);

      return SimpleDialog(
        title: const Text('既存商品を選択'),
        children: [
          if (currentShop.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('既存の商品がありません'),
            ),
          ...currentShop.items.map((item) {
            return SimpleDialogOption(
              onPressed: () => context.pop(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                            fontSize: theme.textTheme.bodyLarge?.fontSize),
                      ),
                    ),
                    Text(
                      '\u00a5${item.price}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    },
  );
}
