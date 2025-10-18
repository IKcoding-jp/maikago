import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

/// ユーザー設定（テーマ/フォント/フォントサイズ）の現在値を保持するグローバル変数。
/// 起動時に `SettingsPersistence` から復元し、設定変更時に更新される。
String currentGlobalFont = 'nunito';
double currentGlobalFontSize = 16.0;
String currentGlobalTheme = 'pink';

/// 現在の `ThemeData` を配信する通知オブジェクト。
/// `late` 初期化のため、初期化前アクセス時は例外となる。
/// そのため UI 側は基本的に `safeThemeNotifier` を参照すること。
late final ValueNotifier<ThemeData> themeNotifier;

/// 現在選択中のフォント名を配信する通知オブジェクト。
/// 現状は主に設定画面の変更通知用途で、`themeNotifier` の再生成トリガーにも利用可能。
late final ValueNotifier<String> fontNotifier;

/// 起動直後など `themeNotifier` が未初期化の場合のフォールバック通知。
/// 実運用では `safeThemeNotifier` 越しに参照されるため、
/// ここでのテーマは最低限の初期描画のためのもの。
final ValueNotifier<ThemeData> _fallbackThemeNotifier =
    ValueNotifier<ThemeData>(
  // デフォルトのテーマ
  SettingsTheme.generateTheme(
    selectedTheme: 'pink',
    selectedFont: 'nunito',
    fontSize: 16.0,
  ),
);

/// `themeNotifier` を安全に取得するためのゲッター。
/// 未初期化時はフォールバックを返し、クラッシュを防ぐ。
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
  // `SettingsTheme.generateTheme` の薄いラッパー関数。
  // 既定値と引数の受け渡しを一元化する。
  return SettingsTheme.generateTheme(
    selectedTheme: theme,
    selectedFont: fontFamily,
    fontSize: fontSize,
  );
}

/// テーマ更新用のグローバル関数。
/// - `currentGlobalTheme` を更新し、`themeNotifier` に新しい `ThemeData` を流す。
/// - SharedPreferencesに設定を保存する。
void updateGlobalTheme(String themeKey) {
  currentGlobalTheme = themeKey;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    currentGlobalFontSize,
    themeKey,
  );
  // SharedPreferencesに保存
  SettingsPersistence.saveTheme(themeKey);
}

/// フォント更新用のグローバル関数。
/// - `currentGlobalFont` を更新し、`themeNotifier` を再生成して UI を再構築させる。
/// - SharedPreferencesに設定を保存する。
void updateGlobalFont(String fontFamily) {
  currentGlobalFont = fontFamily;
  themeNotifier.value = _defaultTheme(
    fontFamily,
    currentGlobalFontSize,
    currentGlobalTheme,
  );
  // SharedPreferencesに保存
  SettingsPersistence.saveFont(fontFamily);
}

/// フォントサイズ更新用のグローバル関数。
/// - `currentGlobalFontSize` を更新し、`themeNotifier` を再生成して UI を再構築させる。
/// - SharedPreferencesに設定を保存する。
void updateGlobalFontSize(double fontSize) {
  currentGlobalFontSize = fontSize;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    fontSize,
    currentGlobalTheme,
  );
  // SharedPreferencesに保存
  SettingsPersistence.saveFontSize(fontSize);
}

