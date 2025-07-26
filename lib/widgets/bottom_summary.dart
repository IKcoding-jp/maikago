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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = over
        ? (isDark ? Colors.red[200]! : Colors.red)
        : (isDark ? Colors.white : Theme.of(context).colorScheme.primary);
    return Container(
      color: Theme.of(context).colorScheme.surface,
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
                ),
                child: const Text('予算変更'),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container()),
              FloatingActionButton(
                onPressed: onFab,
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
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
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                elevation: 0,
                color: theme.colorScheme.surface,
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: Center(
                    child: Text(
                      '¥$total',
                      style: TextStyle(
                        fontSize: 30,
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
