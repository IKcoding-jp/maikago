import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

/// アイテム編集ダイアログ
class _ItemEditDialog extends StatefulWidget {
  final Item item;
  final Function(Item)? onUpdate;
  final VoidCallback? onDelete;

  const _ItemEditDialog({
    required this.item,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<_ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<_ItemEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  late String _name;
  late int _quantity;
  late int _price;
  late double _discount;

  @override
  void initState() {
    super.initState();
    _name = widget.item.name;
    _quantity = widget.item.quantity;
    _price = widget.item.price;
    _discount = widget.item.discount;

    _nameController = TextEditingController(text: _name);
    _quantityController = TextEditingController(text: _quantity.toString());
    _priceController = TextEditingController(text: _price.toString());
    _discountController =
        TextEditingController(text: (_discount * 100).round().toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _updateQuantity(String value) {
    final newQuantity = int.tryParse(value) ?? 1;
    if (newQuantity >= 1 && newQuantity <= 999) {
      setState(() {
        _quantity = newQuantity;
      });
    }
  }

  void _updatePrice(String value) {
    final newPrice = int.tryParse(value) ?? 0;
    if (newPrice >= 0 && newPrice <= 999999) {
      setState(() {
        _price = newPrice;
      });
    }
  }

  void _updateDiscount(String value) {
    final newDiscount = int.tryParse(value) ?? 0;
    if (newDiscount >= 0 && newDiscount <= 100) {
      setState(() {
        _discount = newDiscount / 100;
      });
    }
  }

  void _updateName(String value) {
    setState(() {
      _name = value;
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('削除の確認'),
          content: Text(
            '「$_name」を削除しますか？',
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
                Navigator.pop(context); // 削除確認ダイアログを閉じる
                Navigator.pop(context); // 編集ダイアログを閉じる
                widget.onDelete?.call();
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
    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アイテム編集',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'アイテム名',
              border: OutlineInputBorder(),
              hintText: 'アイテム名を入力してください',
            ),
            onChanged: _updateName,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 個数入力欄
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '個数',
                border: OutlineInputBorder(),
                hintText: '1',
              ),
              onChanged: _updateQuantity,
            ),
            const SizedBox(height: 16),
            // 単価入力欄
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '単価 (円)',
                border: OutlineInputBorder(),
                hintText: '0',
                prefixText: '¥',
              ),
              onChanged: _updatePrice,
            ),
            const SizedBox(height: 16),
            // 割引率入力欄
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '割引率 (%)',
                border: OutlineInputBorder(),
                hintText: '0',
                suffixText: '%',
              ),
              onChanged: _updateDiscount,
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
                    '¥${(_price * _quantity * (1 - _discount)).round()}',
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
            _showDeleteConfirmation(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('削除'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // 更新されたアイテムを作成
            final updatedItem = widget.item.copyWith(
              name: _name.trim(),
              quantity: _quantity,
              price: _price,
              discount: _discount,
            );
            // 更新処理を実行
            widget.onUpdate?.call(updatedItem);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class ListEdit extends StatefulWidget {
  final Item item;
  final ValueChanged<bool> onCheckToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final Function(Item)? onUpdate;
  final bool showEdit;

  const ListEdit({
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
  State<ListEdit> createState() => _ListEditState();
}

class _ListEditState extends State<ListEdit> {
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ItemEditDialog(
          item: widget.item,
          onUpdate: widget.onUpdate,
          onDelete: widget.onDelete,
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
              color: widget.item.isChecked
                  ? colorScheme.tertiary.withValues(alpha: 0.8) // 未購入に戻す色
                  : colorScheme.primary.withValues(alpha: 0.8), // 購入済みに移動する色
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Icon(
              widget.item.isChecked ? Icons.undo : Icons.check,
              color: colorScheme.onPrimary,
              size: 28,
            ),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: widget.item.isChecked
                  ? colorScheme.tertiary.withValues(alpha: 0.8) // 未購入に戻す色
                  : colorScheme.primary.withValues(alpha: 0.8), // 購入済みに移動する色
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              widget.item.isChecked ? Icons.undo : Icons.check,
              color: colorScheme.onPrimary,
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
