import 'package:flutter/material.dart';

/// 共有グループ用のプリセットアイコン定義
class SharedGroupIcons {
  /// デフォルトアイコン（既存の共有マーク）
  static const IconData defaultIcon = Icons.share;

  /// プリセットアイコンの一覧
  static const List<SharedGroupIcon> presets = [
    SharedGroupIcon(
      name: 'share',
      icon: Icons.share,
      displayName: '共有',
    ),
    SharedGroupIcon(
      name: 'favorite',
      icon: Icons.favorite,
      displayName: 'ハート',
    ),
    SharedGroupIcon(
      name: 'star',
      icon: Icons.star,
      displayName: '星',
    ),
    SharedGroupIcon(
      name: 'square',
      icon: Icons.crop_square,
      displayName: '四角',
    ),
    SharedGroupIcon(
      name: 'circle',
      icon: Icons.radio_button_unchecked,
      displayName: '丸',
    ),
    SharedGroupIcon(
      name: 'triangle',
      icon: Icons.change_history,
      displayName: '三角',
    ),
    SharedGroupIcon(
      name: 'diamond',
      icon: Icons.diamond,
      displayName: 'ダイヤ',
    ),
    SharedGroupIcon(
      name: 'hexagon',
      icon: Icons.hexagon,
      displayName: '六角形',
    ),
    SharedGroupIcon(
      name: 'clover',
      icon: Icons.cruelty_free,
      displayName: 'クローバー',
    ),
    SharedGroupIcon(
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

  /// アイコン名からSharedGroupIconを取得
  static SharedGroupIcon? getPresetFromName(String? iconName) {
    if (iconName == null) return null;

    return presets.cast<SharedGroupIcon?>().firstWhere(
          (preset) => preset!.name == iconName,
          orElse: () => null,
        );
  }

  /// デフォルトのSharedGroupIconを取得
  static SharedGroupIcon getDefaultPreset() {
    return presets.first; // 'share' アイコン
  }
}

/// 共有グループアイコンの定義
class SharedGroupIcon {
  const SharedGroupIcon({
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
    return other is SharedGroupIcon && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'SharedGroupIcon(name: $name, displayName: $displayName)';
}
