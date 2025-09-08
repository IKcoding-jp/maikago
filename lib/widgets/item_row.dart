import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class ItemRow extends StatefulWidget {
  final Item item;
  final ValueChanged<bool> onCheckToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final Function(Item)? onUpdate;
  final bool showEdit;

  const ItemRow({
    super.key,
    required this.item,
    required this.onCheckToggle,
    this.onEdit,
    this.onDelete,
    this.onRename,
    this.onUpdate,
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

  void _showItemInputDialog(BuildContext context) {
    int quantity = widget.item.quantity;
    int price = widget.item.price;
    double discount = widget.item.discount;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                widget.item.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 個数入力
                    _buildNumberInput(
                      '個数',
                      quantity,
                      (value) => setState(() => quantity = value),
                      min: 1,
                      max: 999,
                    ),
                    const SizedBox(height: 16),
                    // 単価入力
                    _buildNumberInput(
                      '単価 (円)',
                      price,
                      (value) => setState(() => price = value),
                      min: 0,
                      max: 999999,
                    ),
                    const SizedBox(height: 16),
                    // 割引率入力
                    _buildDiscountInput(
                      '割引率 (%)',
                      (discount * 100).round(),
                      (value) => setState(() => discount = value / 100),
                    ),
                    const SizedBox(height: 16),
                    // 合計金額表示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '合計:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '¥${(price * quantity * (1 - discount)).round()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 更新されたアイテムを作成
                    final updatedItem = widget.item.copyWith(
                      quantity: quantity,
                      price: price,
                      discount: discount,
                    );
                    // 更新処理を実行
                    widget.onUpdate?.call(updatedItem);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNumberInput(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int min = 0,
    int max = 999,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountInput(
    String label,
    int value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              onPressed: value < 100 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
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
            maxLines: null,
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
        child: Dismissible(
          key: ValueKey(widget.item.id),
          direction: DismissDirection.horizontal,
          resizeDuration: const Duration(milliseconds: 200),
          movementDuration: const Duration(milliseconds: 200),
          dismissThresholds: const {
            DismissDirection.horizontal: 0.3,
          },
          background: Container(
            decoration: BoxDecoration(
              color: widget.item.isChecked ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Icon(
              widget.item.isChecked ? Icons.undo : Icons.check,
              color: Colors.white,
              size: 28,
            ),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: widget.item.isChecked ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              widget.item.isChecked ? Icons.undo : Icons.check,
              color: Colors.white,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) async {
            // スライドでチェック状態を切り替え
            widget.onCheckToggle(!widget.item.isChecked);
            return false; // アイテムを削除しない
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showItemInputDialog(context),
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
                              maxLines: null,
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
                                  style:
                                      TextStyle(color: colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 3点メニュー
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            widget.onRename?.call();
                            break;
                          case 'delete':
                            _showDeleteConfirmation(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('名前を変更'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('削除'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
