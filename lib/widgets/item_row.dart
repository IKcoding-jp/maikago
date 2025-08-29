import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class ItemRow extends StatefulWidget {
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

  @override
  State<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<ItemRow> {
  bool? _strikethroughEnabled;

  @override
  void initState() {
    super.initState();
    _loadStrikethroughSetting();
  }

  @override
  void dispose() {
    // ウィジェットが破棄される際の処理
    super.dispose();
  }

  /// 取り消し線設定を読み込み
  Future<void> _loadStrikethroughSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('strikethrough_on_completed_items') ?? false;
    if (mounted) {
      setState(() {
        _strikethroughEnabled = enabled;
      });
    }
  }

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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
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
                            widget.item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.visible,
                            maxLines: null, // 行数制限を削除して商品名の長さに応じて自動調整
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          if (widget.item.discount > 0)
                            Wrap(
                              spacing: 8,
                              children: [
                                Text(
                                  '¥${widget.item.price}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  '¥${(widget.item.price * (1 - widget.item.discount)).round()}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '| ×${widget.item.quantity}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '¥${widget.item.price} | ×${widget.item.quantity}',
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
              if (widget.showEdit && widget.onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('編集'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit!();
                  },
                ),
              if (widget.onDelete != null)
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
            '「${widget.item.name}」を削除しますか？',
            overflow: TextOverflow.visible,
            maxLines: null, // 行数制限を削除して商品名の長さに応じて自動調整
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
                widget.onDelete!();
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

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        elevation: 2,
        color: theme.brightness == Brightness.dark
            ? colorScheme.primary
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onCheckToggle(!widget.item.isChecked),
          onLongPress: () => _showActionSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            widget.item.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (widget.item.isChecked &&
                                      _strikethroughEnabled == true)
                                  ? Colors.grey
                                  : colorScheme.onSurface,
                              decoration: (widget.item.isChecked &&
                                      _strikethroughEnabled == true)
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            overflow: TextOverflow.visible,
                            maxLines: null, // 行数制限を削除して商品名の長さに応じて自動調整
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (widget.item.discount > 0) ...[
                                Text(
                                  '¥${widget.item.price}',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  '¥${(widget.item.price * (1 - widget.item.discount)).round()}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else
                                Text(
                                  '¥${widget.item.price}',
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                              Text(
                                '×${widget.item.quantity}',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // RepaintBoundary終了
    );
  }
}
