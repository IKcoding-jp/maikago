// アプリのエントリーポイント。
// - Firebase / 広告 / アプリ内課金の初期化
// - ユーザー設定（テーマ/フォント/サイズ）の読み込みと適用
// - ルートウィジェット（MaterialApp）の構築
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';

import 'services/subscription_integration_service.dart';
import 'services/subscription_service.dart';
import 'services/transmission_service.dart';
import 'services/realtime_sharing_service.dart';
import 'services/feature_access_control.dart';
// import 'services/payment_service.dart'; // Removed: 購入処理を無効化
import 'services/debug_service.dart'; // Added
import 'services/store_preparation_service.dart'; // Added
import 'services/app_info_service.dart';
import 'providers/transmission_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/family_sharing_screen.dart';
import 'services/iap_service.dart';

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
  // Flutter エンジンとプラグインの初期化を保証
  WidgetsFlutterBinding.ensureInitialized();
  // アプリ内のデバッグ出力フィルター：英字を含むメッセージは表示しない
  // （英語のデバッグログを一括で無効化するためにグローバルで上書き）
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) return;
    // 英字（A-Z, a-z）を含むメッセージを抑止
    if (RegExp(r'[A-Za-z]').hasMatch(message)) return;
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };
  // Firebase 初期化（設定ファイルがない場合はスキップ）
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase初期化成功');
  } catch (e) {
    debugPrint('Firebase初期化失敗（設定ファイルなし）: $e');
    debugPrint('ローカルモードで動作します');
  }
  // Google Mobile Ads 初期化
  MobileAds.instance.initialize();

  // インタースティシャル広告サービスの初期化
  InterstitialAdService().resetSession();

  // 購入処理は無効化済みのため初期化をスキップ

  // バックグラウンドで更新チェックを実行
  _checkForUpdatesInBackground();

  // SettingsPersistenceから設定を復元
  final savedTheme = await SettingsPersistence.loadTheme();
  final savedFont = await SettingsPersistence.loadFont();
  final savedFontSize = await SettingsPersistence.loadFontSize();

  // 除外ワードを読み込み
  final excludedWords = await SettingsPersistence.loadExcludedWords();
  VoiceParser.setExcludedWords(excludedWords);

  // グローバル変数に保存された設定を反映
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
        // アプリ内課金サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => IapService()),
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
        // 決済サービスの提供は停止
        // デバッグサービス（シングルトン）
        ChangeNotifierProvider(create: (_) => DebugService()),
        // ストア申請準備サービス（シングルトン）
        ChangeNotifierProvider(create: (_) => StorePreparationService()),
        // アプリ内購入サービスの提供は停止
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
