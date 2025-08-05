import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  PackageInfo? _packageInfo;
  String? _latestVersion;
  bool _isUpdateAvailable = false;

  /// パッケージ情報を初期化
  Future<void> _initPackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
  }

  /// アプリのバージョンを取得
  Future<String> getCurrentVersion() async {
    try {
      await _initPackageInfo();
      return _packageInfo!.version;
    } catch (e) {
      debugPrint('バージョンの取得に失敗しました: $e');
      // フォールバックとしてpubspec.yamlのバージョンを使用
      return '0.4.5';
    }
  }

  /// ビルド番号を取得
  Future<String> getBuildNumber() async {
    try {
      await _initPackageInfo();
      return _packageInfo!.buildNumber;
    } catch (e) {
      debugPrint('ビルド番号の取得に失敗しました: $e');
      // フォールバックとしてpubspec.yamlのビルド番号を使用
      return '24';
    }
  }

  /// アプリの完全なバージョン情報を取得（例: 0.4.5+24）
  Future<String> getFullVersion() async {
    final version = await getCurrentVersion();
    final buildNumber = await getBuildNumber();
    return '$version+$buildNumber';
  }

  /// 最新バージョンをチェック（GitHubのリリースから取得）
  Future<bool> checkForUpdates() async {
    try {
      // GitHubのリリースAPIから最新バージョンを取得
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/ikcoding/maikago/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = data['tag_name'].replaceAll('v', '');

        final currentVersion = await getCurrentVersion();
        _isUpdateAvailable =
            _compareVersions(_latestVersion!, currentVersion) > 0;

        return _isUpdateAvailable;
      }
    } catch (e) {
      debugPrint('バージョンチェックエラー: $e');
    }

    return false;
  }

  /// バージョン比較（semantic versioning）
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // 短い方のバージョンを0で埋める
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }

    return 0;
  }

  /// 更新が利用可能かどうか
  bool get isUpdateAvailable => _isUpdateAvailable;

  /// 最新バージョン
  String? get latestVersion => _latestVersion;

  /// アプリストアでアプリを開く
  Future<void> openAppStore() async {
    try {
      // Androidの場合
      final androidUrl =
          'https://play.google.com/store/apps/details?id=com.ikcoding.maikago';
      // iOSの場合（App Store IDが必要）
      final iosUrl =
          'https://apps.apple.com/app/maikago/id1234567890'; // 実際のApp Store IDに変更が必要

      // プラットフォームに応じてURLを選択
      String url;
      if (Platform.isIOS) {
        url = iosUrl;
      } else {
        url = androidUrl; // Androidとその他のプラットフォーム
      }

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('アプリストアを開けませんでした: $e');
    }
  }

  /// GitHubのリリースページを開く
  Future<void> openGitHubReleases() async {
    try {
      const url = 'https://github.com/ikcoding/maikago/releases';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('GitHubリリースページを開けませんでした: $e');
    }
  }
}
