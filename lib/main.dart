import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'constants/colors.dart';

final themeNotifier = ValueNotifier<ThemeData>(_defaultTheme());
final fontNotifier = ValueNotifier<String>('nunito');

ThemeData _defaultTheme([String fontFamily = 'nunito']) {
  TextTheme textTheme;
  switch (fontFamily) {
    case 'roboto':
      textTheme = GoogleFonts.robotoTextTheme();
      break;
    case 'sawarabi':
      textTheme = GoogleFonts.sawarabiMinchoTextTheme();
      break;
    case 'mplus':
      textTheme = GoogleFonts.mPlus1pTextTheme();
      break;
    case 'kosugi':
      textTheme = GoogleFonts.kosugiTextTheme();
      break;
    case 'dela':
      textTheme = GoogleFonts.delaGothicOneTextTheme();
      break;
    case 'montserrat':
      textTheme = GoogleFonts.montserratTextTheme();
      break;
    case 'pacifico':
      textTheme = GoogleFonts.pacificoTextTheme();
      break;
    case 'dancing':
      textTheme = GoogleFonts.dancingScriptTextTheme();
      break;
    case 'zen':
      textTheme = GoogleFonts.zenMaruGothicTextTheme();
      break;
    // 追加フォント
    case 'zenmaru':
      textTheme = GoogleFonts.zenMaruGothicTextTheme();
      break;
    case 'mplusrounded':
      textTheme = GoogleFonts.mPlusRounded1cTextTheme();
      break;
    case 'kosugimaru':
      textTheme = GoogleFonts.kosugiMaruTextTheme();
      break;
    case 'yuseimagic':
      textTheme = GoogleFonts.yuseiMagicTextTheme();
      break;
    case 'caveat':
      textTheme = GoogleFonts.caveatTextTheme();
      break;
    default:
      textTheme = GoogleFonts.nunitoTextTheme();
  }

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
          // ログイン済みの場合もデータを読み込み
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<DataProvider>().loadData();
          });

          return MainScreen(
            onThemeChanged: (ThemeData newTheme) {
              themeNotifier.value = newTheme;
            },
            onFontChanged: (String fontFamily) {
              fontNotifier.value = fontFamily;
              currentGlobalFont = fontFamily;
              // MainScreenのテーマ設定を反映してテーマを更新
              // フォントのみを更新し、色設定はMainScreenに任せる
            },
          );
        }

        return LoginScreen(
          onLoginSuccess: () {
            // ログイン成功時にデータを読み込み
            context.read<DataProvider>().loadData();
          },
        );
      },
    );
  }
}
