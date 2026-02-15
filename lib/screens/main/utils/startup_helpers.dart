import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/providers/theme_provider.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/widgets/welcome_dialog.dart';
import 'package:maikago/widgets/version_update_dialog.dart';
import 'package:maikago/services/version_notification_service.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/models/release_history.dart';
import 'package:maikago/screens/release_history_screen.dart';
import 'package:maikago/services/settings_persistence.dart';

/// メイン画面の起動時ヘルパー（バージョン更新・ウェルカムダイアログ）
class StartupHelpers {
  StartupHelpers._();

  /// バージョン更新通知をチェック
  static Future<void> checkForVersionUpdate(BuildContext context) async {
    try {
      final shouldShow =
          await VersionNotificationService.shouldShowVersionNotification();
      if (shouldShow && context.mounted) {
        final latestRelease = VersionNotificationService.getLatestReleaseNote();
        if (latestRelease != null) {
          showVersionUpdateDialog(context, latestRelease);
        }
      }
    } catch (e) {
      DebugService().log('バージョン更新チェックエラー: $e');
    }
  }

  /// バージョン更新ダイアログを表示
  static void showVersionUpdateDialog(
      BuildContext context, ReleaseNote latestRelease) {
    final tp = context.read<ThemeProvider>();
    showConstrainedDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VersionUpdateDialog(
        latestRelease: latestRelease,
        currentTheme: tp.selectedTheme,
        currentFont: tp.selectedFont,
        currentFontSize: tp.fontSize,
        onViewDetails: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReleaseHistoryScreen(
                currentTheme: tp.selectedTheme,
                currentFont: tp.selectedFont,
                currentFontSize: tp.fontSize,
              ),
            ),
          );
        },
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// 初回起動時にウェルカムダイアログを表示
  static Future<void> checkAndShowWelcomeDialog(BuildContext context) async {
    final isFirstLaunch = await SettingsPersistence.isFirstLaunch();
    if (isFirstLaunch && context.mounted) {
      unawaited(showConstrainedDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeDialog(),
      ));
    }
  }
}
