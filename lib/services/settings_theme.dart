import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:maikago/widgets/common_dialog.dart';
import 'package:maikago/screens/drawer/settings/settings_font.dart';

/// アプリ全体の色定義を管理するクラス
class AppColors {
  // === ブランドカラー ===
  static const Color primary = Color(0xFFFFB6C1);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFFB5EAD7);
  static const Color tertiary = Color(0xFFC7CEEA);
  static const Color accent = Color(0xFFFFDAC1);

  // === 背景・表面色 ===
  static const Color background = Color(0xFFFFF1F8);
  static const Color surface = Color(0xFFFFF1F8);
  static const Color lightBackground = Color(0xFFF8F9FA);

  // === セマンティックカラー ===
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);

  // === テキスト色 ===
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textDisabled = Colors.black38;
  static const Color headingDark = Color(0xFF2C3E50);
  static const Color subtextGrey = Color(0xFF7F8C8D);

  // === ボーダー・シャドウ ===
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);

  // === プロモーション・プレミアム ===
  static const Color promoPink = Color(0xFFFFC0CB);

  // === 機能説明・装飾色 ===
  static const Color featureGreen = Color(0xFF90EE90);
  static const Color featureSky = Color(0xFF87CEEB);
  static const Color featureOrange = Color(0xFFFFA500);
  static const Color featureGold = Color(0xFFFFD700);
  static const Color featureMaterialGreen = Color(0xFF4CAF50);
  static const Color featureMaterialBlue = Color(0xFF2196F3);
  static const Color featureMaterialOrange = Color(0xFFFF9800);
  static const Color featurePurple = Color(0xFF9C27B0);
  static const Color featureRed = Color(0xFFE74C3C);
  static const Color featurePremiumBlue = Color(0xFF3498DB);
  static const Color featurePremiumGreen = Color(0xFF2ECC71);

  // === ダークテーマ固有色 ===
  static const Color darkBackground = Color(0xFF1C1C1C);
  static const Color darkSurface = Color(0xFF1C1C1C);
  static const Color darkCard = Color(0xFF2B2B2B);
  static const Color darkCardAlt = Color(0xFF333333);
  static const Color darkButton = Color(0xFF3A3A3A);
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
    final TextTheme textTheme = _getTextTheme(selectedFont, fontSize);

    // ライトテーマの surface は白に統一（Material 3 が surface から派生色を自動生成するため）
    switch (selectedTheme) {
      case 'light':
        primary = const Color(0xFF90A4AE);
        secondary = const Color(0xFFCFD8DC); // グレー
        break;
      case 'dark':
        primary = const Color(0xFF757575);
        secondary = const Color(0xFF505050);
        break;
      case 'orange':
        primary = const Color(0xFFFFC107);
        secondary = const Color(0xFFFFE082); // オレンジ
        break;
      case 'green':
        primary = const Color(0xFF8BC34A);
        secondary = const Color(0xFFC5E1A5); // グリーン
        break;
      case 'blue':
        primary = const Color(0xFF2196F3);
        secondary = const Color(0xFF90CAF9); // ブルー
        break;
      case 'beige':
        primary = const Color(0xFFFFE0B2);
        secondary = const Color(0xFFFFECB3); // ベージュ
        break;
      case 'mint':
        primary = const Color(0xFFB5EAD7);
        secondary = const Color(0xFFA8E6CF); // ミントグリーン
        break;
      case 'lavender':
        primary = const Color(0xFFB39DDB);
        secondary = const Color(0xFFD1C4E9); // ラベンダー
        break;
      case 'purple':
        primary = const Color(0xFF9C27B0);
        secondary = const Color(0xFFCE93D8); // パープル
        break;
      case 'teal':
        primary = const Color(0xFF009688);
        secondary = const Color(0xFF80CBC4); // ティール
        break;
      case 'amber':
        primary = const Color(0xFFFF9800);
        secondary = const Color(0xFFFFCC02); // アンバー
        break;
      case 'indigo':
        primary = const Color(0xFF3F51B5);
        secondary = const Color(0xFF9FA8DA); // インディゴ
        break;
      case 'soda':
        primary = const Color(0xFF81D4FA);
        secondary = const Color(0xFFB3E5FC); // ソーダブルー
        break;
      case 'coral':
        primary = const Color(0xFFFFAB91);
        secondary = const Color(0xFFFFCCBC); // コーラル
        break;
      default: // pink
        primary = const Color(0xFFFFC0CB); // パステルピンク
        secondary = const Color(0xFFFFE4E1); // より薄いピンク
    }
    surface = selectedTheme == 'dark' ? AppColors.darkCard : Colors.white;

    // テキストカラーの設定
    onPrimary = Colors.white;
    onSurface = selectedTheme == 'dark' ? Colors.white : Colors.black87;

    // 統一された背景色の設定
    final backgroundColor = _getBackgroundColor(selectedTheme);

    // 統一されたカード色の設定
    final cardColor = selectedTheme == 'dark'
        ? AppColors.darkCard
        : Colors.white;

    // 統一されたボーダー色の設定
    final borderColor = selectedTheme == 'dark'
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black87.withValues(alpha: 0.3);

    return ThemeData(
      colorScheme: ColorScheme(
        brightness:
            selectedTheme == 'dark' ? Brightness.dark : Brightness.light,
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
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
      ),
      useMaterial3: true,
    );
  }

  /// テーマキーに対応するプライマリカラーを取得
  static Color getPrimaryColor(String selectedTheme) {
    switch (selectedTheme) {
      case 'light':
        return const Color(0xFF90A4AE);
      case 'dark':
        return const Color(0xFF757575);
      case 'orange':
        return const Color(0xFFFFC107);
      case 'green':
        return const Color(0xFF8BC34A);
      case 'blue':
        return const Color(0xFF2196F3);
      case 'beige':
        return const Color(0xFFFFE0B2);
      case 'mint':
        return const Color(0xFFB5EAD7);
      case 'lavender':
        return const Color(0xFFB39DDB);
      case 'purple':
        return const Color(0xFF9C27B0);
      case 'teal':
        return const Color(0xFF009688);
      case 'amber':
        return const Color(0xFFFF9800);
      case 'indigo':
        return const Color(0xFF3F51B5);
      case 'soda':
        return const Color(0xFF81D4FA);
      case 'coral':
        return const Color(0xFFFFAB91);
      case 'pink':
      default:
        return const Color(0xFFFFC0CB);
    }
  }

  /// フォントに基づいてテキストテーマを取得
  static TextTheme _getTextTheme(String selectedFont, double fontSize) {
    return FontSettings.getTextTheme(selectedFont, fontSize);
  }

  /// 背景色を取得
  static Color _getBackgroundColor(String theme) {
    if (theme == 'dark') {
      return AppColors.darkBackground;
    }
    return Colors.white;
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
      {'key': 'pink', 'label': 'デフォルト', 'color': const Color(0xFFFFB6C1)},
      {'key': 'light', 'label': 'ライト', 'color': const Color(0xFF90A4AE)},
      {'key': 'orange', 'label': 'オレンジ', 'color': const Color(0xFFFFC107)},
      {'key': 'dark', 'label': 'ダーク', 'color': const Color(0xFF757575)},
      {'key': 'green', 'label': 'グリーン', 'color': const Color(0xFF8BC34A)},
      {'key': 'soda', 'label': 'ソーダ', 'color': const Color(0xFF81D4FA)},
      {'key': 'blue', 'label': 'ブルー', 'color': const Color(0xFF2196F3)},
      {'key': 'lavender', 'label': 'ラベンダー', 'color': const Color(0xFFB39DDB)},
      {'key': 'coral', 'label': 'コーラル', 'color': const Color(0xFFFFAB91)},
      {'key': 'beige', 'label': 'ベージュ', 'color': const Color(0xFFFFE0B2)},
      {'key': 'mint', 'label': 'ミント', 'color': const Color(0xFFB5EAD7)},
      {'key': 'purple', 'label': 'パープル', 'color': const Color(0xFF9C27B0)},
      {'key': 'teal', 'label': 'ティール', 'color': const Color(0xFF009688)},
      {'key': 'amber', 'label': 'アンバー', 'color': const Color(0xFFFF9800)},
      {'key': 'indigo', 'label': 'インディゴ', 'color': const Color(0xFF3F51B5)},
    ];
  }

  /// 背景色に対するコントラスト色を取得
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// プライマリカラー背景上のアイコン・テキスト色を取得
  static Color getOnPrimaryColor(String selectedTheme) {
    return Colors.white;
  }

  /// テーマに応じたテキスト色を取得
  @Deprecated('Use Theme.of(context).colorScheme.onSurface instead')
  static Color getTextColor(String selectedTheme) {
    return selectedTheme == 'dark' ? Colors.white : Colors.black87;
  }

  /// テーマに応じたサブテキスト色を取得
  @Deprecated('Use Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6) instead')
  static Color getSubtextColor(String selectedTheme) {
    return selectedTheme == 'dark' ? Colors.white70 : Colors.black54;
  }

  /// テーマに応じたカード背景色を取得
  @Deprecated('Use Theme.of(context).cardColor instead')
  static Color getCardColor(String selectedTheme) {
    return selectedTheme == 'dark' ? AppColors.darkCard : Colors.white;
  }

  /// テーマに応じた画面背景色を取得（Scaffold内のContainer用）
  @Deprecated('Use Theme.of(context).scaffoldBackgroundColor instead')
  static Color getSurfaceColor(String selectedTheme) {
    return selectedTheme == 'dark' ? AppColors.darkSurface : Colors.transparent;
  }

  /// プライマリカラーの反対色（補色）を取得
  static Color getComplementaryColor(String selectedTheme) {
    final primary = getPrimaryColor(selectedTheme);
    final hsl = HSLColor.fromColor(primary);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }
}

