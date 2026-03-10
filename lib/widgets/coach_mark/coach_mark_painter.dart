import 'package:flutter/material.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_step.dart';

/// コーチマークの半透明オーバーレイと穴抜き描画を行う CustomPainter
class CoachMarkPainter extends CustomPainter {
  CoachMarkPainter({
    required this.targetRect,
    required this.shape,
    this.borderRadius = 12.0,
    this.overlayColor = const Color(0xB3000000),
  });

  final Rect targetRect;
  final CoachMarkShape shape;
  final double borderRadius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
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

    canvas.drawPath(
      overlayPath,
      Paint()..color = overlayColor,
    );
  }

  @override
  bool shouldRepaint(CoachMarkPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.shape != shape;
  }
}
