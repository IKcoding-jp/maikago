import 'package:flutter/material.dart';
import 'package:maikago/models/release_history.dart';
import 'package:maikago/drawer/settings/settings_theme.dart';
import 'package:maikago/utils/theme_utils.dart';

/// 新バージョン通知ダイアログ
class VersionUpdateDialog extends StatelessWidget {
  const VersionUpdateDialog({
    super.key,
    required this.latestRelease,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
    this.onViewDetails,
    this.onDismiss,
  });

  final ReleaseNote latestRelease;
  final String currentTheme;
  final String currentFont;
  final double currentFontSize;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _getCardColor(),
      title: Row(
        children: [
          Icon(
            Icons.system_update_rounded,
            color: SettingsTheme.getPrimaryColor(currentTheme),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '新機能のお知らせ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: Theme.of(context).textTheme.headlineMedium?.fontSize,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // バージョン情報
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SettingsTheme.getPrimaryColor(currentTheme),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'v${latestRelease.version}',
              style: TextStyle(
                color: SettingsTheme.getContrastColor(
                  SettingsTheme.getPrimaryColor(currentTheme),
                ),
                fontWeight: FontWeight.bold,
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 変更内容のプレビュー（最初の3項目まで）
          Text(
            '主な変更点:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
            ),
          ),
          const SizedBox(height: 8),
          ...latestRelease.changes.take(3).map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 12),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(change.category),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        change.description,
                        style: TextStyle(
                          color: Theme.of(context).subtextColor,
                          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (latestRelease.changes.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '他 ${latestRelease.changes.length - 3} 件の変更があります',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (latestRelease.developerComment != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SettingsTheme.getPrimaryColor(currentTheme)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SettingsTheme.getPrimaryColor(currentTheme)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: SettingsTheme.getPrimaryColor(currentTheme),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latestRelease.developerComment!,
                      style: TextStyle(
                        color: Theme.of(context).subtextColor,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            '閉じる',
            style: TextStyle(
              color: Theme.of(context).subtextColor,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onViewDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: SettingsTheme.getPrimaryColor(currentTheme),
            foregroundColor: SettingsTheme.getContrastColor(
              SettingsTheme.getPrimaryColor(currentTheme),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: const Text('詳しく見る'),
        ),
      ],
    );
  }

  Color _getCategoryColor(ChangeCategory category) {
    switch (category) {
      case ChangeCategory.newFeature:
        return Colors.purple;
      case ChangeCategory.bugFix:
        return Colors.red;
      case ChangeCategory.improvement:
        return Colors.green;
      case ChangeCategory.other:
        return Colors.orange;
    }
  }

  Color _getCardColor() {
    switch (currentTheme) {
      case 'dark':
        return AppColors.darkCard;
      default:
        return Colors.white;
    }
  }
}
