import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/shop.dart';
import '../../../models/sort_mode.dart';

/// 並び替えダイアログ
class SortDialog extends StatelessWidget {
  final Shop shop;
  final bool isIncomplete;
  final VoidCallback? onSortChanged;

  const SortDialog({
    super.key,
    required this.shop,
    required this.isIncomplete,
    this.onSortChanged,
  });

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context, {
    required Shop shop,
    required bool isIncomplete,
    VoidCallback? onSortChanged,
  }) {
    return showDialog<void>(
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
                      final navigator = Navigator.of(context);

                      final updatedShop = shop.copyWith(
                        incSortMode: isIncomplete ? mode : shop.incSortMode,
                        comSortMode: isIncomplete ? shop.comSortMode : mode,
                      );

                      debugPrint(
                          '🔧 ソートモード変更: ${isIncomplete ? "未購入" : "購入済み"} = ${mode.label}');

                      await dataProvider.updateShop(updatedShop);

                      navigator.pop();

                      // コールバックを呼び出し（広告表示やUI更新のため）
                      onSortChanged?.call();
                    },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('閉じる', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
