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

  group('isNumber', () {
    test('returns true for int', () {
      expect(isNumber(42), isTrue);
      expect(isNumber(0), isTrue);
      expect(isNumber(-10), isTrue);
    });

    test('returns true for double', () {
      expect(isNumber(3.14), isTrue);
      expect(isNumber(0.0), isTrue);
      expect(isNumber(-2.5), isTrue);
    });

    test('returns true for numeric strings', () {
      expect(isNumber('100'), isTrue);
      expect(isNumber('10.5'), isTrue);
      expect(isNumber('-5'), isTrue);
      expect(isNumber('-2.5'), isTrue);
      expect(isNumber('0'), isTrue);
    });

    test('returns true for scientific notation strings', () {
      expect(isNumber('1e3'), isTrue);
      expect(isNumber('2.5e-2'), isTrue);
    });

    test('returns false for null', () {
      expect(isNumber(null), isFalse);
    });

    test('returns false for empty or whitespace strings', () {
      expect(isNumber(''), isFalse);
      expect(isNumber('   '), isFalse);
    });

    test('returns false for non-numeric strings', () {
      expect(isNumber('abc'), isFalse);
      expect(isNumber('12abc'), isFalse);
      expect(isNumber('1.2.3'), isFalse);
    });

    test('returns false for other types', () {
      expect(isNumber(true), isFalse);
      expect(isNumber(false), isFalse);
      expect(isNumber([]), isFalse);
      expect(isNumber({}), isFalse);
    });
  });
}
