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
    String selectedField = 'price'; // 選択中の項目（単価をデフォルトに）

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
                height:
                    MediaQuery.of(context).size.height * 0.7, // 画面の70%の高さに制限
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 入力欄を上に配置
                      _buildInputFields(
                          quantity, price, discount, selectedField, (field) {
                        setState(() {
                          selectedField = field;
                        });
                      }),
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
                      const SizedBox(height: 16),
                      // 一つの数字キーボード
                      _buildNumberKeyboard(
                          selectedField, quantity, price, discount, setState,
                          (q, p, d) {
                        setState(() {
                          quantity = q;
                          price = p;
                          discount = d;
                        });
                      }),
                    ],
                  ),
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

  Widget _buildInputFields(int quantity, int price, double discount,
      String selectedField, Function(String) onFieldSelected) {
    return Column(
      children: [
        // 個数入力欄
        _buildInputField(
          '個数',
          quantity.toString(),
          selectedField == 'quantity',
          () => onFieldSelected('quantity'),
        ),
        const SizedBox(height: 12),
        // 単価入力欄
        _buildInputField(
          '単価 (円)',
          price.toString(),
          selectedField == 'price',
          () => onFieldSelected('price'),
        ),
        const SizedBox(height: 12),
        // 割引率入力欄
        _buildInputField(
          '割引率 (%)',
          '${(discount * 100).round()}',
          selectedField == 'discount',
          () => onFieldSelected('discount'),
        ),
      ],
    );
  }

  Widget _buildInputField(
      String label, String value, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberKeyboard(
      String selectedField,
      int quantity,
      int price,
      double discount,
      StateSetter setState,
      Function(int, int, double) onValuesChanged) {
    return Column(
      children: [
        // 1-3行
        Row(
          children: [
            _buildNumberKey(
                '1',
                () => _handleNumberInput('1', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '2',
                () => _handleNumberInput('2', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '3',
                () => _handleNumberInput('3', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
          ],
        ),
        const SizedBox(height: 8),
        // 4-6行
        Row(
          children: [
            _buildNumberKey(
                '4',
                () => _handleNumberInput('4', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '5',
                () => _handleNumberInput('5', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '6',
                () => _handleNumberInput('6', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
          ],
        ),
        const SizedBox(height: 8),
        // 7-9行
        Row(
          children: [
            _buildNumberKey(
                '7',
                () => _handleNumberInput('7', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '8',
                () => _handleNumberInput('8', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '9',
                () => _handleNumberInput('9', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
          ],
        ),
        const SizedBox(height: 8),
        // 0と削除ボタン
        Row(
          children: [
            _buildNumberKey(
                '0',
                () => _handleNumberInput('0', selectedField, quantity, price,
                    discount, setState, onValuesChanged)),
            _buildNumberKey(
                '⌫',
                () => _handleDelete(selectedField, quantity, price, discount,
                    setState, onValuesChanged)),
            _buildNumberKey(
                'C',
                () => _handleClear(selectedField, quantity, price, discount,
                    setState, onValuesChanged)),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberKey(String text, VoidCallback onPressed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _handleNumberInput(
      String digit,
      String selectedField,
      int quantity,
      int price,
      double discount,
      StateSetter setState,
      Function(int, int, double) onValuesChanged) {
    switch (selectedField) {
      case 'quantity':
        final newQuantity = quantity * 10 + int.parse(digit);
        if (newQuantity <= 999) {
          setState(() {
            onValuesChanged(newQuantity, price, discount);
          });
        }
        break;
      case 'price':
        final newPrice = price * 10 + int.parse(digit);
        if (newPrice <= 999999) {
          setState(() {
            onValuesChanged(quantity, newPrice, discount);
          });
        }
        break;
      case 'discount':
        final currentDiscount = (discount * 100).round();
        final newDiscount = currentDiscount * 10 + int.parse(digit);
        if (newDiscount <= 100) {
          setState(() {
            onValuesChanged(quantity, price, newDiscount / 100);
          });
        }
        break;
    }
  }

  void _handleDelete(
      String selectedField,
      int quantity,
      int price,
      double discount,
      StateSetter setState,
      Function(int, int, double) onValuesChanged) {
    switch (selectedField) {
      case 'quantity':
        final newQuantity = quantity ~/ 10;
        // 個数が1桁の場合でも削除できるように、0も許可
        setState(() {
          onValuesChanged(newQuantity, price, discount);
        });
        break;
      case 'price':
        final newPrice = price ~/ 10;
        setState(() {
          onValuesChanged(quantity, newPrice < 0 ? 0 : newPrice, discount);
        });
        break;
      case 'discount':
        final currentDiscount = (discount * 100).round();
        final newDiscount = currentDiscount ~/ 10;
        setState(() {
          onValuesChanged(quantity, price, newDiscount / 100);
        });
        break;
    }
  }

  void _handleClear(
      String selectedField,
      int quantity,
      int price,
      double discount,
      StateSetter setState,
      Function(int, int, double) onValuesChanged) {
    switch (selectedField) {
      case 'quantity':
        setState(() {
          onValuesChanged(1, price, discount);
        });
        break;
      case 'price':
        setState(() {
          onValuesChanged(quantity, 0, discount);
        });
        break;
      case 'discount':
        setState(() {
          onValuesChanged(quantity, price, 0.0);
        });
        break;
    }
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('名前を変更'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onRename?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('削除'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
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
            onLongPress: () => _showActionMenu(context),
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
