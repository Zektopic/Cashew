import 'package:flutter_test/flutter_test.dart';
import 'package:budget/functions.dart';

void main() {
  group('daysBetween', () {
    test('same day returns 0', () {
      final from = DateTime(2023, 10, 1);
      final to = DateTime(2023, 10, 1);
      expect(daysBetween(from, to), 0);
    });

    test('same day different times returns 0', () {
      final from = DateTime(2023, 10, 1, 10, 0);
      final to = DateTime(2023, 10, 1, 20, 0);
      expect(daysBetween(from, to), 0);
    });

    test('next day returns 1', () {
      final from = DateTime(2023, 10, 1);
      final to = DateTime(2023, 10, 2);
      expect(daysBetween(from, to), 1);
    });

    test('next day late from early to returns 1', () {
      final from = DateTime(2023, 10, 1, 23, 59);
      final to = DateTime(2023, 10, 2, 0, 1);
      expect(daysBetween(from, to), 1);
    });

    test('multi-day difference', () {
      final from = DateTime(2023, 10, 1);
      final to = DateTime(2023, 10, 10);
      expect(daysBetween(from, to), 9);
    });

    test('across months', () {
      final from = DateTime(2023, 9, 30);
      final to = DateTime(2023, 10, 1);
      expect(daysBetween(from, to), 1);
    });

    test('across years', () {
      final from = DateTime(2023, 12, 31);
      final to = DateTime(2024, 1, 1);
      expect(daysBetween(from, to), 1);
    });

    test('leap year Feb 28 to Mar 1', () {
      final from = DateTime(2024, 2, 28);
      final to = DateTime(2024, 3, 1);
      expect(daysBetween(from, to), 2);
    });

    test('non-leap year Feb 28 to Mar 1', () {
      final from = DateTime(2023, 2, 28);
      final to = DateTime(2023, 3, 1);
      expect(daysBetween(from, to), 1);
    });

    test('to before from returns negative', () {
      final from = DateTime(2023, 10, 2);
      final to = DateTime(2023, 10, 1);
      expect(daysBetween(from, to), -1);
    });

    test('large difference', () {
      final from = DateTime(2020, 1, 1);
      final to = DateTime(2023, 1, 1);
      // 2020 (leap), 2021, 2022
      // 366 + 365 + 365 = 1096
      expect(daysBetween(from, to), 1096);
    });

    test('DST transition spring (missing hour)', () {
      // 2023 spring DST was March 12.
      final from = DateTime(2023, 3, 12);
      final to = DateTime(2023, 3, 13);
      expect(daysBetween(from, to), 1);
    });

    test('DST transition fall (extra hour)', () {
      // 2023 fall DST was Nov 5.
      final from = DateTime(2023, 11, 5);
      final to = DateTime(2023, 11, 6);
      expect(daysBetween(from, to), 1);
    });
  });

  group('absoluteZeroString', () {
    test('removes minus from basic zeros', () {
      expect(absoluteZeroString("-0"), "0");
      expect(absoluteZeroString("-0.0"), "0.0");
      expect(absoluteZeroString("-0.00"), "0.00");
      expect(absoluteZeroString("-0.000"), "0.000");
      expect(absoluteZeroString("-0.0000"), "0.0000");
    });

    test('leaves non-zero negative numbers untouched', () {
      expect(absoluteZeroString("-1"), "-1");
      expect(absoluteZeroString("-0.1"), "-0.1");
      expect(absoluteZeroString("-0.0001"), "-0.0001");
      expect(absoluteZeroString("-1.0"), "-1.0");
    });

    test('leaves positive numbers untouched', () {
      expect(absoluteZeroString("0"), "0");
      expect(absoluteZeroString("0.0"), "0.0");
      expect(absoluteZeroString("1"), "1");
      expect(absoluteZeroString("0.1"), "0.1");
    });

    test('handles empty or non-numeric strings safely', () {
      expect(absoluteZeroString(""), "");
      expect(absoluteZeroString("abc"), "abc");
      expect(absoluteZeroString("-"), "-");
    });
  });
}
