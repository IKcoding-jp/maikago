import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sort_mode.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import 'main_screen_extensions.dart';
import 'main_screen_body.dart';
import '../services/interstitial_ad_service.dart';
import 'settings_persistence.dart';
import '../widgets/welcome_dialog.dart';

class MainScreen extends StatefulWidget {
  final void Function(ThemeData)? onThemeChanged;
  final void Function(String)? onFontChanged;
  final void Function(double)? onFontSizeChanged;
  final String? initialTheme;
  final String? initialFont;
  final double? initialFontSize;
  const MainScreen({
    super.key,
    this.onThemeChanged,
    this.onFontChanged,
    this.onFontSizeChanged,
    this.initialTheme,
    this.initialFont,
    this.initialFontSize,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with TickerProviderStateMixin, MainScreenLogicMixin {
  late TabController _tabController;
  int selectedTabIndex = 0;
  @override
  late String currentTheme;
  @override
  late String currentFont;
  @override
  late double currentFontSize;
  @override
  Map<String, Color> customColors = {
    'primary': Color(0xFFFFB6C1),
    'secondary': Color(0xFFB5EAD7),
    'surface': Color(0xFFFFF1F8),
  };
  @override
  String nextShopId = '1';
  @override
  String nextItemId = '0';
  @override
  SortMode incSortMode = SortMode.dateNew;
  @override
  SortMode comSortMode = SortMode.dateNew;
  @override
  bool includeTax = false;
  @override
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    currentTheme = widget.initialTheme ?? 'pink';
    currentFont = widget.initialFont ?? 'nunito';
    currentFontSize = widget.initialFontSize ?? 16.0;
    _tabController = TabController(length: 0, vsync: this);

    // 初回起動時にウェルカムダイアログを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcomeDialog();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // インタースティシャル広告の破棄
    InterstitialAdService().dispose();
    super.dispose();
  }

  // 初回起動時にウェルカムダイアログを表示するメソッド
  Future<void> _checkAndShowWelcomeDialog() async {
    final isFirstLaunch = await SettingsPersistence.isFirstLaunch();

    if (isFirstLaunch && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeDialog(),
      );
    }
  }

  // TabControllerの変更を処理するメソッド
  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // 認証状態の変更を監視してテーマとフォントを更新
  void _updateThemeAndFontIfNeeded(AuthProvider authProvider) {
    // 認証状態が変更された際に、保存されたテーマとフォントを読み込む
    if (authProvider.isLoggedIn) {
      _loadSavedThemeAndFont();
    }
  }

  // 保存されたテーマとフォントを読み込む
  Future<void> _loadSavedThemeAndFont() async {
    try {
      final savedTheme = await SettingsPersistence.loadTheme();
      final savedFont = await SettingsPersistence.loadFont();

      if (mounted) {
        setState(() {
          currentTheme = savedTheme;
          currentFont = savedFont;
        });
      }
    } catch (e) {
      debugPrint('テーマ・フォント読み込みエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataProvider, AuthProvider>(
      builder: (context, dataProvider, authProvider, child) {
        // 認証状態の変更を監視してテーマとフォントを更新
        _updateThemeAndFontIfNeeded(authProvider);

        // TabControllerの長さを更新（必要な場合のみ）
        if (_tabController.length != dataProvider.shops.length) {
          _tabController.dispose();
          _tabController = TabController(
            length: dataProvider.shops.length,
            vsync: this,
            initialIndex: 0,
          );
          // リスナーを追加
          _tabController.addListener(_onTabChanged);
        }

        // shopsが空の場合は0を返す
        final selectedIndex = dataProvider.shops.isEmpty
            ? 0
            : _tabController.index.clamp(0, dataProvider.shops.length - 1);

        return MainScreenBody(
          isLoading: dataProvider.isLoading,
          shops: dataProvider.shops,
          currentTheme: currentTheme,
          currentFont: currentFont, // currentFontを追加
          currentFontSize: currentFontSize,
          customColors: customColors,
          incSortMode: incSortMode,
          comSortMode: comSortMode,
          theme: getCustomTheme(),
          showAddTabDialog: showAddTabDialog,
          showTabEditDialog: (index, shops) => showTabEditDialog(index, shops),
          showBudgetDialog: showBudgetDialog,
          showItemEditDialog: showItemEditDialog,
          showBulkDeleteDialog: showBulkDeleteDialog,
          showSortDialog: showSortDialog,
          calcTotal: calcTotal,
          onTabChanged: (index) {
            final validIndex = index.clamp(0, dataProvider.shops.length - 1);
            if (mounted) {
              setState(() {
                _tabController.index = validIndex;
              });
            }
          },
          onThemeChanged: (themeKey) async {
            if (mounted) {
              setState(() {
                currentTheme = themeKey;
              });
            }
            await SettingsPersistence.saveTheme(themeKey);
            updateGlobalTheme(themeKey);
          },
          onFontChanged: (font) async {
            if (mounted) {
              setState(() {
                currentFont = font;
              });
            }
            await SettingsPersistence.saveFont(font);
            if (widget.onFontChanged != null) {
              widget.onFontChanged!(font);
            }
            // グローバルフォント更新関数を呼び出し
            updateGlobalFont(font);
          },
          onFontSizeChanged: (fontSize) async {
            if (mounted) {
              setState(() {
                currentFontSize = fontSize;
              });
            }
            await SettingsPersistence.saveFontSize(fontSize);
            if (widget.onFontSizeChanged != null) {
              widget.onFontSizeChanged!(fontSize);
            }
            // グローバルフォントサイズ更新関数を呼び出し
            updateGlobalFontSize(fontSize);
          },
          onCustomThemeChanged: (colors) {
            if (mounted) {
              setState(() {
                customColors = colors;
              });
            }
            if (widget.onThemeChanged != null) {
              widget.onThemeChanged!(getCustomTheme());
            }
          },
          onDarkModeChanged: (isDark) {
            if (mounted) {
              setState(() {
                isDarkMode = isDark;
              });
            }
            if (widget.onThemeChanged != null) {
              widget.onThemeChanged!(getCustomTheme());
            }
          },
          selectedTabIndex: selectedIndex, // selectedTabIndexを渡す
        );
      },
    );
  }
}
