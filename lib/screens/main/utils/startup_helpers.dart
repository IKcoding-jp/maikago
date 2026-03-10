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
import 'package:go_router/go_router.dart';
import 'package:maikago/providers/auth_provider.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_overlay.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_step.dart';

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
          context.pop();
          context.push('/release-history', extra: {
            'currentTheme': tp.selectedTheme,
            'currentFont': tp.selectedFont,
            'currentFontSize': tp.fontSize,
          });
        },
        onDismiss: () {
          context.pop();
        },
      ),
    );
  }

  /// 初回起動時にウェルカムダイアログを表示
  static Future<void> checkAndShowWelcomeDialog(
    BuildContext context, {
    GlobalKey? fabKey,
    GlobalKey? itemListKey,
    GlobalKey? addTabKey,
    GlobalKey? budgetKey,
  }) async {
    final isFirstLaunch = await SettingsPersistence.isFirstLaunch();
    if (isFirstLaunch && context.mounted) {
      unawaited(showConstrainedDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => WelcomeDialog(
          onCompleted: () {
            if (fabKey != null && itemListKey != null && addTabKey != null && budgetKey != null) {
              _showCoachMark(
                context,
                fabKey: fabKey,
                itemListKey: itemListKey,
                addTabKey: addTabKey,
                budgetKey: budgetKey,
              );
            }
          },
        ),
      ));
    } else if (!isFirstLaunch) {
      // 初回起動ではないが、コーチマーク未完了の場合
      if (fabKey != null && itemListKey != null && addTabKey != null && budgetKey != null) {
        await _showCoachMark(
          context,
          fabKey: fabKey,
          itemListKey: itemListKey,
          addTabKey: addTabKey,
          budgetKey: budgetKey,
        );
      }
    }
  }

  static Future<void> _showCoachMark(
    BuildContext context, {
    required GlobalKey fabKey,
    required GlobalKey itemListKey,
    required GlobalKey addTabKey,
    required GlobalKey budgetKey,
  }) async {
    final isCompleted = await SettingsPersistence.isCoachMarkCompleted();
    if (isCompleted || !context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      // 認証済みまたはゲストモードでない場合はスキップ（リダイレクト前の誤表示防止）
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn && !authProvider.isGuestMode) return;
      } catch (_) {
        return;
      }

      CoachMarkOverlay.show(
        context: context,
        steps: [
          CoachMarkStep(
            targetKey: fabKey,
            description: 'ここからアイテムを追加できます',
            shape: CoachMarkShape.roundedRectangle,
          ),
          CoachMarkStep(
            targetKey: itemListKey,
            description: 'アイテムを追加したら左スワイプで購入済みに移動できます',
            shape: CoachMarkShape.roundedRectangle,
          ),
          CoachMarkStep(
            targetKey: addTabKey,
            description: 'タブを追加して複数の買い物リストを管理できます',
            shape: CoachMarkShape.roundedRectangle,
          ),
          CoachMarkStep(
            targetKey: budgetKey,
            description: '予算を設定して買いすぎを防止しましょう',
            shape: CoachMarkShape.roundedRectangle,
          ),
        ],
      );
    });
  }
}
