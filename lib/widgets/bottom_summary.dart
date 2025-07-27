import 'package:flutter/material.dart';
import '../main.dart';

class BottomSummary extends StatelessWidget {
  final int total;
  final int? budget;
  final VoidCallback onBudgetClick;
  final VoidCallback onFab;
  const BottomSummary({
    super.key,
    required this.total,
    required this.budget,
    required this.onBudgetClick,
    required this.onFab,
  });

  @override
  Widget build(BuildContext context) {
    final over = budget != null && total > budget!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: onBudgetClick,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                ),
                child: const Text('予算変更'),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container()),
              FloatingActionButton(
                onPressed: onFab,
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 2,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: themeNotifier,
            builder: (context, _) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 100,
                  child: Center(
                    child: Text(
                      '¥$total',
                      style: TextStyle(
                        fontSize: 42,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '⚠ 予算を超えています！',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
