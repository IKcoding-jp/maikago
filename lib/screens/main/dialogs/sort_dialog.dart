import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:go_router/go_router.dart';

/// 並び替えダイアログ
class SortDialog extends StatelessWidget {
  const SortDialog({
    super.key,
    required this.shop,
    required this.isIncomplete,
    this.onSortChanged,
  });

  final Shop shop;
  final bool isIncomplete;
  final VoidCallback? onSortChanged;

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context, {
    required Shop shop,
    required bool isIncomplete,
    VoidCallback? onSortChanged,
  }) {
    return showConstrainedDialog<void>(
      context: context,
      builder: (context) => SortDialog(
        shop: shop,
        isIncomplete: isIncomplete,
        onSortChanged: onSortChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.read<DataProvider>();
    if (dataProvider.shops.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = isIncomplete ? shop.incSortMode : shop.comSortMode;

    return AlertDialog(
      title: Text('並び替え', style: Theme.of(context).textTheme.titleLarge),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: SortMode.values.map((mode) {
            return ListTile(
              title: Text(mode.label),
              trailing: mode == current ? const Icon(Icons.check) : null,
              enabled: mode != current,
              onTap: mode == current
                  ? null
                  : () async {
                      final updatedShop = shop.copyWith(
                        incSortMode: isIncomplete ? mode : shop.incSortMode,
                        comSortMode: isIncomplete ? shop.comSortMode : mode,
                      );

                      DebugService().log(
                          '🔧 ソートモード変更: ${isIncomplete ? "未購入" : "購入済み"} = ${mode.label}');

                      await dataProvider.updateShop(updatedShop);

                      if (!context.mounted) return;
                      context.pop();

                      // コールバックを呼び出し（広告表示やUI更新のため）
                      onSortChanged?.call();
                    },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text('閉じる', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
