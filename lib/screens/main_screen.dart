import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
import '../widgets/item_row.dart';
import '../widgets/bottom_summary.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'upcoming_features_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'main_screen_extensions.dart';
import 'main_screen_body.dart';

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
  @override
  late TabController _tabController;
  @override
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
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // グローバルフォント設定を読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // フォント設定は親から渡されるため、ここでは初期化のみ
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          customColors: customColors,
          incSortMode: incSortMode,
          comSortMode: comSortMode,
          theme: getCustomTheme(),
          showAddTabDialog: showAddTabDialog,
          showTabEditDialog: (index, shops) => showTabEditDialog(index, shops),
          showBudgetDialog: showBudgetDialog,
          showItemEditDialog: showItemEditDialog,
          showSortDialog: showSortDialog,
          calcTotal: calcTotal,
          onTabChanged: (index) {
            setState(() {
              _tabController.index = index;
            });
          },
          onThemeChanged: (themeKey) async {
            setState(() {
              currentTheme = themeKey;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('selected_theme', themeKey);
            updateGlobalTheme(themeKey);
          },
          onFontChanged: (font) async {
            setState(() {
              currentFont = font;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('selected_font', font);
            if (widget.onFontChanged != null) {
              widget.onFontChanged!(font);
            }
            if (widget.onThemeChanged != null) {
              widget.onThemeChanged!(getCustomTheme());
            }
          },
          onFontSizeChanged: (fontSize) async {
            setState(() {
              currentFontSize = fontSize;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('selected_font_size', fontSize);
            if (widget.onFontSizeChanged != null) {
              widget.onFontSizeChanged!(fontSize);
            }
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
