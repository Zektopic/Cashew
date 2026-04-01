import 'package:flutter_test/flutter_test.dart';
import 'package:budget/pages/billSplitter.dart';

void main() {
  group('SplitPerson JSON serialization', () {
    test('fromJson with all properties', () {
      final Map<String, dynamic> json = {
        'name': 'Alice',
        'percent': 0.5,
      };

      final person = SplitPerson.fromJson(json);

      expect(person.name, 'Alice');
      expect(person.percent, 0.5);
    });

    test('fromJson with missing optional percent', () {
      final Map<String, dynamic> json = {
        'name': 'Bob',
      };

      final person = SplitPerson.fromJson(json);

      expect(person.name, 'Bob');
      expect(person.percent, null);
    });

    test('toJson with all properties', () {
      final person = SplitPerson('Charlie', percent: 0.25);

      final json = person.toJson();

      expect(json, {
        'name': 'Charlie',
        'percent': 0.25,
      });
    });

    test('toJson with missing optional percent', () {
      final person = SplitPerson('Dave');

      final json = person.toJson();

      expect(json, {
        'name': 'Dave',
        'percent': null,
      });
    });
  });
}
