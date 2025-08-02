import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';
import 'settings_logic.dart';
import 'settings_ui.dart';

/// 詳細設定画面
/// 詳細な設定項目を管理する画面
class AdvancedSettingsScreen extends StatefulWidget {
  final String currentTheme;
  final String currentFont;
  final double currentFontSize;
  final ThemeData? theme;

  const AdvancedSettingsScreen({
    super.key,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
    this.theme,
  });

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  late SettingsState _settingsState;

  @override
  void initState() {
    super.initState();
    _settingsState = SettingsState();
    _settingsState.setInitialState(
      theme: widget.currentTheme,
      font: widget.currentFont,
      fontSize: widget.currentFontSize,
    );
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
        '詳細設定',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
      ),
      backgroundColor: _getCurrentTheme(settingsState).colorScheme.primary,
      foregroundColor: _getCurrentTheme(settingsState).colorScheme.onPrimary,
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
          _buildInputSection(settingsState),
        ],
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(SettingsState settingsState) {
    return SettingsUI.buildSectionHeader(
      context: context,
      title: '詳細設定',
      icon: Icons.settings_applications,
      iconColor: settingsState.selectedTheme == 'light'
          ? Colors.black87
          : _getCurrentTheme(settingsState).colorScheme.primary,
      textColor: settingsState.selectedTheme == 'dark'
          ? Colors.white
          : Colors.black87,
    );
  }

  /// 入力セクションを構築
  Widget _buildInputSection(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsUI.buildSectionTitle(
          context: context,
          title: '詳細設定',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildAutoCompleteCard(settingsState),
        const SizedBox(height: 14),
        _buildStrikethroughCard(settingsState),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 自動完了カードを構築
  Widget _buildAutoCompleteCard(SettingsState settingsState) {
    return FutureBuilder<bool>(
      future: _getAutoCompleteEnabled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 56);
        }
        final isEnabled = snapshot.data ?? false;
        return SettingsUI.buildSettingsCard(
          backgroundColor: settingsState.selectedTheme == 'dark'
              ? Color(0xFF424242)
              : _getCurrentTheme(settingsState).colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 14),
          child: SwitchListTile(
            title: Text(
              '金額入力時の自動完了',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            subtitle: Text(
              '金額入力時に候補を自動で表示する',
              style: TextStyle(
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            value: isEnabled,
            onChanged: (bool value) async {
              await _setAutoCompleteEnabled(value);
              setState(() {});
            },
            activeColor: _getCurrentTheme(settingsState).colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
          ),
        );
      },
    );
  }

  /// 自動完了設定を取得
  Future<bool> _getAutoCompleteEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_complete_on_price_input') ?? false;
  }

  /// 自動完了設定を保存
  Future<void> _setAutoCompleteEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_complete_on_price_input', enabled);
  }

  /// 取り消し線カードを構築
  Widget _buildStrikethroughCard(SettingsState settingsState) {
    return FutureBuilder<bool>(
      future: _getStrikethroughEnabled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 56);
        }
        final isEnabled = snapshot.data ?? false;
        return SettingsUI.buildSettingsCard(
          backgroundColor: settingsState.selectedTheme == 'dark'
              ? Color(0xFF424242)
              : _getCurrentTheme(settingsState).colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 14),
          child: SwitchListTile(
            title: Text(
              '購入済みの商品に取り消し線を引く',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            subtitle: Text(
              '購入済みの商品名に取り消し線を表示する',
              style: TextStyle(
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            value: isEnabled,
            onChanged: (bool value) async {
              await _setStrikethroughEnabled(value);
              setState(() {});
            },
            activeColor: _getCurrentTheme(settingsState).colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
          ),
        );
      },
    );
  }

  /// 取り消し線設定を取得
  Future<bool> _getStrikethroughEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('strikethrough_on_completed_items') ?? false;
  }

  /// 取り消し線設定を保存
  Future<void> _setStrikethroughEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('strikethrough_on_completed_items', enabled);
  }

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme(SettingsState settingsState) {
    return SettingsLogic.generateTheme(
      selectedTheme: settingsState.selectedTheme,
      selectedFont: settingsState.selectedFont,
      detailedColors: {},
      fontSize: settingsState.selectedFontSize,
    );
  }
}
