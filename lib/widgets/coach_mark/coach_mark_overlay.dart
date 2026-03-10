import 'package:flutter/material.dart';
import 'package:maikago/services/settings_persistence.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_step.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_painter.dart';
import 'package:maikago/widgets/coach_mark/coach_mark_tooltip.dart';

/// コーチマークオーバーレイ
/// Overlay上に表示し、ステップごとにターゲットをハイライトして説明を表示する
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  final List<CoachMarkStep> steps;
  final VoidCallback onComplete;

  /// Overlay にコーチマークを挿入する
  static OverlayEntry? show({
    required BuildContext context,
    required List<CoachMarkStep> steps,
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => CoachMarkOverlay(
        steps: steps,
        onComplete: () {
          entry?.remove();
          onComplete?.call();
        },
      ),
    );
    overlay.insert(entry);
    return entry;
  }

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with TickerProviderStateMixin {
  int _currentStepIndex = 0;

  late final AnimationController _overlayController;
  late final Animation<double> _overlayAnimation;

  late final AnimationController _holeController;
  late final Animation<double> _holeAnimation;

  late final AnimationController _tooltipController;
  late final Animation<double> _tooltipAnimation;

  Rect _currentTargetRect = Rect.zero;
  Rect _previousTargetRect = Rect.zero;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );

    _holeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _holeAnimation = CurvedAnimation(
      parent: _holeController,
      curve: Curves.easeInOut,
    );

    _tooltipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tooltipAnimation = CurvedAnimation(
      parent: _tooltipController,
      curve: Curves.easeOut,
    );

    _initStep();
    _overlayController.forward().then((_) {
      _holeController.forward().then((_) {
        _tooltipController.forward();
      });
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _holeController.dispose();
    _tooltipController.dispose();
    super.dispose();
  }

  void _initStep() {
    final step = widget.steps[_currentStepIndex];
    final rect = step.getTargetRect();
    if (rect != null) {
      _currentTargetRect = rect;
      _previousTargetRect = rect;
    }
  }

  Future<void> _goToNext() async {
    if (_currentStepIndex >= widget.steps.length - 1) {
      await _complete();
      return;
    }

    await _tooltipController.reverse();

    _currentStepIndex++;
    final step = widget.steps[_currentStepIndex];
    final rect = step.getTargetRect();
    if (rect != null) {
      _previousTargetRect = _currentTargetRect;
      _currentTargetRect = rect;
    }

    _holeController.reset();
    await _holeController.forward();

    _tooltipController.reset();
    await _tooltipController.forward();

    // setState to update the step shape in the painter
    if (mounted) setState(() {});
  }

  Future<void> _complete() async {
    await SettingsPersistence.setCoachMarkCompleted();
    await _overlayController.reverse();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final step = widget.steps[_currentStepIndex];

    return AnimatedBuilder(
      animation: Listenable.merge([
        _overlayAnimation,
        _holeAnimation,
        _tooltipAnimation,
      ]),
      builder: (context, child) {
        final animatedRect = Rect.lerp(
          _previousTargetRect,
          _currentTargetRect,
          _holeAnimation.value,
        )!;

        return GestureDetector(
          onTap: () {},
          child: Stack(
            children: [
              Opacity(
                opacity: _overlayAnimation.value,
                child: CustomPaint(
                  size: screenSize,
                  painter: CoachMarkPainter(
                    targetRect: animatedRect,
                    shape: step.shape,
                    borderRadius: step.borderRadius,
                  ),
                ),
              ),
              if (_tooltipAnimation.value > 0)
                CoachMarkTooltip(
                  description: step.description,
                  currentStep: _currentStepIndex,
                  totalSteps: widget.steps.length,
                  targetRect: animatedRect,
                  screenSize: screenSize,
                  onNext: _goToNext,
                  onSkip: _complete,
                  animation: _tooltipAnimation,
                ),
            ],
          ),
        );
      },
    );
  }
}
