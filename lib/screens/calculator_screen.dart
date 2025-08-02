import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorScreen extends StatefulWidget {
  final String currentTheme;
  final ThemeData theme;

  const CalculatorScreen({
    super.key,
    required this.currentTheme,
    required this.theme,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  double totalAmount = 0.0;
  String _currentInput = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addToInput(String value) {
    setState(() {
      _currentInput += value;
    });
    HapticFeedback.lightImpact();
  }

  void _addAmount() {
    if (_currentInput.isNotEmpty) {
      final amount = double.tryParse(_currentInput);
      if (amount != null && amount > 0) {
        setState(() {
          totalAmount += amount;
          _currentInput = '';
        });

        // 追加時のアニメーション
        _animationController.forward().then((_) {
          _animationController.reverse();
        });

        // ハプティックフィードバック
        HapticFeedback.lightImpact();
      }
    }
  }

  void _clearAll() {
    setState(() {
      totalAmount = 0.0;
      _currentInput = '';
    });
    HapticFeedback.mediumImpact();
  }

  void _deleteLastDigit() {
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
      HapticFeedback.lightImpact();
    }
  }

  Color _getIconColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return Colors.white;
      case 'light':
        return Colors.white;
      case 'lemon':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  Color _getTotalAmountColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return Colors.white;
      case 'light':
        return widget.theme.colorScheme.primary;
      case 'lemon':
        return const Color(0xFF8B6914);
      default:
        return widget.theme.colorScheme.primary;
    }
  }

  Color? _getTextColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return Colors.white;
      default:
        return Colors.black87;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return const Color(0xFF1E1E1E);
      default:
        return widget.theme.colorScheme.primary;
    }
  }

  Color _getCardColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return const Color(0xFF2D2D2D);
      default:
        return Colors.white;
    }
  }

  Color _getButtonColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return const Color(0xFF3A3A3A);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.calculate_rounded, color: _getIconColor()),
            const SizedBox(width: 8),
            Text(
              '簡単電卓',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getIconColor(),
              ),
            ),
          ],
        ),
        backgroundColor: _getBackgroundColor(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _getIconColor()),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            // 合計表示エリア
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: _getCardColor(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.currentTheme == 'dark'
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.savings_rounded,
                    size: 40,
                    color: _getTotalAmountColor(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '合計金額',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Text(
                          '¥${totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getTotalAmountColor(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 入力表示エリア
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: _getCardColor(),
                borderRadius: BorderRadius.circular(20),
                boxShadow: widget.currentTheme == 'dark'
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Text(
                _currentInput.isEmpty ? '0' : '¥$_currentInput',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 電卓ボタンエリア
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _getCardColor(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 数字ボタン
                    Column(
                      children: [
                        // 1行目: 7, 8, 9
                        Row(
                          children: [
                            _buildNumberButton('7'),
                            const SizedBox(width: 8),
                            _buildNumberButton('8'),
                            const SizedBox(width: 8),
                            _buildNumberButton('9'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 2行目: 4, 5, 6
                        Row(
                          children: [
                            _buildNumberButton('4'),
                            const SizedBox(width: 8),
                            _buildNumberButton('5'),
                            const SizedBox(width: 8),
                            _buildNumberButton('6'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 3行目: 1, 2, 3
                        Row(
                          children: [
                            _buildNumberButton('1'),
                            const SizedBox(width: 8),
                            _buildNumberButton('2'),
                            const SizedBox(width: 8),
                            _buildNumberButton('3'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 4行目: 0, 00, 削除
                        Row(
                          children: [
                            _buildNumberButton('0'),
                            const SizedBox(width: 8),
                            _buildNumberButton('00'),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.backspace_rounded,
                              onPressed: _deleteLastDigit,
                              color: widget.theme.colorScheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // アクションボタン
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.clear_all_rounded,
                            label: 'クリア',
                            onPressed: _clearAll,
                            color: widget.theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.add_rounded,
                            label: '追加',
                            onPressed: _addAmount,
                            color: widget.theme.colorScheme.primary,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // 下部マージンを追加
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: SizedBox(
        height: 60,
        child: ElevatedButton(
          onPressed: () => _addToInput(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(),
            foregroundColor: _getTextColor(),
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            side: widget.currentTheme == 'dark'
                ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
                : BorderSide(
                    color: widget.theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
            elevation: widget.currentTheme == 'dark' ? 0 : 2,
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    Color getActionButtonColor() {
      if (isPrimary) {
        return color;
      } else {
        return _getButtonColor();
      }
    }

    Color getActionButtonForegroundColor() {
      if (isPrimary) {
        switch (widget.currentTheme) {
          case 'lemon':
            return const Color(0xFF8B6914);
          case 'light':
            return Colors.black87;
          case 'dark':
            return Colors.white;
          default:
            return Colors.white;
        }
      } else {
        return color;
      }
    }

    return Expanded(
      child: SizedBox(
        height: label != null ? 50 : 60, // ラベルがある場合は少し小さく
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: getActionButtonColor(),
            foregroundColor: getActionButtonForegroundColor(),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            side: isPrimary
                ? null
                : (widget.currentTheme == 'dark'
                      ? BorderSide(color: color.withValues(alpha: 0.3))
                      : BorderSide(color: color.withValues(alpha: 0.3))),
            elevation: widget.currentTheme == 'dark'
                ? (isPrimary ? 2 : 0)
                : (isPrimary ? 3 : 1),
          ),
          child: label != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Icon(icon),
        ),
      ),
    );
  }
}
