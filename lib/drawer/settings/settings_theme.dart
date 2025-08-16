import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/donation_manager.dart';

import '../../screens/subscription_screen.dart';
import 'settings_font.dart';

/// アプリ全体の色定義を管理するクラス
class AppColors {
  // プライマリカラー（ピンク）
  static const Color primary = Color(0xFFFFB6C1);

  // プライマリカラー上のテキスト色
  static const Color onPrimary = Colors.white;

  // セカンダリカラー（ミントグリーン）
  static const Color secondary = Color(0xFFB5EAD7);

  // サードカラー（ライトブルー）
  static const Color tertiary = Color(0xFFC7CEEA);

  // アクセントカラー（イエロー）
  static const Color accent = Color(0xFFFFDAC1);

  // 背景色
  static const Color background = Color(0xFFFFF1F8);

  // 表面色
  static const Color surface = Color(0xFFFFF1F8);

  // エラー色
  static const Color error = Color(0xFFE57373);

  // 成功色
  static const Color success = Color(0xFF81C784);

  // 警告色
  static const Color warning = Color(0xFFFFB74D);

  // 情報色
  static const Color info = Color(0xFF64B5F6);

  // テキスト色
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textDisabled = Colors.black38;

  // ボーダー色
  static const Color border = Color(0xFFE0E0E0);

  // シャドウ色
  static const Color shadow = Color(0x1A000000);
}

/// アプリ全体のテーマ定義を管理するクラス
class SettingsTheme {
  /// テーマデータを生成
  static ThemeData generateTheme({
    required String selectedTheme,
    required String selectedFont,
    double fontSize = 16.0,
  }) {
    Color primary, secondary, surface;
    Color onPrimary, onSurface;

    // テキストテーマを先に取得
    TextTheme textTheme = _getTextTheme(selectedFont, fontSize);

    switch (selectedTheme) {
      case 'light':
        primary = Color(0xFF9E9E9E); // より薄いグレー
        secondary = Color(0xFFBDBDBD);
        surface = Color(0xFFFAFAFA); // より薄いグレー
        break;
      case 'dark':
        primary = Color(0xFF1F1F1F); // YouTube風の明るい黒
        secondary = Color(0xFF2D2D2D); // より明るいグレー
        surface = Color(0xFF0F0F0F); // YouTube風の背景色
        break;
      case 'orange':
        primary = Color(0xFFFFC107);
        secondary = Color(0xFFFFE082); // オレンジ
        surface = Color(0xFFFFF8E1);
        break;
      case 'green':
        primary = Color(0xFF8BC34A);
        secondary = Color(0xFFC5E1A5); // グリーン
        surface = Color(0xFFF1F8E9);
        break;
      case 'blue':
        primary = Color(0xFF2196F3);
        secondary = Color(0xFF90CAF9); // ブルー
        surface = Color(0xFFE3F2FD);
        break;
      case 'gray':
        primary = Color(0xFF90A4AE);
        secondary = Color(0xFFCFD8DC); // グレー
        surface = Color(0xFFF5F5F5);
        break;
      case 'beige':
        primary = Color(0xFFFFE0B2);
        secondary = Color(0xFFFFECB3); // ベージュ
        surface = Color(0xFFFFF8E1);
        break;
      case 'mint':
        primary = Color(0xFFB5EAD7);
        secondary = Color(0xFFA8E6CF); // ミントグリーン
        surface = Color(0xFFE0F7FA);
        break;
      case 'lavender':
        primary = Color(0xFFB39DDB);
        secondary = Color(0xFFD1C4E9); // ラベンダー
        surface = Color(0xFFF3E5F5);
        break;
      case 'purple':
        primary = Color(0xFF9C27B0);
        secondary = Color(0xFFCE93D8); // パープル
        surface = Color(0xFFF3E5F5);
        break;
      case 'teal':
        primary = Color(0xFF009688);
        secondary = Color(0xFF80CBC4); // ティール
        surface = Color(0xFFE0F2F1);
        break;
      case 'amber':
        primary = Color(0xFFFF9800);
        secondary = Color(0xFFFFCC02); // アンバー
        surface = Color(0xFFFFF8E1);
        break;
      case 'indigo':
        primary = Color(0xFF3F51B5);
        secondary = Color(0xFF9FA8DA); // インディゴ
        surface = Color(0xFFE8EAF6);
        break;
      case 'soda':
        primary = Color(0xFF81D4FA);
        secondary = Color(0xFFB3E5FC); // ソーダブルー
        surface = Color(0xFFE1F5FE);
        break;
      case 'coral':
        primary = Color(0xFFFFAB91);
        secondary = Color(0xFFFFCCBC); // コーラル
        surface = Color(0xFFFFF3E0);
        break;
      default: // pink
        primary = Color(0xFFFFC0CB); // パステルピンク（アクセント）
        secondary = Color(0xFFFFE4E1); // より薄いピンク
        surface = Colors.white; // 白の背景
    }

    // テキストカラーの設定
    onPrimary = Colors.white;
    onSurface = selectedTheme == 'dark' ? Colors.white : Colors.black87;

    // 統一された背景色の設定
    final backgroundColor = _getBackgroundColor(selectedTheme);

    // 統一されたカード色の設定
    final cardColor = selectedTheme == 'dark'
        ? Color(0xFF1F1F1F) // YouTube風のカード色
        : Colors.white;

    // 統一されたボーダー色の設定
    final borderColor = selectedTheme == 'dark'
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black87.withValues(alpha: 0.3);

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: selectedTheme == 'dark'
            ? Brightness.dark
            : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface, // カード色と統一
        onSurface: onSurface, // 背景上のテキスト色
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: textTheme.apply(
        bodyColor: selectedTheme == 'dark' ? Colors.white : Colors.black87,
        displayColor: selectedTheme == 'dark' ? Colors.white : Colors.black87,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: borderColor,
      useMaterial3: true,
    );
  }

