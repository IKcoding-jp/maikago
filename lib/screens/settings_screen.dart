import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'account_screen.dart';

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
  late String selectedTheme;
  late String selectedFont;
  late double selectedFontSize;
  late Map<String, Color> customColors;
  late Map<String, Color> detailedColors;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
    selectedFont = widget.currentFont;
    selectedFontSize = widget.currentFontSize;
    customColors =
        widget.customColors ??
        {
          'primary': Color(0xFFFFB6C1),
          'secondary': Color(0xFFB5EAD7),
          'surface': Color(0xFFFFF1F8),
        };
    _initializeDetailedColors();
  }

  void _initializeDetailedColors() {
    detailedColors = {
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
      'tabColor': customColors['tabColor'] ?? customColors['primary']!,
    };
  }

  Future<void> _saveCustomTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customThemesJson = prefs.getString('custom_themes');
      Map<String, Map<String, dynamic>> customThemes = {};

      if (customThemesJson != null) {
        customThemes = Map<String, Map<String, dynamic>>.from(
          json.decode(customThemesJson),
        );
      }

      final themeName = 'カスタム${customThemes.length + 1}';
      customThemes[themeName] = detailedColors.map(
        (k, v) => MapEntry(
          k,
          (((v.a.toInt()) << 24) |
              (v.r.toInt() << 16) |
              (v.g.toInt() << 8) |
              v.b.toInt()),
        ),
      );

      await prefs.setString('custom_themes', json.encode(customThemes));
    } catch (e) {
      // 本番環境ではprintを使わず、必要ならロギングフレームワークを利用してください。
    }
  }

  void _handleThemeChanged(String theme) {
    setState(() {
      selectedTheme = theme;
    });
    widget.onThemeChanged(theme);
  }

  void _handleFontChanged(String font) {
    setState(() {
      selectedFont = font;
    });
    widget.onFontChanged(font);
  }

  void _handleFontSizeChanged(double fontSize) {
    setState(() {
      selectedFontSize = fontSize;
    });
    widget.onFontSizeChanged(fontSize);
  }

  ThemeData _getCurrentTheme() {
    Color primary, secondary, surface, tabColor;
    Color onPrimary, onSurface;
    if (selectedTheme == 'custom') {
      primary = detailedColors['appBarColor']!;
      secondary = detailedColors['buttonColor']!;
      surface = detailedColors['backgroundColor']!;
      tabColor = detailedColors['tabColor']!;
      customColors['tabColor'] = tabColor;
    } else {
      switch (selectedTheme) {
        case 'orange':
          primary = Color(0xFFFFC107);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'green':
          primary = Color(0xFF8BC34A);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF1F8E9);
          break;
        case 'blue':
          primary = Color(0xFF2196F3);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE3F2FD);
          break;
        case 'gray':
          primary = Color(0xFF90A4AE);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF5F5F5);
          break;
        case 'beige':
          primary = Color(0xFFFFE0B2);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'mint':
          primary = Color(0xFFB5EAD7);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE0F7FA);
          break;
        case 'lavender':
          primary = Color(0xFFB39DDB);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF3E5F5);
          break;
        case 'lemon':
          primary = Color(0xFFFFF176);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFFDE7);
          break;
        case 'soda':
          primary = Color(0xFF81D4FA);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE1F5FE);
          break;
        case 'coral':
          primary = Color(0xFFFFAB91);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF3E0);
          break;
        default:
          primary = Color(0xFFFFB6C1);
          secondary = Color(0xFFB5EAD7);
          surface = Color(0xFFFFF1F8);
      }
    }
    onPrimary = Colors.white;
    onSurface = Colors.black87;
    TextTheme textTheme;
    switch (selectedFont) {
      case 'sawarabi':
        textTheme = GoogleFonts.sawarabiMinchoTextTheme();
        break;
      case 'mplus':
        textTheme = GoogleFonts.mPlus1pTextTheme();
        break;
      case 'zenmaru':
        textTheme = GoogleFonts.zenMaruGothicTextTheme();
        break;
      case 'yuseimagic':
        textTheme = GoogleFonts.yuseiMagicTextTheme();
        break;
      case 'yomogi':
        textTheme = GoogleFonts.yomogiTextTheme();
        break;
      default:
        textTheme = GoogleFonts.nunitoTextTheme();
    }
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _getCurrentTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '設定',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor:
              (widget.theme ?? _getCurrentTheme()).colorScheme.primary,
          foregroundColor:
              (widget.theme ?? _getCurrentTheme()).colorScheme.onPrimary,
          iconTheme: IconThemeData(
            color: (widget.theme ?? _getCurrentTheme()).colorScheme.onPrimary,
          ),
          elevation: 0,
        ),
        body: Container(
          color: Colors.transparent,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0, left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: (widget.theme ?? _getCurrentTheme())
                          .colorScheme
                          .primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '設定',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // アカウント情報カード
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: (widget.theme ?? _getCurrentTheme())
                        .colorScheme
                        .surface
                        .withOpacity(0.98),
                    child: SizedBox(
                      height: 72,
                      child: ListTile(
                        dense: true,
                        minVerticalPadding: 8,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        title: Text(
                          'アカウント情報',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          authProvider.isLoggedIn
                              ? 'ログイン済み'
                              : 'Googleアカウントでログイン',
                        ),
                        leading: CircleAvatar(
                          backgroundImage: authProvider.userPhotoURL != null
                              ? NetworkImage(authProvider.userPhotoURL!)
                              : null,
                          backgroundColor: (widget.theme ?? _getCurrentTheme())
                              .colorScheme
                              .primary,
                          child: authProvider.userPhotoURL == null
                              ? Icon(
                                  Icons.account_circle_rounded,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AccountScreen()),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '外観',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                color: (widget.theme ?? _getCurrentTheme()).colorScheme.surface
                    .withOpacity(0.98),
                child: SizedBox(
                  height: 72,
                  child: ListTile(
                    dense: true,
                    minVerticalPadding: 8,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: Text(
                      'テーマ',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(_themeLabel(selectedTheme)),
                    leading: CircleAvatar(
                      backgroundColor: (widget.theme ?? _getCurrentTheme())
                          .colorScheme
                          .primary,
                      child: Icon(
                        Icons.color_lens_rounded,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: (widget.theme ?? _getCurrentTheme())
                          .colorScheme
                          .primary,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ThemeSelectScreen(
                            currentTheme: selectedTheme,
                            theme: _getCurrentTheme(),
                            onThemeChanged: _handleThemeChanged,
                            customColors: customColors,
                            onCustomThemeChanged: widget.onCustomThemeChanged,
                            detailedColors: detailedColors,
                            onDetailedColorsChanged: (colors) {
                              setState(() {
                                detailedColors = colors;
                              });
                            },
                            onSaveCustomTheme: _saveCustomTheme,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                color: (widget.theme ?? _getCurrentTheme()).colorScheme.surface
                    .withOpacity(0.98),
                child: SizedBox(
                  height: 72,
                  child: ListTile(
                    dense: true,
                    minVerticalPadding: 8,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: Text(
                      'フォント',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(_fontLabel(selectedFont)),
                    leading: CircleAvatar(
                      backgroundColor: (widget.theme ?? _getCurrentTheme())
                          .colorScheme
                          .primary,
                      child: Icon(
                        Icons.font_download_rounded,
                        color: Colors.white,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: (widget.theme ?? _getCurrentTheme())
                          .colorScheme
                          .primary,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FontSelectScreen(
                            currentFont: selectedFont,
                            currentFontSize: selectedFontSize,
                            theme: _getCurrentTheme(),
                            onFontChanged: _handleFontChanged,
                            onFontSizeChanged: _handleFontSizeChanged,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(String key) {
    switch (key) {
      case 'mint':
        return 'ミント';
      case 'lavender':
        return 'ラベンダー';
      case 'lemon':
        return 'レモン';
      case 'soda':
        return 'ソーダ';
      case 'coral':
        return 'コーラル';
      case 'orange':
        return 'オレンジ';
      case 'green':
        return 'グリーン';
      case 'blue':
        return 'ブルー';
      case 'gray':
        return 'グレー';
      case 'beige':
        return 'ベージュ';
      case 'custom':
        return 'カスタム';
      default:
        return 'パステルピンク';
    }
  }

  String _fontLabel(String key) {
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
}

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
          actions: [],
        ),
        body: ListView(
          children: [
            _themeTile(context, 'pink', 'デフォルト', Color(0xFFFFB6C1)),
            _themeTile(context, 'mint', 'ミント', Color(0xFFB5EAD7)),
            _themeTile(context, 'lavender', 'ラベンダー', Color(0xFFB39DDB)),
            _themeTile(context, 'lemon', 'レモン', Color(0xFFFFF176)),
            _themeTile(context, 'soda', 'ソーダ', Color(0xFF81D4FA)),
            _themeTile(context, 'coral', 'コーラル', Color(0xFFFFAB91)),
            _themeTile(context, 'orange', 'オレンジ', Color(0xFFFFC107)),
            _themeTile(context, 'green', 'グリーン', Color(0xFF8BC34A)),
            _themeTile(context, 'blue', 'ブルー', Color(0xFF2196F3)),
            _themeTile(context, 'gray', 'グレー', Color(0xFF90A4AE)),
            _themeTile(context, 'beige', 'ベージュ', Color(0xFFFFE0B2)),
          ],
        ),
      ),
    );
  }

  ThemeData _getCurrentTheme() {
    Color primary, secondary, surface;
    Color onPrimary, onSurface;
    if (selectedTheme == 'custom') {
      primary = detailedColors['appBarColor']!;
      secondary = detailedColors['buttonColor']!;
      surface = detailedColors['backgroundColor']!;
    } else {
      switch (selectedTheme) {
        case 'orange':
          primary = Color(0xFFFFC107);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'green':
          primary = Color(0xFF8BC34A);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF1F8E9);
          break;
        case 'blue':
          primary = Color(0xFF2196F3);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE3F2FD);
          break;
        case 'gray':
          primary = Color(0xFF90A4AE);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF5F5F5);
          break;
        case 'beige':
          primary = Color(0xFFFFE0B2);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF8E1);
          break;
        case 'mint':
          primary = Color(0xFFB5EAD7);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE0F7FA);
          break;
        case 'lavender':
          primary = Color(0xFFB39DDB);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFF3E5F5);
          break;
        case 'lemon':
          primary = Color(0xFFFFF176);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFFDE7);
          break;
        case 'soda':
          primary = Color(0xFF81D4FA);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFE1F5FE);
          break;
        case 'coral':
          primary = Color(0xFFFFAB91);
          secondary = Color(0xFFFFB6C1);
          surface = Color(0xFFFFF3E0);
          break;
        default:
          primary = Color(0xFFFFB6C1);
          secondary = Color(0xFFB5EAD7);
          surface = Color(0xFFFFF1F8);
      }
    }
    onPrimary = Colors.white;
    onSurface = Colors.black87;
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: Colors.red,
        onError: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  Widget _themeTile(
    BuildContext context,
    String key,
    String label,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: selectedTheme == key
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        widget.onThemeChanged(key);
        setState(() {
          selectedTheme = key;
        });
      },
    );
  }

  Widget _colorPaletteItem(String name, Color currentColor) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                '$nameの色を選択',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) {
                    setState(() {
                      // 色名に基づいて適切なプロパティを更新
                      switch (name) {
                        case 'アプリバー':
                          detailedColors['appBarColor'] = color;
                          break;
                        case 'ボタン':
                          detailedColors['buttonColor'] = color;
                          break;
                        case 'アイコン':
                          detailedColors['iconColor'] = color;
                          break;
                        case 'タブ':
                          detailedColors['tabColor'] = color;
                          break;
                        case 'メイン背景':
                          detailedColors['backgroundColor'] = color;
                          break;
                        case 'カード背景':
                          detailedColors['cardBackgroundColor'] = color;
                          break;
                        case 'ダイアログ背景':
                          detailedColors['dialogBackgroundColor'] = color;
                          break;
                        case '入力欄背景':
                          detailedColors['inputBackgroundColor'] = color;
                          break;
                        case 'ボーダー':
                          detailedColors['borderColor'] = color;
                          break;
                      }
                      widget.onDetailedColorsChanged?.call(detailedColors);
                    });
                  },
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: _getContrastColor(currentColor),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

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
                  // ヘッダー部分
                  Container(
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '選択したフォントがアプリ全体に適用されます',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
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
                  ),
                  const SizedBox(height: 24),
                  // フォント選択肢
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              final fonts = [
                                {
                                  'key': 'nunito',
                                  'label': 'デフォルト',
                                  'style': GoogleFonts.nunito(),
                                },
                                {
                                  'key': 'sawarabi',
                                  'label': '明朝体',
                                  'style': GoogleFonts.sawarabiMincho(),
                                },
                                {
                                  'key': 'mplus',
                                  'label': 'ゴシック体',
                                  'style': GoogleFonts.mPlus1p(),
                                },
                                {
                                  'key': 'zenmaru',
                                  'label': '丸ゴシック体',
                                  'style': GoogleFonts.zenMaruGothic(),
                                },
                                {
                                  'key': 'yuseimagic',
                                  'label': '毛筆',
                                  'style': GoogleFonts.yuseiMagic(),
                                },
                                {
                                  'key': 'yomogi',
                                  'label': 'かわいい',
                                  'style': GoogleFonts.yomogi(),
                                },
                              ];
                              final font = fonts[index];
                              final isSelected = selectedFont == font['key'];

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        selectedFont = font['key'] as String;
                                      });
                                      widget.onFontChanged(
                                        font['key'] as String,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            font['label'] as String,
                                            style: (font['style'] as TextStyle)
                                                .copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 6),
                                          if (isSelected)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '選択中',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                            },
                          ),
                          const SizedBox(height: 24),
                          // フォントサイズ設定
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_size_rounded,
                                      size: 24,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'フォントサイズ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      '小',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          inactiveTrackColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3),
                                          thumbColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          overlayColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 16,
                                              ),
                                        ),
                                        child: Slider(
                                          value: selectedFontSize,
                                          min: 12.0,
                                          max: 24.0,
                                          divisions: 12,
                                          onChanged: (fontSize) {
                                            setState(() {
                                              selectedFontSize = fontSize;
                                            });
                                            widget.onFontSizeChanged(fontSize);
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '大',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: selectedFontSize),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
