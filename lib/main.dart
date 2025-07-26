import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeNotifier = ValueNotifier<ThemeData>(_defaultTheme());
final fontNotifier = ValueNotifier<String>('nunito');

ThemeData _defaultTheme([
  String fontFamily = 'nunito',
  double fontSize = 16.0,
  String theme = 'pink',
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

  // テーマに基づいて色を設定
  Color primary, secondary, surface;
  switch (theme) {
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
    default: // pink
      primary = Color(0xFFFFB6C1);
      secondary = Color(0xFFB5EAD7);
      surface = Color(0xFFFFF1F8);
  }

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
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
String currentGlobalTheme = 'pink';

// テーマ更新用のグローバル関数
void updateGlobalTheme(String themeKey) {
  currentGlobalTheme = themeKey;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    currentGlobalFontSize,
    themeKey,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // SharedPreferencesから設定を復元
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('selected_theme') ?? 'pink';
  final savedFont = prefs.getString('selected_font') ?? 'nunito';
  final savedFontSize = prefs.getDouble('selected_font_size') ?? 16.0;

  currentGlobalFont = savedFont;
  currentGlobalFontSize = savedFontSize;
  currentGlobalTheme = savedTheme;
  themeNotifier.value = _defaultTheme(savedFont, savedFontSize, savedTheme);
  fontNotifier.value = savedFont;

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<DataProvider>().loadData();
          });

          return MainScreen(
            onFontChanged: (String fontFamily) {
              fontNotifier.value = fontFamily;
              currentGlobalFont = fontFamily;
              themeNotifier.value = _defaultTheme(
                fontFamily,
                currentGlobalFontSize,
                currentGlobalTheme,
              );
            },
            onFontSizeChanged: (double fontSize) {
              currentGlobalFontSize = fontSize;
              themeNotifier.value = _defaultTheme(
                currentGlobalFont,
                fontSize,
                currentGlobalTheme,
              );
            },
            initialTheme: currentGlobalTheme,
            initialFont: currentGlobalFont,
            initialFontSize: currentGlobalFontSize,
          );
        }

        return LoginScreen(
          onLoginSuccess: () {
            context.read<DataProvider>().loadData();
          },
        );
      },
    );
  }
}
