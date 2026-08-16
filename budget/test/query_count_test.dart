import 'package:budget/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts every statement drift sends to the database, so a test can assert on
/// the *shape* of the query load rather than on wall-clock time (which is far
/// too flaky to gate CI on).
class _CountingInterceptor extends QueryInterceptor {
  final List<String> statements = [];

  void _record(String statement) => statements.add(statement);

  /// Statements that read from the `categories` table.
  int get categorySelects => statements
      .where((s) =>
          s.toLowerCase().contains('from "categories"') ||
          s.toLowerCase().contains('from categories'))
      .length;

  void reset() => statements.clear();

  @override
  Future<void> runCustom(
      QueryExecutor executor, String statement, List<Object?> args) {
    _record(statement);
    return super.runCustom(executor, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    _record(statement);
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
      QueryExecutor executor, String statement, List<Object?> args) {
    _record(statement);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runInsert(
      QueryExecutor executor, String statement, List<Object?> args) {
    _record(statement);
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runDelete(
      QueryExecutor executor, String statement, List<Object?> args) {
    _record(statement);
    return super.runDelete(executor, statement, args);
  }
}

/// Seeds [count] categories, each with a budget limit attached to [budgetPk].
Future<void> _seedLimits(
  FinanceDatabase db,
  String budgetPk,
  int count,
) async {
  for (int i = 0; i < count; i++) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          categoryPk: Value('cat_$i'),
          name: 'Category $i',
          dateCreated: Value(DateTime.now()),
          order: i,
          colour: Value(''),
          iconName: Value(''),
        ));
    await db.into(db.categoryBudgetLimits).insert(
          CategoryBudgetLimitsCompanion.insert(
            categoryLimitPk: Value('limit_$i'),
            categoryFk: 'cat_$i',
            budgetFk: budgetPk,
            amount: 10,
            dateTimeModified: Value(DateTime.now()),
          ),
        );
  }
}

void main() {
  // Several tests intentionally open more than one in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late _CountingInterceptor interceptor;
  late FinanceDatabase db;

  setUp(() async {
    interceptor = _CountingInterceptor();
    db = FinanceDatabase(
      NativeDatabase.memory().interceptWith(interceptor),
    );

    // categoryBudgetLimits.walletFk defaults to "0", so seed that wallet.
    await db.into(db.wallets).insert(WalletsCompanion.insert(
          walletPk: Value('0'),
          name: 'Wallet',
          dateCreated: Value(DateTime.now()),
          order: 0,
          colour: Value(''),
          currency: Value('usd'),
        ));
  });

  tearDown(() async => db.close());

  test(
      'toggleAbsolutePercentSpendingCategoryBudgetLimits reads categories in a '
      'bounded number of queries, not one per limit', () async {
    await db.into(db.budgets).insert(BudgetsCompanion.insert(
          budgetPk: Value('budget_1'),
          name: 'Budget',
          dateCreated: Value(DateTime.now()),
          order: 0,
          colour: Value(''),
          amount: 100,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          periodLength: 1,
        ));

    await _seedLimits(db, 'budget_1', 25);

    final allWallets = AllWallets(list: [], indexedByPk: {});

    interceptor.reset();
    await db.toggleAbsolutePercentSpendingCategoryBudgetLimits(
      allWallets,
      'budget_1',
      100,
      true,
    );

    // The optimised implementation fetches every needed category with a single
    // `categoryPk IN (...)` select. The N+1 version it replaced issued one
    // `getCategoryInstance` select per limit, so reverting that change makes
    // this assertion fail with ~25 selects instead of 1.
    expect(
      interceptor.categorySelects,
      lessThanOrEqualTo(2),
      reason: 'expected a bounded number of category selects for 25 limits, '
          'got ${interceptor.categorySelects} — the N+1 fix in '
          'toggleAbsolutePercentSpendingCategoryBudgetLimits has regressed',
    );
  });

  test('category query count does not grow with the number of limits',
      () async {
    Future<int> selectsFor(int limitCount) async {
      final localInterceptor = _CountingInterceptor();
      final localDb = FinanceDatabase(
        NativeDatabase.memory().interceptWith(localInterceptor),
      );
      await localDb.into(localDb.budgets).insert(BudgetsCompanion.insert(
            budgetPk: Value('budget_1'),
            name: 'Budget',
            dateCreated: Value(DateTime.now()),
            order: 0,
            colour: Value(''),
            amount: 100,
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            periodLength: 1,
          ));
      await _seedLimits(localDb, 'budget_1', limitCount);

      localInterceptor.reset();
      await localDb.toggleAbsolutePercentSpendingCategoryBudgetLimits(
        AllWallets(list: [], indexedByPk: {}),
        'budget_1',
        100,
        true,
      );
      final result = localInterceptor.categorySelects;
      await localDb.close();
      return result;
    }

    final few = await selectsFor(5);
    final many = await selectsFor(40);

    // This is the property that actually matters: query count is independent of
    // row count. An N+1 regression breaks it even if the absolute number above
    // were retuned.
    expect(
      many,
      equals(few),
      reason: 'category selects grew from $few (5 limits) to $many (40 limits) '
          '— the query count scales with the data, which is the N+1 signature',
    );
  });
}
