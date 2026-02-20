import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:maikago/services/settings_theme.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/widgets/welcome_dialog.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:maikago/services/debug_service.dart';

/// 詳細設定画面
/// 詳細な設定項目を管理する画面
class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({
    super.key,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
    this.theme,
  });

  final String currentTheme;
  final String currentFont;
  final double currentFontSize;
  final ThemeData? theme;

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  late SettingsState _settingsState;
  late Future<bool> _autoCompleteFuture;
  late Future<bool> _strikethroughFuture;

  @override
  void initState() {
    super.initState();
    _settingsState = SettingsState();
    _settingsState.setInitialState(
      theme: widget.currentTheme,
      font: widget.currentFont,
      fontSize: widget.currentFontSize,
    );
    _autoCompleteFuture = _getAutoCompleteEnabled();
    _strikethroughFuture = _getStrikethroughEnabled();
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
              appBar: _buildAppBar(settingsState, currentTheme),
              body: _buildBody(settingsState, currentTheme),
            ),
          );
        },
      ),
    );
  }

  /// アプリバーを構築
  PreferredSizeWidget _buildAppBar(SettingsState settingsState, ThemeData currentTheme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
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
      backgroundColor: currentTheme.colorScheme.primary,
      foregroundColor: currentTheme.colorScheme.onPrimary,
      iconTheme: IconThemeData(
        color: settingsState.selectedTheme == 'dark'
            ? Colors.white
            : Colors.black87,
      ),
      elevation: 0,
    );
  }

  /// ボディを構築
  Widget _buildBody(SettingsState settingsState, ThemeData currentTheme) {
    return Container(
      color: settingsState.selectedTheme == 'dark'
          ? AppColors.darkSurface
          : Colors.transparent,
      child: ListView(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          _buildHeader(settingsState, currentTheme),
          _buildInputSection(settingsState, currentTheme),
        ],
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(SettingsState settingsState, ThemeData currentTheme) {
    return _buildSectionHeader(
      context: context,
      title: '詳細設定',
      icon: Icons.settings_applications,
      iconColor: settingsState.selectedTheme == 'light'
          ? Colors.black87
          : currentTheme.colorScheme.primary,
      textColor:
          settingsState.selectedTheme == 'dark' ? Colors.white : Colors.black87,
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

  /// 入力セクションを構築
  Widget _buildInputSection(SettingsState settingsState, ThemeData currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 入力・操作設定セクション
        _buildInputOperationSection(settingsState, currentTheme),
        const SizedBox(height: 24),

        // 表示設定セクション
        _buildDisplaySection(settingsState, currentTheme),
        const SizedBox(height: 24),

        // デバッグセクション（デバッグモード時のみ表示）
        if (kDebugMode) ...[
          _buildDebugSection(settingsState, currentTheme),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  /// 入力・操作設定セクションを構築
  Widget _buildInputOperationSection(SettingsState settingsState, ThemeData currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context: context,
          title: '入力・操作設定',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildAutoCompleteCard(settingsState, currentTheme),
      ],
    );
  }

  /// 表示設定セクションを構築
  Widget _buildDisplaySection(SettingsState settingsState, ThemeData currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context: context,
          title: '表示設定',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildStrikethroughCard(settingsState, currentTheme),
      ],
    );
  }

  /// 自動完了カードを構築
  Widget _buildAutoCompleteCard(SettingsState settingsState, ThemeData currentTheme) {
    return FutureBuilder<bool>(
      future: _autoCompleteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 56);
        }
        final isEnabled = snapshot.data ?? false;
        return _buildSettingsCard(
          backgroundColor: currentTheme.cardColor,
          margin: const EdgeInsets.only(bottom: 14),
          child: SwitchListTile(
            title: Text(
              '金額入力時の自動購入済み',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            subtitle: Text(
              '金額を入力したときに、自動で購入済みに移動する',
              style: TextStyle(
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            value: isEnabled,
            onChanged: (bool value) async {
              await _setAutoCompleteEnabled(value);
              setState(() {
                _autoCompleteFuture = _getAutoCompleteEnabled();
              });
            },
            activeThumbColor: currentTheme.colorScheme.primary,
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
    return await SettingsPersistence.loadAutoComplete();
  }

  /// 自動完了設定を保存
  Future<void> _setAutoCompleteEnabled(bool enabled) async {
    await SettingsPersistence.saveAutoComplete(enabled);
  }

  /// 取り消し線カードを構築
  Widget _buildStrikethroughCard(SettingsState settingsState, ThemeData currentTheme) {
    return FutureBuilder<bool>(
      future: _strikethroughFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 56);
        }
        final isEnabled = snapshot.data ?? false;
        return _buildSettingsCard(
          backgroundColor: currentTheme.cardColor,
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
              setState(() {
                _strikethroughFuture = _getStrikethroughEnabled();
              });
            },
            activeThumbColor: currentTheme.colorScheme.primary,
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
    return await SettingsPersistence.loadStrikethrough();
  }

  /// 取り消し線設定を保存
  Future<void> _setStrikethroughEnabled(bool enabled) async {
    await SettingsPersistence.saveStrikethrough(enabled);
  }

  /// デバッグセクションを構築
  Widget _buildDebugSection(SettingsState settingsState, ThemeData currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context: context,
          title: 'デバッグ機能',
          textColor: settingsState.selectedTheme == 'dark'
              ? Colors.white
              : Colors.black87,
        ),
        _buildWelcomeDialogDebugCard(settingsState, currentTheme),
      ],
    );
  }

  /// ウェルカムダイアログデバッグカードを構築
  Widget _buildWelcomeDialogDebugCard(SettingsState settingsState, ThemeData currentTheme) {
    return _buildSettingsCard(
      backgroundColor: currentTheme.cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(
          Icons.celebration,
          color: currentTheme.colorScheme.primary,
        ),
        title: Text(
          'ウェルカムダイアログを表示',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          '初回インストール時のウェルカムダイアログを表示します',
          style: TextStyle(
            color: settingsState.selectedTheme == 'dark'
                ? Colors.white70
                : Colors.black54,
          ),
        ),
        onTap: () {
          DebugService().log('🔍 デバッグ: ウェルカムダイアログを表示');
          showConstrainedDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const WelcomeDialog(),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 4,
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
}
