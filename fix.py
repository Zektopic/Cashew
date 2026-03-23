with open("budget/lib/database/tables.dart", "r") as f:
    content = f.read()

content = content.replace("""<<<<<<< Updated upstream
      List<String> wanderingCategoryLimitsKeys =
          wanderingCategoryLimits.map((e) => e.categoryLimitPk).toList();
      await createDeleteLogs(
          DeleteLogType.CategoryBudgetLimit, wanderingCategoryLimitsKeys);
      await (delete(categoryBudgetLimits)
            ..where((t) => t.categoryLimitPk.isIn(wanderingCategoryLimitsKeys)))
=======
      List<String> pksToDelete = wanderingCategoryLimits
          .map((limit) => limit.categoryLimitPk)
          .toList();
      await createDeleteLogs(DeleteLogType.CategoryBudgetLimit, pksToDelete);
      await (delete(categoryBudgetLimits)
            ..where((t) => t.categoryLimitPk.isIn(pksToDelete)))
>>>>>>> Stashed changes""", """      List<String> wanderingCategoryLimitsKeys =
          wanderingCategoryLimits.map((e) => e.categoryLimitPk).toList();
      await createDeleteLogs(
          DeleteLogType.CategoryBudgetLimit, wanderingCategoryLimitsKeys);
      await (delete(categoryBudgetLimits)
            ..where((t) => t.categoryLimitPk.isIn(wanderingCategoryLimitsKeys)))""")


content = content.replace("""<<<<<<< Updated upstream
      List<String> wanderingBudgetLimitsKeys =
          wanderingBudgetLimits.map((e) => e.categoryLimitPk).toList();
      await createDeleteLogs(
          DeleteLogType.CategoryBudgetLimit, wanderingBudgetLimitsKeys);
      await (delete(categoryBudgetLimits)
            ..where((t) => t.categoryLimitPk.isIn(wanderingBudgetLimitsKeys)))
=======
      List<String> pksToDelete =
          wanderingBudgetLimits.map((limit) => limit.categoryLimitPk).toList();
      await createDeleteLogs(DeleteLogType.CategoryBudgetLimit, pksToDelete);
      await (delete(categoryBudgetLimits)
            ..where((t) => t.categoryLimitPk.isIn(pksToDelete)))
>>>>>>> Stashed changes""", """      List<String> wanderingBudgetLimitsKeys =
          wanderingBudgetLimits.map((e) => e.categoryLimitPk).toList();
      await createDeleteLogs(
          DeleteLogType.CategoryBudgetLimit, wanderingBudgetLimitsKeys);
      await (delete(categoryBudgetLimits)
            ..where((t) => t.categoryLimitPk.isIn(wanderingBudgetLimitsKeys)))""")

content = content.replace("""<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes""", "")

with open("budget/lib/database/tables.dart", "w") as f:
    f.write(content)
