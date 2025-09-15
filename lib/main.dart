import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';

import 'services/subscription_integration_service.dart';
// import 'services/subscription_service.dart'; // 削除済み
import 'services/one_time_purchase_service.dart';
import 'services/feature_access_control.dart';
import 'services/debug_service.dart';
import 'services/store_preparation_service.dart';
import 'services/app_info_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'drawer/maikago_premium.dart';

import 'drawer/settings/settings_theme.dart';
import 'drawer/settings/settings_persistence.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad/interstitial_ad_service.dart';
import 'env.dart';
import 'config.dart';

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
void updateGlobalTheme(String themeKey) {
  currentGlobalTheme = themeKey;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    currentGlobalFontSize,
    themeKey,
  );
}

/// フォント更新用のグローバル関数。
/// - `currentGlobalFont` を更新し、`themeNotifier` を再生成して UI を再構築させる。
void updateGlobalFont(String fontFamily) {
  currentGlobalFont = fontFamily;
  themeNotifier.value = _defaultTheme(
    fontFamily,
    currentGlobalFontSize,
    currentGlobalTheme,
  );
}

/// フォントサイズ更新用のグローバル関数。
/// - `currentGlobalFontSize` を更新し、`themeNotifier` を再生成して UI を再構築させる。
void updateGlobalFontSize(double fontSize) {
  currentGlobalFontSize = fontSize;
  themeNotifier.value = _defaultTheme(
    currentGlobalFont,
    fontSize,
    currentGlobalTheme,
  );
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

        // 商品名要約機能のテスト（一時的）
        await _testProductNameSummarizer();

        // 起動前に保存済みの設定を読み込み、スプラッシュ表示時に正しいテーマを適用する
        String loadedTheme = 'pink';
        String loadedFont = 'nunito';
        double loadedFontSize = 16.0;
        try {
          // SharedPreferences からの読み込みは比較的軽量なので起動前に行う
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
          DebugService().logDebug('🔥 Firebase初期化開始...');
          if (Firebase.apps.isEmpty) {
            if (Platform.isIOS) {
              DebugService()
                  .logDebug('📱 iOS: GoogleService-Info.plist を用いた標準初期化を実行');
              DebugService().logDebug(
                '📱 iOS: バンドルID: ${const String.fromEnvironment('PRODUCT_BUNDLE_IDENTIFIER', defaultValue: 'unknown')}',
              );
            }
            // Firebase初期化にタイムアウトを設定（15秒）
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
              final auth = firebase_auth.FirebaseAuth.instance;
              DebugService().logDebug('✅ Firebase Auth初期化確認完了');
              DebugService().logDebug(
                  '🔐 認証状態: ${auth.currentUser != null ? 'ログイン済み' : '未ログイン'}');
            } catch (authError) {
              DebugService().logError('❌ Firebase Auth初期化エラー: $authError');
              rethrow;
            }
          } else {
            DebugService().logDebug('ℹ️ Firebaseは既に初期化済み');
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
        DebugService().logDebug('🖼️ UI起動');
        runApp(const MyApp());
        DebugService().logDebug('✅ runApp完了。バックグラウンドで初期化を継続');

        // Google Mobile Ads 初期化（非同期で実行、失敗しても続行）
        _initializeMobileAdsInBackground();

        // インタースティシャル広告サービスの初期化（非同期で実行）
        _initializeInterstitialAdsInBackground();

        // 非消耗型アプリ内購入サービスの初期化
        try {
          DebugService().logDebug('💰 非消耗型アプリ内購入サービス初期化開始...');
          final oneTimePurchaseService = OneTimePurchaseService();
          await oneTimePurchaseService.initialize();
          DebugService().logDebug('✅ 非消耗型アプリ内購入サービス初期化完了');
        } catch (e) {
          DebugService().logError('❌ アプリ内購入サービス初期化失敗: $e');
          // アプリ内購入サービス初期化に失敗してもアプリは起動する
        }

        // バックグラウンドで更新チェックを実行
        _checkForUpdatesInBackground();

        // SettingsPersistenceから設定を復元
        try {
          DebugService().logDebug('⚙️ 設定読み込み開始...');
          final savedTheme = await SettingsPersistence.loadTheme();
          final savedFont = await SettingsPersistence.loadFont();
          final savedFontSize = await SettingsPersistence.loadFontSize();
          DebugService().logDebug(
            '✅ 設定読み込み完了: theme=$savedTheme, font=$savedFont, size=$savedFontSize',
          );

          // グローバル変数に保存された設定を反映
          currentGlobalFont = savedFont;
          currentGlobalFontSize = savedFontSize;
          currentGlobalTheme = savedTheme;

          // ValueNotifierを初期化（保存された設定で）
          // 既に初期化されている場合は値を更新して再描画する
          try {
            themeNotifier;
            // 既存の notifier があれば値だけ差し替える
            themeNotifier.value =
                _defaultTheme(savedFont, savedFontSize, savedTheme);
          } catch (_) {
            themeNotifier = ValueNotifier<ThemeData>(
              _defaultTheme(savedFont, savedFontSize, savedTheme),
            );
          }

          try {
            fontNotifier;
            fontNotifier.value = savedFont;
          } catch (_) {
            fontNotifier = ValueNotifier<String>(savedFont);
          }
          DebugService().logDebug('✅ テーマ初期化完了');
        } catch (e) {
          DebugService().logError('❌ 設定読み込み失敗: $e');
          // デフォルト値で初期化
          currentGlobalFont = 'nunito';
          currentGlobalFontSize = 16.0;
          currentGlobalTheme = 'pink';

          // 設定読み込み失敗時も二重初期化を防ぐ
          try {
            themeNotifier;
          } catch (_) {
            themeNotifier = ValueNotifier<ThemeData>(
              _defaultTheme('nunito', 16.0, 'pink'),
            );
          }

          try {
            fontNotifier;
          } catch (_) {
            fontNotifier = ValueNotifier<String>('nunito');
          }
        }

        DebugService().logDebug('🎯 バックグラウンド初期化完了または継続中');
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
void _initializeMobileAdsInBackground() async {
  try {
    DebugService().logDebug('📺 Google Mobile Ads初期化開始（バックグラウンド）...');

    // WebViewの初期化を待つ（より長い時間）
    await Future.delayed(const Duration(milliseconds: 2000));

    // リクエスト設定を更新（WebView問題の対策）
    // デバッグモード時はテストデバイス設定を追加
    final testDeviceIds = configEnableDebugMode
        ? [
            '4A1374DD02BA1DF5AA510337859580DB',
            '003E9F00CE4E04B9FE8D8FFDACCFD244'
          ] // 複数のテストデバイスID
        : <String>[];

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: testDeviceIds,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      ),
    );

    if (configEnableDebugMode) {
      DebugService().logDebug('🔧 デバッグモード: テスト広告設定を適用しました');
      DebugService().logDebug('🔧 テストデバイスID: $testDeviceIds');
    }

    // 10秒でタイムアウト
    final status = await MobileAds.instance.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        DebugService().logError('Google Mobile Ads初期化タイムアウト');
        throw TimeoutException(
            'Google Mobile Ads初期化がタイムアウトしました', const Duration(seconds: 15));
      },
    );
    DebugService().logDebug('✅ Google Mobile Ads初期化完了: $status');
  } catch (e, stackTrace) {
    DebugService().logError('❌ Google Mobile Ads初期化失敗: $e', e, stackTrace);
    if (Platform.isAndroid) {
      DebugService().logWarning('📱 Android固有の広告初期化エラーです');
      DebugService().logWarning('📱 Androidトラブルシューティング:');
      DebugService().logWarning('   1. WebViewの初期化状態を確認');
      DebugService().logWarning('   2. ネットワーク接続を確認');
      DebugService().logWarning('   3. Google Play Servicesの状態を確認');
      DebugService().logWarning('   4. デバイスのメモリ不足を確認');
    } else if (Platform.isIOS) {
      DebugService().logWarning('📱 iOS固有の広告初期化エラーです');
      DebugService().logWarning('📱 iOSトラブルシューティング:');
      DebugService()
          .logWarning('   1. Info.plistのGADApplicationIdentifierが正しいか確認');
      DebugService().logWarning('   2. Google Mobile Ads SDKのバージョンに互換性があるか確認');
      DebugService().logWarning('   3. 広告ネットワークの設定が正しいか確認');
    }
    // 広告初期化に失敗してもアプリは起動する
  }
}

