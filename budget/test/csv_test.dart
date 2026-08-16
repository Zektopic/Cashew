import 'package:budget/widgets/exportCSV.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Characterization tests for the CSV import/export path.
///
/// This path handles user-supplied files and had no coverage at all, which is
/// why the `csv` package upgrade was held back. These tests pin the encode and
/// decode behaviour the app actually depends on — quoting, embedded delimiters
/// and newlines, unicode, and the formula-injection guard — so the package can
/// be migrated and checked against real expectations rather than against
/// nothing.
void main() {
  group('sanitizeCsvField formula-injection guard', () {
    // Spreadsheet apps execute cells beginning with these characters, so a
    // transaction titled "=HYPERLINK(...)" would run when the file is opened.
    const List<String> dangerousPrefixes = <String>[
      '=', '+', '-', '@', '\t', '\r', '\n',
    ];

    for (final String prefix in dangerousPrefixes) {
      test('prefixes a field starting with U+${prefix.codeUnitAt(0)}', () {
        final String out = sanitizeCsvField('${prefix}SUM(A1:A9)');
        expect(out, startsWith("'"));
        expect(out, equals("'${prefix}SUM(A1:A9)"));
      });
    }

    test('leaves ordinary values untouched', () {
      expect(sanitizeCsvField('Groceries'), equals('Groceries'));
      expect(sanitizeCsvField('12.34'), equals('12.34'));
      expect(sanitizeCsvField(''), equals(''));
    });

    test('does not prefix a value that merely contains a dangerous char', () {
      expect(sanitizeCsvField('a=b'), equals('a=b'));
      expect(sanitizeCsvField('Tim@work'), equals('Tim@work'));
      expect(sanitizeCsvField('non-breaking'), equals('non-breaking'));
    });

    test('a negative amount is quoted, which is intended', () {
      // Worth pinning: "-12.34" starts with '-', so it is exported as "'-12.34".
      // That is deliberate — the guard cannot distinguish a negative number
      // from a formula, and mangling one cell is preferable to executing it.
      expect(sanitizeCsvField('-12.34'), equals("'-12.34"));
    });
  });

  group('cleanFileNameString', () {
    test('replaces filesystem-hostile characters', () {
      expect(cleanFileNameString('my budget/report'),
          equals('my-budget-report'));
      expect(cleanFileNameString('a:b*c?d'), equals('a-b-c-d'));
    });

    test('trims leading and trailing hyphens', () {
      expect(cleanFileNameString('  spaced  '), equals('spaced'));
      expect(cleanFileNameString('.hidden.'), equals('hidden'));
    });
  });

  group('csv encode/decode round-trip', () {
    // Mirrors exactly what exportCSV.dart and importCSV.dart do, including the
    // line-ending normalization the importer applies before parsing.
    String encode(List<List<dynamic>> rows) =>
        ListToCsvConverter().convert(rows);

    List<List<dynamic>> decode(String text) {
      text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      return CsvToListConverter()
          .convert(text, eol: '\n', shouldParseNumbers: false);
    }

    test('round-trips a simple table', () {
      final rows = <List<dynamic>>[
        ['date', 'amount', 'title'],
        ['2026-08-16', '12.34', 'Coffee'],
      ];
      expect(decode(encode(rows)), equals(rows));
    });

    test('round-trips values containing the delimiter', () {
      final rows = <List<dynamic>>[
        ['title', 'note'],
        ['Dinner, with friends', 'split 3, ways'],
      ];
      expect(decode(encode(rows)), equals(rows));
    });

    test('round-trips values containing quotes', () {
      final rows = <List<dynamic>>[
        ['title'],
        ['The "Good" Cafe'],
      ];
      expect(decode(encode(rows)), equals(rows));
    });

    test('round-trips values containing embedded newlines', () {
      final rows = <List<dynamic>>[
        ['note'],
        ['line one\nline two'],
      ];
      expect(decode(encode(rows)), equals(rows));
    });

    test('round-trips unicode', () {
      final rows = <List<dynamic>>[
        ['title', 'currency'],
        ['Café — Zürich', '£€¥'],
        ['日本語のテスト', '₹'],
      ];
      expect(decode(encode(rows)), equals(rows));
    });

    test('keeps numeric-looking values as strings on decode', () {
      // shouldParseNumbers: false matters — amounts are parsed by the app's own
      // locale-aware logic, not by the CSV reader. Losing the leading zeros or
      // the string type here would change how amounts are interpreted.
      final decoded = decode('amount\n0012.30\n');
      expect(decoded[1][0], isA<String>());
      expect(decoded[1][0], equals('0012.30'));
    });

    test('preserves the injection guard through a round-trip', () {
      final String guarded = sanitizeCsvField('=cmd|calc');
      final decoded = decode(encode(<List<dynamic>>[
        ['title'],
        [guarded],
      ]));
      expect(decoded[1][0], equals("'=cmd|calc"),
          reason: 'the leading apostrophe must survive encoding');
    });

    test('CRLF files decode without a trailing carriage return', () {
      // Regression guard. ListToCsvConverter writes \r\n, but the importer
      // passes eol: '\n'. Before line-ending normalization was added, the last
      // column of every row came back with a stray '\r' — which silently
      // corrupted every re-import of this app's own export and of the
      // downloadable import template.
      final decoded = decode('date,amount,title\r\n2026-08-16,12.34,Coffee\r\n');
      expect(decoded[0], equals(['date', 'amount', 'title']));
      expect(decoded[1], equals(['2026-08-16', '12.34', 'Coffee']));
      for (final row in decoded) {
        for (final cell in row) {
          expect(cell.toString(), isNot(contains('\r')));
        }
      }
    });

    test('LF-only files still decode', () {
      final decoded = decode('date,amount\n2026-08-16,12.34\n');
      expect(decoded[1], equals(['2026-08-16', '12.34']));
    });
  });
}
