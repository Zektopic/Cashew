import 'package:budget/database/tables.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'dart:math';

void main() async {
  test('benchmark fixWanderingCategoryLimitsInBudget', () async {
    final db = FinanceDatabase(NativeDatabase.memory());

    // Set up app state
    appStateSettings["selectedWalletPk"] = "testWallet";

    // Setup initial data
    final wallets = AllWallets(
      indexedByPk: {'testWallet': TransactionWallet(walletPk: 'testWallet', name: 'Test', dateCreated: DateTime.now(), dateTimeModified: DateTime.now(), order: 0, decimals: 2)},
      list: [],
    );

    int count = 1000;
    List<CategoryBudgetLimit> limits = [];
    for (int i = 0; i < count; i++) {
      limits.add(CategoryBudgetLimit(
        categoryLimitPk: "limit_$i",
        categoryFk: "cat_$i",
        budgetFk: "budget_$i",
        amount: 100,
        dateTimeModified: DateTime.now(),
        walletFk: "unknownWallet",
      ));
    }

    await db.batch((batch) {
        batch.insertAll(db.categoryBudgetLimits, limits);
    });

    final start = DateTime.now();
    await db.fixWanderingCategoryLimitsInBudget(allWallets: wallets);
    final end = DateTime.now();

    print('Execution time for $count limits: ${end.difference(start).inMilliseconds} ms');

    // Verify
    final updatedLimits = await db.select(db.categoryBudgetLimits).get();
    for (var limit in updatedLimits) {
      if (limit.walletFk != "testWallet") {
         print("Validation failed: ${limit.walletFk}");
      }
    }

    await db.close();
  });
}