  /// フォントに基づいてテキストテーマを取得
  static TextTheme _getTextTheme(String selectedFont, double fontSize) {
    return FontSettings.getTextTheme(selectedFont, fontSize);
  }

  /// 背景色を取得
  static Color _getBackgroundColor(String theme) {
    switch (theme) {
      case 'light':
        return Color(0xFFFAFAFA); // より薄いグレー
      case 'dark':
        return Color(0xFF0F0F0F); // YouTube風の背景色
      case 'mint':
        return Color(0xFFE0F7FA); // ミントグリーン
      case 'lavender':
        return Color(0xFFF3E5F5); // ラベンダー
      case 'purple':
        return Color(0xFFF3E5F5); // パープル
      case 'teal':
        return Color(0xFFE0F2F1); // ティール
      case 'amber':
        return Color(0xFFFFF8E1); // アンバー
      case 'indigo':
        return Color(0xFFE8EAF6); // インディゴ
      case 'soda':
        return Color(0xFFE1F5FE); // ソーダブルー
      case 'coral':
        return Color(0xFFFFF3E0); // コーラル
      case 'orange':
        return Color(0xFFFFF8E1); // オレンジ
      case 'green':
        return Color(0xFFF1F8E9); // グリーン
      case 'blue':
        return Color(0xFFE3F2FD); // ブルー
      case 'gray':
        return Color(0xFFFAFAFA); // より薄いグレー
      case 'beige':
        return Color(0xFFFFF8E1); // ベージュ
      case 'pink':
        return Color(0xFFFFF1F8); // パステルピンクの背景
      default:
        return Color(0xFFFAFAFA); // デフォルトも薄いグレー
    }
  }

  /// テーマのラベルを取得
  static String getThemeLabel(String key) {
    switch (key) {
      case 'pink':
        return 'デフォルト';
      case 'light':
        return 'ライト';
      case 'dark':
        return 'ダーク';

      case 'orange':
        return 'オレンジ';
      case 'green':
        return 'グリーン';
      case 'soda':
        return 'ソーダ';
      case 'blue':
        return 'ブルー';
      case 'lavender':
        return 'ラベンダー';
      case 'coral':
        return 'コーラル';
      case 'beige':
        return 'ベージュ';
      case 'gray':
        return 'グレー';
      case 'mint':
        return 'ミント';
      case 'purple':
        return 'パープル';
      case 'teal':
        return 'ティール';
      case 'amber':
        return 'アンバー';
      case 'indigo':
        return 'インディゴ';
      default:
        return 'デフォルト';
    }
  }

