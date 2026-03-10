import 'package:flutter/material.dart';

/// コーチマークの吹き出しウィジェット
/// ターゲットの位置に応じて上下に表示位置を自動判定する
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

  /// ターゲットが画面の上半分にあるかどうか
  bool get _showBelow => targetRect.center.dy < screenSize.height / 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: 24,
      right: 24,
      top: _showBelow ? targetRect.bottom + 16 : null,
      bottom: _showBelow ? null : screenSize.height - targetRect.top + 16,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, _showBelow ? -0.1 : 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: Material(
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
        ),
      ),
    );
  }
}
