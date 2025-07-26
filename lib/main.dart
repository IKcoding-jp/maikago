import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'constants/colors.dart';

final themeNotifier = ValueNotifier<ThemeData>(_defaultTheme());
final fontNotifier = ValueNotifier<String>('nunito');

// 設定のキー
const String _themeKey = 'selected_theme';
const String _fontKey = 'selected_font';
const String _fontSizeKey = 'selected_font_size';

ThemeData _defaultTheme([
  String fontFamily = 'nunito',
  double fontSize = 16.0,
  String themeColor = 'pink', // テーマ色を追加
]) {
  TextTheme textTheme;
  switch (fontFamily) {
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

  // フォントサイズを明示的に指定
  textTheme = textTheme.copyWith(
    displayLarge: textTheme.displayLarge?.copyWith(fontSize: fontSize + 10),
    displayMedium: textTheme.displayMedium?.copyWith(fontSize: fontSize + 6),
    displaySmall: textTheme.displaySmall?.copyWith(fontSize: fontSize + 2),
    headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: fontSize + 4),
    headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: fontSize + 2),
    headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: fontSize),
    titleLarge: textTheme.titleLarge?.copyWith(fontSize: fontSize),
    titleMedium: textTheme.titleMedium?.copyWith(fontSize: fontSize - 2),
    titleSmall: textTheme.titleSmall?.copyWith(fontSize: fontSize - 4),
    bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: fontSize),
    bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: fontSize - 2),
    bodySmall: textTheme.bodySmall?.copyWith(fontSize: fontSize - 4),
    labelLarge: textTheme.labelLarge?.copyWith(fontSize: fontSize - 2),
    labelMedium: textTheme.labelMedium?.copyWith(fontSize: fontSize - 4),
    labelSmall: textTheme.labelSmall?.copyWith(fontSize: fontSize - 6),
  );

  // テーマ色を設定
  Color primaryColor;
  switch (themeColor) {
    case 'orange':
      primaryColor = Color(0xFFFFC107);
      break;
    case 'green':
      primaryColor = Color(0xFF8BC34A);
      break;
    case 'blue':
      primaryColor = Color(0xFF2196F3);
      break;
    case 'gray':
      primaryColor = Color(0xFF90A4AE);
      break;
    case 'beige':
      primaryColor = Color(0xFFFFE0B2);
      break;
    case 'mint':
      primaryColor = Color(0xFFB5EAD7);
      break;
    case 'lavender':
      primaryColor = Color(0xFFB39DDB);
      break;
    case 'lemon':
      primaryColor = Color(0xFFFFF176);
      break;
    case 'soda':
      primaryColor = Color(0xFF81D4FA);
      break;
    case 'coral':
      primaryColor = Color(0xFFFFAB91);
      break;
    default:
      primaryColor = AppColors.primary; // デフォルトはピンク
  }

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      brightness: Brightness.light,
    ),
    textTheme: textTheme,
    useMaterial3: true,
  );
}

// グローバルなフォント設定を管理
String currentGlobalFont = 'nunito';
double currentGlobalFontSize = 16.0;

// 設定を保存する関数
Future<void> _saveSettings({
  String? theme,
  String? font,
  double? fontSize,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (theme != null) await prefs.setString(_themeKey, theme);
  if (font != null) await prefs.setString(_fontKey, font);
  if (fontSize != null) await prefs.setDouble(_fontSizeKey, fontSize);
}

// 設定を読み込む関数
Future<Map<String, dynamic>> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'theme': prefs.getString(_themeKey) ?? 'pink',
    'font': prefs.getString(_fontKey) ?? 'nunito',
    'fontSize': prefs.getDouble(_fontSizeKey) ?? 16.0,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 保存された設定を読み込み
  final settings = await _loadSettings();
  currentGlobalFont = settings['font'];
  currentGlobalFontSize = settings['fontSize'];

  // 初期テーマを設定（保存されたテーマ設定を使用）
  final savedTheme = settings['theme'];
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    currentGlobalFontSize,
    savedTheme,
  );
  fontNotifier.value = currentGlobalFont;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: ValueListenableBuilder<ThemeData>(
        valueListenable: themeNotifier,
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Maikago',
            theme: theme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isLoggedIn) {
          // ログイン済みの場合もデータを読み込み
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<DataProvider>().loadData();
          });

          return MainScreen(
            onThemeChanged: (ThemeData newTheme) {
              themeNotifier.value = newTheme;
            },
            onFontChanged: (String fontFamily) async {
              fontNotifier.value = fontFamily;
              currentGlobalFont = fontFamily;
              // 現在のテーマ色を取得
              final prefs = await SharedPreferences.getInstance();
              final currentTheme = prefs.getString(_themeKey) ?? 'pink';
              // フォントとフォントサイズの両方を反映
              themeNotifier.value = _defaultTheme(
                fontFamily,
                currentGlobalFontSize,
                currentTheme,
              );
              // 設定を保存
              _saveSettings(font: fontFamily);
            },
            onFontSizeChanged: (double fontSize) async {
              currentGlobalFontSize = fontSize;
              // 現在のテーマ色を取得
              final prefs = await SharedPreferences.getInstance();
              final currentTheme = prefs.getString(_themeKey) ?? 'pink';
              // フォントサイズの変更を反映
              themeNotifier.value = _defaultTheme(
                currentGlobalFont,
                fontSize,
                currentTheme,
              );
              // 設定を保存
              _saveSettings(fontSize: fontSize);
            },
            globalTheme: themeNotifier.value, // グローバルテーマを渡す
          );
        }

        return LoginScreen(
          onLoginSuccess: () {
            // ログイン成功時にデータを読み込み
            context.read<DataProvider>().loadData();
          },
        );
      },
    );
  }
}
