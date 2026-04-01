import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget/colors.dart';

void main() {
  group('darken', () {
    test('decreases lightness by default amount (0.1)', () {
      const color = Color(0xFF808080); // Gray (lightness 0.5)
      final result = darken(color);

      final originalHsl = HSLColor.fromColor(color);
      final resultHsl = HSLColor.fromColor(result);

      expect(resultHsl.lightness, closeTo(originalHsl.lightness - 0.1, 0.005));
    });

    test('decreases lightness by custom amount', () {
      const color = Color(0xFF808080); // Gray (lightness 0.5)
      final result = darken(color, 0.3);

      final originalHsl = HSLColor.fromColor(color);
      final resultHsl = HSLColor.fromColor(result);

      expect(resultHsl.lightness, closeTo(originalHsl.lightness - 0.3, 0.005));
    });

    test('clamps lightness to 0.0 when darkening a very dark color', () {
      const color = Color(0xFF111111); // Very dark gray
      final result = darken(color, 0.8);

      final resultHsl = HSLColor.fromColor(result);

      expect(resultHsl.lightness, equals(0.0));
      expect(result, equals(const Color(0xFF000000))); // Black
    });

    test('returns black when darkening by 1.0', () {
      const color = Color(0xFFFF0000); // Red
      final result = darken(color, 1.0);

      expect(result, equals(const Color(0xFF000000))); // Black
    });

    test('returns same color when darkening by 0.0', () {
      const color = Color(0xFFFF0000); // Red
      final result = darken(color, 0.0);

      expect(result.value, equals(color.value));
    });

    test('throws assertion error if amount is negative', () {
      const color = Color(0xFFFF0000);
      expect(() => darken(color, -0.1), throwsAssertionError);
    });

    test('throws assertion error if amount is > 1.0', () {
      const color = Color(0xFFFF0000);
      expect(() => darken(color, 1.1), throwsAssertionError);
    });
  });

  group('lighten', () {
    test('increases lightness by default amount (0.1)', () {
      const color = Color(0xFF808080); // Gray (lightness 0.5)
      final result = lighten(color);

      final originalHsl = HSLColor.fromColor(color);
      final resultHsl = HSLColor.fromColor(result);

      expect(resultHsl.lightness, closeTo(originalHsl.lightness + 0.1, 0.005));
    });

    test('increases lightness by custom amount', () {
      const color = Color(0xFF808080); // Gray (lightness 0.5)
      final result = lighten(color, 0.3);

      final originalHsl = HSLColor.fromColor(color);
      final resultHsl = HSLColor.fromColor(result);

      expect(resultHsl.lightness, closeTo(originalHsl.lightness + 0.3, 0.005));
    });

    test('clamps lightness to 1.0 when lightening a very light color', () {
      const color = Color(0xFFEEEEEE); // Very light gray
      final result = lighten(color, 0.8);

      final resultHsl = HSLColor.fromColor(result);

      expect(resultHsl.lightness, equals(1.0));
      expect(result, equals(const Color(0xFFFFFFFF))); // White
    });

    test('returns white when lightening by 1.0', () {
      const color = Color(0xFFFF0000); // Red
      final result = lighten(color, 1.0);

      expect(result, equals(const Color(0xFFFFFFFF))); // White
    });

    test('returns same color when lightening by 0.0', () {
      const color = Color(0xFFFF0000); // Red
      final result = lighten(color, 0.0);

      expect(result.value, equals(color.value));
    });

    test('throws assertion error if amount is negative', () {
      const color = Color(0xFFFF0000);
      expect(() => lighten(color, -0.1), throwsAssertionError);
    });

    test('throws assertion error if amount is > 1.0', () {
      const color = Color(0xFFFF0000);
      expect(() => lighten(color, 1.1), throwsAssertionError);
    });
  });
}
