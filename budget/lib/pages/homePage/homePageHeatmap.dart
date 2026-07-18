import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/homePage/homePageLineGraph.dart';
import 'package:budget/pages/settingsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/lineGraph.dart';
import 'package:budget/widgets/linearGradientFadedEdges.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/transactionEntry/incomeAmountArrow.dart';
import 'package:budget/widgets/util/keepAliveClientMixin.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntries.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/holdToRevealListener.dart';

class HomePageHeatMap extends StatefulWidget {
  const HomePageHeatMap({super.key});

  @override
  State<HomePageHeatMap> createState() => _HomePageHeatMapState();
}

class _HomePageHeatMapState extends State<HomePageHeatMap> {
  int monthsToLoad = 5;
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      if (getIsFullScreen(context)) {
        setState(() {
          monthsToLoad = 10;
        });
      }
    });
    super.initState();
  }

  void loadMoreMonths(int amountToLoad) {
    setState(() {
      monthsToLoad = monthsToLoad + amountToLoad;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeepAliveClientMixin(
      child: StreamBuilder<List<Transaction>>(
        stream: database.getTransactionsInTimeRangeFromCategories(
          DateTime.now().justDay(monthOffset: -monthsToLoad),
          DateTime.now().justDay(),
          null,
          null,
          true,
          null,
          null,
          null,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            CalculatePointsParams p = CalculatePointsParams(
              transactions: snapshot.data ?? [],
              customStartDate:
                  DateTime.now().justDay(monthOffset: -monthsToLoad),
              customEndDate: DateTime.now(),
              totalSpentBefore: 0,
              isIncome: null,
              removeBalanceCorrection: true,
              allWallets: Provider.of<AllWallets>(context, listen: false),
              showCumulativeSpending: false,
              appStateSettingsPassed: appStateSettings,
              cycleThroughAllDays: true, // needed for heatmap
            );
            List<Pair> points = calculatePoints(p);
            return HeatMap(
              points: points,
              loadMoreMonths: loadMoreMonths,
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}

class HeatMap extends StatefulWidget {
  const HeatMap({
    required this.points,
    this.dayWidth = 18,
    this.dayPadding = 1.5,
    this.bottomTitleSpacing = 24,
    this.loadMoreMonths,
    super.key,
  });
  final List<Pair> points;
  final double dayWidth;
  final double dayPadding;
  final double bottomTitleSpacing;
  final Function(int monthsToLoad)? loadMoreMonths;

  @override
  State<HeatMap> createState() => _HeatMapState();
}

class _HeatMapState extends State<HeatMap> {

  double? getMaxY(List<Pair?> pairs, bool isIncome) {
    double? maxY;
    for (Pair? pair in pairs) {
      if (pair != null &&
          (isIncome && pair.y > 0 || isIncome == false && pair.y < 0)) {
        if (maxY == null || pair.y > maxY) {
          maxY = pair.y;
        }
      }
    }
    return maxY;
  }

  double? getMinY(List<Pair?> pairs, bool isIncome) {
    double? minY;
    for (Pair? pair in pairs) {
      if (pair != null &&
          (isIncome && pair.y > 0 || isIncome == false && pair.y < 0)) {
        if (minY == null || pair.y < minY) {
          minY = pair.y;
        }
      }
    }
    return minY;
  }

  @override
  Widget build(BuildContext context) {
    final int totalDaysBeforeFixed = widget.points.length;
    final int lastDateWeekday =
        widget.points[totalDaysBeforeFixed - 1].dateTime?.weekday ?? 0;
    int extraDaysOffset = 7 -
        lastDateWeekday -
        1 +
        // Follow the locale (1 is Monday, 0 if for Sunday)
        (appStateSettings["firstDayOfWeek"] == -1
            ? MaterialLocalizations.of(context).firstDayOfWeekIndex
            : (int.tryParse(appStateSettings["firstDayOfWeek"].toString()) ??
                MaterialLocalizations.of(context).firstDayOfWeekIndex));
    if (extraDaysOffset < 0) {
      extraDaysOffset = 7 - extraDaysOffset.abs();
    }
    final List<Pair?> pointsOffsetFixed = [
      ...widget.points,
      for (int i = 0; i < extraDaysOffset; i++) null,
    ];
    final double maxIncome = getMaxY(pointsOffsetFixed, true) ?? 0;
    final double minIncome = getMinY(pointsOffsetFixed, true) ?? 0;
    final double maxExpense = getMaxY(pointsOffsetFixed, false) ?? 0;
    final double minExpense = getMinY(pointsOffsetFixed, false) ?? 0;
    final int totalDays = pointsOffsetFixed.length;
    final int totalWeeks = (totalDays / 7).ceil();
    final Color backgroundColor =
        getColor(context, "lightDarkAccentHeavyLight");

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 13),
      child: HoldToRevealListener(
        builder: (context, isRevealed) => Container(
          height: 12 +
              7 * widget.dayWidth +
              7 * 2 * widget.dayPadding +
              widget.bottomTitleSpacing +
              15,
          margin: EdgeInsetsDirectional.symmetric(horizontal: 13),
          padding:
              EdgeInsetsDirectional.only(start: 0, end: 0, bottom: 12, top: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadiusDirectional.all(Radius.circular(15)),
            color: backgroundColor,
            boxShadow: boxShadowCheck(boxShadowGeneral(context)),
          ),
          child: LinearGradientFadedEdges(
            enableBottom: false,
            enableTop: false,
            gradientColor: backgroundColor,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollNotification) {
                if (widget.loadMoreMonths != null &&
                    scrollNotification.metrics.pixels >=
                        scrollNotification.metrics.maxScrollExtent) {
                  widget.loadMoreMonths!(1);
                }
                return false;
              },
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: totalWeeks + 1,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 13),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, itemIndex) {
                  if (itemIndex == totalWeeks)
                    return widget.loadMoreMonths == null
                        ? SizedBox.shrink()
                        : Tooltip(
                            message: "view-more".tr(),
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                  end: 8.0, bottom: widget.bottomTitleSpacing),
                              child: ButtonIcon(
                                padding: EdgeInsetsDirectional.zero,
                                size:
                                    widget.dayWidth * 2 + widget.dayPadding * 4,
                                icon: appStateSettings["outlinedIcons"]
                                    ? Icons.history_outlined
                                    : Icons.history_rounded,
                                onTap: () {
                                  widget.loadMoreMonths!(1);
                                },
                              ),
                            ),
                          );
                  return Container(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            for (int j = 7; j >= 1; j--)
                              Padding(
                                padding: EdgeInsetsDirectional.all(
                                    widget.dayPadding),
                                child: Builder(
                                  builder: (context) {
                                    int index = totalDays - (itemIndex * 7 + j);
                                    double? amount = nullIfIndexOutOfRange(
                                                pointsOffsetFixed, index) ==
                                            null
                                        ? null
                                        : nullIfIndexOutOfRange(
                                                pointsOffsetFixed, index)
                                            ?.y;
                                    DateTime? day = nullIfIndexOutOfRange(
                                                pointsOffsetFixed, index) ==
                                            null
                                        ? null
                                        : nullIfIndexOutOfRange(
                                                pointsOffsetFixed, index)
                                            ?.dateTime;
                                    Color color = getHeatMapColor(
                                      context: context,
                                      amount: amount,
                                      maxExpense: maxExpense,
                                      minExpense: minExpense,
                                      minIncome: minIncome,
                                      maxIncome: maxIncome,
                                    );
                                    return Tooltip(
                                      waitDuration: Duration(milliseconds: 200),
                                      message: day == null
                                          ? ""
                                          : getWordedDate(
                                                day,
                                                includeMonthDate: true,
                                                includeYearIfNotCurrentYear:
                                                    true,
                                              ) +
                                              (amount == null
                                                  ? ""
                                                  : "\n" +
                                                      convertToMoney(
                                                        Provider.of<AllWallets>(
                                                            context,
                                                            listen: false),
                                                        amount,
                                                        forceReveal:
                                                            isRevealed,
                                                      )),
                                      child: Tappable(
                                        onTap: () {
                                          if (amount != null)
                                            openTransactionsOnDayBottomSheet(
                                                context, day);
                                        },
                                        child: Container(
                                          height: widget.dayWidth,
                                          width: widget.dayWidth,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: amount == null
                                                  ? Theme.of(context)
                                                              .brightness ==
                                                          Brightness.light
                                                      ? color.withValues(alpha: 0.05)
                                                      : color.withValues(alpha: 0.2)
                                                  : color.withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadiusDirectional
                                                    .circular(5),
                                          ),
                                        ),
                                        borderRadius: 5,
                                        color: color,
                                      ),
                                    );
                                  },
                                ),
                              )
                          ],
                        ),
                        itemIndex % 4 == 4 - 1
                            ? Container(
                                width: widget.dayWidth,
                                padding: EdgeInsetsDirectional.only(start: 3),
                                child: OverflowBox(
                                  maxWidth: widget.dayWidth * 4 +
                                      widget.dayPadding * 4 * 2,
                                  alignment: Alignment.bottomLeft,
                                  child: HeatMapMonthLabel(
                                    label: getWordedDateShort(
                                      nullIfIndexOutOfRange(
                                                  pointsOffsetFixed,
                                                  totalDays -
                                                      (itemIndex * 7 + 1))
                                              ?.dateTime ??
                                          DateTime.now(),
                                      showTodayTomorrow: false,
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: widget.bottomTitleSpacing,
                              )
                      ],
                    ),
                  );
                  //return Container(child: Text(itemIndex.toString()));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color getHeatMapColor({
  required BuildContext context,
  required double? amount,
  required double maxExpense,
  required double minExpense,
  required double minIncome,
  required double maxIncome,
  Color? defaultColor,
  double minimumOpacityThreshold = 0.5,
  double subtractedOpacityThreshold = 0.5,
}) {
  if (amount == null) {
    return Colors.transparent;
  } else if (amount == 0) {
    return defaultColor ??
        (appStateSettings["materialYou"]
            ? Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.6)
            : getColor(context, "lightDarkAccent").withValues(alpha: 0.6));
  } else if (amount < 0) {
    return getColor(context, "expenseAmount").withValues(alpha: 
      (minimumOpacityThreshold +
          (((1 - subtractedOpacityThreshold) / 4) *
                  (getRangeIndex(maxExpense, minExpense, amount) + 1))
              .clamp(0, 1)),
    );
  } else {
    return getColor(context, "incomeAmount").withValues(alpha: 
      (minimumOpacityThreshold +
          (((1 - subtractedOpacityThreshold) / 4) *
                  (getRangeIndex(minIncome, maxIncome, amount) + 1))
              .clamp(0, 1)),
    );
  }
}

Future<dynamic> openTransactionsOnDayBottomSheet(
    BuildContext context, DateTime? day) {
  return openBottomSheet(
    context,
    PopupFramework(
      hasPadding: false,
      customSubtitleWidget: StreamBuilder<double?>(
        stream: database.watchTotalSpentInTimeRangeFromCategories(
          allWallets: Provider.of<AllWallets>(context, listen: false),
          start: day ?? DateTime.now(),
          end: day ?? DateTime.now(),
          categoryFks: null,
          categoryFksExclude: null,
          budgetTransactionFilters: null,
          memberTransactionFilters: null,
          allCashFlow: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Padding(
              padding: EdgeInsetsDirectional.only(
                  top: getPlatform() == PlatformOS.isIOS ? 4 : 1),
              child: AmountWithColorAndArrow(
                showIncomeArrow: true,
                totalSpent: snapshot.data ?? 0,
                fontSize: 19,
                iconSize: 24,
                iconWidth: 15,
                mainAxisAlignment: getPlatform() == PlatformOS.isIOS
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                countNumber: false,
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
      child: TransactionEntries(
        renderType: TransactionEntriesRenderType.nonSlivers,
        day,
        day,
        transactionBackgroundColor: getPopupBackgroundColor(context),
        dateDividerColor: Colors.transparent,
        includeDateDivider: false,
        allowSelect: false,
        useHorizontalPaddingConstrained: false,
        noResultsPadding:
            EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 10),
        limitPerDay: 50,
        enableFutureTransactionsCollapse: false,
      ),
      title: day == null
          ? ""
          : getWordedDate(
              day,
              includeMonthDate: true,
              includeYearIfNotCurrentYear: true,
            ),
    ),
  );
}

class HeatMapMonthLabel extends StatelessWidget {
  const HeatMapMonthLabel({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextFont(
        textAlign: TextAlign.center,
        fontSize: 13,
        text: label,
        textColor: dynamicPastel(context, Theme.of(context).colorScheme.primary,
                amount: 0.8, inverse: true)
            .withValues(alpha: 0.5),
      ),
    );
  }
}

int getRangeIndex(double minValue, double maxValue, double number) {
  number = number.abs();
  minValue = minValue.abs();
  maxValue = maxValue.abs();
  double rangeWidth = (maxValue - minValue) / 4;
  if (number >= minValue && number <= maxValue) {
    for (int i = 0; i < 4; i++) {
      double rangeStart = minValue + (i * rangeWidth);
      double rangeEnd = minValue + ((i + 1) * rangeWidth);

      if (number >= rangeStart && number <= rangeEnd) {
        return i;
      }
    }
  }
  return 4 - 1;
}

class HomePageHeatMapSettings extends StatelessWidget {
  const HomePageHeatMapSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "edit-heatmap".tr(),
      child: FirstDayOfWeekSetting(
        // We already update the homepage when we exit edit homepage settings
        updateHomePage: false,
      ),
    );
  }
}
