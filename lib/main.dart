// アプリのエントリーポイント。
// - Firebase / 広告 / アプリ内課金の初期化
// - ユーザー設定（テーマ/フォント/サイズ）の読み込みと適用
// - ルートウィジェット（MaterialApp）の構築
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'services/voice_parser.dart';
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
  try {
    debugPrint('🚀 アプリ起動開始');

    // Flutter エンジンとプラグインの初期化を保証
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✅ Flutterエンジン初期化完了');

    // Firebase 初期化（iOSはGoogleService-Info.plistを利用）
    try {
      debugPrint('🔥 Firebase初期化開始...');
      if (Firebase.apps.isEmpty) {
        if (Platform.isIOS) {
          debugPrint('📱 iOS: GoogleService-Info.plist を用いた標準初期化を実行');
        }
        await Firebase.initializeApp();
        debugPrint('✅ Firebase初期化成功');
      } else {
        debugPrint('ℹ️ Firebaseは既に初期化済み');
      }
    } catch (e) {
      debugPrint('❌ Firebase初期化失敗: $e');
      debugPrint('⚠️ ローカルモードで動作します');
      // Firebase初期化に失敗してもアプリは起動する
    }

    // Google Mobile Ads 初期化
    try {
      debugPrint('📺 Google Mobile Ads初期化開始...');
      await MobileAds.instance.initialize();
      debugPrint('✅ Google Mobile Ads初期化完了');
    } catch (e) {
      debugPrint('❌ Google Mobile Ads初期化失敗: $e');
      // 広告初期化に失敗してもアプリは起動する
    }

    // インタースティシャル広告サービスの初期化
    try {
      debugPrint('🎬 インタースティシャル広告サービス初期化...');
      InterstitialAdService().resetSession();
      debugPrint('✅ インタースティシャル広告サービス初期化完了');
    } catch (e) {
      debugPrint('❌ インタースティシャル広告サービス初期化失敗: $e');
      // 広告サービス初期化に失敗してもアプリは起動する
    }

    // アプリ内購入サービスは無効化されています
    debugPrint('💰 アプリ内購入サービスは無効化されています');

    // PaymentServiceは無効化されています
    debugPrint('💳 PaymentServiceは無効化されています');

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

      // 除外ワードを読み込み
      final excludedWords = await SettingsPersistence.loadExcludedWords();
      VoiceParser.setExcludedWords(excludedWords);
      debugPrint('✅ 除外ワード読み込み完了: ${excludedWords.length}件');

      // グローバル変数に保存された設定を反映
      currentGlobalFont = savedFont;
      currentGlobalFontSize = savedFontSize;
      currentGlobalTheme = savedTheme;

      // ValueNotifierを初期化（保存された設定で）
      themeNotifier = ValueNotifier<ThemeData>(
        _defaultTheme(savedFont, savedFontSize, savedTheme),
      );
      fontNotifier = ValueNotifier<String>(savedFont);
      debugPrint('✅ テーマ初期化完了');
    } catch (e) {
      debugPrint('❌ 設定読み込み失敗: $e');
      // デフォルト値で初期化
      currentGlobalFont = 'nunito';
      currentGlobalFontSize = 16.0;
      currentGlobalTheme = 'pink';
      themeNotifier = ValueNotifier<ThemeData>(
        _defaultTheme('nunito', 16.0, 'pink'),
      );
      fontNotifier = ValueNotifier<String>('nunito');
    }

    debugPrint('🎯 アプリ起動準備完了、MyAppを開始');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('💥 アプリ起動中に致命的エラーが発生: $e');
    debugPrint('📚 スタックトレース: $stackTrace');

    // エラーが発生しても最小限のアプリを起動
    try {
      debugPrint('🔄 エラー復旧モードでアプリを起動');
      currentGlobalFont = 'nunito';
      currentGlobalFontSize = 16.0;
      currentGlobalTheme = 'pink';
      themeNotifier = ValueNotifier<ThemeData>(
        _defaultTheme('nunito', 16.0, 'pink'),
      );
      fontNotifier = ValueNotifier<String>('nunito');

      runApp(const MyApp());
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
                  const Text('アプリの起動に失敗しました', style: TextStyle(fontSize: 18)),
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
        ChangeNotifierProxyProvider2<
          TransmissionService,
          RealtimeSharingService,
          TransmissionProvider
        >(
          create: (context) => TransmissionProvider(
            transmissionService: context.read<TransmissionService>(),
            realtimeSharingService: context.read<RealtimeSharingService>(),
          ),
          update:
              (
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
            home: SafeArea(child: const SplashWrapper()),
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
        if (authProvider.canUseApp) {
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
