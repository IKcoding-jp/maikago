import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/settings_logic.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final themeNotifier = ValueNotifier<ThemeData>(_defaultTheme());
final fontNotifier = ValueNotifier<String>('nunito');

ThemeData _defaultTheme([
  String fontFamily = 'nunito',
  double fontSize = 16.0,
  String theme = 'pink',
]) {
  // settings_logic.dartのgenerateThemeを使用
  return SettingsLogic.generateTheme(
    selectedTheme: theme,
    selectedFont: fontFamily,
    detailedColors: {},
    fontSize: fontSize,
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
  MobileAds.instance.initialize();

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
            home: const SplashWrapper(),
          );
        },
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onSplashComplete: _onSplashComplete);
    }
    return const AuthWrapper();
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
