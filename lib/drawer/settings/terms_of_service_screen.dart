import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_theme.dart';

/// 利用規約画面
class TermsOfServiceScreen extends StatefulWidget {
  final String currentTheme;
  final String currentFont;
  final double currentFontSize;
  final ThemeData? theme;

  const TermsOfServiceScreen({
    super.key,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
    this.theme,
  });

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
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
        '利用規約',
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
            _buildTermsContent(settingsState),
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
                    Icons.description_rounded,
                    color: (widget.theme ?? _getCurrentTheme(settingsState))
                        .colorScheme
                        .onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '利用規約',
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

  /// 利用規約の内容を構築
  Widget _buildTermsContent(SettingsState settingsState) {
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
              title: '第1条（適用）',
              content: '本規約は、Maikagoアプリ（以下「本アプリ」）の利用に関して適用されます。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第2条（利用登録）',
              content: '本アプリの利用者は、本規約に同意の上、本アプリを利用するものとします。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第3条（禁止事項）',
              content:
                  '利用者は、本アプリの利用にあたり、以下の行為をしてはなりません。\n\n'
                  '1. 法令または公序良俗に違反する行為\n'
                  '2. 犯罪行為に関連する行為\n'
                  '3. 本アプリのサーバーまたはネットワークの機能を破壊する行為\n'
                  '4. 他の利用者に迷惑をかける行為\n'
                  '5. その他、当社が不適切と判断する行為',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第4条（本アプリの提供の停止等）',
              content:
                  '当社は、以下のいずれかの事由があると判断した場合、利用者に事前に通知することなく本アプリの全部または一部の提供を停止または中断することができるものとします。\n\n'
                  '1. 本アプリにかかるコンピュータシステムの保守点検または更新を行う場合\n'
                  '2. 地震、落雷、火災、停電または天災などの不可抗力により、本アプリの提供が困難となった場合\n'
                  '3. その他、当社が本アプリの提供が困難と判断した場合',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第5条（免責事項）',
              content:
                  '当社は、本アプリに関して、利用者と他の利用者または第三者との間において生じた取引、連絡または紛争等について一切責任を負いません。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第6条（サービス内容の変更等）',
              content:
                  '当社は、利用者に通知することなく、本アプリの内容を変更しまたは本アプリの提供を中止することができるものとし、これによって利用者に生じた損害について一切の責任を負いません。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第7条（利用規約の変更）',
              content: '当社は、必要と判断した場合には、利用者に通知することなくいつでも本規約を変更することができるものとします。',
              settingsState: settingsState,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '第8条（準拠法・裁判管轄）',
              content:
                  '1. 本規約の解釈にあたっては、日本法を準拠法とします。\n'
                  '2. 本アプリに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。',
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
