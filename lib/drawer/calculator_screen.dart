import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maikago/utils/dialog_utils.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.currentTheme,
    required this.theme,
  });

  final String currentTheme;
  final ThemeData theme;

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

  void _showHintDialog() {
    showConstrainedDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: widget.theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                '簡単電卓の使い方',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'リストとかいらないから、とにかく価格だけ知りたいってときに使える、価格を計算するためだけの電卓です。',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildHintItem(
                '1. 数字を入力',
                '数字ボタンをタップして価格を入力します',
                Icons.dialpad_rounded,
              ),
              const SizedBox(height: 12),
              _buildHintItem(
                '2. 追加ボタンをタップ',
                '入力した価格を合計に追加します',
                Icons.add_rounded,
              ),
              const SizedBox(height: 12),
              _buildHintItem(
                '3. 繰り返し計算',
                '複数の商品価格を順番に追加できます',
                Icons.repeat_rounded,
              ),
              const SizedBox(height: 12),
              _buildHintItem(
                '4. クリアでリセット',
                '合計を0にリセットして新しい計算を始めます',
                Icons.clear_all_rounded,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '閉じる',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHintItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: widget.theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        return Colors.black;
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

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
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: _getIconColor()),
            onPressed: _showHintDialog,
            tooltip: '使い方を見る',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 16.0,
            vertical: isSmallScreen ? 12.0 : 20.0,
          ),
          child: Column(
            children: [
              // 合計表示エリア
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
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
                      size: isSmallScreen ? 32 : 40,
                      color: _getTotalAmountColor(),
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Text(
                      '合計金額',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w500,
                        color: _getTextColor(),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '¥${totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 28 : 36,
                                fontWeight: FontWeight.bold,
                                color: _getTotalAmountColor(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),

              // 入力表示エリア
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _currentInput.isEmpty ? '0' : '¥$_currentInput',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),

              // 電卓ボタンエリア
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
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
                      Expanded(
                        child: Column(
                          children: [
                            // 1行目: 7, 8, 9
                            Expanded(
                              child: Row(
                                children: [
                                  _buildNumberButton('7', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('8', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('9', isSmallScreen),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            // 2行目: 4, 5, 6
                            Expanded(
                              child: Row(
                                children: [
                                  _buildNumberButton('4', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('5', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('6', isSmallScreen),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            // 3行目: 1, 2, 3
                            Expanded(
                              child: Row(
                                children: [
                                  _buildNumberButton('1', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('2', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('3', isSmallScreen),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            // 4行目: 0, 00, 削除
                            Expanded(
                              child: Row(
                                children: [
                                  _buildNumberButton('0', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildNumberButton('00', isSmallScreen),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildActionButton(
                                    icon: Icons.backspace_rounded,
                                    onPressed: _deleteLastDigit,
                                    color: widget.theme.colorScheme.error,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      // アクションボタン
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.clear_all_rounded,
                              label: 'クリア',
                              onPressed: _clearAll,
                              color: widget.theme.colorScheme.error,
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.add_rounded,
                              label: '追加',
                              onPressed: _addAmount,
                              color: widget.theme.colorScheme.primary,
                              isPrimary: true,
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 20), // 下部マージンを追加
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, bool isSmallScreen) {
    return Expanded(
      child: SizedBox(
        height: isSmallScreen ? 70 : 80,
        child: ElevatedButton(
          onPressed: () => _addToInput(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(),
            foregroundColor: _getTextColor(),
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: TextStyle(
                fontSize: isSmallScreen ? 32 : 36,
                fontWeight: FontWeight.w500,
              ),
            ),
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
    required bool isSmallScreen,
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
            return Colors.black;
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
        height: label != null
            ? (isSmallScreen ? 40 : 50)
            : (isSmallScreen ? 50 : 60),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: getActionButtonColor(),
            foregroundColor: getActionButtonForegroundColor(),
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: isSmallScreen ? 18 : 24),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Icon(icon, size: isSmallScreen ? 20 : 24),
        ),
      ),
    );
  }
}
