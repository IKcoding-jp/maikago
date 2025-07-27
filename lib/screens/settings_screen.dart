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
import '../services/donation_manager.dart';
import '../services/in_app_purchase_service.dart';
import 'donation_screen.dart';

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
          SettingsUI.buildSettingsListItem(
            title: '寄付状態確認',
            subtitle: '現在の寄付状態を表示',
            leadingIcon: Icons.favorite,
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
              final donationManager = Provider.of<DonationManager>(
                context,
                listen: false,
              );
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('寄付状態'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('寄付済み: ${donationManager.isDonated}'),
                      Text('特典有効: ${donationManager.hasBenefits}'),
                      Text('広告非表示: ${donationManager.shouldHideAds}'),
                      Text('テーマ変更可能: ${donationManager.canChangeTheme}'),
                      Text('フォント変更可能: ${donationManager.canChangeFont}'),
                    ],
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
          SettingsUI.buildSettingsListItem(
            title: '寄付特典を有効化（テスト）',
            subtitle: 'テスト用に寄付特典を有効にする',
            leadingIcon: Icons.star,
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
              final donationManager = Provider.of<DonationManager>(
                context,
                listen: false,
              );
              await donationManager.enableDonationBenefits();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('寄付特典を有効にしました'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          SettingsUI.buildSettingsListItem(
            title: '寄付状態をリセット（テスト）',
            subtitle: 'テスト用に寄付状態をリセットする',
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
            onTap: () async {
              final donationManager = Provider.of<DonationManager>(
                context,
                listen: false,
              );
              await donationManager.resetDonationStatus();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('寄付状態をリセットしました'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          SettingsUI.buildSettingsListItem(
            title: 'アプリ内購入状態確認',
            subtitle: '現在の購入状態を表示',
            leadingIcon: Icons.shopping_cart,
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
              final purchaseService = Provider.of<InAppPurchaseService>(
                context,
                listen: false,
              );
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('アプリ内購入状態'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('利用可能: ${purchaseService.isAvailable}'),
                      Text('商品数: ${purchaseService.products.length}'),
                      Text('購入処理中: ${purchaseService.purchasePending}'),
                      if (purchaseService.queryProductError != null)
                        Text('エラー: ${purchaseService.queryProductError}'),
                      const SizedBox(height: 8),
                      Text('利用可能な商品:'),
                      ...purchaseService.products.map(
                        (product) => Text('  ${product.id}: ${product.price}'),
                      ),
                    ],
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
            title: 'テーマ',
            subtitle: isLocked
                ? '寄付でアンロック'
                : SettingsLogic.getThemeLabel(settingsState.selectedTheme),
            leadingIcon: isLocked ? Icons.lock : Icons.color_lens_rounded,
            backgroundColor: isLocked
                ? Colors.grey.withOpacity(0.3)
                : (widget.theme ?? _getCurrentTheme(settingsState))
                      .colorScheme
                      .primary,
            textColor: isLocked
                ? Colors.grey
                : (settingsState.selectedTheme == 'dark'
                      ? Colors.white
                      : Colors.black87),
            iconColor: isLocked
                ? Colors.grey
                : (settingsState.selectedTheme == 'light'
                      ? Colors.black87
                      : Colors.white),
            onTap: isLocked
                ? () => _showDonationRequiredDialog()
                : () => _navigateToThemeSelect(settingsState),
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
                    .withOpacity(0.98),
          margin: const EdgeInsets.only(bottom: 14),
          child: SettingsUI.buildSettingsListItem(
            title: 'フォント',
            subtitle: isLocked
                ? '寄付でアンロック'
                : SettingsLogic.getFontLabel(settingsState.selectedFont),
            leadingIcon: isLocked ? Icons.lock : Icons.font_download_rounded,
            backgroundColor: isLocked
                ? Colors.grey.withOpacity(0.3)
                : (widget.theme ?? _getCurrentTheme(settingsState))
                      .colorScheme
                      .primary,
            textColor: isLocked
                ? Colors.grey
                : (settingsState.selectedTheme == 'dark'
                      ? Colors.white
                      : Colors.black87),
            iconColor: isLocked
                ? Colors.grey
                : (settingsState.selectedTheme == 'light'
                      ? Colors.black87
                      : Colors.white),
            onTap: isLocked
                ? () => _showDonationRequiredDialog()
                : () => _navigateToFontSelect(settingsState),
          ),
        );
      },
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

  /// 寄付が必要なダイアログを表示
  void _showDonationRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('機能がロックされています'),
          ],
        ),
        content: Text(
          'この機能を利用するには、300円以上の寄付が必要です。\n'
          '寄付ページで特典をアンロックしてください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationScreen()),
              );
            },
            child: Text('寄付ページへ'),
          ),
        ],
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
