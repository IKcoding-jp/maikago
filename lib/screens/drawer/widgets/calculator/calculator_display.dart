import 'package:flutter/material.dart';
import 'package:maikago/utils/theme_utils.dart';

/// 合計金額表示ウィジェット
class CalculatorTotalDisplay extends StatelessWidget {
  const CalculatorTotalDisplay({
    super.key,
    required this.theme,
    required this.totalAmount,
    required this.scaleAnimation,
    required this.isSmallScreen,
    required this.totalAmountColor,
    required this.textColor,
    required this.cardColor,
  });

  final ThemeData theme;
  final double totalAmount;
  final Animation<double> scaleAnimation;
  final bool isSmallScreen;
  final Color totalAmountColor;
  final Color? textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.savings_rounded,
            size: isSmallScreen ? 32 : 40,
            color: totalAmountColor,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            '合計金額',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimation.value,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '¥${totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: totalAmountColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 入力中の金額表示ウィジェット
class CalculatorInputDisplay extends StatelessWidget {
  const CalculatorInputDisplay({
    super.key,
    required this.theme,
    required this.currentInput,
    required this.isSmallScreen,
    required this.textColor,
    required this.cardColor,
  });

  final ThemeData theme;
  final String currentInput;
  final bool isSmallScreen;
  final Color? textColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          currentInput.isEmpty ? '0' : '¥$currentInput',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
