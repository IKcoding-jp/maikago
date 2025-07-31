import 'package:flutter/material.dart';
import 'settings_logic.dart';
import 'settings_ui.dart';

/// テーマ選択画面のウィジェット
/// テーマの選択、カスタムカラーの設定、カラーピッカーなどの機能
class ThemeSelectScreen extends StatefulWidget {
  final String currentTheme;
  final ThemeData? theme;
  final ValueChanged<String> onThemeChanged;
  final Map<String, Color>? customColors;
  final ValueChanged<Map<String, Color>>? onCustomThemeChanged;
  final Map<String, Color>? detailedColors;
  final ValueChanged<Map<String, Color>>? onDetailedColorsChanged;
  final Future<void> Function()? onSaveCustomTheme;

  const ThemeSelectScreen({
    super.key,
    required this.currentTheme,
    this.theme,
    required this.onThemeChanged,
    this.customColors,
    this.onCustomThemeChanged,
    this.detailedColors,
    this.onDetailedColorsChanged,
    this.onSaveCustomTheme,
  });

  @override
  State<ThemeSelectScreen> createState() => _ThemeSelectScreenState();
}

class _ThemeSelectScreenState extends State<ThemeSelectScreen> {
  late String selectedTheme;
  late Map<String, Color> customColors;
  late Map<String, Color> detailedColors;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
    customColors =
        widget.customColors ??
        {
          'primary': Color(0xFFFFB6C1),
          'secondary': Color(0xFFB5EAD7),
          'surface': Color(0xFFFFF1F8),
        };
    detailedColors =
        widget.detailedColors ??
        {
          'appBarColor': customColors['primary']!,
          'backgroundColor': customColors['surface']!,
          'buttonColor': customColors['primary']!,
          'backgroundColor2': customColors['surface']!,
          'fontColor1': Colors.black87,
          'fontColor2': Colors.white,
          'iconColor': customColors['primary']!,
          'cardBackgroundColor': Colors.white,
          'borderColor': Color(0xFFE0E0E0),
          'dialogBackgroundColor': Colors.white,
          'dialogTextColor': Colors.black87,
          'inputBackgroundColor': Color(0xFFF5F5F5),
          'inputTextColor': Colors.black87,
        };
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _getCurrentTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'テーマを選択',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _getCurrentTheme().colorScheme.primary,
          foregroundColor:
              _getCurrentTheme().colorScheme.primary.computeLuminance() > 0.5
              ? Colors.black87
              : Colors.white,
          iconTheme: IconThemeData(
            color:
                _getCurrentTheme().colorScheme.primary.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          ),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withAlpha(13),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(child: _buildThemeGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.palette_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'テーマを選択',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'お好みのカラーテーマを選んでください',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// テーマ選択グリッドを構築
  Widget _buildThemeGrid() {
    final themes = SettingsLogic.getAvailableThemes();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = selectedTheme == theme['key'] as String;

        return SettingsUI.buildThemeItem(
          theme: theme,
          isSelected: isSelected,
          backgroundColor: selectedTheme == 'dark'
              ? Color(0xFF424242)
              : (Theme.of(context).colorScheme.surface == Colors.white
                    ? Color(0xFFF8F9FA)
                    : Theme.of(context).colorScheme.surface),
          textColor: selectedTheme == 'dark'
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          primaryColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            widget.onThemeChanged(theme['key'] as String);
            setState(() {
              selectedTheme = theme['key'] as String;
            });
          },
        );
      },
    );
  }

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme() {
    return SettingsLogic.generateTheme(
      selectedTheme: selectedTheme,
      selectedFont: 'nunito', // デフォルトフォント
      detailedColors: detailedColors,
    );
  }
}
