import 'package:flutter/material.dart';

/// 設定画面の状態管理クラス
/// テーマ、フォント、フォントサイズ、カスタムカラーなどの状態を管理
class SettingsState extends ChangeNotifier {
  String _selectedTheme = 'pink';
  String _selectedFont = 'nunito';
  double _selectedFontSize = 16.0;
  Map<String, Color> _customColors = {
    'primary': Color(0xFFFFB6C1),
    'secondary': Color(0xFFB5EAD7),
    'surface': Color(0xFFFFF1F8),
  };
  Map<String, Color> _detailedColors = {};

  // Getters
  String get selectedTheme => _selectedTheme;
  String get selectedFont => _selectedFont;
  double get selectedFontSize => _selectedFontSize;
  Map<String, Color> get customColors => _customColors;
  Map<String, Color> get detailedColors => _detailedColors;

  /// 初期化時に詳細カラーを設定
  void initializeDetailedColors() {
    _detailedColors = {
      'appBarColor': _customColors['primary']!,
      'backgroundColor': _customColors['surface']!,
      'buttonColor': _customColors['primary']!,
      'backgroundColor2': _customColors['surface']!,
      'fontColor1': Colors.black87,
      'fontColor2': Colors.white,
      'iconColor': _customColors['primary']!,
      'cardBackgroundColor': Colors.white,
      'borderColor': Color(0xFFE0E0E0),
      'dialogBackgroundColor': Colors.white,
      'dialogTextColor': Colors.black87,
      'inputBackgroundColor': Color(0xFFF5F5F5),
      'inputTextColor': Colors.black87,
      'tabColor': _customColors['tabColor'] ?? _customColors['primary']!,
    };
  }

  /// テーマを更新
  void updateTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  /// フォントを更新
  void updateFont(String font) {
    _selectedFont = font;
    notifyListeners();
  }

  /// フォントサイズを更新
  void updateFontSize(double fontSize) {
    _selectedFontSize = fontSize;
    notifyListeners();
  }

  /// カスタムカラーを更新
  void updateCustomColors(Map<String, Color> colors) {
    _customColors = colors;
    notifyListeners();
  }

  /// 詳細カラーを更新
  void updateDetailedColors(Map<String, Color> colors) {
    _detailedColors = colors;
    notifyListeners();
  }

  /// 初期状態を設定
  void setInitialState({
    required String theme,
    required String font,
    required double fontSize,
    Map<String, Color>? customColors,
  }) {
    _selectedTheme = theme;
    _selectedFont = font;
    _selectedFontSize = fontSize;
    if (customColors != null) {
      _customColors = customColors;
    }
    initializeDetailedColors();
    notifyListeners();
  }
}