void main() async {
  // iOSのクラッシュ対策：ゾーンエラーハンドリングを追加
  runZonedGuarded(
    () async {
      try {
        DebugService().logDebug('🚀 アプリ起動開始');
        DebugService().logDebug(
            '📱 プラットフォーム: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
        DebugService().logDebug(
            '🔧 Flutterバージョン: ${const String.fromEnvironment('FLUTTER_VERSION', defaultValue: 'unknown')}');

        // APIキーの状態をデバッグ出力
        Env.debugApiKeyStatus();

        // Flutter エンジンとプラグインの初期化を保証
        WidgetsFlutterBinding.ensureInitialized();
        DebugService().logDebug('✅ Flutterエンジン初期化完了');

        // 起動前に保存済みの設定を読み込み、スプラッシュ表示時に正しいテーマを適用する
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

        // themeNotifier と fontNotifier を保存値で初期化または更新
        try {
          themeNotifier;
          themeNotifier.value =
              _defaultTheme(loadedFont, loadedFontSize, loadedTheme);
        } catch (_) {
          themeNotifier = ValueNotifier<ThemeData>(
            _defaultTheme(loadedFont, loadedFontSize, loadedTheme),
          );
        }

        try {
          fontNotifier;
          fontNotifier.value = loadedFont;
        } catch (_) {
          fontNotifier = ValueNotifier<String>(loadedFont);
        }

        // 先行起動はやめ、Firebase初期化完了後にrunAppする（[core/no-app]回避）

        // Firebase 初期化（iOSはGoogleService-Info.plistを利用）
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp().timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                DebugService().logError('Firebase初期化タイムアウト');
                throw TimeoutException(
                    'Firebase初期化がタイムアウトしました', const Duration(seconds: 15));
              },
            );
            DebugService().logDebug('✅ Firebase初期化成功');

            // Firebase Authの初期化確認
            try {
              firebase_auth.FirebaseAuth.instance;
              DebugService().logDebug('✅ Firebase Auth初期化確認完了');
            } catch (authError) {
              DebugService().logError('❌ Firebase Auth初期化エラー: $authError');
              rethrow;
            }
          }
        } catch (e, stackTrace) {
          DebugService().logError('❌ Firebase初期化失敗: $e', e, stackTrace);
          if (Platform.isIOS) {
            DebugService().logWarning('📱 iOS固有のFirebaseエラーです');
            DebugService().logWarning('📱 iOSトラブルシューティング:');
            DebugService()
                .logWarning('   1. GoogleService-Info.plistファイルの存在を確認');
            DebugService().logWarning('   2. ファイル内のBUNDLE_IDが正しいか確認');
            DebugService()
                .logWarning('   3. FirebaseコンソールでiOSアプリが正しく設定されているか確認');
            DebugService().logWarning('   4. Firebase Authが有効になっているか確認');
          }
          DebugService().logWarning('⚠️ ローカルモードで動作します');
          // Firebase初期化に失敗してもアプリは起動する
        }

        // Firebase初期化の成否に関わらずUIを起動（各サービス側でローカルモード分岐）
        runApp(const MyApp());

        // Google Mobile Ads 初期化（非同期で実行、失敗しても続行）
        // 初期化完了を待ってからバナー広告とインタースティシャル広告を順次初期化
        _initializeMobileAdsInBackground();

        // 非消耗型アプリ内購入サービスの初期化
        try {
          final oneTimePurchaseService = OneTimePurchaseService();
          await oneTimePurchaseService.initialize();
        } catch (e) {
          DebugService().logError('❌ アプリ内購入サービス初期化失敗: $e');
          // アプリ内購入サービス初期化に失敗してもアプリは起動する
        }

        // バックグラウンドで更新チェックを実行
        _checkForUpdatesInBackground();

        // バージョン通知サービスの初期化
        _initializeVersionNotification();
      } catch (e, stackTrace) {
        DebugService().logError('💥 アプリ起動中に致命的エラーが発生: $e', e, stackTrace);

        // エラーが発生しても最小限のUIは既に起動済みのため、最終手段のみ提示
        try {
          DebugService().logWarning('🔄 エラー復旧モード');
        } catch (recoveryError) {
          DebugService().logError('💥 復旧モードでも起動失敗: $recoveryError');
          // 最後の手段としてエラー画面を表示
          runApp(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'アプリの起動に失敗しました',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('エラー: $e', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => main(),
                        child: const Text('再起動'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    },
    (error, stackTrace) {
      DebugService()
          .logError('💥 ゾーン内でキャッチされなかったエラー: $error', error, stackTrace);
    },
  );
}

/// Google Mobile Adsをバックグラウンドで初期化する。
/// 失敗しても起動フローをブロックしない。
Future<void> _initializeMobileAdsInBackground() async {
  try {
    DebugService().logDebug('🔧 Google Mobile Ads初期化開始');

    // WebViewの初期化を待つ
    await Future.delayed(const Duration(milliseconds: 10000));
    DebugService().logDebug('🔧 WebView初期化待機完了');

    // リクエスト設定を更新（WebView問題の対策）
    final testDeviceIds = <String>[];

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: testDeviceIds,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.t,
      ),
    );
    DebugService().logDebug('🔧 Google Mobile Ads設定更新完了');

    // 初期化
    await MobileAds.instance.initialize().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        DebugService().logError('Google Mobile Ads初期化タイムアウト');
        throw TimeoutException(
            'Google Mobile Ads初期化がタイムアウトしました', const Duration(seconds: 30));
      },
    );
    DebugService().logDebug('✅ Google Mobile Ads初期化完了');

    // 初期化完了後、さらに待機
    await Future.delayed(const Duration(milliseconds: 5000));

    // OneTimePurchaseServiceの初期化完了を待つ
    final purchaseService = OneTimePurchaseService();
    int waitCount = 0;
    while (!purchaseService.isInitialized && waitCount < 50) {
      await Future.delayed(const Duration(milliseconds: 200));
      waitCount++;
    }

    if (purchaseService.isInitialized) {
      DebugService().logDebug('✅ OneTimePurchaseService初期化確認完了');
    } else {
      DebugService().logWarning('⚠️ OneTimePurchaseService初期化未完了のまま広告処理を続行');
    }

    // アプリ起動広告を初期化
    try {
      final appOpenAdManager = app_open_ad.AppOpenAdManager();
      DebugService().logDebug('🔧 アプリ起動広告マネージャー初期化完了');

      // プレミアム状態をチェック
      if (purchaseService.isPremiumUnlocked) {
        DebugService().logDebug('🔧 プレミアムユーザーのため広告読み込みをスキップ');
        return;
      }

      // 広告読み込みを試行（より安全な方法）
      appOpenAdManager.loadAd();
      DebugService().logDebug('🔧 アプリ起動広告読み込み開始');

      // 読み込み完了を待つ（最大10秒）
      int loadWaitCount = 0;
      while (!appOpenAdManager.isAdAvailable && loadWaitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 200));
        loadWaitCount++;
      }

      if (appOpenAdManager.isAdAvailable) {
        DebugService().logDebug('✅ アプリ起動広告読み込み完了');
      } else {
        DebugService().logWarning('⚠️ アプリ起動広告読み込み未完了（タイムアウト）');
      }
    } catch (e) {
      DebugService().logError('❌ アプリ起動広告初期化失敗: $e');
    }
  } catch (e, stackTrace) {
    DebugService().logError('❌ Google Mobile Ads初期化失敗: $e', e, stackTrace);
    // 広告初期化に失敗してもアプリは起動する
  }
}

