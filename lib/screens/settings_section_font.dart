import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_logic.dart';
import 'settings_ui.dart';
import '../services/donation_manager.dart';
import 'donation_screen.dart';

/// フォント選択画面のウィジェット
/// フォントの選択とプレビュー機能
class FontSelectScreen extends StatefulWidget {
  final String currentFont;
  final ThemeData? theme;
  final ValueChanged<String> onFontChanged;

  const FontSelectScreen({
    super.key,
    required this.currentFont,
    this.theme,
    required this.onFontChanged,
  });

  @override
  State<FontSelectScreen> createState() => _FontSelectScreenState();
}

class _FontSelectScreenState extends State<FontSelectScreen>
    with TickerProviderStateMixin {
  late String selectedFont;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    selectedFont = widget.currentFont;
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
                Theme.of(context).colorScheme.primary.withAlpha(13),
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

  /// フォントコンテンツを構築
  Widget _buildFontContent() {
    return SingleChildScrollView(child: Column(children: [_buildFontGrid()]));
  }

  /// フォント選択グリッドを構築
  Widget _buildFontGrid() {
    final fonts = SettingsLogic.getAvailableFonts();

    return Consumer<DonationManager>(
      builder: (context, donationManager, child) {
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
            final isLocked =
                !donationManager.canChangeFont && font['key'] != 'nunito';

            return SettingsUI.buildFontItem(
              context: context,
              font: font,
              isSelected: isSelected,
              isLocked: isLocked,
              backgroundColor: Theme.of(context).colorScheme.surface,
              textColor: Theme.of(context).colorScheme.onSurface,
              primaryColor: Theme.of(context).colorScheme.primary,
              onTap: isLocked
                  ? () => _showDonationRequiredDialog()
                  : () {
                      setState(() {
                        selectedFont = font['key'] as String;
                      });
                      widget.onFontChanged(font['key'] as String);
                    },
            );
          },
        );
      },
    );
  }

  /// 寄付が必要なダイアログを表示
  void _showDonationRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('寄付が必要です'),
        content: const Text('このフォントを利用するには寄付が必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 寄付画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationScreen()),
              );
            },
            child: const Text('寄付する'),
          ),
        ],
      ),
    );
  }
}

/// フォントサイズ選択画面
class FontSizeSelectScreen extends StatefulWidget {
  final double currentFontSize;
  final ThemeData theme;
  final ValueChanged<double> onFontSizeChanged;

  const FontSizeSelectScreen({
    super.key,
    required this.currentFontSize,
    required this.theme,
    required this.onFontSizeChanged,
  });

  @override
  State<FontSizeSelectScreen> createState() => _FontSizeSelectScreenState();
}

class _FontSizeSelectScreenState extends State<FontSizeSelectScreen> {
  late double _selectedFontSize;

  @override
  void initState() {
    super.initState();
    _selectedFontSize = widget.currentFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォントサイズ'),
        backgroundColor: widget.theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プレビューセクション
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.theme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プレビュー',
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'このテキストのサイズで表示されます',
                    style: widget.theme.textTheme.bodyLarge?.copyWith(
                      fontSize: _selectedFontSize,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '小さいテキストの例',
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      fontSize: _selectedFontSize - 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // フォントサイズ選択
            Text(
              'フォントサイズ',
              style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.theme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // スライダー
                  Slider(
                    value: _selectedFontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    label: '${_selectedFontSize.toInt()}px',
                    onChanged: (value) {
                      setState(() {
                        _selectedFontSize = value;
                      });
                      widget.onFontSizeChanged(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // プリセットボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPresetButton(14.0, '小'),
                      _buildPresetButton(16.0, '中'),
                      _buildPresetButton(18.0, '大'),
                      _buildPresetButton(20.0, '特大'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 現在のサイズ表示
            Center(
              child: Text(
                '現在のサイズ: ${_selectedFontSize.toInt()}px',
                style: widget.theme.textTheme.bodyMedium?.copyWith(
                  fontSize: _selectedFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(double fontSize, String label) {
    final isSelected = _selectedFontSize == fontSize;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFontSize = fontSize;
        });
        widget.onFontSizeChanged(fontSize);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? widget.theme.colorScheme.primary
            : widget.theme.colorScheme.surface,
        foregroundColor: isSelected
            ? Colors.white
            : widget.theme.colorScheme.onSurface,
        side: BorderSide(
          color: isSelected
              ? widget.theme.colorScheme.primary
              : widget.theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: TextStyle(fontSize: fontSize - 2)),
    );
  }
}
