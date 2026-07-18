import 'dart:math';

import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/budgetPage.dart' show determineBudgetPolarity;
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Budget rollover: when enabled for a budget, the unspent balance of the
// previous period is carried into the current period (a single-period carry —
// leftovers do not compound across multiple periods). Overspending the
// previous period reduces the current period, floored at zero.
//
// The rollover flag is stored per-budget in appStateSettings
// ("budgetRollover": {budgetPk: true}) following the same pattern as
// "watchedCategoriesOnBudget", so no database schema migration is needed.
// The adjustment is applied by wrapping budget consumers in
// [RolloverAdjustedBudget], which hands descendants a Budget whose amount
// already includes the carry — every internal calculation (remaining, per-day,
// timelines, limits) then uses the adjusted amount automatically.

bool budgetHasRollover(String budgetPk) {
  final dynamic map = appStateSettings["budgetRollover"] ?? {};
  return map[budgetPk] == true;
}

Future<void> setBudgetRollover(String budgetPk, bool enabled) async {
  final Map<String, dynamic> map =
      Map<String, dynamic>.from(appStateSettings["budgetRollover"] ?? {});
  if (enabled) {
    map[budgetPk] = true;
  } else {
    map.remove(budgetPk);
  }
  await updateSettings("budgetRollover", map,
      pagesNeedingRefresh: [0, 2], updateGlobalState: true);
}

// Carry from the previous period, expressed in the budget's own currency.
// Positive = leftover, negative = overspend. 0 when there is no previous
// period or rollover does not apply.
Future<double> getRolloverCarryInBudgetCurrency(
    AllWallets allWallets, Budget budget) async {
  if (budget.reoccurrence == null ||
      budget.reoccurrence == BudgetReoccurence.custom) {
    return 0;
  }
  if (budget.amount == 0) return 0;

  final DateTimeRange currentRange = getBudgetDate(budget, DateTime.now());
  final DateTime previousAnchor =
      currentRange.start.subtract(Duration(days: 1));
  // No previous period before the budget was started
  if (previousAnchor.isBefore(budget.startDate)) return 0;
  final DateTimeRange previousRange = getBudgetDate(budget, previousAnchor);

  final List<CategoryWithTotal> totals = await database
      .watchTotalSpentInEachCategoryInTimeRangeFromCategories(
        allWallets: allWallets,
        start: previousRange.start,
        end: previousRange.end,
        categoryFks: budget.categoryFks,
        categoryFksExclude: budget.categoryFksExclude,
        budgetTransactionFilters: budget.budgetTransactionFilters,
        memberTransactionFilters: budget.memberTransactionFilters,
        onlyShowTransactionsBelongingToBudgetPk:
            budget.sharedKey != null || budget.addedTransactionsOnly == true
                ? budget.budgetPk
                : null,
        budget: budget,
      )
      .first;
  double previousSpentPrimary = 0;
  for (final CategoryWithTotal categoryWithTotal in totals) {
    previousSpentPrimary += categoryWithTotal.total;
  }
  previousSpentPrimary =
      previousSpentPrimary * determineBudgetPolarity(budget);

  final double budgetAmountPrimary =
      budgetAmountToPrimaryCurrency(allWallets, budget);
  final double carryPrimary = budgetAmountPrimary - previousSpentPrimary;

  // Convert the carry from primary currency back into the budget's currency
  // using the same rate budgetAmountToPrimaryCurrency applied
  final double rate = budgetAmountPrimary / budget.amount;
  if (rate == 0) return 0;
  return carryPrimary / rate;
}

// Provides descendants with a Budget whose amount includes the previous
// period's carry (floored at zero) when rollover is enabled for it.
class RolloverAdjustedBudget extends StatelessWidget {
  const RolloverAdjustedBudget({
    required this.budget,
    required this.builder,
    super.key,
  });

  final Budget budget;
  final Widget Function(Budget budget) builder;

  @override
  Widget build(BuildContext context) {
    if (budgetHasRollover(budget.budgetPk) == false) {
      return builder(budget);
    }
    return FutureBuilder<double>(
      future: getRolloverCarryInBudgetCurrency(
          Provider.of<AllWallets>(context, listen: false), budget),
      initialData: 0,
      builder: (context, snapshot) {
        final double carry = snapshot.data ?? 0;
        if (carry == 0) return builder(budget);
        return builder(
          budget.copyWith(amount: max(0, budget.amount + carry)),
        );
      },
    );
  }
}
