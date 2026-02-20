import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/models/shop.dart';
import 'package:go_router/go_router.dart';

/// タブ追加ダイアログ
class TabAddDialog extends StatefulWidget {
  const TabAddDialog({
    super.key,
    required this.nextShopId,
    this.onAdded,
  });

  final String nextShopId;
  final Future<void> Function(String newNextShopId)? onAdded;

  @override
  State<TabAddDialog> createState() => _TabAddDialogState();

  static Future<void> show(
    BuildContext context, {
    required String nextShopId,
    Future<void> Function(String newNextShopId)? onAdded,
  }) {
    return showConstrainedDialog<void>(
      context: context,
      builder: (context) => TabAddDialog(
        nextShopId: nextShopId,
        onAdded: onAdded,
      ),
    );
  }
}

class _TabAddDialogState extends State<TabAddDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    final newShop = Shop(id: widget.nextShopId, name: name, items: []);
    final newNextShopId = (int.parse(widget.nextShopId) + 1).toString();

    try {
      await context.read<DataProvider>().addShop(newShop);

      if (widget.onAdded != null) {
        await widget.onAdded!(newNextShopId);
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.pop();
      if (!mounted) return;
      unawaited(showConstrainedDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '新しいタブを追加',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'タブ名',
              labelStyle: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'キャンセル',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        ElevatedButton(
          onPressed: _handleAdd,
          child: Text('追加', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
