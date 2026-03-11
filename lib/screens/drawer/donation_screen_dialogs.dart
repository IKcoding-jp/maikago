import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maikago/widgets/common_dialog.dart';

/// 寄付画面のダイアログ群
class DonationDialogs {
  DonationDialogs._();

  /// 寄付確認ダイアログを表示
  ///
  /// [selectedAmount] 選択された寄付金額
  /// [onConfirm] 寄付確認時のコールバック
  static void showDonationConfirmDialog({
    required BuildContext context,
    required int selectedAmount,
    required VoidCallback onConfirm,
  }) {
    CommonDialog.show(
      context: context,
      builder: (BuildContext context) {
        return CommonDialog(
          title: '寄付の確認',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '以下の金額で寄付を行いますか？',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¥${selectedAmount.toString()}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '※ 寄付は開発者の活動を支援するためのものです。\n※ 返金はできませんのでご了承ください。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
          actions: [
            CommonDialog.cancelButton(context),
            CommonDialog.primaryButton(context, label: '寄付する',
                onPressed: () {
              context.pop();
              onConfirm();
            }),
          ],
        );
      },
    );
  }
}
