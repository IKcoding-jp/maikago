import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_theme.dart';

/// プライバシーポリシー画面
class PrivacyPolicyScreen extends StatefulWidget {
  final String currentTheme;
  final String currentFont;
  final double currentFontSize;
  final ThemeData? theme;

  const PrivacyPolicyScreen({
    super.key,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
    this.theme,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
        'プライバシーポリシー',
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(settingsState),
            const SizedBox(height: 24),
            _buildPrivacyContent(settingsState),
          ],
        ),
      ),
    );
  }

  /// ヘッダーを構築
  Widget _buildHeader(SettingsState settingsState) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: (widget.theme ?? _getCurrentTheme(settingsState)).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      (widget.theme ?? _getCurrentTheme(settingsState))
                          .colorScheme
                          .primary,
                  child: Icon(
                    Icons.privacy_tip_rounded,
                    color: (widget.theme ?? _getCurrentTheme(settingsState))
                        .colorScheme
                        .onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'プライバシーポリシー',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              '最終更新日: 2024年12月',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: settingsState.selectedTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// プライバシーポリシーの内容を構築
  Widget _buildPrivacyContent(SettingsState settingsState) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: (widget.theme ?? _getCurrentTheme(settingsState)).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '1. 個人情報の収集について',
              content:
                  '当社は、Maikagoアプリ（以下「本アプリ」）の提供にあたり、以下の個人情報を収集する場合があります。\n\n'
                  '• アカウント情報（ユーザー名、メールアドレス等）\n'
                  '• アプリの利用状況データ\n'
                  '• デバイス情報（OS、バージョン等）\n'
                  '• その他、サービス提供に必要な情報',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '2. 個人情報の利用目的',
              content:
                  '収集した個人情報は、以下の目的で利用いたします。\n\n'
                  '• 本アプリの提供・運営\n'
                  '• ユーザーサポートの提供\n'
                  '• サービスの改善・開発\n'
                  '• セキュリティの確保\n'
                  '• 法令に基づく対応',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '3. 個人情報の管理',
              content:
                  '当社は、個人情報の正確性及び安全性を確保するために、セキュリティの向上及び個人情報の漏洩、滅失またはき損の防止その他の個人情報の安全管理のために必要かつ適切な措置を講じます。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '4. 個人情報の第三者提供',
              content:
                  '当社は、以下の場合を除き、個人情報を第三者に提供いたしません。\n\n'
                  '• ご本人の同意がある場合\n'
                  '• 法令に基づき開示することが必要である場合\n'
                  '• 人の生命、身体または財産の保護のために必要な場合\n'
                  '• 公衆衛生の向上または児童の健全な育成の推進のために特に必要な場合',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '5. 個人情報の開示・訂正・削除',
              content:
                  'ご本人からの個人情報の開示、訂正、削除、利用停止のご要望については、法令に基づき適切に対応いたします。お問い合わせは、アプリ内のフィードバック機能またはお問い合わせ先までご連絡ください。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '6. クッキー・トラッキング技術の使用',
              content:
                  '本アプリでは、ユーザーエクスペリエンスの向上のため、クッキーや類似の技術を使用する場合があります。これらの技術により収集される情報は、統計的な分析やサービスの改善に使用されます。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '7. プライバシーポリシーの変更',
              content:
                  '当社は、必要に応じて、このプライバシーポリシーの内容を変更することがあります。その場合、変更内容をアプリ内でお知らせいたします。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '8. お問い合わせ',
              content:
                  '本プライバシーポリシーに関するお問い合わせは、アプリ内のフィードバック機能または以下の方法でお願いいたします。\n\n'
                  '• アプリ内フィードバック機能をご利用ください\n'
                  '• お問い合わせの際は、具体的な内容をお知らせください',
              settingsState: settingsState,
            ),
          ],
        ),
      ),
    );
  }

  /// セクションを構築
  Widget _buildSection({
    required String title,
    required String content,
    required SettingsState settingsState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: settingsState.selectedTheme == 'dark'
                ? Colors.white
                : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: settingsState.selectedTheme == 'dark'
                ? Colors.white70
                : Colors.black87,
            height: 1.6,
          ),
        ),
      ],
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