/// アプリ更新の有無をバックグラウンドで確認する。
/// 失敗しても起動フローをブロックしない。
void _checkForUpdatesInBackground() async {
  try {
    final appInfoService = AppInfoService();
    await appInfoService.checkForUpdates();
  } catch (e) {
    // エラーが発生してもアプリの起動には影響しない
    DebugService().logError('バックグラウンド更新チェックエラー: $e');
  }
}

/// バージョン通知サービスを初期化する。
/// 失敗しても起動フローをブロックしない。
void _initializeVersionNotification() async {
  try {
    await VersionNotificationService.recordAppLaunch();
  } catch (e) {
    // エラーが発生してもアプリの起動には影響しない
    DebugService().logError('バージョン通知サービス初期化エラー: $e');
  }
}

/// ルートウィジェット。
/// - 複数の `ChangeNotifier` を `Provider` 経由でアプリ全体に提供
/// - テーマは `safeThemeNotifier` を購読してリアルタイムに反映
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 認証状態
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // データ（ショップ/アイテム）
        ChangeNotifierProvider(create: (_) => DataProvider()),
        // サブスクリプション統合サービス（シングルトン）は削除済み
        // 非消耗型アプリ内課金サービス（直接利用用）
        ChangeNotifierProvider(create: (_) => OneTimePurchaseService()),
        // 寄付サービス（複数回の寄付をサポート）
        ChangeNotifierProvider(create: (_) => DonationService()),

        // 機能制御システム（シングルトン）
        ChangeNotifierProvider(create: (_) => FeatureAccessControl()),
        // デバッグサービス（シングルトン）
        ChangeNotifierProvider(create: (_) => DebugService()),
      ],
      child: ValueListenableBuilder<ThemeData>(
        valueListenable: safeThemeNotifier,
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'まいカゴ – 値札読み取りで買い物合計が一瞬でわかる',
            theme: theme,
            themeAnimationDuration: Duration.zero,
            themeAnimationCurve: Curves.linear,
            home: const SafeArea(child: SplashWrapper()),
            routes: {
              '/subscription': (context) => const SubscriptionScreen(),
            },
          );
        },
      ),
    );
  }
}

