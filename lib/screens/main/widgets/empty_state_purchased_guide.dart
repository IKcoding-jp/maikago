import 'package:flutter/material.dart';

/// 購入済みアイテムが0個のとき購入済みリスト領域に表示する空状態ガイド
class EmptyStatePurchasedGuide extends StatefulWidget {
  const EmptyStatePurchasedGuide({super.key});

  @override
  State<EmptyStatePurchasedGuide> createState() =>
      _EmptyStatePurchasedGuideState();
}

class _EmptyStatePurchasedGuideState extends State<EmptyStatePurchasedGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Align(
      alignment: const Alignment(0, -0.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 92,
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_bounceAnimation.value, 0),
                  child: Icon(
                    Icons.swipe_right_rounded,
                    size: 72,
                    color: primaryColor.withValues(alpha: 0.7),
                  ),
                );
              },
            ),
          ),
          Text(
            'リストを右にスワイプして\n購入済みへ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ここに移動すると\n合計金額に反映されます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
