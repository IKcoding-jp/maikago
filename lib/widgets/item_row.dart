import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemRow extends StatelessWidget {
  final Item item;
  final ValueChanged<bool> onCheckToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEdit;

  const ItemRow({
    super.key,
    required this.item,
    required this.onCheckToggle,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
  });

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイテム情報の表示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_bag,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.visible,
                            maxLines: 3,
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          if (item.discount > 0)
                            Text(
                              '×${item.quantity} | ¥${(item.price * (1 - item.discount)).round()}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Text(
                              '×${item.quantity} | ¥${item.price}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // アクションボタン
              if (showEdit && onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('編集'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('削除'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('削除の確認'),
          content: Text(
            '「${item.name}」を削除しますか？',
            overflow: TextOverflow.visible,
            maxLines: 3,
            softWrap: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete!();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: item.isChecked,
              onChanged: (v) => onCheckToggle(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.isChecked
                          ? Colors.grey
                          : colorScheme.onSurface,
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.visible,
                    maxLines: 3,
                    softWrap: true,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '×${item.quantity}',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      const SizedBox(width: 8),
                      if (item.discount > 0)
                        Text(
                          '¥${(item.price * (1 - item.discount)).round()}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          '¥${item.price}',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // 三点ボタンで編集・削除
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () => _showActionSheet(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
