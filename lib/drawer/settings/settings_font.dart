import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/donation_manager.dart';
import '../donation_screen.dart';

/// フォント設定を管理するクラス
class FontSettings {
  /// フォントに基づいてテキストテーマを取得
  static TextTheme getTextTheme(String selectedFont, double fontSize) {
    TextTheme baseTextTheme;
    switch (selectedFont) {
      case 'sawarabi':
        baseTextTheme = GoogleFonts.sawarabiMinchoTextTheme();
        break;
      case 'mplus':
        baseTextTheme = GoogleFonts.mPlus1pTextTheme();
        break;
      case 'zenmaru':
        baseTextTheme = GoogleFonts.zenMaruGothicTextTheme();
        break;
      case 'yuseimagic':
        baseTextTheme = GoogleFonts.yuseiMagicTextTheme();
        break;
      case 'yomogi':
        baseTextTheme = GoogleFonts.yomogiTextTheme();
        break;
      default:
        baseTextTheme = GoogleFonts.nunitoTextTheme();
    }

    // フォントサイズを明示的に指定
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: fontSize + 10,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: fontSize + 6,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: fontSize + 2,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: fontSize + 4,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: fontSize + 2,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: fontSize),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: fontSize),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: fontSize - 2),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: fontSize - 4),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: fontSize),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: fontSize - 2),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: fontSize - 4),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: fontSize - 2),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: fontSize - 4),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: fontSize - 6),
    );
  }

  /// フォントのラベルを取得
  static String getFontLabel(String key) {
    switch (key) {
      case 'sawarabi':
        return '明朝体';
      case 'mplus':
        return 'ゴシック体';
      case 'zenmaru':
        return '丸ゴシック体';
      case 'yuseimagic':
        return '毛筆';
      case 'yomogi':
        return 'かわいい';
      case 'nunito':
        return 'デフォルト';
      default:
        return 'デフォルト';
    }
  }

  /// 利用可能なフォントのリストを取得
  static List<Map<String, dynamic>> getAvailableFonts() {
    return [
      {'key': 'nunito', 'label': 'デフォルト', 'style': GoogleFonts.nunito()},
      {
        'key': 'sawarabi',
        'label': '明朝体',
        'style': GoogleFonts.sawarabiMincho(),
      },
      {'key': 'mplus', 'label': 'ゴシック体', 'style': GoogleFonts.mPlus1p()},
      {
        'key': 'zenmaru',
        'label': '丸ゴシック体',
        'style': GoogleFonts.zenMaruGothic(),
      },
      {'key': 'yuseimagic', 'label': '毛筆', 'style': GoogleFonts.yuseiMagic()},
      {'key': 'yomogi', 'label': 'かわいい', 'style': GoogleFonts.yomogi()},
    ];
  }
}

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
        color: Theme.of(context).cardColor,
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
    final fonts = FontSettings.getAvailableFonts();

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

            return _buildFontItem(
              context: context,
              font: font,
              isSelected: isSelected,
              isLocked: isLocked,
              backgroundColor: Theme.of(context).cardColor,
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

  /// フォント選択アイテムを作成
  Widget _buildFontItem({
    required BuildContext context,
    required Map<String, dynamic> font,
    required bool isSelected,
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withAlpha(25)
            : (backgroundColor == Colors.white
                  ? Color(0xFFF8F9FA)
                  : backgroundColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.withAlpha(51),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withAlpha(38),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  font['label'] as String,
                  style: (font['style'] as TextStyle).copyWith(
                    fontSize:
                        Theme.of(context).textTheme.titleMedium?.fontSize ?? 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          '選択中',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          'ロック',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
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
                color: widget.theme.cardColor,
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
                color: widget.theme.cardColor,
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
            : widget.theme.cardColor,
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
