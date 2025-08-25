// アプリのエントリーポイント。
// - Firebase / 広告 / アプリ内課金の初期化
// - ユーザー設定（テーマ/フォント/サイズ）の読み込みと適用
// - ルートウィジェット（MaterialApp）の構築
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';

import 'services/subscription_integration_service.dart';
import 'services/subscription_service.dart';
import 'services/transmission_service.dart';
import 'services/realtime_sharing_service.dart';
import 'services/feature_access_control.dart';
import 'services/debug_service.dart'; // Added
import 'services/store_preparation_service.dart'; // Added
import 'services/app_info_service.dart';
import 'providers/transmission_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/family_sharing_screen.dart';

import 'drawer/settings/settings_theme.dart';
import 'drawer/settings/settings_persistence.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad/interstitial_ad_service.dart';

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
        debugPrint('🚀 アプリ起動開始');
        debugPrint(
            '📱 プラットフォーム: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
        debugPrint(
            '🔧 Flutterバージョン: ${const String.fromEnvironment('FLUTTER_VERSION', defaultValue: 'unknown')}');

        // Flutter エンジンとプラグインの初期化を保証
        WidgetsFlutterBinding.ensureInitialized();
        debugPrint('✅ Flutterエンジン初期化完了');

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
          debugPrint('⚠️ 起動前設定読み込みエラー: $e');
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
          debugPrint('🔥 Firebase初期化開始...');
          if (Firebase.apps.isEmpty) {
            if (Platform.isIOS) {
              debugPrint('📱 iOS: GoogleService-Info.plist を用いた標準初期化を実行');
              debugPrint(
                '📱 iOS: バンドルID: ${const String.fromEnvironment('PRODUCT_BUNDLE_IDENTIFIER', defaultValue: 'unknown')}',
              );
            }
            // Firebase初期化にタイムアウトを設定（15秒）
            await Firebase.initializeApp().timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('Firebase初期化タイムアウト');
                throw TimeoutException(
                    'Firebase初期化がタイムアウトしました', const Duration(seconds: 15));
              },
            );
            debugPrint('✅ Firebase初期化成功');

            // Firebase Authの初期化確認
            try {
              final auth = firebase_auth.FirebaseAuth.instance;
              debugPrint('✅ Firebase Auth初期化確認完了');
              debugPrint(
                  '🔐 認証状態: ${auth.currentUser != null ? 'ログイン済み' : '未ログイン'}');
            } catch (authError) {
              debugPrint('❌ Firebase Auth初期化エラー: $authError');
              rethrow;
            }
          } else {
            debugPrint('ℹ️ Firebaseは既に初期化済み');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Firebase初期化失敗: $e');
          debugPrint('📚 Firebase初期化スタックトレース: $stackTrace');
          if (Platform.isIOS) {
            debugPrint('📱 iOS固有のFirebaseエラーです');
            debugPrint('📱 iOSトラブルシューティング:');
            debugPrint('   1. GoogleService-Info.plistファイルの存在を確認');
            debugPrint('   2. ファイル内のBUNDLE_IDが正しいか確認');
            debugPrint('   3. FirebaseコンソールでiOSアプリが正しく設定されているか確認');
            debugPrint('   4. Firebase Authが有効になっているか確認');
          }
          debugPrint('⚠️ ローカルモードで動作します');
          // Firebase初期化に失敗してもアプリは起動する
        }

        // Firebase初期化の成否に関わらずUIを起動（各サービス側でローカルモード分岐）
        debugPrint('🖼️ UI起動');
        runApp(const MyApp());
        debugPrint('✅ runApp完了。バックグラウンドで初期化を継続');

        // Google Mobile Ads 初期化（非同期で実行、失敗しても続行）
        _initializeMobileAdsInBackground();

        // インタースティシャル広告サービスの初期化（非同期で実行）
        _initializeInterstitialAdsInBackground();

        // アプリ内購入サービスの初期化
        try {
          debugPrint('💰 アプリ内購入サービス初期化開始...');
          final subscriptionService = SubscriptionService();
          await subscriptionService.initialize();
          debugPrint('✅ アプリ内購入サービス初期化完了');
        } catch (e) {
          debugPrint('❌ アプリ内購入サービス初期化失敗: $e');
          // アプリ内購入サービス初期化に失敗してもアプリは起動する
        }

        // バックグラウンドで更新チェックを実行
        _checkForUpdatesInBackground();

        // SettingsPersistenceから設定を復元
        try {
          debugPrint('⚙️ 設定読み込み開始...');
          final savedTheme = await SettingsPersistence.loadTheme();
          final savedFont = await SettingsPersistence.loadFont();
          final savedFontSize = await SettingsPersistence.loadFontSize();
          debugPrint(
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
          debugPrint('✅ テーマ初期化完了');
        } catch (e) {
          debugPrint('❌ 設定読み込み失敗: $e');
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

        debugPrint('🎯 バックグラウンド初期化完了または継続中');
      } catch (e, stackTrace) {
        debugPrint('💥 アプリ起動中に致命的エラーが発生: $e');
        debugPrint('📚 スタックトレース: $stackTrace');

        // エラーが発生しても最小限のUIは既に起動済みのため、最終手段のみ提示
        try {
          debugPrint('🔄 エラー復旧モード');
        } catch (recoveryError) {
          debugPrint('💥 復旧モードでも起動失敗: $recoveryError');
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
      debugPrint('💥 ゾーン内でキャッチされなかったエラー: $error');
      debugPrint('📚 ゾーンスタックトレース: $stackTrace');
    },
  );
}

