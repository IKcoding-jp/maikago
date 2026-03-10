import 'package:flutter/material.dart';

/// アイテムが0個のとき未購入リスト領域に表示する空状態ガイド
class EmptyStateGuide extends StatefulWidget {
  const EmptyStateGuide({super.key});

  @override
  State<EmptyStateGuide> createState() => _EmptyStateGuideState();
}

class _EmptyStateGuideState extends State<EmptyStateGuide>
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

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'アイテムがまだありません',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下の + ボタンから追加してみましょう',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 28,
                  color: primaryColor.withValues(alpha: 0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
