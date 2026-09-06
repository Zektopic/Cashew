import 'package:flutter_test/flutter_test.dart';
import 'package:budget/pages/addTransactionPage.dart';

void main() {
  group('getFileIdFromUrl tests', () {
    test('valid drive url', () {
      expect(
          getFileIdFromUrl('https://drive.google.com/file/d/12345'), '12345');
    });

    test('valid docs url', () {
      expect(getFileIdFromUrl('https://docs.google.com/document/d/12345'),
          '12345');
    });

    test('valid sheets url', () {
      expect(getFileIdFromUrl('https://docs.google.com/spreadsheets/d/12345'),
          '12345');
    });

    test('valid presentation url', () {
      expect(getFileIdFromUrl('https://docs.google.com/presentation/d/12345'),
          '12345');
    });

    test('invalid host', () {
      expect(getFileIdFromUrl('https://malicious.com/file/d/12345'), null);
    });

    test('invalid scheme', () {
      expect(getFileIdFromUrl('http://drive.google.com/file/d/12345'), null);
    });

    test('path traversal', () {
      expect(
          getFileIdFromUrl(
              'https://drive.google.com/file/d/../../../etc/passwd'),
          null);
    });

    test('invalid characters', () {
      // It matches 12345 successfully up to the ? which is stripped by the matcher,
      // but if the URL contains dangerous characters, we should ensure the original logic is tested correctly.
      // Wait, `firstMatch` gets "12345". And `[/?#@\\]|\.\.` doesn't match "12345". So it returns "12345".
      // This is the expected existing behavior since ?foo=bar is not part of the fileID match.
      expect(getFileIdFromUrl('https://drive.google.com/file/d/12345?foo=bar'),
          '12345');
    });
  });
}
