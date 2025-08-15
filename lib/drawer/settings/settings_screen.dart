import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'account_screen.dart';

import 'settings_theme.dart';
import 'settings_persistence.dart';
import 'settings_font.dart';
import '../../services/donation_manager.dart';
import '../../services/app_info_service.dart';
import '../../providers/auth_provider.dart';
import 'advanced_settings_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import '../../widgets/migration_status_widget.dart';
import '../../widgets/debug_info_widget.dart';
import '../../screens/subscription_screen.dart';

/// メインの設定画面
/// アカウント情報、テーマ、フォントなどの設定項目を管理
class SettingsScreen extends StatefulWidget {
  final String currentTheme;
  final String currentFont;
  final double currentFontSize;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ThemeData? theme;
  final ValueChanged<Map<String, Color>>? onCustomThemeChanged;
  final bool? isDarkMode;
  final ValueChanged<bool>? onDarkModeChanged;

  const SettingsScreen({
    super.key,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
    required this.onThemeChanged,
    required this.onFontChanged,
    required this.onFontSizeChanged,
    this.theme,
    this.onCustomThemeChanged,
    this.isDarkMode,
    this.onDarkModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsState _settingsState;
  final AppInfoService _appInfoService = AppInfoService();
  String _currentVersion = '';
  bool _isUpdateAvailable = false;
  String? _latestVersion;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _settingsState = SettingsState();
    _settingsState.setInitialState(
      theme: widget.currentTheme,
      font: widget.currentFont,
      fontSize: widget.currentFontSize,
    );
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
    return ChangeNotifierProvider.value(
      value: _settingsState,
      child: Consumer<SettingsState>(
        builder: (context, settingsState, _) {
          final currentTheme = _getCurrentTheme(settingsState);
          return Theme(
            data: currentTheme,
            child: Scaffold(
              appBar: _buildAppBar(settingsState),
              body: _buildBody(settingsState),
            ),
          );
        },
      ),
    );
  }

  /// アプリバーを構築
  PreferredSizeWidget _buildAppBar(SettingsState settingsState) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '設定',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      iconTheme: IconThemeData(
        color: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
      ),
      elevation: 0,
    );
  }

  /// ボディを構築
  Widget _buildBody(SettingsState settingsState) {
    return Container(
      color: settingsState.selectedTheme == 'dark'
          ? Color(0xFF121212)
          : Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        children: [
          _buildHeader(settingsState),
          _buildMigrationSection(settingsState),
          _buildAccountCard(settingsState),
          _buildAppearanceSection(settingsState),
          _buildAdvancedSection(settingsState),
          _buildUpdateSection(settingsState),
          const SizedBox(height: 16),
          const DebugInfoWidget(),
        ],
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(SettingsState settingsState) {
    return _buildSectionHeader(
      context: context,
      title: '設定',
      icon: Icons.settings,
      iconColor: settingsState.selectedTheme == 'light'
          ? Colors.white
          : Theme.of(context).colorScheme.primary,
      textColor: settingsState.selectedTheme == 'dark'
          ? Colors.white
          : Colors.black87,
    );
  }

  /// 移行セクションを構築
  Widget _buildMigrationSection(SettingsState settingsState) {
    return Consumer<DonationManager>(
      builder: (context, donationManager, _) {
        // サブスクリプションがある場合は表示しない
        if (donationManager.hasBenefits &&
            !donationManager.shouldRecommendSubscription) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: MigrationStatusWidget(
            onUpgradePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            onMigrationComplete: () {
              setState(() {});
            },
          ),
        );
      },
    );
  }

  /// アカウントカードを構築
  Widget _buildAccountCard(SettingsState settingsState) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return _buildSettingsCard(
          backgroundColor: Theme.of(context).cardColor,
          margin: const EdgeInsets.only(bottom: 14),
          child: _buildSettingsListItem(
            context: context,
            title: 'アカウント情報',
            subtitle: authProvider.isLoggedIn ? 'ログイン済み' : 'Googleアカウントでログイン',
            leadingIcon: Icons.account_circle_rounded,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: (settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87),
            iconColor: (settingsState.selectedTheme == 'light'
                ? Colors.white
                : Colors.white),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AccountScreen()),
              );
            },
            trailing: CircleAvatar(
              backgroundImage: authProvider.userPhotoURL != null
                  ? NetworkImage(authProvider.userPhotoURL!)
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: authProvider.userPhotoURL == null
                  ? Icon(
                      Icons.account_circle_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  /// 外観セクションを構築
  Widget _buildAppearanceSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context: context,
          title: '外観',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildThemeCard(settingsState),
        _buildFontCard(settingsState),
        _buildFontSizeCard(settingsState),
      ],
    );
  }

  /// テーマカードを構築
  Widget _buildThemeCard(SettingsState settingsState) {
    return Consumer<DonationManager>(
      builder: (context, donationManager, child) {
        final isLocked = !donationManager.canChangeTheme;

        return _buildSettingsCard(
          backgroundColor: Theme.of(context).cardColor,
          margin: const EdgeInsets.only(bottom: 14),
          child: _buildSettingsListItem(
            context: context,
            title: 'テーマ',
            subtitle: isLocked
                ? 'デフォルトのみ選択可能'
                : SettingsTheme.getThemeLabel(settingsState.selectedTheme),
            leadingIcon: Icons.color_lens_rounded,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: (settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87),
            iconColor: (settingsState.selectedTheme == 'light'
                ? Colors.white
                : Colors.white),
            onTap: () => _navigateToThemeSelect(settingsState),
          ),
        );
      },
    );
  }

  /// フォントカードを構築
  Widget _buildFontCard(SettingsState settingsState) {
    return Consumer<DonationManager>(
      builder: (context, donationManager, child) {
        final isLocked = !donationManager.canChangeFont;

        return _buildSettingsCard(
          backgroundColor: Theme.of(context).cardColor,
          margin: const EdgeInsets.only(bottom: 14),
          child: _buildSettingsListItem(
            context: context,
            title: 'フォント',
            subtitle: isLocked
                ? 'デフォルトのみ選択可能'
                : FontSettings.getFontLabel(settingsState.selectedFont),
            leadingIcon: Icons.font_download_rounded,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: (settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87),
            iconColor: (settingsState.selectedTheme == 'light'
                ? Colors.white
                : Colors.white),
            onTap: () => _navigateToFontSelect(settingsState),
          ),
        );
      },
    );
  }

  /// フォントサイズカードを構築
  Widget _buildFontSizeCard(SettingsState settingsState) {
    return _buildSettingsCard(
      backgroundColor: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      child: _buildSettingsListItem(
        context: context,
        title: 'フォントサイズ',
        subtitle: '${settingsState.selectedFontSize.toInt()}px',
        leadingIcon: Icons.text_fields_rounded,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.white
            : Colors.white,
        onTap: () => _navigateToFontSizeSelect(settingsState),
      ),
    );
  }

  /// 更新情報セクションを構築
  Widget _buildUpdateSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context: context,
          title: 'アプリ情報',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildVersionCard(settingsState),
        if (_isUpdateAvailable) _buildUpdateAvailableCard(settingsState),
        _buildTermsCard(settingsState),
        _buildPrivacyCard(settingsState),
      ],
    );
  }

  /// バージョン情報カードを構築
  Widget _buildVersionCard(SettingsState settingsState) {
    return _buildSettingsCard(
      backgroundColor: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          _buildSettingsListItem(
            context: context,
            title: 'バージョン',
            subtitle: 'Version $_currentVersion',
            leadingIcon: Icons.info_outline_rounded,
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            iconColor: settingsState.selectedTheme == 'light'
                ? Colors.white
                : Colors.white,
            onTap: () => _checkForUpdates(),
          ),
          if (_isUpdateAvailable || _isCheckingUpdate)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_isCheckingUpdate) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '更新をチェック中...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: settingsState.selectedTheme == 'dark'
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.system_update_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '新しいバージョンが利用可能です',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 更新利用可能カードを構築
  Widget _buildUpdateAvailableCard(SettingsState settingsState) {
    return _buildSettingsCard(
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '更新情報',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: settingsState.selectedTheme == 'dark'
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '現在のバージョン: $_currentVersion\n'
              '最新バージョン: $_latestVersion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _appInfoService.openAppStore(),
              icon: const Icon(Icons.store_rounded, size: 16),
              label: const Text('アプリストアで更新'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// テーマ選択画面に遷移
  Future<void> _navigateToThemeSelect(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThemeSelectScreen(
          currentTheme: settingsState.selectedTheme,
          theme: _getCurrentTheme(settingsState),
          onThemeChanged: _handleThemeChanged,
        ),
      ),
    );
  }

  /// フォントサイズ選択画面に遷移
  Future<void> _navigateToFontSizeSelect(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FontSizeSelectScreen(
          currentFontSize: settingsState.selectedFontSize,
          theme: _getCurrentTheme(settingsState),
          onFontSizeChanged: _handleFontSizeChanged,
        ),
      ),
    );
    // フォントサイズ選択画面から戻ってきた時に設定画面のテーマを更新
    setState(() {});
  }

  /// フォント選択画面に遷移
  Future<void> _navigateToFontSelect(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FontSelectScreen(
          currentFont: settingsState.selectedFont,
          theme: _getCurrentTheme(settingsState),
          onFontChanged: _handleFontChanged,
        ),
      ),
    );
    // フォント選択画面から戻ってきた時に設定画面のテーマを更新
    setState(() {});
  }

  /// テーマ変更を処理
  void _handleThemeChanged(String theme) async {
    _settingsState.updateTheme(theme);
    widget.onThemeChanged(theme);
    await SettingsPersistence.saveTheme(theme);
  }

  /// フォント変更を処理
  void _handleFontChanged(String font) async {
    _settingsState.updateFont(font);
    widget.onFontChanged(font);
    await SettingsPersistence.saveFont(font);
    // 設定画面のテーマを更新
    setState(() {});
  }

  /// フォントサイズ変更を処理
  void _handleFontSizeChanged(double fontSize) async {
    _settingsState.updateFontSize(fontSize);
    widget.onFontSizeChanged(fontSize);
    await SettingsPersistence.saveFontSize(fontSize);
    // 設定画面のテーマを更新
    setState(() {});
  }

  /// 詳細セクションを構築
  Widget _buildAdvancedSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildSectionTitle(
          context: context,
          title: 'その他',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildAdvancedSettingsCard(settingsState),
      ],
    );
  }

  /// 詳細設定カードを構築
  Widget _buildAdvancedSettingsCard(SettingsState settingsState) {
    return _buildSettingsCard(
      backgroundColor: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      child: _buildSettingsListItem(
        context: context,
        title: '詳細設定',
        subtitle: 'アプリの詳細な設定',
        leadingIcon: Icons.settings_applications,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.white
            : Colors.white,
        onTap: () => _navigateToAdvancedSettings(settingsState),
      ),
    );
  }

  /// 詳細設定画面に遷移
  Future<void> _navigateToAdvancedSettings(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdvancedSettingsScreen(
          currentTheme: settingsState.selectedTheme,
          currentFont: settingsState.selectedFont,
          currentFontSize: settingsState.selectedFontSize,
          theme: _getCurrentTheme(settingsState),
        ),
      ),
    );
  }

  /// 利用規約カードを構築
  Widget _buildTermsCard(SettingsState settingsState) {
    return _buildSettingsCard(
      backgroundColor: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      child: _buildSettingsListItem(
        context: context,
        title: '利用規約',
        subtitle: 'アプリの利用に関する規約',
        leadingIcon: Icons.description_rounded,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.white
            : Colors.white,
        onTap: () => _navigateToTermsOfService(settingsState),
      ),
    );
  }

  /// プライバシーポリシーカードを構築
  Widget _buildPrivacyCard(SettingsState settingsState) {
    return _buildSettingsCard(
      backgroundColor: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      child: _buildSettingsListItem(
        context: context,
        title: 'プライバシーポリシー',
        subtitle: '個人情報の取り扱いについて',
        leadingIcon: Icons.privacy_tip_rounded,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.white
            : Colors.white,
        onTap: () => _navigateToPrivacyPolicy(settingsState),
      ),
    );
  }

  /// 利用規約画面に遷移
  Future<void> _navigateToTermsOfService(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermsOfServiceScreen(
          currentTheme: settingsState.selectedTheme,
          currentFont: settingsState.selectedFont,
          currentFontSize: settingsState.selectedFontSize,
          theme: _getCurrentTheme(settingsState),
        ),
      ),
    );
  }

  /// プライバシーポリシー画面に遷移
  Future<void> _navigateToPrivacyPolicy(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivacyPolicyScreen(
          currentTheme: settingsState.selectedTheme,
          currentFont: settingsState.selectedFont,
          currentFontSize: settingsState.selectedFontSize,
          theme: _getCurrentTheme(settingsState),
        ),
      ),
    );
  }

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme(SettingsState settingsState) {
    return SettingsTheme.generateTheme(
      selectedTheme: settingsState.selectedTheme,
      selectedFont: settingsState.selectedFont,
      fontSize: settingsState.selectedFontSize,
    );
  }

  /// 設定セクションのヘッダーを作成
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 設定カードを作成
  Widget _buildSettingsCard({
    required Widget child,
    required Color backgroundColor,
    required EdgeInsets margin,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      margin: margin,
      color: backgroundColor,
      child: child,
    );
  }

  /// 設定リストアイテムを作成
  Widget _buildSettingsListItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return SizedBox(
      height: 72,
      child: ListTile(
        dense: true,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor),
        ),
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(leadingIcon, color: iconColor),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: backgroundColor),
        onTap: onTap,
      ),
    );
  }

  /// セクションタイトルを作成
  Widget _buildSectionTitle({
    required BuildContext context,
    required String title,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
