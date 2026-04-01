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

  group('hasDecimalPoints', () {
    test('null returns false', () {
      expect(hasDecimalPoints(null), false);
    });

    test('integer double returns false', () {
      expect(hasDecimalPoints(10.0), false);
    });

    test('double with decimal part returns true', () {
      expect(hasDecimalPoints(10.5), true);
    });

    test('double with trailing zeros after decimal value returns true', () {
      expect(hasDecimalPoints(10.50), true);
    });

    test('double with leading zeros in decimal part returns true', () {
      expect(hasDecimalPoints(10.05), true);
    });

    test('zero returns false', () {
      expect(hasDecimalPoints(0.0), false);
    });

    test('negative zero returns false', () {
      expect(hasDecimalPoints(-0.0), false);
    });

    test('negative number with decimal part returns true', () {
      expect(hasDecimalPoints(-3.14), true);
    });

    test('small fractional number returns true', () {
      expect(hasDecimalPoints(0.0001), true);
    });

    test('exponential notation double string characterization', () {
      // 1e-7 and smaller are represented as e.g. '1e-7' in Dart without a '.',
      // thus hasDecimalPoints returns false. This is characterization of current behavior.
      expect(hasDecimalPoints(0.0000001), false);
      expect(hasDecimalPoints(1e-10), false);
    });
  });

  group('cleanupNoteStringWithURLs', () {
    test('removes standard http URL', () {
      final input = "Check out this link: http://example.com/page";
      final expected = "Check out this link: example.com";
      expect(cleanupNoteStringWithURLs(input), expected);
    });

    test('removes standard https URL', () {
      final input = "Here is a secure link https://www.google.com/?q=flutter";
      final expected = "Here is a secure link google.com";
      expect(cleanupNoteStringWithURLs(input), expected);
    });

    test('removes multiple URLs', () {
      final input = "Read this https://example.com/ first, then go to http://test.org/page";
      final expected = "Read this example.com first, then go to test.org";
      expect(cleanupNoteStringWithURLs(input), expected);
    });

    test('does nothing to string without URLs', () {
      final input = "This is a normal note without any links.";
      expect(cleanupNoteStringWithURLs(input), input);
    });

    test('handles empty string', () {
      final input = "";
      expect(cleanupNoteStringWithURLs(input), "");
    });

    test('handles string containing only a URL', () {
      final input = "https://example.com";
      expect(cleanupNoteStringWithURLs(input), "example.com");
    });

    test('handles URL with trailing slash', () {
      final input = "Link: https://example.com/ ";
      final expected = "Link: example.com";
      expect(cleanupNoteStringWithURLs(input), expected);
    });

    test('handles URL with query parameters', () {
      final input = "Search here: https://example.com/search?q=dart&lang=en";
      final expected = "Search here: example.com";
      expect(cleanupNoteStringWithURLs(input), expected);
    });
  });
}
