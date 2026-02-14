import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/release_history.dart';

/// バージョン通知を管理するサービス
class VersionNotificationService {
  static const String _lastShownVersionKey = 'last_shown_version';
  static const String _lastAppVersionKey = 'last_app_version';

  /// 新バージョンが利用可能かどうかをチェック
  static Future<bool> shouldShowVersionNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = await _getCurrentAppVersion();
      final lastShownVersion = prefs.getString(_lastShownVersionKey);
      final lastAppVersion = prefs.getString(_lastAppVersionKey);

      // 初回起動またはバージョンが変わった場合
      if (lastShownVersion == null || lastShownVersion != currentVersion) {
        // 前回のアプリバージョンと現在のバージョンを比較
        if (lastAppVersion != null && lastAppVersion != currentVersion) {
          // バージョンが変わった場合、通知を表示
          await _updateLastShownVersion(currentVersion);
          return true;
        } else if (lastAppVersion == null) {
          // 初回起動の場合、通知を表示しない（初回は既に最新バージョン）
          await _updateLastShownVersion(currentVersion);
          return false;
        }
      }

      return false;
    } catch (e) {
      // エラーが発生した場合は通知を表示しない
      return false;
    }
  }

  /// 現在のアプリバージョンを取得
  static Future<String> _getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      // フォールバックとしてpubspec.yamlのバージョンを使用
      return '1.2.0'; // 現在のバージョン（pubspec.yamlと一致させる）
    }
  }

  /// 最後に表示したバージョンを更新
  static Future<void> _updateLastShownVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownVersionKey, version);
  }

  /// アプリ起動時のバージョンを記録
  static Future<void> recordAppLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = await _getCurrentAppVersion();
      await prefs.setString(_lastAppVersionKey, currentVersion);
    } catch (e) {
      // エラーが発生してもアプリの動作には影響しない
    }
  }

  /// 最新のリリースノートを取得
  static ReleaseNote? getLatestReleaseNote() {
    return ReleaseHistory.getLatestReleaseNote();
  }

  /// 現在のバージョンが最新かどうかをチェック
  static Future<bool> isCurrentVersionLatest() async {
    try {
      final currentVersion = await _getCurrentAppVersion();
      return ReleaseHistory.isCurrentVersionLatest(currentVersion);
    } catch (e) {
      return true; // エラーの場合は最新とみなす
    }
  }

  /// バージョン通知の表示履歴をリセット（開発用）
  static Future<void> resetNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastShownVersionKey);
    await prefs.remove(_lastAppVersionKey);
  }
}
