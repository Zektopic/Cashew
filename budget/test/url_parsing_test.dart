import 'package:flutter_test/flutter_test.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/widgets/importCSV.dart';

void main() {
  group('getFileIdFromUrl tests', () {
    test('valid drive url', () {
      expect(
        getFileIdFromUrl('https://drive.google.com/file/d/12345_abc-XYZ'),
        '12345_abc-XYZ',
      );
    });

    test('valid docs url', () {
      expect(
        getFileIdFromUrl('https://docs.google.com/document/d/12345'),
        '12345',
      );
    });

    test('valid sheets url', () {
      expect(
        getFileIdFromUrl('https://docs.google.com/spreadsheets/d/12345'),
        '12345',
      );
    });

    test('valid presentation url', () {
      expect(
        getFileIdFromUrl('https://docs.google.com/presentation/d/12345'),
        '12345',
      );
    });

    test('invalid host', () {
      expect(getFileIdFromUrl('https://malicious.com/file/d/12345'), null);
    });

    test('invalid scheme', () {
      expect(getFileIdFromUrl('http://drive.google.com/file/d/12345'), null);
    });

    test('path traversal and non-whitelisted characters rejected', () {
      expect(
        getFileIdFromUrl('https://drive.google.com/file/d/../../../etc/passwd'),
        null,
      );
      expect(
        getFileIdFromUrl('https://drive.google.com/file/d/invalid@id'),
        null,
      );
      expect(
        getFileIdFromUrl('https://drive.google.com/file/d/invalid.id'),
        null,
      );
    });
  });

  group('convertGoogleSheetsUrlToCsvUrl tests', () {
    test('valid sheets url converts to csv export url', () {
      expect(
        ImportCSV.convertGoogleSheetsUrlToCsvUrl(
          'https://docs.google.com/spreadsheets/d/1Eiib2fiaC8SNdau8T8TBQql-wyWXVYOLJY-7Ycuky4I/edit',
        ),
        'https://docs.google.com/spreadsheets/d/1Eiib2fiaC8SNdau8T8TBQql-wyWXVYOLJY-7Ycuky4I/gviz/tq?tqx=out:csv',
      );
    });

    test('invalid host throws', () {
      expect(
        () => ImportCSV.convertGoogleSheetsUrlToCsvUrl(
          'https://attacker.com/spreadsheets/d/12345/edit',
        ),
        throwsA(anything),
      );
    });

    test('invalid scheme throws', () {
      expect(
        () => ImportCSV.convertGoogleSheetsUrlToCsvUrl(
          'http://docs.google.com/spreadsheets/d/12345/edit',
        ),
        throwsA(anything),
      );
    });

    test('non-whitelisted characters in spreadsheetId throw', () {
      expect(
        () => ImportCSV.convertGoogleSheetsUrlToCsvUrl(
          'https://docs.google.com/spreadsheets/d/invalid@id/edit',
        ),
        throwsA(anything),
      );
      expect(
        () => ImportCSV.convertGoogleSheetsUrlToCsvUrl(
          'https://docs.google.com/spreadsheets/d/invalid..id/edit',
        ),
        throwsA(anything),
      );
    });
  });
}
