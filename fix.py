with open('budget/lib/pages/pastBudgetsPage.dart', 'r') as f:
    content = f.read()

search = """        openPage: BudgetPage(
          budgetPk: widget.budget.budgetPk,
          dateForRange: dateForRangeLocal,
          dateForRangeIndex: widget.dateForRangeIndex,
          openedFromHistory: true,
        ),
    );
  }
}"""

replace = """        openPage: BudgetPage(
          budgetPk: widget.budget.budgetPk,
          dateForRange: dateForRangeLocal,
          dateForRangeIndex: widget.dateForRangeIndex,
          openedFromHistory: true,
        ),
      ),
    );
  }
}"""

content = content.replace(search, replace)

with open('budget/lib/pages/pastBudgetsPage.dart', 'w') as f:
    f.write(content)
