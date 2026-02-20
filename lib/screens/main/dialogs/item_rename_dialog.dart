import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/models/list.dart';
import 'package:go_router/go_router.dart';

/// アイテム名前変更ダイアログ
class ItemRenameDialog extends StatefulWidget {
  const ItemRenameDialog({super.key, required this.item});

  final ListItem item;

  @override
  State<ItemRenameDialog> createState() => _ItemRenameDialogState();

  static Future<void> show(BuildContext context, ListItem item) {
    return showConstrainedDialog<void>(
      context: context,
      builder: (context) => ItemRenameDialog(item: item),
    );
  }
}

class _ItemRenameDialogState extends State<ItemRenameDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    try {
      await context.read<DataProvider>().updateItem(
            widget.item.copyWith(name: name),
          );
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
      title: const Text('名前を変更'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'アイテム名',
          hintText: '新しい名前を入力してください',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
