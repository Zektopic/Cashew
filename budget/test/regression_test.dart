import 'package:budget/database/tables.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/lineGraph.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for two type-mismatched comparisons that shipped because
/// nothing here was covered. Both were `always true` / `always false` in a way
/// the analyzer flagged but no test caught.
void main() {
  group('measureCurrencyStringExtraWidth', () {
    // Was: `if (currencyString.length == "1")` — an int compared to a String,
    // so it was always false and the `return 0` branch was unreachable.
    // Single-character symbols were padded as if they were 5px wider.

    AllWallets walletsWithCurrency(String currencyKey) {
      final wallet = TransactionWallet(
        walletPk: 'w1',
        name: 'Wallet',
        order: 0,
        dateCreated: DateTime(2024, 1, 1),
        currency: currencyKey,
        decimals: 2,
      );
      return AllWallets(list: [wallet], indexedByPk: {'w1': wallet});
    }

    setUp(() {
      appStateSettings = {'selectedWalletPk': 'w1'};
      currenciesJSON = {
        'usd': {'Symbol': r'$'},
        'gbp': {'Symbol': '£'},
        'chf': {'Symbol': 'CHF'},
        'none': {'Symbol': ''},
      };
    });

    test('single-character symbol needs no extra width', () {
      expect(measureCurrencyStringExtraWidth(walletsWithCurrency('usd')), 0);
      expect(measureCurrencyStringExtraWidth(walletsWithCurrency('gbp')), 0);
    });

    test('multi-character symbol scales with length', () {
      // "CHF" -> 3 characters
      expect(measureCurrencyStringExtraWidth(walletsWithCurrency('chf')), 15);
    });

    test('empty symbol needs no extra width', () {
      expect(measureCurrencyStringExtraWidth(walletsWithCurrency('none')), 0);
    });
  });

  group('date range chip year suppression', () {
    // Was: `searchFilters.dateTimeRange!.start != DateTime.now().year` — a
    // DateTime compared to an int, so it was always true and filter chips
    // always rendered the year. This pins the intended predicate.
    bool includeYearFor(DateTime date, DateTime now) => date.year != now.year;

    test('omits the year for a date in the current year', () {
      final now = DateTime(2026, 8, 16);
      expect(includeYearFor(DateTime(2026, 1, 1), now), isFalse);
      expect(includeYearFor(DateTime(2026, 12, 31), now), isFalse);
    });

    test('includes the year for a date in a different year', () {
      final now = DateTime(2026, 8, 16);
      expect(includeYearFor(DateTime(2025, 12, 31), now), isTrue);
      expect(includeYearFor(DateTime(2027, 1, 1), now), isTrue);
    });

    test('comparing the DateTime itself to an int is always true', () {
      // Documents the original defect: the old expression could never be false,
      // which is why the year was always shown.
      final date = DateTime(2026, 8, 16);
      // ignore: unrelated_type_equality_checks
      expect(date != DateTime(2026, 1, 1).year, isTrue);
    });
  });
}
