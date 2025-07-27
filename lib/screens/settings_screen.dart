import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'account_screen.dart';
import 'settings_state.dart';
import 'settings_logic.dart';
import 'settings_persistence.dart';
import 'settings_ui.dart';
import 'settings_section_theme.dart';
import 'settings_section_font.dart';
import '../services/interstitial_ad_service.dart';

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
          _buildDebugSection(settingsState),
        ],
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(SettingsState settingsState) {
    return SettingsUI.buildSectionHeader(
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
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface
                .withOpacity(0.98),
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
          title: '外観',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildThemeCard(settingsState),
        _buildFontCard(settingsState),
      ],
    );
  }

  /// デバッグセクションを構築
  Widget _buildDebugSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsUI.buildSectionTitle(
          title: 'デバッグ',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildDebugCard(settingsState),
      ],
    );
  }

  /// デバッグカードを構築
  Widget _buildDebugCard(SettingsState settingsState) {
    return SettingsUI.buildSettingsCard(
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          SettingsUI.buildSettingsListItem(
            title: 'インタースティシャル広告テスト',
            subtitle: 'テスト用広告を強制表示',
            leadingIcon: Icons.ad_units,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface,
            textColor: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            iconColor: settingsState.selectedTheme == 'light'
                ? Colors.black87
                : Colors.white,
            onTap: () async {
              await InterstitialAdService().forceShowAd();
            },
          ),
          SettingsUI.buildSettingsListItem(
            title: '即座に広告表示',
            subtitle: '条件を満たして即座に表示',
            leadingIcon: Icons.play_arrow,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface,
            textColor: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            iconColor: settingsState.selectedTheme == 'light'
                ? Colors.black87
                : Colors.white,
            onTap: () async {
              await InterstitialAdService().showAdImmediately();
            },
          ),
          SettingsUI.buildSettingsListItem(
            title: '広告セッションリセット',
            subtitle: '広告表示カウントをリセット',
            leadingIcon: Icons.refresh,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface,
            textColor: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            iconColor: settingsState.selectedTheme == 'light'
                ? Colors.black87
                : Colors.white,
            onTap: () {
              InterstitialAdService().resetForDebug();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('広告セッションをリセットしました'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          SettingsUI.buildSettingsListItem(
            title: '広告状態確認',
            subtitle: '現在の広告状態を表示',
            leadingIcon: Icons.info,
            backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface,
            textColor: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
            iconColor: settingsState.selectedTheme == 'light'
                ? Colors.black87
                : Colors.white,
            onTap: () {
              final debugInfo = InterstitialAdService().getDebugInfo();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('広告状態'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: debugInfo.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${entry.key}: ${entry.value}'),
                      );
                    }).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// テーマカードを構築
  Widget _buildThemeCard(SettingsState settingsState) {
    return SettingsUI.buildSettingsCard(
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface,
      margin: const EdgeInsets.only(bottom: 14),
      child: SettingsUI.buildSettingsListItem(
        title: 'テーマ',
        subtitle: SettingsLogic.getThemeLabel(settingsState.selectedTheme),
        leadingIcon: Icons.color_lens_rounded,
        backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
            .colorScheme
            .primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.black87
            : Colors.white,
        onTap: () => _navigateToThemeSelect(settingsState),
      ),
    );
  }

  /// フォントカードを構築
  Widget _buildFontCard(SettingsState settingsState) {
    return SettingsUI.buildSettingsCard(
      backgroundColor: settingsState.selectedTheme == 'dark'
          ? Color(0xFF424242)
          : (widget.theme ?? _getCurrentTheme(settingsState))
                .colorScheme
                .surface
                .withOpacity(0.98),
      margin: const EdgeInsets.only(bottom: 14),
      child: SettingsUI.buildSettingsListItem(
        title: 'フォント',
        subtitle: SettingsLogic.getFontLabel(settingsState.selectedFont),
        leadingIcon: Icons.font_download_rounded,
        backgroundColor: (widget.theme ?? _getCurrentTheme(settingsState))
            .colorScheme
            .primary,
        textColor: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
        iconColor: settingsState.selectedTheme == 'light'
            ? Colors.black87
            : Colors.white,
        onTap: () => _navigateToFontSelect(settingsState),
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

  /// フォント選択画面に遷移
  Future<void> _navigateToFontSelect(SettingsState settingsState) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FontSelectScreen(
          currentFont: settingsState.selectedFont,
          currentFontSize: settingsState.selectedFontSize,
          theme: _getCurrentTheme(settingsState),
          onFontChanged: _handleFontChanged,
          onFontSizeChanged: _handleFontSizeChanged,
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

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme(SettingsState settingsState) {
    // デバッグ用：フォント設定をログ出力
    print('SettingsScreen - Current Font: ${settingsState.selectedFont}');
    print(
      'SettingsScreen - Current Font Size: ${settingsState.selectedFontSize}',
    );

    return SettingsLogic.generateTheme(
      selectedTheme: settingsState.selectedTheme,
      selectedFont: settingsState.selectedFont,
      detailedColors: _detailedColors,
      fontSize: settingsState.selectedFontSize,
    );
  }
}
