import 'dart:math';

import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Spending anomaly alerts: once per day (on app open, opt-in via the
// "spendingAnomalyAlerts" setting) month-to-date spending of each expense
// category is compared against the average spent over the same day-span of
// the previous three months. Categories at least [anomalyRatio]x their usual
// pace — and meaningful relative to this month's overall spending — trigger a
// local notification.
const double anomalyRatio = 1.5;
const double minShareOfMonthSpending = 0.05;
const int _notificationIdBase = 900;

class SpendingAnomaly {
  final TransactionCategory category;
  final double currentSpent;
  final double averageSpent;

  SpendingAnomaly({
    required this.category,
    required this.currentSpent,
    required this.averageSpent,
  });

  int get percentOverUsual =>
      (((currentSpent / averageSpent) - 1) * 100).round();
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

Future<Map<String, double>> _spentPerCategory(
    AllWallets allWallets, DateTime start, DateTime end) async {
  final List<CategoryWithTotal> totals = await database
      .watchTotalSpentInEachCategoryInTimeRangeFromCategories(
        allWallets: allWallets,
        start: start,
        end: end,
        categoryFks: null,
        categoryFksExclude: null,
        budgetTransactionFilters: null,
        memberTransactionFilters: null,
        isIncome: false,
      )
      .first;
  final Map<String, double> result = {};
  for (final CategoryWithTotal categoryWithTotal in totals) {
    result[categoryWithTotal.category.categoryPk] =
        (result[categoryWithTotal.category.categoryPk] ?? 0) +
            categoryWithTotal.total.abs();
  }
  return result;
}

Future<List<SpendingAnomaly>> findSpendingAnomalies(
    AllWallets allWallets, DateTime now) async {
  // Too early in the month to have a meaningful pace comparison
  if (now.day < 5) return [];

  final DateTime currentStart = DateTime(now.year, now.month, 1);
  final List<CategoryWithTotal> currentDetailed = await database
      .watchTotalSpentInEachCategoryInTimeRangeFromCategories(
        allWallets: allWallets,
        start: currentStart,
        end: now,
        categoryFks: null,
        categoryFksExclude: null,
        budgetTransactionFilters: null,
        memberTransactionFilters: null,
        isIncome: false,
      )
      .first;
  if (currentDetailed.isEmpty) return [];

  final double totalThisMonth = currentDetailed.fold(
      0.0, (sum, categoryWithTotal) => sum + categoryWithTotal.total.abs());
  if (totalThisMonth <= 0) return [];

  // Average of the same day-span over the previous 3 months
  final Map<String, double> historySum = {};
  const int historyMonths = 3;
  for (int monthsAgo = 1; monthsAgo <= historyMonths; monthsAgo++) {
    final DateTime monthStart = DateTime(now.year, now.month - monthsAgo, 1);
    final int spanEndDay =
        min(now.day, _daysInMonth(monthStart.year, monthStart.month));
    final DateTime monthEnd =
        DateTime(monthStart.year, monthStart.month, spanEndDay, 23, 59, 59);
    final Map<String, double> monthTotals =
        await _spentPerCategory(allWallets, monthStart, monthEnd);
    monthTotals.forEach((categoryPk, total) {
      historySum[categoryPk] = (historySum[categoryPk] ?? 0) + total;
    });
  }

  final List<SpendingAnomaly> anomalies = [];
  for (final CategoryWithTotal categoryWithTotal in currentDetailed) {
    final String categoryPk = categoryWithTotal.category.categoryPk;
    final double currentSpent = categoryWithTotal.total.abs();
    final double average = (historySum[categoryPk] ?? 0) / historyMonths;
    if (average <= 0) continue;
    if (currentSpent < average * anomalyRatio) continue;
    // Ignore categories too small to matter this month
    if (currentSpent < totalThisMonth * minShareOfMonthSpending) continue;
    anomalies.add(SpendingAnomaly(
      category: categoryWithTotal.category,
      currentSpent: currentSpent,
      averageSpent: average,
    ));
  }
  anomalies
      .sort((a, b) => b.percentOverUsual.compareTo(a.percentOverUsual));
  return anomalies;
}

Future<void> runSpendingAnomalyCheckIfEnabled(AllWallets allWallets) async {
  if (kIsWeb) return;
  if (appStateSettings["spendingAnomalyAlerts"] != true) return;

  // Only check once per day
  final String today = DateTime.now().toString().substring(0, 10);
  if (appStateSettings["spendingAnomalyLastCheck"] == today) return;
  await updateSettings("spendingAnomalyLastCheck", today,
      updateGlobalState: false);

  try {
    final List<SpendingAnomaly> anomalies =
        await findSpendingAnomalies(allWallets, DateTime.now());
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'spendingAnomalies',
      'Spending Alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const DarwinNotificationDetails darwinDetails =
        DarwinNotificationDetails(threadIdentifier: 'spendingAnomalies');
    const NotificationDetails details = NotificationDetails(
        android: androidDetails, iOS: darwinDetails);
    // Cap at 3 notifications to avoid spamming
    for (int i = 0; i < anomalies.length && i < 3; i++) {
      final SpendingAnomaly anomaly = anomalies[i];
      await flutterLocalNotificationsPlugin.show(
        _notificationIdBase + i,
        "Spending Alert",
        anomaly.category.name +
            " is " +
            anomaly.percentOverUsual.toString() +
            "% above its usual pace this month",
        details,
      );
    }
  } catch (e) {
    print("Error checking spending anomalies: " + e.toString());
  }
}