/// テーマ選択画面のウィジェット
/// テーマの選択機能
class ThemeSelectScreen extends StatefulWidget {
  const ThemeSelectScreen({
    super.key,
    required this.currentTheme,
    this.theme,
    required this.onThemeChanged,
  });

  final String currentTheme;
  final ThemeData? theme;
  final ValueChanged<String> onThemeChanged;

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
    final currentTheme = _getCurrentTheme();
    final primaryColor = currentTheme.colorScheme.primary;
    final onPrimary = SettingsTheme.getOnPrimaryColor(selectedTheme);

    return Theme(
      data: currentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'テーマを選択',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: onPrimary,
            ),
          ),
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          iconTheme: IconThemeData(
            color: onPrimary,
          ),
          elevation: 0,
        ),
        body: Padding(
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
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
                        ).colorScheme.onSurface.withValues(alpha: 0.70),
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
        // テーマのロック判定: サブスクリプションに基づく（選択時にチェック）
        final isLocked = !context.read<OneTimePurchaseService>().isPremiumUnlocked &&
            theme['key'] != 'pink';

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
          onTap: () {
            final newTheme = theme['key'] as String;
            // 選択時に制限をチェック
            if (isLocked) {
              _showDonationRequiredDialog();
            } else {
              // 先にローカル状態を更新して画面内の色を即時反映
              setState(() {
                selectedTheme = newTheme;
              });
              // 同フレームでグローバルへも即時通知
              widget.onThemeChanged(newTheme);
            }
          },
        );
      },
    );
  }

  /// プレミアムプランが必要なダイアログを表示
  void _showDonationRequiredDialog() {
    CommonDialog.show(
      context: context,
      builder: (context) => CommonDialog(
        title: 'プレミアムプランが必要です',
        content: const Text('テーマカスタマイズ機能はプレミアムプラン以上で利用できます。'),
        actions: [
          CommonDialog.cancelButton(context),
          CommonDialog.primaryButton(context, label: 'プランを確認', onPressed: () {
            context.pop();
            context.push('/subscription');
          }),
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
              ? primaryColor.withValues(alpha: 0.10)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.31),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                    color: (theme['color'] as Color).withValues(alpha: 0.30),
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
                child: const Text(
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      '制限中',
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
