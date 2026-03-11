import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/utils/theme_utils.dart';

void main() {
  group('ThemeUtils', () {
    test('subtextColor uses onSurface with alpha for light theme', () {
      final theme = ThemeData(colorScheme: const ColorScheme.light());
      final color = theme.subtextColor;
      expect(color.a, closeTo(0.6, 0.05));
    });

    test('subtextColor uses onSurface with alpha for dark theme', () {
      final theme = ThemeData(colorScheme: const ColorScheme.dark());
      final color = theme.subtextColor;
      expect(color.a, closeTo(0.6, 0.05));
    });

    test('cardShadowColor lighter for light theme', () {
      final theme = ThemeData(brightness: Brightness.light);
      expect(theme.cardShadowColor.a, closeTo(0.1, 0.05));
    });

    test('cardShadowColor darker for dark theme', () {
      final theme = ThemeData(brightness: Brightness.dark);
      expect(theme.cardShadowColor.a, closeTo(0.3, 0.05));
    });
  });
}
