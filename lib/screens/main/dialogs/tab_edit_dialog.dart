import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/data_provider.dart';
import '../../../models/shop.dart';
import '../../../models/shared_group_icons.dart';

/// タブ編集ダイアログ
class TabEditDialog extends StatefulWidget {
  final int tabIndex;
  final List<Shop> shops;
  final ThemeData? customTheme;

  const TabEditDialog({
    super.key,
    required this.tabIndex,
    required this.shops,
    this.customTheme,
  });

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context, {
    required int tabIndex,
    required List<Shop> shops,
    ThemeData? customTheme,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => TabEditDialog(
        tabIndex: tabIndex,
        shops: shops,
        customTheme: customTheme,
      ),
    );
  }

  @override
  State<TabEditDialog> createState() => _TabEditDialogState();
}

class _TabEditDialogState extends State<TabEditDialog> {
  late final TextEditingController controller;
  late Shop currentShop;
  late List<Shop> otherShops;
  late Set<String> selectedTabIds;
  String? selectedIconName;

  @override
  void initState() {
    super.initState();
    currentShop = widget.shops[widget.tabIndex];
    controller = TextEditingController(text: currentShop.name);
    otherShops =
        widget.shops.where((shop) => shop.id != currentShop.id).toList();
    selectedTabIds = Set<String>.from(currentShop.sharedTabs);
    selectedIconName = currentShop.sharedGroupIcon;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final shopToDelete = widget.shops[widget.tabIndex];
    await context.read<DataProvider>().deleteShop(shopToDelete.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleSave() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    final dataProvider = context.read<DataProvider>();

    // 共有処理と名前更新を同時に行う
    if (selectedTabIds.isNotEmpty) {
      await dataProvider.updateSharedGroup(
        currentShop.id,
        selectedTabIds.toList(),
        name: name,
        sharedGroupIcon: selectedIconName,
      );
    } else if (currentShop.sharedGroupId != null ||
        currentShop.sharedTabs.isNotEmpty) {
      await dataProvider.removeFromSharedGroup(
        currentShop.id,
        originalSharedGroupId: currentShop.sharedGroupId,
        name: name,
      );
    } else {
      // 共有なしで名前だけ変更する場合
      final updatedShop = currentShop.copyWith(name: name);
      await dataProvider.updateShop(updatedShop);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.customTheme ?? Theme.of(context);

    return Theme(
      data: theme,
      child: AlertDialog(
        title: Text('タブ編集', style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'タブ名',
                  labelStyle: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
              if (otherShops.isNotEmpty) ...[
                Text(
                  '共有するタブを選択',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...otherShops.map((shop) {
                  return CheckboxListTile(
                    title: Text(shop.name),
                    value: selectedTabIds.contains(shop.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedTabIds.add(shop.id);
                        } else {
                          selectedTabIds.remove(shop.id);
                        }
                      });
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                if (selectedTabIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '共有したいタブを選択すると共有が有効になります。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                // 共有マーク選択UI（共有タブが選択されている場合のみ表示）
                if (selectedTabIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '共有マークを選択',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: SharedGroupIcons.presets.map((preset) {
                        final isSelected = selectedIconName == preset.name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedIconName = preset.name;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.grey.withValues(alpha: 0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                preset.icon,
                                size: 20,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.iconTheme.color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              if (otherShops.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '共有できる他のタブがありません。',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (widget.shops.length > 1)
            TextButton(
              onPressed: _handleDelete,
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル', style: theme.textTheme.bodyLarge),
          ),
          ElevatedButton(
            onPressed: _handleSave,
            child: Text('保存', style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
