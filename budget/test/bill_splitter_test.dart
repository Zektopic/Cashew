import 'package:flutter_test/flutter_test.dart';
import 'package:budget/pages/billSplitter.dart';

void main() {
  group('SplitPerson JSON serialization', () {
    test('toJson with percent', () {
      final person = SplitPerson('Alice', percent: 25.0);
      final json = person.toJson();
      expect(json, {
        'name': 'Alice',
        'percent': 25.0,
      });
    });

    test('toJson without percent', () {
      final person = SplitPerson('Bob');
      final json = person.toJson();
      expect(json, {
        'name': 'Bob',
        'percent': null,
      });
    });

    test('fromJson with percent', () {
      final json = {
        'name': 'Charlie',
        'percent': 50.0,
      };
      final person = SplitPerson.fromJson(json);
      expect(person.name, 'Charlie');
      expect(person.percent, 50.0);
    });

    test('fromJson without percent', () {
      final json = {
        'name': 'David',
        'percent': null,
      };
      final person = SplitPerson.fromJson(json);
      expect(person.name, 'David');
      expect(person.percent, null);
    });
  });

  group('BillSplitterItem JSON serialization', () {
    test('toJson with default evenSplit and empty users', () {
      final item = BillSplitterItem('Dinner', 100.0, []);
      final json = item.toJson();
      expect(json, {
        'name': 'Dinner',
        'cost': 100.0,
        'evenSplit': true,
        'userAmounts': [],
      });
    });

    test('toJson with users and evenSplit false', () {
      final item = BillSplitterItem(
        'Lunch',
        50.0,
        [
          SplitPerson('Alice', percent: 60.0),
          SplitPerson('Bob', percent: 40.0),
        ],
        evenSplit: false,
      );
      final json = item.toJson();
      expect(json, {
        'name': 'Lunch',
        'cost': 50.0,
        'evenSplit': false,
        'userAmounts': [
          {'name': 'Alice', 'percent': 60.0},
          {'name': 'Bob', 'percent': 40.0},
        ],
      });
    });

    test('fromJson with default evenSplit and empty users', () {
      final json = {
        'name': 'Dinner',
        'cost': 100.0,
        'evenSplit': true,
        'userAmounts': [],
      };
      final item = BillSplitterItem.fromJson(json);
      expect(item.name, 'Dinner');
      expect(item.cost, 100.0);
      expect(item.evenSplit, true);
      expect(item.userAmounts, isEmpty);
    });

    test('fromJson with users and evenSplit false', () {
      final json = {
        'name': 'Lunch',
        'cost': 50.0,
        'evenSplit': false,
        'userAmounts': [
          {'name': 'Alice', 'percent': 60.0},
          {'name': 'Bob', 'percent': 40.0},
        ],
      };
      final item = BillSplitterItem.fromJson(json);
      expect(item.name, 'Lunch');
      expect(item.cost, 50.0);
      expect(item.evenSplit, false);
      expect(item.userAmounts.length, 2);
      expect(item.userAmounts[0].name, 'Alice');
      expect(item.userAmounts[0].percent, 60.0);
      expect(item.userAmounts[1].name, 'Bob');
      expect(item.userAmounts[1].percent, 40.0);
    });
  });
}
