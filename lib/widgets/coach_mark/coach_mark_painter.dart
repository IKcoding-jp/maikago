import 'package:flutter/material.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_step.dart';

/// コーチマークの半透明オーバーレイと穴抜き描画を行う CustomPainter
/// 穴の周囲にグロー（光彩）効果を描画してターゲットを強調する
class CoachMarkPainter extends CustomPainter {
  CoachMarkPainter({
    required this.targetRect,
    required this.shape,
    this.borderRadius = 12.0,
    this.overlayColor = const Color(0xB3000000),
    this.glowProgress = 1.0,
  });

  final Rect targetRect;
  final CoachMarkShape shape;
  final double borderRadius;
  final Color overlayColor;

  /// グローのパルス進捗（0.0〜1.0）
  final double glowProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // 画面全体の暗いオーバーレイ
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holePath = Path();
    switch (shape) {
      case CoachMarkShape.circle:
        final center = targetRect.center;
        final radius = targetRect.shortestSide / 2;
        holePath.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case CoachMarkShape.roundedRectangle:
        holePath.addRRect(
          RRect.fromRectAndRadius(targetRect, Radius.circular(borderRadius)),
        );
        break;
    }

    final overlayPath = Path.combine(
      PathOperation.difference,
      fullPath,
      holePath,
    );

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // 穴の周囲にグロー効果（白い光彩ボーダー）
    final glowOpacity = 0.3 + 0.3 * glowProgress; // 0.3〜0.6
    final glowWidth = 2.0 + 2.0 * glowProgress; // 2〜4px

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth;

    switch (shape) {
      case CoachMarkShape.circle:
        final center = targetRect.center;
        final radius = targetRect.shortestSide / 2;
        canvas.drawCircle(center, radius, glowPaint);
        break;
      case CoachMarkShape.roundedRectangle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(targetRect, Radius.circular(borderRadius)),
          glowPaint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(CoachMarkPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.shape != shape ||
        oldDelegate.glowProgress != glowProgress;
  }
}
