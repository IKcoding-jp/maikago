import 'package:flutter/material.dart';

/// 設定セクションのヘッダーウィジェット
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.textColor,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// 設定カードウィジェット
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      margin: margin,
      color: backgroundColor,
      child: child,
    );
  }
}

/// 設定リストアイテムウィジェット
class SettingsListItem extends StatelessWidget {
  const SettingsListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // フォントサイズに応じて高さを動的に調整
    final fontSize = Theme.of(context).textTheme.titleMedium?.fontSize ?? 16.0;
    final minHeight = fontSize > 18 ? 88.0 : 72.0;
    final maxHeight = fontSize > 20 ? 100.0 : 88.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: fontSize > 18 ? 12 : 8,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 20, vertical: fontSize > 18 ? 8 : 4),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(leadingIcon, color: iconColor),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: iconColor),
        onTap: onTap,
      ),
    );
  }
}

/// セクションタイトルウィジェット
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    super.key,
    required this.title,
    required this.textColor,
  });

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
