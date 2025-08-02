import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// 設定画面で使用する共通のUIコンポーネント
/// カード、ボタン、リストアイテムなどの再利用可能なウィジェット
class SettingsUI {
  /// 設定セクションのヘッダーを作成
  static Widget buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  /// 設定カードを作成
  static Widget buildSettingsCard({
    required Widget child,
    required Color backgroundColor,
    required EdgeInsets margin,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      margin: margin,
      color: backgroundColor,
      child: child,
    );
  }

  /// 設定リストアイテムを作成
  static Widget buildSettingsListItem({
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return SizedBox(
      height: 72,
      child: ListTile(
        dense: true,
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: textColor)),
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(leadingIcon, color: iconColor),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: backgroundColor),
        onTap: onTap,
      ),
    );
  }

  /// アカウント情報カードを作成
  static Widget buildAccountCard({
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return buildSettingsCard(
          backgroundColor: backgroundColor,
          margin: const EdgeInsets.only(bottom: 14),
          child: buildSettingsListItem(
            title: 'アカウント情報',
            subtitle: authProvider.isLoggedIn ? 'ログイン済み' : 'Googleアカウントでログイン',
            leadingIcon: Icons.account_circle_rounded,
            backgroundColor: primaryColor,
            textColor: textColor,
            iconColor: iconColor,
            onTap: onTap,
            trailing: CircleAvatar(
              backgroundImage: authProvider.userPhotoURL != null
                  ? NetworkImage(authProvider.userPhotoURL!)
                  : null,
              backgroundColor: primaryColor,
              child: authProvider.userPhotoURL == null
                  ? Icon(Icons.account_circle_rounded, color: iconColor)
                  : null,
            ),
          ),
        );
      },
    );
  }

  /// セクションタイトルを作成
  static Widget buildSectionTitle({
    required String title,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  /// テーマ選択アイテムを作成
  static Widget buildThemeItem({
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
              : (backgroundColor == Colors.white
                    ? Color(0xFFF8F9FA)
                    : backgroundColor),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withAlpha(51),
            width: isSelected ? 2 : 1,
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
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : textColor,
                fontSize: 13,
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
                child: Text(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      'ロック',
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

  /// フォント選択アイテムを作成
  static Widget buildFontItem({
    required Map<String, dynamic> font,
    required bool isSelected,
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withAlpha(25)
            : (backgroundColor == Colors.white
                  ? Color(0xFFF8F9FA)
                  : backgroundColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey.withAlpha(51),
          width: isSelected ? 2 : 1,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  font['label'] as String,
                  style: (font['style'] as TextStyle).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          '選択中',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          'ロック',
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
            ),
          ),
        ),
      ),
    );
  }

  /// フォントサイズスライダーを作成
  static Widget buildFontSizeSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color primaryColor,
    required Color textColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text('小', style: TextStyle(color: textColor.withAlpha(153))),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: primaryColor.withAlpha(76),
                  thumbColor: primaryColor,
                  overlayColor: primaryColor.withAlpha(51),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
            Text('大', style: TextStyle(color: textColor.withAlpha(153))),
          ],
        ),
      ],
    );
  }
}
