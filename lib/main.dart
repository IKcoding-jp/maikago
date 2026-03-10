import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:maikago/services/auth_service.dart';
import 'package:maikago/providers/auth_provider.dart';
import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/providers/theme_provider.dart';
import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/services/app_info_service.dart';
import 'package:maikago/services/donation_service.dart';
import 'package:maikago/services/version_notification_service.dart';
import 'package:maikago/services/ad/app_open_ad_service.dart';
import 'package:go_router/go_router.dart';
import 'package:maikago/router.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:maikago/env.dart';
import 'package:maikago/firebase_options.dart';

void main() async {
  unawaited(runZonedGuarded(
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

        // 環境変数を読み込み（--dart-define優先、env.jsonフォールバック）
        await Env.load();
        Env.debugApiKeyStatus();

        // サービスインスタンスの作成
        final purchaseService = OneTimePurchaseService();
        final donationService = DonationService();
        final featureControl = FeatureAccessControl();

        // テーマ設定の読み込み
        final themeProvider = ThemeProvider();
        await themeProvider.initFromPersistence();

        // 広告サービスの作成（モバイルのみ）
        AppOpenAdManager? appOpenAdManager;
        if (!kIsWeb) {
          appOpenAdManager = AppOpenAdManager(purchaseService);
        }

        // Firebase 初期化
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            DebugService().logDebug('✅ Firebase初期化成功');

            // Firestoreオフラインキャッシュを明示的に有効化
            // （Android/iOSはデフォルト有効だが、Webはデフォルト無効）
            FirebaseFirestore.instance.settings = const Settings(
              persistenceEnabled: true,
              cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
            );
            DebugService().logDebug('✅ Firestoreオフラインキャッシュ設定完了');
          }

          // Webでリダイレクト認証の結果を確認（iOS PWA対応）
          if (kIsWeb) {
            await AuthService().checkRedirectResult();
          }
        } catch (e) {
          DebugService().logError('❌ Firebase初期化失敗: $e');
        }

        runApp(MyApp(
          purchaseService: purchaseService,
          donationService: donationService,
          featureControl: featureControl,
          themeProvider: themeProvider,
          appOpenAdManager: appOpenAdManager,
        ));

        // 各種サービスのバックグラウンド初期化
        if (!kIsWeb) {
          unawaited(_initializeMobileAdsInBackground(
            purchaseService,
            appOpenAdManager!,
          ));
        }

        try {
          await purchaseService.initialize();
        } catch (e) {
          DebugService().logError('❌ アプリ内購入サービス初期化失敗: $e');
        }

        unawaited(_checkForUpdatesInBackground());
        unawaited(_initializeVersionNotification());
      } catch (e, stackTrace) {
        DebugService().logError('💥 アプリ起動中に致命的エラーが発生: $e', e, stackTrace);
      }
    },
    (error, stackTrace) {
      DebugService()
          .logError('💥 ゾーン内でキャッチされなかったエラー: $error', error, stackTrace);
    },
  ));
}

Future<void> _initializeMobileAdsInBackground(
  OneTimePurchaseService purchaseService,
  AppOpenAdManager appOpenAdManager,
) async {
  if (kIsWeb) return;
  try {
    DebugService().logDebug('🔧 Google Mobile Ads初期化開始');
    // UIレンダリング完了を待ってから広告SDKを初期化
    await Future.delayed(const Duration(milliseconds: 3000));
    await MobileAds.instance.initialize();
    DebugService().logDebug('✅ Google Mobile Ads初期化完了');

    if (!purchaseService.isPremiumUnlocked) {
      appOpenAdManager.loadAd();
    }
  } catch (e) {
    DebugService().logError('❌ Google Mobile Ads初期化失敗: $e');
  }
}

Future<void> _checkForUpdatesInBackground() async {
  try {
    await AppInfoService().checkForUpdates();
  } catch (e) {
    DebugService().logError('バックグラウンド更新チェックエラー: $e');
  }
}

Future<void> _initializeVersionNotification() async {
  try {
    await VersionNotificationService.recordAppLaunch();
  } catch (e) {
    DebugService().logError('バージョン通知サービス初期化エラー: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.purchaseService,
    required this.donationService,
    required this.featureControl,
    required this.themeProvider,
    this.appOpenAdManager,
  });

  final OneTimePurchaseService purchaseService;
  final DonationService donationService;
  final FeatureAccessControl featureControl;
  final ThemeProvider themeProvider;
  final AppOpenAdManager? appOpenAdManager;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(
      purchaseService: widget.purchaseService,
      featureControl: widget.featureControl,
      donationService: widget.donationService,
    );
    _router = createAppRouter(_authProvider);

    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      _showAppOpenAdOnResume();
    }
  }

  Future<void> _showAppOpenAdOnResume() async {
    if (kIsWeb) return;
    try {
      if (!_authProvider.isLoggedIn) return;
      if (widget.appOpenAdManager != null) {
        widget.appOpenAdManager!.showAdIfAvailable();
      }
    } catch (e) {
      DebugService().logError('❌ アプリ復帰時の広告表示エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider.value(value: widget.purchaseService),
        ChangeNotifierProvider.value(value: widget.donationService),
        ChangeNotifierProvider.value(value: widget.featureControl),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        if (widget.appOpenAdManager != null)
          Provider<AppOpenAdManager>.value(value: widget.appOpenAdManager!),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'まいカゴ',
            theme: themeProvider.themeData,
            routerConfig: _router,
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