/// インタースティシャル広告サービスをバックグラウンドで初期化する。
/// 失敗しても起動フローをブロックしない。
void _initializeInterstitialAdsInBackground() async {
  try {
    DebugService().logDebug('🎬 インタースティシャル広告サービス初期化（バックグラウンド）...');
    InterstitialAdService().resetSession();
    DebugService().logDebug('✅ インタースティシャル広告サービス初期化完了');
  } catch (e) {
    DebugService().logError('❌ インタースティシャル広告サービス初期化失敗: $e');
    // 広告サービス初期化に失敗してもアプリは起動する
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
        // 寄付機能は削除（寄付特典がなくなったため）
        // サブスクリプション統合サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => SubscriptionIntegrationService()),
        // 非消耗型アプリ内課金サービス（直接利用用）
        ChangeNotifierProvider(create: (_) => OneTimePurchaseService()),

        // 機能制御システム（シングルトン）
        ChangeNotifierProvider(create: (_) => FeatureAccessControl()),
        // デバッグサービス（シングルトン）
        ChangeNotifierProvider(create: (_) => DebugService()),
        // ストア申請準備サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => StorePreparationService()),
        // 通知サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => NotificationService()),
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

class _SplashWrapperState extends State<SplashWrapper> {
  // スプラッシュ表示中かどうか
  bool _showSplash = true;

  /// スプラッシュ完了時のコールバック
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

      // NotificationServiceのリスナー開始
      if (mounted) {
        final notificationService = context.read<NotificationService>();
        notificationService.startListening();
      }

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
          DebugService().logDebug('✅ ユーザーログイン済み: ${authProvider.userId}');

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
        DebugService().logDebug('🔐 ユーザー未ログイン: ログイン画面を表示');
        return LoginScreen(
          onLoginSuccess: () {
            DebugService().logDebug('✅ ログイン成功: メイン画面に遷移');
            // ログイン成功時の処理（データは既に読み込み済み）
          },
        );
      },
    );
  }
}

/// 商品名要約機能のテスト（一時的）
Future<void> _testProductNameSummarizer() async {
  try {
    DebugService().logDebug('🧪 商品名要約機能は削除されました');
  } catch (e) {
    DebugService().logDebug('❌ 商品名要約機能テストエラー: $e');
  }
}
