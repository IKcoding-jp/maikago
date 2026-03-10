import 'package:flutter/material.dart';

/// コーチマークの穴の形状
enum CoachMarkShape {
  circle,
  roundedRectangle,
}

/// コーチマークの1ステップを表すデータモデル
class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.description,
    required this.shape,
    this.padding = 8.0,
    this.borderRadius = 12.0,
  });

  /// ターゲットウィジェットの GlobalKey
  final GlobalKey targetKey;

  /// 説明テキスト
  final String description;

  /// 穴の形状
  final CoachMarkShape shape;

  /// ターゲットの周囲パディング
  final double padding;

  /// 角丸矩形の場合の borderRadius
  final double borderRadius;

  /// ターゲットの Rect を取得
  Rect? getTargetRect() {
    final renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Rect.fromLTWH(
      offset.dx - padding,
      offset.dy - padding,
      size.width + padding * 2,
      size.height + padding * 2,
    );
  }
}