  /// 利用可能なテーマのリストを取得
  static List<Map<String, dynamic>> getAvailableThemes() {
    return [
      {'key': 'pink', 'label': 'デフォルト', 'color': Color(0xFFFFB6C1)},
      {'key': 'light', 'label': 'ライト', 'color': Color(0xFFEEEEEE)},
      {'key': 'orange', 'label': 'オレンジ', 'color': Color(0xFFFFC107)},
      {'key': 'dark', 'label': 'ダーク', 'color': Color(0xFF424242)},

      {'key': 'green', 'label': 'グリーン', 'color': Color(0xFF8BC34A)},
      {'key': 'soda', 'label': 'ソーダ', 'color': Color(0xFF81D4FA)},
      {'key': 'blue', 'label': 'ブルー', 'color': Color(0xFF2196F3)},
      {'key': 'lavender', 'label': 'ラベンダー', 'color': Color(0xFFB39DDB)},
      {'key': 'coral', 'label': 'コーラル', 'color': Color(0xFFFFAB91)},
      {'key': 'beige', 'label': 'ベージュ', 'color': Color(0xFFFFE0B2)},
      {'key': 'gray', 'label': 'グレー', 'color': Color(0xFF90A4AE)},
      {'key': 'mint', 'label': 'ミント', 'color': Color(0xFFB5EAD7)},
      {'key': 'purple', 'label': 'パープル', 'color': Color(0xFF9C27B0)},
      {'key': 'teal', 'label': 'ティール', 'color': Color(0xFF009688)},
      {'key': 'amber', 'label': 'アンバー', 'color': Color(0xFFFF9800)},
      {'key': 'indigo', 'label': 'インディゴ', 'color': Color(0xFF3F51B5)},
    ];
  }

  /// 背景色に対するコントラスト色を取得
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// テーマ選択画面のウィジェット
/// テーマの選択機能
class ThemeSelectScreen extends StatefulWidget {
  final String currentTheme;
  final ThemeData? theme;
  final ValueChanged<String> onThemeChanged;

  const ThemeSelectScreen({
    super.key,
    required this.currentTheme,
    this.theme,
    required this.onThemeChanged,
  });

  @override
  State<ThemeSelectScreen> createState() => _ThemeSelectScreenState();
}

class _ThemeSelectScreenState extends State<ThemeSelectScreen> {
  late String selectedTheme;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
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
    final themes = SettingsTheme.getAvailableThemes();

    return Consumer<DonationManager>(
      builder: (context, donationManager, child) {
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
            final isLocked =
                !donationManager.canChangeTheme && theme['key'] != 'pink';

            return _buildThemeItem(
              context: context,
              theme: theme,
              isSelected: isSelected,
              isLocked: isLocked,
              backgroundColor: Theme.of(context).cardColor,
              textColor: selectedTheme == 'dark'
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              primaryColor: Theme.of(context).colorScheme.primary,
              onTap: isLocked
                  ? () => _showDonationRequiredDialog()
                  : () {
                      final newTheme = theme['key'] as String;
                      widget.onThemeChanged(newTheme);
                      setState(() {
                        selectedTheme = newTheme;
                      });
                    },
            );
          },
        );
      },
    );
  }

  /// プレミアムプランが必要なダイアログを表示
  void _showDonationRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアムプランが必要です'),
        content: const Text('テーマカスタマイズ機能はプレミアムプラン以上で利用できます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // サブスクリプション画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text('プランを確認'),
          ),
        ],
      ),
    );
  }

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme() {
    return SettingsTheme.generateTheme(
      selectedTheme: selectedTheme,
      selectedFont: 'nunito', // デフォルトフォント
    );
  }

  /// テーマ選択アイテムを作成
  Widget _buildThemeItem({
    required BuildContext context,
    required Map<String, dynamic> theme,
    required bool isSelected,
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withAlpha(25)
              : Theme.of(context).cardColor,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme['color'] as Color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (theme['color'] as Color).withAlpha(76),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme['label'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : textColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '選択中',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            if (isLocked) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 10),
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
          ],
        ),
      ),
    );
  }
}

/// 設定画面の状態管理クラス
/// テーマ、フォント、フォントサイズなどの状態を管理
class SettingsState extends ChangeNotifier {
  String _selectedTheme = 'pink';
  String _selectedFont = 'nunito';
  double _selectedFontSize = 16.0;

  // Getters
  String get selectedTheme => _selectedTheme;
  String get selectedFont => _selectedFont;
  double get selectedFontSize => _selectedFontSize;

  /// テーマを更新
  void updateTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  /// フォントを更新
  void updateFont(String font) {
    _selectedFont = font;
    notifyListeners();
  }

  /// フォントサイズを更新
  void updateFontSize(double fontSize) {
    _selectedFontSize = fontSize;
    notifyListeners();
  }

  /// 初期状態を設定
  void setInitialState({
    required String theme,
    required String font,
    required double fontSize,
  }) {
    _selectedTheme = theme;
    _selectedFont = font;
    _selectedFontSize = fontSize;
    notifyListeners();
  }
}
