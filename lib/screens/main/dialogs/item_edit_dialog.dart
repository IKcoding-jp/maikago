import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:go_router/go_router.dart';

/// アイテム追加/編集ダイアログ
class ItemEditDialog extends StatefulWidget {
  const ItemEditDialog({
    super.key,
    this.original,
    required this.shop,
    this.onItemSaved,
  });

  final ListItem? original;
  final Shop shop;
  final Future<void> Function()? onItemSaved;

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context, {
    ListItem? original,
    required Shop shop,
    Future<void> Function()? onItemSaved,
  }) {
    return showConstrainedDialog<void>(
      context: context,
      builder: (context) => ItemEditDialog(
        original: original,
        shop: shop,
        onItemSaved: onItemSaved,
      ),
    );
  }

  @override
  State<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  late final TextEditingController nameController;
  late final TextEditingController qtyController;
  late final TextEditingController priceController;
  late final TextEditingController discountController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.original?.name ?? '');
    qtyController = TextEditingController(
      text: widget.original?.quantity.toString() ?? '1',
    );
    priceController = TextEditingController(
      text: widget.original?.price.toString() ?? '',
    );
    discountController = TextEditingController(
      text: ((widget.original?.discount ?? 0.0) * 100).round().toString(),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    discountController.dispose();
    super.dispose();
  }

  int _calculateTotal() {
    final price = int.tryParse(priceController.text) ?? 0;
    final qty = int.tryParse(qtyController.text) ?? 1;
    final discountPercent = int.tryParse(discountController.text) ?? 0;
    return (price * qty * (1 - discountPercent / 100.0)).round();
  }

  Future<void> _handleSave() async {
    final name = nameController.text.trim();
    final qty = int.tryParse(qtyController.text) ?? 1;
    final price = int.tryParse(priceController.text) ?? 0;
    final discount = (int.tryParse(discountController.text) ?? 0) / 100.0;
    if (name.isEmpty) return;

    final dataProvider = context.read<DataProvider>();

    try {
      if (widget.original == null) {
        // 新規追加
        final isAutoCompleteEnabled =
            await SettingsPersistence.loadAutoComplete();
        final shouldAutoComplete = isAutoCompleteEnabled && price > 0;

        final newItem = ListItem(
          id: '',
          name: name,
          quantity: qty,
          price: price,
          discount: discount,
          shopId: widget.shop.id,
          isChecked: shouldAutoComplete,
        );

        await dataProvider.addItem(newItem);
      } else {
        // 編集
        final isAutoCompleteEnabled =
            await SettingsPersistence.loadAutoComplete();
        final shouldAutoCompleteOnEdit =
            isAutoCompleteEnabled && (price > 0) && !widget.original!.isChecked;

        final updatedItem = widget.original!.copyWith(
          name: name,
          quantity: qty,
          price: price,
          discount: discount,
          isChecked:
              shouldAutoCompleteOnEdit ? true : widget.original!.isChecked,
        );

        await dataProvider.updateItem(updatedItem);
      }

      if (!mounted) return;

      // コールバックを呼び出し（広告表示などのため）
      await widget.onItemSaved?.call();

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        widget.original == null ? 'リストを追加' : 'リスト編集',
        style: TextStyle(fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // アイテム名入力欄
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'アイテム名',
                  border: const OutlineInputBorder(),
                  hintText: 'アイテム名を入力してください',
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              // 個数入力欄
              TextField(
                controller: qtyController,
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
                  _noLeadingZeroFormatter(),
                ],
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // 単価入力欄
              TextField(
                controller: priceController,
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
                  _noLeadingZeroFormatter(),
                ],
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // 割引率入力欄
              TextField(
                controller: discountController,
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
                  _noLeadingZeroFormatter(),
                ],
                onChanged: (value) => setState(() {}),
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
                      '¥${_calculateTotal()}',
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
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : null,
          ),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
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

  /// 先頭ゼロを許可しないフォーマッター
  TextInputFormatter _noLeadingZeroFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      if (newValue.text.isEmpty) return newValue;
      if (newValue.text.startsWith('0') && newValue.text.length > 1) {
        return TextEditingValue(
          text: newValue.text.substring(1),
          selection: TextSelection.collapsed(
            offset: newValue.text.length - 1,
          ),
        );
      }
      return newValue;
    });
  }
}
