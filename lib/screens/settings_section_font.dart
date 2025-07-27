import 'package:flutter/material.dart';
import 'settings_logic.dart';
import 'settings_ui.dart';

/// フォント選択画面のウィジェット
/// フォントの選択、フォントサイズの調整、プレビュー機能など
class FontSelectScreen extends StatefulWidget {
  final String currentFont;
  final double currentFontSize;
  final ThemeData? theme;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<double> onFontSizeChanged;

  const FontSelectScreen({
    super.key,
    required this.currentFont,
    required this.currentFontSize,
    this.theme,
    required this.onFontChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<FontSelectScreen> createState() => _FontSelectScreenState();
}

class _FontSelectScreenState extends State<FontSelectScreen>
    with TickerProviderStateMixin {
  late String selectedFont;
  late double selectedFontSize;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    selectedFont = widget.currentFont;
    selectedFontSize = widget.currentFontSize;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.theme ?? Theme.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'フォントを選択',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildFontContent()),
                ],
              ),
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
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.font_download_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'お好みのフォントを選んでください',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '選択したフォントがアプリ全体に適用されます',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// フォントコンテンツを構築
  Widget _buildFontContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFontGrid(),
          const SizedBox(height: 24),
          _buildFontSizeSection(),
        ],
      ),
    );
  }

  /// フォント選択グリッドを構築
  Widget _buildFontGrid() {
    final fonts = SettingsLogic.getAvailableFonts();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: fonts.length,
      itemBuilder: (context, index) {
        final font = fonts[index];
        final isSelected = selectedFont == font['key'];

        return SettingsUI.buildFontItem(
          font: font,
          isSelected: isSelected,
          backgroundColor: Theme.of(context).colorScheme.surface,
          textColor: Theme.of(context).colorScheme.onSurface,
          primaryColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            setState(() {
              selectedFont = font['key'] as String;
            });
            widget.onFontChanged(font['key'] as String);
          },
        );
      },
    );
  }

  /// フォントサイズ設定セクションを構築
  Widget _buildFontSizeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFontSizeHeader(),
          const SizedBox(height: 16),
          _buildFontSizeSlider(),
          const SizedBox(height: 12),
          _buildFontSizePreview(),
        ],
      ),
    );
  }

  /// フォントサイズヘッダーを構築
  Widget _buildFontSizeHeader() {
    return Row(
      children: [
        Icon(
          Icons.format_size_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          'フォントサイズ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// フォントサイズスライダーを構築
  Widget _buildFontSizeSlider() {
    return SettingsUI.buildFontSizeSlider(
      context: context,
      value: selectedFontSize,
      min: 12.0,
      max: 24.0,
      divisions: 12,
      primaryColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onSurface,
      onChanged: (fontSize) {
        setState(() {
          selectedFontSize = fontSize;
        });
        widget.onFontSizeChanged(fontSize);
      },
    );
  }

  /// フォントサイズプレビューを構築
  Widget _buildFontSizePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'プレビュー: このテキストでフォントサイズを確認できます',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: selectedFontSize,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
