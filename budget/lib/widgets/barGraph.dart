import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:budget/widgets/holdToRevealListener.dart';

class BarGraph extends StatefulWidget {
  BarGraph({
    required this.budget,
    required this.color,
    required this.dateRanges,
    required this.bars,
    required this.initialBars,
    required this.horizontalLineAt,
    required this.maxY,
    Key? key,
  }) : super(key: key);

  final Color color;
  final List<DateTimeRange> dateRanges;
  final List<BarChartGroupData> bars;
  final List<BarChartGroupData> initialBars;
  final Budget budget;

  final double? horizontalLineAt;
  final double maxY;

  @override
  State<StatefulWidget> createState() => BarGraphState();
}

class BarGraphState extends State<BarGraph> {
  bool loaded = false;


  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HoldToRevealListener(
      builder: (context, isRevealed) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, end: 30, top: 5),
        child: Container(
          height: 190,
          child: BarChart(
            swapAnimationCurve: Curves.easeInOutCubicEmphasized,
            swapAnimationDuration: Duration(milliseconds: 1700),
            BarChartData(
              maxY: widget.maxY,
              minY: -1,
              alignment: BarChartAlignment.spaceBetween,
              barTouchData: BarTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => dynamicPastel(
                    context,
                    getColor(context, "white"),
                    inverse: true,
                    amountLight: 0.2,
                    amountDark: 0.05,
                  ).withValues(alpha: 0.8),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      convertToMoney(
                        Provider.of<AllWallets>(context, listen: false),
                        rod.toY == -1e-14 ? 0 : rod.toY,
                        forceReveal: isRevealed,
                      ),
                      TextStyle(
                        color: getColor(context, "black").withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamilyFallback: ['Inter'],
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                checkToShowHorizontalLine: (value) {
                  if (value == widget.horizontalLineAt) {
                    return true;
                  } else if (value == 0) {
                    return true;
                  } else if (value % ((widget.maxY / 3.8).ceil()) == 1) {
                    return true;
                  }
                  return false;
                },
                getDrawingHorizontalLine: (value) {
                  if (value == widget.horizontalLineAt) {
                    return FlLine(
                      dashArray: [2, 2],
                      strokeWidth: 2,
                      color: dynamicPastel(
                        context,
                        widget.color,
                        amount: 0.3,
                      ).withValues(alpha: 0.7),
                    );
                  } else if (value == 0) {
                    return FlLine(
                      color: dynamicPastel(
                        context,
                        widget.color,
                        amount: 0.3,
                      ).withValues(alpha: 0.2),
                      strokeWidth: 2,
                    );
                  } else if (value % ((widget.maxY / 3.8).ceil()) == 1) {
                    return FlLine(
                      color: dynamicPastel(
                        context,
                        widget.color,
                        amount: 0.3,
                      ).withValues(alpha: 0.2),
                      strokeWidth: 2,
                      dashArray: [2, 8],
                    );
                  }
                  return FlLine(color: Colors.transparent, strokeWidth: 0);
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: dynamicPastel(
                      context,
                      widget.color,
                      amount: 0.3,
                    ).withValues(alpha: 0.2),
                    strokeWidth: 2,
                    dashArray: [2, 8],
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(top: 8.0),
                        child: TextFont(
                          textAlign: TextAlign.center,
                          fontSize: 13,
                          text: widget.budget.reoccurrence ==
                                  BudgetReoccurence.monthly
                              ? DateFormat(
                                  'MMM',
                                  context.locale.toString(),
                                ).format(widget.dateRanges[value.toInt()].start)
                              : widget.budget.reoccurrence ==
                                      BudgetReoccurence.yearly
                                  ? DateFormat(
                                      'yyyy',
                                      context.locale.toString(),
                                    ).format(
                                      widget.dateRanges[value.toInt()].start)
                                  : DateFormat(
                                      'MMM\nd',
                                      context.locale.toString(),
                                    ).format(
                                      widget.dateRanges[value.toInt()].start,
                                    ),
                          textColor: dynamicPastel(
                            context,
                            widget.color,
                            amount: 0.8,
                            inverse: true,
                          ).withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, titleMeta) {
                      bool show =
                          value == 0 || (value < widget.maxY && value > 1);
                      if (!show) {
                        return SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: TextFont(
                          textAlign: TextAlign.end,
                          text: getWordedNumber(
                            context,
                            Provider.of<AllWallets>(context),
                            value,
                            forceReveal: isRevealed,
                          ),
                          textColor: dynamicPastel(
                            context,
                            widget.color,
                            amount: 0.5,
                            inverse: true,
                          ).withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                      );
                    },
                    reservedSize: 48,
                    interval: (widget.maxY / 3.8),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: loaded ? widget.bars : widget.initialBars,
            ),
          ),
        ),
      ),
    );
  }
}

BarChartGroupData makeGroupData(int x, double y1, double y2, color) {
  return BarChartGroupData(
    barsSpace: 0,
    x: x,
    barRods: [
      BarChartRodData(
        fromY: 0,
        toY: y1,
        gradient: LinearGradient(
          colors: [color.withAlpha(120), color],
          begin: AlignmentDirectional.bottomCenter,
          end: AlignmentDirectional.topCenter,
        ),
        width: 13,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      // BarChartRodData(
      //   y: y2,
      //   colors: [color.withAlpha(120), color],
      //   width: 10,
      // ),
    ],
  );
}
