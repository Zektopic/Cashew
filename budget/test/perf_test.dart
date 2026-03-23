import 'package:budget/database/tables.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:budget/struct/databaseGlobal.dart';

void main() {
  test('perf test for fixWanderingCategoryLimitsInBudget', () async {
    final db = FinanceDatabase(NativeDatabase.memory());
    database = db; // Initialize global database required by some logging functions

    // Create some wallets
    await db.into(db.wallets).insert(TransactionWallet(
      walletPk: 'w1', name: 'w1', colour: 'w1', decimals: 2, dateCreated: DateTime.now(), dateTimeModified: null, order: 0, currency: 'USD'
    ));

    // Create some categories
    await db.into(db.categories).insert(TransactionCategory(
      categoryPk: 'c1', name: 'c1', colour: 'c1', iconName: 'c1', dateCreated: DateTime.now(), dateTimeModified: null, order: 0, income: false
    ));

    // Create some budgets
    await db.into(db.budgets).insert(Budget(
      budgetPk: 'b1', name: 'b1', colour: 'b1', amount: 100, startDate: DateTime.now(), endDate: DateTime.now(), addedTransactionsOnly: false, dateCreated: DateTime.now(), dateTimeModified: null, order: 0, walletFk: 'w1',
      income: false, archived: false, pinned: false, sharedKey: '', sharedDateUpdated: DateTime.now(), sharedOwnerMember: null, periodLength: 1, isAbsoluteSpendingLimit: false, reoccurrence: BudgetReoccurence.monthly
    ));

    // Insert many wandering budget limits
    for (int i = 0; i < 5000; i++) {
      await db.into(db.categoryBudgetLimits).insert(CategoryBudgetLimit(
        categoryLimitPk: 'l$i',
        categoryFk: 'c1',
        budgetFk: 'b_missing', // no such budget
        amount: 100,
        walletFk: 'w1'
      ));
    }

    print('Starting delete operation (N+1 approach)...');
    final stopwatch = Stopwatch()..start();

    List<Budget> allBudgets = await db.select(db.budgets).get();
    List<String> budgetKeys = allBudgets.map((e) => e.budgetPk).toList();
    List<CategoryBudgetLimit> wanderingBudgetLimits =
        await (db.select(db.categoryBudgetLimits)
              ..where((t) => t.budgetFk.isNotIn(budgetKeys)))
            .get();
    for (CategoryBudgetLimit limit in wanderingBudgetLimits) {
      await db.deleteCategoryBudgetLimit(limit.categoryLimitPk);
    }

    stopwatch.stop();
    print('Delete took: ${stopwatch.elapsedMilliseconds}ms');

    // Setup for batch operation approach
    for (int i = 0; i < 5000; i++) {
      await db.into(db.categoryBudgetLimits).insert(CategoryBudgetLimit(
        categoryLimitPk: 'l$i',
        categoryFk: 'c1',
        budgetFk: 'b_missing', // no such budget
        amount: 100,
        walletFk: 'w1'
      ));
    }

    print('Starting delete operation (batch approach)...');
    final stopwatch2 = Stopwatch()..start();

    List<CategoryBudgetLimit> wanderingBudgetLimits2 =
        await (db.select(db.categoryBudgetLimits)
              ..where((t) => t.budgetFk.isNotIn(budgetKeys)))
            .get();

    List<String> pksToDelete = wanderingBudgetLimits2.map((e) => e.categoryLimitPk).toList();

    // Since sharedPreferences isn't initialized we skip logging in batch to test real db time
    // We mock batch deletion here:
    await (db.delete(db.categoryBudgetLimits)
          ..where((t) => t.categoryLimitPk.isIn(pksToDelete)))
        .go();

    stopwatch2.stop();
    print('Batch delete took: ${stopwatch2.elapsedMilliseconds}ms');

    await db.close();
  });
}
