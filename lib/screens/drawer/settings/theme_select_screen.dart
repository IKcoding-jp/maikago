import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:maikago/utils/dialog_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:maikago/services/settings_theme.dart';

/// テーマ選択画面のウィジェット
/// テーマの選択機能
class ThemeSelectScreen extends StatefulWidget {
  const ThemeSelectScreen({
    super.key,
    required this.currentTheme,
    this.theme,
    required this.onThemeChanged,
  });

  final String currentTheme;
  final ThemeData? theme;
  final ValueChanged<String> onThemeChanged;

  @override
  State<ThemeSelectScreen> createState() => _ThemeSelectScreenState();
}

class _ThemeSelectScreenState extends State<ThemeSelectScreen> {
  late String selectedTheme;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = _getCurrentTheme();
    final primaryColor = currentTheme.colorScheme.primary;
    final onPrimary = SettingsTheme.getOnPrimaryColor(selectedTheme);

    return Theme(
      data: currentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'テーマを選択',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: onPrimary,
            ),
          ),
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          iconTheme: IconThemeData(
            color: onPrimary,
          ),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(child: _buildThemeGrid()),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.palette_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'テーマを選択',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'お好みのカラーテーマを選んでください',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// テーマ選択グリッドを構築
  Widget _buildThemeGrid() {
    final themes = SettingsTheme.getAvailableThemes();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = selectedTheme == theme['key'] as String;
        // テーマのロック判定: サブスクリプションに基づく（選択時にチェック）
        final isLocked = !context.read<OneTimePurchaseService>().isPremiumUnlocked &&
            theme['key'] != 'pink';

        return _buildThemeItem(
          context: context,
          theme: theme,
          isSelected: isSelected,
          isLocked: isLocked,
          backgroundColor: Theme.of(context).cardColor,
          textColor: selectedTheme == 'dark'
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          primaryColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            final newTheme = theme['key'] as String;
            // 選択時に制限をチェック
            if (isLocked) {
              _showDonationRequiredDialog();
            } else {
              // 先にローカル状態を更新して画面内の色を即時反映
              setState(() {
                selectedTheme = newTheme;
              });
              // 同フレームでグローバルへも即時通知
              widget.onThemeChanged(newTheme);
            }
          },
        );
      },
    );
  }

  /// プレミアムプランが必要なダイアログを表示
  void _showDonationRequiredDialog() {
    showConstrainedDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアムプランが必要です'),
        content: const Text('テーマカスタマイズ機能はプレミアムプラン以上で利用できます。'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.push('/subscription');
            },
            child: const Text('プランを確認'),
          ),
        ],
      ),
    );
  }

  /// 現在のテーマを取得
  ThemeData _getCurrentTheme() {
    return SettingsTheme.generateTheme(
      selectedTheme: selectedTheme,
      selectedFont: 'nunito', // デフォルトフォント
    );
  }

  /// テーマ選択アイテムを作成
  Widget _buildThemeItem({
    required BuildContext context,
    required Map<String, dynamic> theme,
    required bool isSelected,
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withAlpha(25)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withAlpha(80),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withAlpha(38),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme['color'] as Color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (theme['color'] as Color).withAlpha(76),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme['label'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : textColor,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '選択中',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            if (isLocked) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 10),
                    SizedBox(width: 2),
                    Text(
                      '制限中',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 設定画面の状態管理クラス
/// テーマ、フォント、フォントサイズなどの状態を管理
class SettingsState extends ChangeNotifier {
  String _selectedTheme = 'pink';
  String _selectedFont = 'nunito';
  double _selectedFontSize = 16.0;

  // Getters
  String get selectedTheme => _selectedTheme;
  String get selectedFont => _selectedFont;
  double get selectedFontSize => _selectedFontSize;

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

  /// 初期状態を設定
  void setInitialState({
    required String theme,
    required String font,
    required double fontSize,
  }) {
    _selectedTheme = theme;
    _selectedFont = font;
    _selectedFontSize = fontSize;
    notifyListeners();
  }
}
