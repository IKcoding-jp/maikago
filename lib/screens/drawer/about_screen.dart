import 'package:flutter/material.dart';
import 'package:maikago/screens/drawer/widgets/about/about_features_section.dart';
import 'package:maikago/screens/drawer/widgets/about/about_header_section.dart';
import 'package:maikago/screens/drawer/widgets/about/about_story_section.dart';
import 'package:maikago/screens/drawer/widgets/about/about_version_section.dart';
import 'package:maikago/services/app_info_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final AppInfoService _appInfoService = AppInfoService();
  String _currentVersion = '';
  bool _isUpdateAvailable = false;
  String? _latestVersion;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _checkForUpdates();
  }

  Future<void> _loadVersionInfo() async {
    final version = await _appInfoService.getCurrentVersion();
    setState(() {
      _currentVersion = version;
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final hasUpdate = await _appInfoService.checkForUpdates();
      setState(() {
        _isUpdateAvailable = hasUpdate;
        _latestVersion = _appInfoService.latestVersion;
        _isCheckingUpdate = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリについて'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            const AboutHeaderSection(),
            const SizedBox(height: 24),

            // 開発ストーリーセクション
            const AboutStorySection(),
            const SizedBox(height: 24),

            // アプリの特徴セクション
            const AboutFeaturesSection(),
            const SizedBox(height: 24),

            // 更新情報 + バージョン情報セクション
            AboutVersionSection(
              currentVersion: _currentVersion,
              isUpdateAvailable: _isUpdateAvailable,
              latestVersion: _latestVersion,
              isCheckingUpdate: _isCheckingUpdate,
              appInfoService: _appInfoService,
              onCheckForUpdates: _checkForUpdates,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
