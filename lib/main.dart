import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'services/donation_manager.dart';
import 'services/in_app_purchase_service.dart';
import 'services/app_info_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

import 'drawer/settings/settings_theme.dart';
import 'drawer/settings/settings_persistence.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad/interstitial_ad_service.dart';

// グローバルな設定を管理
String currentGlobalFont = 'nunito';
double currentGlobalFontSize = 16.0;
String currentGlobalTheme = 'pink';

// ValueNotifierを遅延初期化
late final ValueNotifier<ThemeData> themeNotifier;
late final ValueNotifier<String> fontNotifier;

// テストや未初期化対策用のフォールバック
final ValueNotifier<ThemeData> _fallbackThemeNotifier =
    ValueNotifier<ThemeData>(
      // デフォルトのテーマ
      SettingsTheme.generateTheme(
        selectedTheme: 'pink',
        selectedFont: 'nunito',
        fontSize: 16.0,
      ),
    );

ValueNotifier<ThemeData> get safeThemeNotifier {
  try {
    return themeNotifier;
  } catch (_) {
    return _fallbackThemeNotifier;
  }
}

ThemeData _defaultTheme([
  String fontFamily = 'nunito',
  double fontSize = 16.0,
  String theme = 'pink',
]) {
  // app_theme.dartのgenerateThemeを使用
  return SettingsTheme.generateTheme(
    selectedTheme: theme,
    selectedFont: fontFamily,
    fontSize: fontSize,
  );
}

// テーマ更新用のグローバル関数
void updateGlobalTheme(String themeKey) {
  currentGlobalTheme = themeKey;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    currentGlobalFontSize,
    themeKey,
  );
}

// フォント更新用のグローバル関数
void updateGlobalFont(String fontFamily) {
  currentGlobalFont = fontFamily;
  themeNotifier.value = _defaultTheme(
    fontFamily,
    currentGlobalFontSize,
    currentGlobalTheme,
  );
}

// フォントサイズ更新用のグローバル関数
void updateGlobalFontSize(double fontSize) {
  currentGlobalFontSize = fontSize;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    fontSize,
    currentGlobalTheme,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();

  // インタースティシャル広告サービスの初期化
  InterstitialAdService().resetSession();

  // アプリ内購入サービスの初期化
  await InAppPurchaseService().initialize();

  // バックグラウンドで更新チェックを実行
  _checkForUpdatesInBackground();

  // SettingsPersistenceから設定を復元
  final savedTheme = await SettingsPersistence.loadTheme();
  final savedFont = await SettingsPersistence.loadFont();
  final savedFontSize = await SettingsPersistence.loadFontSize();

  // グローバル変数に保存された設定を設定
  currentGlobalFont = savedFont;
  currentGlobalFontSize = savedFontSize;
  currentGlobalTheme = savedTheme;

  // ValueNotifierを初期化（保存された設定で）
  themeNotifier = ValueNotifier<ThemeData>(
    _defaultTheme(savedFont, savedFontSize, savedTheme),
  );
  fontNotifier = ValueNotifier<String>(savedFont);

  runApp(const MyApp());
}

// バックグラウンドで更新チェックを実行
void _checkForUpdatesInBackground() async {
  try {
    final appInfoService = AppInfoService();
    await appInfoService.checkForUpdates();
  } catch (e) {
    // エラーが発生してもアプリの起動には影響しない
    debugPrint('バックグラウンド更新チェックエラー: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => DonationManager()),
        ChangeNotifierProvider(create: (_) => InAppPurchaseService()),
      ],
      child: ValueListenableBuilder<ThemeData>(
        valueListenable: safeThemeNotifier,
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'まいカゴ',
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
        // 初期化中またはローディング中の場合はローディング表示
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ログイン済みの場合、メイン画面を表示
        if (authProvider.canUseApp) {
          return MainScreen(
            onFontChanged: (String fontFamily) {
              fontNotifier.value = fontFamily;
              currentGlobalFont = fontFamily;
              updateGlobalFont(fontFamily);
            },
            onFontSizeChanged: (double fontSize) {
              currentGlobalFontSize = fontSize;
              updateGlobalFontSize(fontSize);
            },
            initialTheme: currentGlobalTheme,
            initialFont: currentGlobalFont,
            initialFontSize: currentGlobalFontSize,
          );
        }

        // ログイン画面を表示
        return LoginScreen(
          onLoginSuccess: () {
            // ログイン成功時の処理（データは既に読み込み済み）
          },
        );
      },
    );
  }
}
