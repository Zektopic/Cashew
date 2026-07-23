import 'package:budget/database/tables.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  test('N+1 Query vs Cached Query Performance', () async {
    final db = FinanceDatabase(NativeDatabase.memory());

    // Insert a couple of budgets
    for (int i = 0; i < 3; i++) {
      await db.into(db.budgets).insert(BudgetsCompanion.insert(
        budgetPk: Value('budget_$i'),
        name: 'Budget $i',
        dateCreated: Value(DateTime.now()),
        order: i,
        colour: Value(''),
        amount: 100,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        periodLength: 1,
      ));
    }

    // Insert lots of transactions sharing the same budgets
    for (int i = 0; i < 500; i++) {
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        transactionPk: Value('tx_$i'),
        name: 'Tx $i',
        amount: 10,
        note: '',
        categoryFk: 'cat_1',
        walletFk: Value('wallet_1'),
        dateCreated: Value(DateTime.now()),
        income: Value(false),
        paid: Value(true),
        skipPaid: Value(false),
        sharedReferenceBudgetPk: Value('budget_${i % 3}'),
      ));
    }

    final transactions = await (db.select(db.transactions)..where((t) => t.categoryFk.equals('cat_1'))).get();

    // Baseline (Current Code behavior)
    final stopwatchSeq = Stopwatch()..start();
    int countSeq = 0;
    for (var tx in transactions) {
      if (tx.sharedReferenceBudgetPk != null) {
        var budget = await db.getBudgetInstance(tx.sharedReferenceBudgetPk!);
        countSeq++;
      }
    }
    stopwatchSeq.stop();
    print('Baseline (N+1 Queries) Time for ${transactions.length} txs: ${stopwatchSeq.elapsedMilliseconds} ms');

    // Optimized (Cached Code behavior)
    final stopwatchOpt = Stopwatch()..start();
    Map<String, Budget> budgetCache = {};
    int countOpt = 0;
    for (var tx in transactions) {
      if (tx.sharedReferenceBudgetPk != null) {
        final budgetPk = tx.sharedReferenceBudgetPk!;
        if (!budgetCache.containsKey(budgetPk)) {
          budgetCache[budgetPk] = await db.getBudgetInstance(budgetPk);
        }
        var budget = budgetCache[budgetPk]!;
        countOpt++;
      }
    }
    stopwatchOpt.stop();
    print('Optimized (Cached Queries) Time for ${transactions.length} txs: ${stopwatchOpt.elapsedMilliseconds} ms');
  });
}
