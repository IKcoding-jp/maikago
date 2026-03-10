import 'package:flutter/material.dart';

/// プレミアムアップグレード誘導ダイアログ（汎用）
///
/// OCR、ショップ、レシピ、共有グループなど、
/// 各種機能制限に達した際に表示する共通ダイアログ。
class PremiumUpgradeDialog extends StatelessWidget {
  const PremiumUpgradeDialog({
    super.key,
    required this.title,
    required this.message,
    this.onUpgrade,
  });

  final String title;
  final String message;
  final VoidCallback? onUpgrade;

  /// ダイアログを表示するユーティリティメソッド
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onUpgrade,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        title: title,
        message: message,
        onUpgrade: onUpgrade,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade?.call();
          },
          child: const Text('プレミアムにアップグレード'),
        ),
      ],
    );
  }
}
