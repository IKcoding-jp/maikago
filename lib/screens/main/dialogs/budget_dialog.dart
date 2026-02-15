import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'package:maikago/utils/snackbar_utils.dart';

/// 予算変更ダイアログ
class BudgetDialog extends StatefulWidget {
  const BudgetDialog({super.key, required this.shop});

  final Shop shop;

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(BuildContext context, Shop shop) {
    return showConstrainedDialog<void>(
      context: context,
      builder: (context) => BudgetDialog(shop: shop),
    );
  }
}

class _BudgetDialogState extends State<BudgetDialog> {
  late TextEditingController controller;
  bool isLoading = true;
  late final String _initialBudgetText;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.shop.budget?.toString() ?? '',
    );
    _initialBudgetText = controller.text;
    loadBudgetSettings();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> loadBudgetSettings() async {
    final currentBudget = await SettingsPersistence.getCurrentBudget(
      widget.shop.id,
    );

    setState(() {
      // ユーザー入力を上書きしない: 初期値のまま、または空のときだけ反映
      if (currentBudget != null) {
        final newText = currentBudget.toString();
        final isUserEdited =
            controller.text.isNotEmpty && controller.text != _initialBudgetText;
        if (!isUserEdited) {
          controller.text = newText;
        }
      }
      isLoading = false;
    });
  }

  Future<void> saveBudget() async {
    final budgetText = controller.text.trim();
    int? finalBudget;

    if (budgetText.isEmpty || budgetText == '0') {
      finalBudget = null;
    } else {
      final budget = int.tryParse(budgetText);
      if (budget == null) {
        showErrorSnackBar(context, '有効な数値を入力してください', duration: const Duration(seconds: 2));
        return;
      }
      finalBudget = budget;
    }

    final dataProvider = context.read<DataProvider>();

    try {
      // 個別予算として保存
      await SettingsPersistence.saveTabBudget(widget.shop.id, finalBudget);
      final updatedShop = finalBudget == null
          ? widget.shop.copyWith(clearBudget: true)
          : widget.shop.copyWith(budget: finalBudget);
      await dataProvider.updateShop(updatedShop);

      // 共有グループ内の予算同期
      if (widget.shop.sharedGroupId != null) {
        await dataProvider.syncSharedGroupBudget(
            widget.shop.sharedGroupId!, finalBudget);
      }

      dataProvider.clearDisplayTotalCache();

      // 即座にUIを更新するため、DataProviderのnotifyListenersを呼び出し
      dataProvider.notifyListeners();

      // State の mounted をチェックしてから BuildContext を使う
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      // State の mounted をチェックしてから BuildContext を使う
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: ${e.toString()}'),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
      title: Text(
        widget.shop.budget != null ? '予算を変更' : '予算を設定',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.shop.budget != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '現在の予算: ¥${widget.shop.budget}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '金額 (¥)',
                  labelStyle: Theme.of(context).textTheme.bodyLarge,
                  helperText: '0を入力すると予算を未設定にできます',
                  helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    if (newValue.text == '0') return newValue;
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('キャンセル', style: Theme.of(context).textTheme.bodyLarge),
        ),
        ElevatedButton(
          onPressed: saveBudget,
          child: Text('保存', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