/// スプラッシュ表示の有無を切り替え、完了次第 `AuthWrapper` に遷移する。
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with WidgetsBindingObserver {
  // スプラッシュ表示中かどうか
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // アプリのライフサイクルを監視
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリがバックグラウンドから復帰した時にアプリ起動広告を表示
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAdOnResume();
    }
  }

  /// アプリ復帰時のアプリ起動広告表示処理
  void _showAppOpenAdOnResume() async {
    try {
      DebugService().logDebug('🔧 アプリ復帰: アプリ起動広告表示を試行');

      // OneTimePurchaseServiceの初期化完了を待つ
      final purchaseService = OneTimePurchaseService();
      int waitCount = 0;
      while (!purchaseService.isInitialized && waitCount < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      if (purchaseService.isInitialized) {
        DebugService().logDebug('✅ OneTimePurchaseService初期化確認完了');
      } else {
        DebugService().logWarning('⚠️ OneTimePurchaseService初期化未完了のまま広告表示を試行');
      }

      final appOpenAdManager = app_open_ad.AppOpenAdManager();
      // 使用回数を記録
      appOpenAdManager.recordAppUsage();

      // 少し待ってから広告表示を試行
      await Future.delayed(const Duration(milliseconds: 500));
      appOpenAdManager.showAdIfAvailable();
    } catch (e) {
      DebugService().logError('❌ アプリ復帰時の広告表示エラー: $e');
    }
  }

  /// スプラッシュ完了時のコールバック
  void _onSplashComplete() async {
    setState(() {
      _showSplash = false;
    });

    // スプラッシュ完了後にアプリ起動広告を表示
    try {
      DebugService().logDebug('🔧 スプラッシュ完了: アプリ起動広告表示を試行');

      // OneTimePurchaseServiceの初期化完了を待つ
      final purchaseService = OneTimePurchaseService();
      int waitCount = 0;
      while (!purchaseService.isInitialized && waitCount < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      if (purchaseService.isInitialized) {
        DebugService().logDebug('✅ OneTimePurchaseService初期化確認完了');
      } else {
        DebugService().logWarning('⚠️ OneTimePurchaseService初期化未完了のまま広告表示を試行');
      }

      final appOpenAdManager = app_open_ad.AppOpenAdManager();
      appOpenAdManager.recordAppUsage();

      // 少し待ってから広告表示を試行
      await Future.delayed(const Duration(milliseconds: 1000));
      appOpenAdManager.showAdIfAvailable();
    } catch (e) {
      DebugService().logError('❌ スプラッシュ完了後の広告表示エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onSplashComplete: _onSplashComplete);
    }
    return const AuthWrapper();
  }
}

/// 認証状態に応じて `MainScreen` または `LoginScreen` を出し分ける。
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
      // 非消耗型アプリ内課金サービスの初期化
      final oneTimePurchaseService = context.read<OneTimePurchaseService>();
      await oneTimePurchaseService.initialize();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      DebugService().logError('サービスの初期化に失敗: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 初期化中またはローディング中の場合はローディング表示
        if (authProvider.isLoading || !_isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ログイン済みの場合、メイン画面を表示
        if (authProvider.isLoggedIn) {
          return MainScreen(
            onFontChanged: (String fontFamily) {
              // フォント変更：グローバル状態とテーマを更新
              fontNotifier.value = fontFamily; // 必要ならフォント依存UIの個別更新に利用
              updateGlobalFont(fontFamily); // `currentGlobalFont` 更新とテーマ再生成
            },
            onFontSizeChanged: (double fontSize) {
              // フォントサイズ変更：テーマ再生成でUI全体を更新
              updateGlobalFontSize(fontSize);
            },
            initialTheme: currentGlobalTheme,
            initialFont: currentGlobalFont,
            initialFontSize: currentGlobalFontSize,
          );
        }

        // 未ログインの場合、ログイン画面を表示
        return LoginScreen(
          onLoginSuccess: () {
            // ログイン成功時の処理（データは既に読み込み済み）
          },
        );
      },
    );
  }
}
