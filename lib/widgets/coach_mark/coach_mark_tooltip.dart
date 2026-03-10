import 'package:flutter/material.dart';

/// コーチマークの吹き出しウィジェット
/// ターゲットの位置に応じて上下に表示位置を自動判定し、三角矢印でターゲットを指す
class CoachMarkTooltip extends StatelessWidget {
  const CoachMarkTooltip({
    super.key,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    required this.targetRect,
    required this.screenSize,
    required this.onNext,
    required this.onSkip,
    required this.animation,
  });

  final String description;
  final int currentStep;
  final int totalSteps;
  final Rect targetRect;
  final Size screenSize;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Animation<double> animation;

  bool get _isLastStep => currentStep == totalSteps - 1;

  /// ターゲットが画面の上半分にあるかどうか → 吹き出しを下に表示
  bool get _showBelow => targetRect.center.dy < screenSize.height / 2;

  /// 三角矢印の水平位置（ターゲット中心に合わせ、画面端をクランプ）
  double get _arrowX {
    final center = targetRect.center.dx;
    return center.clamp(48.0, screenSize.width - 48.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const arrowSize = 12.0;

    return Positioned(
      left: 24,
      right: 24,
      top: _showBelow ? targetRect.bottom + arrowSize + 4 : null,
      bottom: _showBelow
          ? null
          : screenSize.height - targetRect.top + arrowSize + 4,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, _showBelow ? -0.1 : 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 上向き三角矢印（吹き出しがターゲットの下にある場合）
              if (_showBelow)
                Align(
                  alignment: Alignment(
                    ((_arrowX - 24) / (screenSize.width - 48)) * 2 - 1,
                    0,
                  ),
                  child: CustomPaint(
                    size: const Size(24, arrowSize),
                    painter: _ArrowPainter(pointUp: true),
                  ),
                ),
              // 吹き出し本体
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 説明テキスト + スキップ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              description,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onSkip,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(48, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'スキップ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 次へ / 始めるボタン
                      Center(
                        child: FilledButton(
                          onPressed: onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          child: Text(
                            _isLastStep
                                ? '始める'
                                : '次へ (${currentStep + 1}/$totalSteps)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 下向き三角矢印（吹き出しがターゲットの上にある場合）
              if (!_showBelow)
                Align(
                  alignment: Alignment(
                    ((_arrowX - 24) / (screenSize.width - 48)) * 2 - 1,
                    0,
                  ),
                  child: CustomPaint(
                    size: const Size(24, arrowSize),
                    painter: _ArrowPainter(pointUp: false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 三角矢印を描画する CustomPainter
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.pointUp});

  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.pointUp != pointUp;
}
