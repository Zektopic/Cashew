import 'dart:core';

class MockBudget {
  final String? sharedKey;
  MockBudget(this.sharedKey);
}

class MockDocumentSnapshot {
  final String id;
  MockDocumentSnapshot(this.id);
}

void baseline(List<MockBudget> budgets, List<MockDocumentSnapshot> budgetSnapshot) {
  for (MockBudget budget in budgets) {
    if (budget.sharedKey != null) {
      bool found = false;
      for (MockDocumentSnapshot budgetCloud in budgetSnapshot) {
        if (budgetCloud.id == budget.sharedKey) {
          found = true;
          break;
        }
      }
      if (found == false) {
        // Not found
      }
    }
  }
  for (MockDocumentSnapshot budgetCloud in budgetSnapshot) {
    bool found = false;
    for (MockBudget budget in budgets) {
      if (budget.sharedKey != null && budgetCloud.id == budget.sharedKey) {
        found = true;
        break;
      }
    }
    if (found == false) {
      // Not found
    }
  }
}

void optimized(List<MockBudget> budgets, List<MockDocumentSnapshot> budgetSnapshot) {
  Set<String> cloudBudgetIds = budgetSnapshot.map((e) => e.id).toSet();
  Set<String> localSharedKeys = budgets.map((e) => e.sharedKey).whereType<String>().toSet();

  for (MockBudget budget in budgets) {
    if (budget.sharedKey != null) {
      if (!cloudBudgetIds.contains(budget.sharedKey)) {
        // Not found
      }
    }
  }
  for (MockDocumentSnapshot budgetCloud in budgetSnapshot) {
    if (!localSharedKeys.contains(budgetCloud.id)) {
      // Not found
    }
  }
}

void main() {
  List<MockBudget> budgets = List.generate(5000, (i) => MockBudget('budget_$i'));
  List<MockDocumentSnapshot> budgetSnapshot = List.generate(5000, (i) => MockDocumentSnapshot('budget_$i'));

  // Warmup
  for (int i = 0; i < 10; i++) {
    baseline(budgets, budgetSnapshot);
    optimized(budgets, budgetSnapshot);
  }

  print('Testing baseline (nested loops)...');
  Stopwatch sw = Stopwatch()..start();
  for (int i = 0; i < 100; i++) {
    baseline(budgets, budgetSnapshot);
  }
  sw.stop();
  print('Baseline time: ${sw.elapsedMilliseconds}ms');

  print('Testing optimized (Set lookup)...');
  sw.reset();
  sw.start();
  for (int i = 0; i < 100; i++) {
    optimized(budgets, budgetSnapshot);
  }
  sw.stop();
  print('Optimized time: ${sw.elapsedMilliseconds}ms');
}
