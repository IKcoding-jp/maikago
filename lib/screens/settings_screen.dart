import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'account_screen.dart';
import 'settings_state.dart';
import 'settings_logic.dart';
import 'settings_persistence.dart';
import 'settings_ui.dart';
import 'settings_section_theme.dart';
import 'settings_section_font.dart';
import '../services/donation_manager.dart';
import '../services/app_info_service.dart';
import 'advanced_settings_screen.dart';

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
  final Map<String, Color>? customColors;
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
    this.customColors,
    this.isDarkMode,
    this.onDarkModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsState _settingsState;
  late Map<String, Color> _detailedColors;
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
      customColors: widget.customColors,
    );
    _detailedColors = _settingsState.detailedColors;
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
      backgroundColor:
          (widget.theme ?? _getCurrentTheme(settingsState)).colorScheme.primary,
      foregroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
          .colorScheme
          .onPrimary,
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
          _buildAccountCard(settingsState),
          _buildAppearanceSection(settingsState),
          _buildAdvancedSection(settingsState),
          _buildUpdateSection(settingsState),
        ],
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(SettingsState settingsState) {
    return SettingsUI.buildSectionHeader(
      context: context,
      title: '設定',
      icon: Icons.settings,
      iconColor: settingsState.selectedTheme == 'light'
          ? Colors.black87
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .primary,
      textColor: settingsState.selectedTheme == 'dark'
          ? Colors.white
          : Colors.black87,
    );
  }

  /// アカウントカードを構築
  Widget _buildAccountCard(SettingsState settingsState) {
    return SettingsUI.buildAccountCard(
      context: context,
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface
                .withAlpha(250),
      textColor: settingsState.selectedTheme == 'dark'
          ? Colors.white
          : Colors.black87,
      primaryColor:
          (widget.theme ?? _getCurrentTheme(settingsState)).colorScheme.primary,
      iconColor: settingsState.selectedTheme == 'light'
          ? Colors.black87
          : Colors.white,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AccountScreen()),
        );
      },
    );
  }

  /// 外観セクションを構築
  Widget _buildAppearanceSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsUI.buildSectionTitle(
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

        return SettingsUI.buildSettingsCard(
          backgroundColor: settingsState.selectedTheme == 'dark'
              ? Color(0xFF424242)
              : (widget.theme ?? _getCurrentTheme(settingsState))
                    .colorScheme
                    .surface,
          margin: const EdgeInsets.only(bottom: 14),
          child: SettingsUI.buildSettingsListItem(
            context: context,
            title: 'テーマ',
            subtitle: isLocked
                ? 'デフォルトのみ選択可能'
                : SettingsLogic.getThemeLabel(settingsState.selectedTheme),
            leadingIcon: Icons.color_lens_rounded,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .primary,
            textColor: (settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87),
            iconColor: (settingsState.selectedTheme == 'light'
                ? Colors.black87
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

        return SettingsUI.buildSettingsCard(
          backgroundColor: settingsState.selectedTheme == 'dark'
              ? Color(0xFF424242)
              : (widget.theme ?? _getCurrentTheme(settingsState))
                    .colorScheme
                    .surface
                    .withAlpha(250),
          margin: const EdgeInsets.only(bottom: 14),
          child: SettingsUI.buildSettingsListItem(
            context: context,
            title: 'フォント',
            subtitle: isLocked
                ? 'デフォルトのみ選択可能'
                : SettingsLogic.getFontLabel(settingsState.selectedFont),
            leadingIcon: Icons.font_download_rounded,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .primary,
            textColor: (settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87),
            iconColor: (settingsState.selectedTheme == 'light'
                ? Colors.black87
                : Colors.white),
            onTap: () => _navigateToFontSelect(settingsState),
          ),
        );
      },
    );
  }

  /// フォントサイズカードを構築
  Widget _buildFontSizeCard(SettingsState settingsState) {
    return SettingsUI.buildSettingsCard(
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface
                .withAlpha(250),
      margin: const EdgeInsets.only(bottom: 14),
      child: SettingsUI.buildSettingsListItem(
        context: context,
        title: 'フォントサイズ',
        subtitle: '${settingsState.selectedFontSize.toInt()}px',
        leadingIcon: Icons.text_fields_rounded,
        backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
            .colorScheme
            .primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.black87
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
        SettingsUI.buildSectionTitle(
          context: context,
          title: 'アプリ情報',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildVersionCard(settingsState),
        if (_isUpdateAvailable) _buildUpdateAvailableCard(settingsState),
      ],
    );
  }

  /// バージョン情報カードを構築
  Widget _buildVersionCard(SettingsState settingsState) {
    return SettingsUI.buildSettingsCard(
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface
                .withAlpha(250),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          SettingsUI.buildSettingsListItem(
            context: context,
            title: 'バージョン',
            subtitle: 'Version $_currentVersion',
            leadingIcon: Icons.info_outline_rounded,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .primary,
            textColor: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            iconColor: settingsState.selectedTheme == 'light'
                ? Colors.black87
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
    return SettingsUI.buildSettingsCard(
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
          customColors: settingsState.customColors,
          onCustomThemeChanged: widget.onCustomThemeChanged,
          detailedColors: _detailedColors,
          onDetailedColorsChanged: (colors) {
            setState(() {
              _detailedColors = colors;
            });
          },
          onSaveCustomTheme: _saveCustomTheme,
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

  /// カスタムテーマを保存
  Future<void> _saveCustomTheme() async {
    await SettingsPersistence.saveCustomTheme(_detailedColors);
  }

  /// 詳細セクションを構築
  Widget _buildAdvancedSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        SettingsUI.buildSectionTitle(
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
    return SettingsUI.buildSettingsCard(
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface
                .withAlpha(250),
      margin: const EdgeInsets.only(bottom: 14),
      child: SettingsUI.buildSettingsListItem(
        context: context,
        title: '詳細設定',
        subtitle: 'アプリの詳細な設定',
        leadingIcon: Icons.settings_applications,
        backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
            .colorScheme
            .primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.black87
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

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme(SettingsState settingsState) {
    return SettingsLogic.generateTheme(
      selectedTheme: settingsState.selectedTheme,
      selectedFont: settingsState.selectedFont,
      detailedColors: _detailedColors,
      fontSize: settingsState.selectedFontSize,
    );
  }
}
