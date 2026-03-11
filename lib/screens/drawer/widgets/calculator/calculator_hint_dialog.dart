import 'package:flutter/material.dart';
import 'package:maikago/widgets/common_dialog.dart';
import 'package:maikago/utils/theme_utils.dart';

/// 電卓の使い方ヒントダイアログを表示する
void showCalculatorHintDialog(BuildContext context, ThemeData theme) {
  CommonDialog.show(
    context: context,
    builder: (BuildContext context) {
      return CommonDialog(
        title: '簡単電卓の使い方',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'リストとかいらないから、とにかく価格だけ知りたいってときに使える、価格を計算するためだけの電卓です。',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _CalculatorHintItem(
              title: '1. 数字を入力',
              description: '数字ボタンをタップして価格を入力します',
              icon: Icons.dialpad_rounded,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _CalculatorHintItem(
              title: '2. 追加ボタンをタップ',
              description: '入力した価格を合計に追加します',
              icon: Icons.add_rounded,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _CalculatorHintItem(
              title: '3. 繰り返し計算',
              description: '複数の商品価格を順番に追加できます',
              icon: Icons.repeat_rounded,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _CalculatorHintItem(
              title: '4. クリアでリセット',
              description: '合計を0にリセットして新しい計算を始めます',
              icon: Icons.clear_all_rounded,
              theme: theme,
            ),
          ],
        ),
        actions: [
          CommonDialog.closeButton(context),
        ],
      );
    },
  );
}

/// ヒントダイアログの各項目ウィジェット
class _CalculatorHintItem extends StatelessWidget {
  const _CalculatorHintItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.theme,
  });

  final String title;
  final String description;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  color: Theme.of(context).subtextColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
