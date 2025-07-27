import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sort_mode.dart';
import '../providers/data_provider.dart';
import '../main.dart';
import 'main_screen_extensions.dart';
import 'main_screen_body.dart';
import '../services/interstitial_ad_service.dart';
import 'settings_persistence.dart';

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
  SortMode incSortMode = SortMode.jaAsc;
  @override
  SortMode comSortMode = SortMode.jaAsc;
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // インタースティシャル広告の破棄
    InterstitialAdService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // TabControllerの長さを更新（必要な場合のみ）
        if (_tabController.length != dataProvider.shops.length) {
          _tabController.dispose();
          _tabController = TabController(
            length: dataProvider.shops.length,
            vsync: this,
          );
          _tabController.addListener(() {
            if (mounted) setState(() {});
          });
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
            setState(() {
              _tabController.index = validIndex;
            });
          },
          onThemeChanged: (themeKey) async {
            setState(() {
              currentTheme = themeKey;
            });
            await SettingsPersistence.saveTheme(themeKey);
            updateGlobalTheme(themeKey);
          },
          onFontChanged: (font) async {
            setState(() {
              currentFont = font;
            });
            await SettingsPersistence.saveFont(font);
            if (widget.onFontChanged != null) {
              widget.onFontChanged!(font);
            }
            // グローバルフォント更新関数を呼び出し
            updateGlobalFont(font);
          },
          onFontSizeChanged: (fontSize) async {
            setState(() {
              currentFontSize = fontSize;
            });
            await SettingsPersistence.saveFontSize(fontSize);
            if (widget.onFontSizeChanged != null) {
              widget.onFontSizeChanged!(fontSize);
            }
            // グローバルフォントサイズ更新関数を呼び出し
            updateGlobalFontSize(fontSize);
          },
          onCustomThemeChanged: (colors) {
            setState(() {
              customColors = colors;
            });
            if (widget.onThemeChanged != null) {
              widget.onThemeChanged!(getCustomTheme());
            }
          },
          onDarkModeChanged: (isDark) {
            setState(() {
              isDarkMode = isDark;
            });
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
