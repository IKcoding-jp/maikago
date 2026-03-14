import 'package:flutter/material.dart';

/// 共有タブ用のプリセットアイコン定義
class SharedTabIcons {
  /// デフォルトアイコン（既存の共有マーク）
  static const IconData defaultIcon = Icons.share;

  /// プリセットアイコンの一覧
  static const List<SharedTabIcon> presets = [
    SharedTabIcon(
      name: 'share',
      icon: Icons.share,
      displayName: '共有',
    ),
    SharedTabIcon(
      name: 'favorite',
      icon: Icons.favorite,
      displayName: 'ハート',
    ),
    SharedTabIcon(
      name: 'star',
      icon: Icons.star,
      displayName: '星',
    ),
    SharedTabIcon(
      name: 'square',
      icon: Icons.crop_square,
      displayName: '四角',
    ),
    SharedTabIcon(
      name: 'circle',
      icon: Icons.radio_button_unchecked,
      displayName: '丸',
    ),
    SharedTabIcon(
      name: 'triangle',
      icon: Icons.change_history,
      displayName: '三角',
    ),
    SharedTabIcon(
      name: 'diamond',
      icon: Icons.diamond,
      displayName: 'ダイヤ',
    ),
    SharedTabIcon(
      name: 'hexagon',
      icon: Icons.hexagon,
      displayName: '六角形',
    ),
    SharedTabIcon(
      name: 'clover',
      icon: Icons.cruelty_free,
      displayName: 'クローバー',
    ),
    SharedTabIcon(
      name: 'lightning',
      icon: Icons.bolt,
      displayName: '稲妻',
    ),
  ];

  /// アイコン名からIconDataを取得
  static IconData getIconFromName(String? iconName) {
    if (iconName == null) return defaultIcon;

    final preset = presets.firstWhere(
      (preset) => preset.name == iconName,
      orElse: () => presets.first, // 見つからない場合はデフォルト
    );

    return preset.icon;
  }

  /// アイコン名からSharedTabIconを取得
  static SharedTabIcon? getPresetFromName(String? iconName) {
    if (iconName == null) return null;

    return presets.cast<SharedTabIcon?>().firstWhere(
          (preset) => preset!.name == iconName,
          orElse: () => null,
        );
  }

  /// デフォルトのSharedTabIconを取得
  static SharedTabIcon getDefaultPreset() {
    return presets.first; // 'share' アイコン
  }
}

/// 共有タブアイコンの定義
class SharedTabIcon {
  const SharedTabIcon({
    required this.name,
    required this.icon,
    required this.displayName,
  });

  final String name;
  final IconData icon;
  final String displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedTabIcon && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'SharedTabIcon(name: $name, displayName: $displayName)';
}
