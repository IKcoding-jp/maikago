import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'package:maikago/utils/dialog_utils.dart';

/// リスト編集ダイアログ
class _ListItemEditDialog extends StatefulWidget {
  const _ListItemEditDialog({
    required this.item,
    this.onUpdate,
    this.onDelete,
  });

  final ListItem item;
  final Function(ListItem)? onUpdate;
  final VoidCallback? onDelete;

  @override
  State<_ListItemEditDialog> createState() => _ListItemEditDialogState();
}

class _ListItemEditDialogState extends State<_ListItemEditDialog> {
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
    showConstrainedDialog(
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        'リスト編集',
        style: TextStyle(fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // アイテム名入力欄（titleから移動）
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'アイテム名',
                  border: const OutlineInputBorder(),
                  hintText: 'アイテム名を入力してください',
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  filled: true,
                ),
                onChanged: _updateName,
              ),
              const SizedBox(height: 16),
              // 個数入力欄
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '個数',
                  border: const OutlineInputBorder(),
                  hintText: '1',
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  filled: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    if (newValue.text.startsWith('0') &&
                        newValue.text.length > 1) {
                      return TextEditingValue(
                        text: newValue.text.substring(1),
                        selection: TextSelection.collapsed(
                          offset: newValue.text.length - 1,
                        ),
                      );
                    }
                    return newValue;
                  }),
                ],
                onChanged: _updateQuantity,
              ),
              const SizedBox(height: 16),
              // 単価入力欄
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '単価 (円)',
                  border: const OutlineInputBorder(),
                  hintText: '0',
                  prefixText: '¥',
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  filled: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    if (newValue.text.startsWith('0') &&
                        newValue.text.length > 1) {
                      return TextEditingValue(
                        text: newValue.text.substring(1),
                        selection: TextSelection.collapsed(
                          offset: newValue.text.length - 1,
                        ),
                      );
                    }
                    return newValue;
                  }),
                ],
                onChanged: _updatePrice,
              ),
              const SizedBox(height: 16),
              // 割引率入力欄
              TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '割引率 (%)',
                  border: const OutlineInputBorder(),
                  hintText: '0',
                  suffixText: '%',
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  filled: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    if (newValue.text.startsWith('0') &&
                        newValue.text.length > 1) {
                      return TextEditingValue(
                        text: newValue.text.substring(1),
                        selection: TextSelection.collapsed(
                          offset: newValue.text.length - 1,
                        ),
                      );
                    }
                    return newValue;
                  }),
                ],
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
                    Text(
                      '合計:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                    Text(
                      '¥${(_price * _quantity * (1 - _discount)).round()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : null,
          ),
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
            final updatedListItem = widget.item.copyWith(
              name: _name.trim(),
              quantity: _quantity,
              price: _price,
              discount: _discount,
            );
            // 更新処理を実行
            widget.onUpdate?.call(updatedListItem);
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

  final ListItem item;
  final ValueChanged<bool> onCheckToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final Function(ListItem)? onUpdate;
  final bool showEdit;

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
    final enabled = await SettingsPersistence.loadStrikethrough();
    if (mounted) {
      setState(() {
        _strikethroughEnabled = enabled;
      });
    }
  }

  void _showListItemInputDialog(BuildContext context) {
    showConstrainedDialog(
      context: context,
      builder: (BuildContext context) {
        return _ListItemEditDialog(
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            elevation: 2,
            color: theme.brightness == Brightness.dark
                ? colorScheme.primary
                : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      : colorScheme.primary
                          .withValues(alpha: 0.8), // 購入済みに移動する色
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
                      : colorScheme.primary
                          .withValues(alpha: 0.8), // 購入済みに移動する色
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
                onTap: () => _showListItemInputDialog(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.item.isRecipeOrigin)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: colorScheme.secondary,
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    (widget.item.recipeName != null &&
                                            widget.item.recipeName!.isNotEmpty)
                                        ? widget.item.recipeName!
                                        : 'レシピ由来',
                                    style: TextStyle(
                                      fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
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
                                          color:
                                              colorScheme.onSurface.withValues(
                                            alpha: 0.7,
                                          ),
                                          decoration:
                                              TextDecoration.lineThrough,
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
                                        style: TextStyle(
                                            color: colorScheme.onSurface),
                                      ),
                                    Text(
                                      '×${widget.item.quantity}',
                                      style: TextStyle(
                                          color: colorScheme.onSurface),
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
        ),
      ),
    );
  }
}
