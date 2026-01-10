import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'services/one_time_purchase_service.dart';
import 'services/feature_access_control.dart';
import 'services/debug_service.dart';
import 'services/app_info_service.dart';
import 'services/donation_service.dart';
import 'services/version_notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'drawer/maikago_premium.dart';
import 'ad/app_open_ad_service.dart' as app_open_ad;

import 'drawer/settings/settings_theme.dart';
import 'drawer/settings/settings_persistence.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'env.dart';
import 'firebase_options.dart';

/// ユーザー設定（テーマ/フォント/フォントサイズ）の現在値を保持するグローバル変数。
String currentGlobalFont = 'nunito';
double currentGlobalFontSize = 16.0;
String currentGlobalTheme = 'pink';

late final ValueNotifier<ThemeData> themeNotifier;
late final ValueNotifier<String> fontNotifier;

final ValueNotifier<ThemeData> _fallbackThemeNotifier =
    ValueNotifier<ThemeData>(
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
  return SettingsTheme.generateTheme(
    selectedTheme: theme,
    selectedFont: fontFamily,
    fontSize: fontSize,
  );
}

void updateGlobalTheme(String themeKey) {
  currentGlobalTheme = themeKey;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    currentGlobalFontSize,
    themeKey,
  );
  SettingsPersistence.saveTheme(themeKey);
}

void updateGlobalFont(String fontFamily) {
  currentGlobalFont = fontFamily;
  themeNotifier.value = _defaultTheme(
    fontFamily,
    currentGlobalFontSize,
    currentGlobalTheme,
  );
  SettingsPersistence.saveFont(fontFamily);
}

void updateGlobalFontSize(double fontSize) {
  currentGlobalFontSize = fontSize;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    fontSize,
    currentGlobalTheme,
  );
  SettingsPersistence.saveFontSize(fontSize);
}

void main() async {
  runZonedGuarded(
    () async {
      try {
        DebugService().logDebug('🚀 アプリ起動開始');

        // プラットフォーム情報の出力
        if (kIsWeb) {
          DebugService().logDebug('📱 プラットフォーム: Web');
        } else {
          DebugService().logDebug('📱 プラットフォーム: ${Platform.operatingSystem}');
        }

        WidgetsFlutterBinding.ensureInitialized();
        DebugService().logDebug('✅ Flutterエンジン初期化完了');

        // env.jsonから環境変数を読み込む
        await Env.load();
        Env.debugApiKeyStatus();

        // 設定の読み込み
        String loadedTheme = 'pink';
        String loadedFont = 'nunito';
        double loadedFontSize = 16.0;
        try {
          loadedTheme = await SettingsPersistence.loadTheme();
          loadedFont = await SettingsPersistence.loadFont();
          loadedFontSize = await SettingsPersistence.loadFontSize();
        } catch (e) {
          DebugService().logWarning('⚠️ 起動前設定読み込みエラー: $e');
        }

        currentGlobalFont = loadedFont;
        currentGlobalFontSize = loadedFontSize;
        currentGlobalTheme = loadedTheme;

        // Notifierの初期化
        try {
          themeNotifier;
        } catch (_) {
          themeNotifier = ValueNotifier<ThemeData>(
              _defaultTheme(loadedFont, loadedFontSize, loadedTheme));
        }
        try {
          fontNotifier;
        } catch (_) {
          fontNotifier = ValueNotifier<String>(loadedFont);
        }

        // Firebase 初期化
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            DebugService().logDebug('✅ Firebase初期化成功');
          }
        } catch (e) {
          DebugService().logError('❌ Firebase初期化失敗: $e');
        }

        runApp(const MyApp());

        // 各種サービスのバックグラウンド初期化
        if (!kIsWeb) {
          _initializeMobileAdsInBackground();
        }

        try {
          await OneTimePurchaseService().initialize();
        } catch (e) {
          DebugService().logError('❌ アプリ内購入サービス初期化失敗: $e');
        }

        _checkForUpdatesInBackground();
        _initializeVersionNotification();
      } catch (e, stackTrace) {
        DebugService().logError('💥 アプリ起動中に致命的エラーが発生: $e', e, stackTrace);
      }
    },
    (error, stackTrace) {
      DebugService()
          .logError('💥 ゾーン内でキャッチされなかったエラー: $error', error, stackTrace);
    },
  );
}

Future<void> _initializeMobileAdsInBackground() async {
  if (kIsWeb) return;
  try {
    DebugService().logDebug('🔧 Google Mobile Ads初期化開始');
    await Future.delayed(const Duration(milliseconds: 10000));
    await MobileAds.instance.initialize();
    DebugService().logDebug('✅ Google Mobile Ads初期化完了');

    final appOpenAdManager = app_open_ad.AppOpenAdManager();
    if (!OneTimePurchaseService().isPremiumUnlocked) {
      appOpenAdManager.loadAd();
    }
  } catch (e) {
    DebugService().logError('❌ Google Mobile Ads初期化失敗: $e');
  }
}

void _checkForUpdatesInBackground() async {
  try {
    await AppInfoService().checkForUpdates();
  } catch (e) {
    DebugService().logError('バックグラウンド更新チェックエラー: $e');
  }
}

void _initializeVersionNotification() async {
  try {
    await VersionNotificationService.recordAppLaunch();
  } catch (e) {
    DebugService().logError('バージョン通知サービス初期化エラー: $e');
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
        ChangeNotifierProvider(create: (_) => OneTimePurchaseService()),
        ChangeNotifierProvider(create: (_) => DonationService()),
        ChangeNotifierProvider(create: (_) => FeatureAccessControl()),
        ChangeNotifierProvider(create: (_) => DebugService()),
      ],
      child: ValueListenableBuilder<ThemeData>(
        valueListenable: safeThemeNotifier,
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'まいカゴ',
            theme: theme,
            home: const SplashWrapper(),
            routes: {
              '/subscription': (context) => const SubscriptionScreen(),
            },
            builder: (context, child) {
              // Webプラットフォームの場合、横幅の最大制限を設定
              if (kIsWeb) {
                final backgroundColor =
                    Theme.of(context).scaffoldBackgroundColor;
                return Container(
                  color: backgroundColor,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: child!,
                    ),
                  ),
                );
              }
              return child!;
            },
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

class _SplashWrapperState extends State<SplashWrapper>
    with WidgetsBindingObserver {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      _showAppOpenAdOnResume();
    }
  }

  void _showAppOpenAdOnResume() async {
    if (kIsWeb) return;
    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isLoggedIn) return;

      final appOpenAdManager = app_open_ad.AppOpenAdManager();
      appOpenAdManager.showAdIfAvailable();
    } catch (e) {
      DebugService().logError('❌ アプリ復帰時の広告表示エラー: $e');
    }
  }

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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await context.read<OneTimePurchaseService>().initialize();
    } finally {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading || !_isInitialized) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (authProvider.isLoggedIn) {
          return MainScreen(
            onFontChanged: updateGlobalFont,
            onFontSizeChanged: updateGlobalFontSize,
            initialTheme: currentGlobalTheme,
            initialFont: currentGlobalFont,
            initialFontSize: currentGlobalFontSize,
          );
        }
        return LoginScreen(onLoginSuccess: () {});
      },
    );
  }
}
