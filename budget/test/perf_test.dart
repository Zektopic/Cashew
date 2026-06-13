import 'package:budget/database/tables.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

void main() async {
  final db = FinanceDatabase(NativeDatabase.memory());

  // Insert some dummy data
  for (int i = 0; i < 100; i++) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
      categoryPk: Value(i.toString()),
      name: 'Cat $i',
      dateCreated: Value(DateTime.now()),
      order: i,
      colour: Value(''),
      iconName: Value(''),
    ));
    await db.into(db.budgets).insert(BudgetsCompanion.insert(
      budgetPk: Value(i.toString()),
      name: 'Budget $i',
      dateCreated: Value(DateTime.now()),
      order: i,
      colour: Value(''),
      amount: 100,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      periodLength: 1,
    ));
    await db.into(db.objectives).insert(ObjectivesCompanion.insert(
      objectivePk: Value(i.toString()),
      name: 'Obj $i',
      dateCreated: Value(DateTime.now()),
      order: i,
      colour: Value(''),
      amount: 100,
      iconName: Value(''),
      type: Value(i % 2 == 0 ? ObjectiveType.goal : ObjectiveType.loan),
    ));
  }

  // Method 1: Sequential (Current)
  final stopwatchSeq = Stopwatch()..start();
  for (int i = 0; i < 50; i++) {
    await db.getAllCategories(categoryFks: ['1', '2', '3'], allCategories: false);
    await db.getAllCategories(categoryFks: ['4', '5', '6'], allCategories: false, includeSubCategories: true);
    await db.getAllBudgets();
    await db.getAllBudgets(); // Repeated
    await db.getAllObjectives(objectiveType: ObjectiveType.goal);
    await db.getAllObjectives(objectiveType: ObjectiveType.loan);
  }
  stopwatchSeq.stop();
  print('Sequential time: ${stopwatchSeq.elapsedMilliseconds} ms');

  // Method 2: Concurrent + Reuse (Optimized)
  final stopwatchOpt = Stopwatch()..start();
  for (int i = 0; i < 50; i++) {
    final futures = await Future.wait([
      db.getAllCategories(categoryFks: ['1', '2', '3'], allCategories: false),
      db.getAllCategories(categoryFks: ['4', '5', '6'], allCategories: false, includeSubCategories: true),
      db.getAllBudgets(),
      db.getAllObjectives(objectiveType: ObjectiveType.goal),
      db.getAllObjectives(objectiveType: ObjectiveType.loan),
    ]);
    final categories = futures[0] as List<TransactionCategory>;
    final subcategories = futures[1] as List<TransactionCategory>;
    final budgets = futures[2] as List<Budget>;
    final goals = futures[3] as List<Objective>;
    final loans = futures[4] as List<Objective>;
  }
  stopwatchOpt.stop();
  print('Optimized time: ${stopwatchOpt.elapsedMilliseconds} ms');
}