/// Google Mobile Adsをバックグラウンドで初期化する。
/// 失敗しても起動フローをブロックしない。
void _initializeMobileAdsInBackground() async {
  try {
    debugPrint('📺 Google Mobile Ads初期化開始（バックグラウンド）...');
    // 10秒でタイムアウト
    final status = await MobileAds.instance.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Google Mobile Ads初期化タイムアウト');
        throw TimeoutException(
            'Google Mobile Ads初期化がタイムアウトしました', const Duration(seconds: 10));
      },
    );
    debugPrint('✅ Google Mobile Ads初期化完了: $status');
  } catch (e, stackTrace) {
    debugPrint('❌ Google Mobile Ads初期化失敗: $e');
    debugPrint('📚 Google Mobile Adsスタックトレース: $stackTrace');
    if (Platform.isIOS) {
      debugPrint('📱 iOS固有の広告初期化エラーです');
      debugPrint('📱 iOSトラブルシューティング:');
      debugPrint('   1. Info.plistのGADApplicationIdentifierが正しいか確認');
      debugPrint('   2. Google Mobile Ads SDKのバージョンに互換性があるか確認');
      debugPrint('   3. 広告ネットワークの設定が正しいか確認');
    }
    // 広告初期化に失敗してもアプリは起動する
  }
}

/// インタースティシャル広告サービスをバックグラウンドで初期化する。
/// 失敗しても起動フローをブロックしない。
void _initializeInterstitialAdsInBackground() async {
  try {
    debugPrint('🎬 インタースティシャル広告サービス初期化（バックグラウンド）...');
    InterstitialAdService().resetSession();
    debugPrint('✅ インタースティシャル広告サービス初期化完了');
  } catch (e) {
    debugPrint('❌ インタースティシャル広告サービス初期化失敗: $e');
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
    debugPrint('バックグラウンド更新チェックエラー: $e');
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
        // サブスクリプションサービス（シングルトン）
        ChangeNotifierProvider(create: (_) => SubscriptionService()),
        // 送信型共有サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => TransmissionService()),
        // リアルタイム共有サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => RealtimeSharingService()),
        // 送信型共有プロバイダー（統合）
        ChangeNotifierProxyProvider2<TransmissionService,
            RealtimeSharingService, TransmissionProvider>(
          create: (context) => TransmissionProvider(
            transmissionService: context.read<TransmissionService>(),
            realtimeSharingService: context.read<RealtimeSharingService>(),
          ),
          update: (
            context,
            transmissionService,
            realtimeSharingService,
            previous,
          ) =>
              previous ??
              TransmissionProvider(
                transmissionService: transmissionService,
                realtimeSharingService: realtimeSharingService,
              ),
        ),
        // 機能制御システム（シングルトン）
        ChangeNotifierProvider(create: (_) => FeatureAccessControl()),
        // デバッグサービス（シングルトン）
        ChangeNotifierProvider(create: (_) => DebugService()),
        // ストア申請準備サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => StorePreparationService()),
      ],
      child: ValueListenableBuilder<ThemeData>(
        valueListenable: safeThemeNotifier,
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'まいカゴ',
            theme: theme,
            home: const SafeArea(child: SplashWrapper()),
            routes: {
              '/subscription': (context) => const SubscriptionScreen(),
              '/family_sharing': (context) => const FamilySharingScreen(),
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
  bool _isTransmissionInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // SubscriptionServiceの初期化
      final subscriptionService = context.read<SubscriptionService>();
      await subscriptionService.initialize();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('サービスの初期化に失敗: $e');
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
          debugPrint('✅ ユーザーログイン済み: ${authProvider.userId}');
          // ユーザーが利用可能になったら一度だけ TransmissionProvider を初期化
          if (!_isTransmissionInitialized) {
            // フラグはビルド中に setState せずに直接設定して二重初期化を防ぐ
            _isTransmissionInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                debugPrint('🔧 AuthWrapper: TransmissionProvider自動初期化開始');
                await context.read<TransmissionProvider>().initialize();
                debugPrint('✅ AuthWrapper: TransmissionProvider自動初期化完了');
              } catch (e) {
                debugPrint('❌ AuthWrapper: TransmissionProvider自動初期化エラー: $e');
              }
            });
          }

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
        debugPrint('🔐 ユーザー未ログイン: ログイン画面を表示');
        return LoginScreen(
          onLoginSuccess: () {
            debugPrint('✅ ログイン成功: メイン画面に遷移');
            // ログイン成功時の処理（データは既に読み込み済み）
          },
        );
      },
    );
  }
}
