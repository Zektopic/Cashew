import 'dart:async';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/countNumber.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

import 'incomeAmountArrow.dart';

class TransactionEntryAmount extends StatefulWidget {
  const TransactionEntryAmount({
    required this.transaction,
    required this.showOtherCurrency,
    required this.unsetCustomCurrency,
    super.key,
  });
  final Transaction transaction;
  final bool showOtherCurrency;
  final bool unsetCustomCurrency;

  @override
  State<TransactionEntryAmount> createState() => _TransactionEntryAmountState();
}

class _TransactionEntryAmountState extends State<TransactionEntryAmount> {
  bool _isRevealed = false;
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double count = widget.transaction.amount.abs() *
        (amountRatioToPrimaryCurrencyGivenPk(
            Provider.of<AllWallets>(context), widget.transaction.walletFk));
    return Listener(
      onPointerDown: (_) {
        setState(() => _isRevealed = true);
        _revealTimer?.cancel();
        _revealTimer = Timer(Duration(seconds: 2), () {
          if (mounted) setState(() => _isRevealed = false);
        });
      },
      onPointerUp: (_) {
        _revealTimer?.cancel();
        setState(() => _isRevealed = false);
      },
      onPointerCancel: (_) {
        _revealTimer?.cancel();
        setState(() => _isRevealed = false);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CountNumber(
                count: count,
                duration: Duration(milliseconds: 1000),
                initialCount: count,
                textBuilder: (number) {
                  return Row(
                    children: [
                      AnimatedSizeSwitcher(
                        child: ((widget.transaction.type ==
                                        TransactionSpecialType.credit ||
                                    widget.transaction.type ==
                                        TransactionSpecialType.debt) &&
                                widget.transaction.paid == false)
                            ? SizedBox.shrink()
                            : IncomeOutcomeArrow(
                                isIncome: widget.transaction.income,
                                color: getTransactionAmountColor(
                                  context,
                                  widget.transaction,
                                ),
                                width: 15,
                                iconSize: 24,
                              ),
                      ),
                      TextFont(
                        text: convertToMoney(
                          Provider.of<AllWallets>(context),
                          number,
                          finalNumber: count,
                          forceReveal: _isRevealed,
                        ),
                        fontSize: 19 - (widget.showOtherCurrency ? 1 : 0),
                        fontWeight: FontWeight.bold,
                        textColor: getTransactionAmountColor(
                            context, widget.transaction),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          // Original amount:
          AnimatedSizeSwitcher(
            child: widget.showOtherCurrency
                ? TextFont(
                    key: ValueKey(1),
                    text: convertToMoney(
                      Provider.of<AllWallets>(context),
                      widget.transaction.amount.abs(),
                      decimals: Provider.of<AllWallets>(context)
                              .indexedByPk[widget.transaction.walletFk]
                              ?.decimals ??
                          2,
                      currencyKey: Provider.of<AllWallets>(context)
                          .indexedByPk[widget.transaction.walletFk]
                          ?.currency,
                      addCurrencyName: true,
                      forceReveal: _isRevealed,
                    ),
                    fontSize: 12,
                    textColor:
                        getTransactionAmountColor(context, widget.transaction),
                  )
                : Container(
                    key: ValueKey(0),
                  ),
          ),
        ],
      ),
    );
  }
}

Color getTransactionAmountColor(BuildContext context, Transaction transaction) {
  Color color = transaction.objectiveLoanFk != null && transaction.paid
      ? transaction.income
          ? getColor(context, "unPaidOverdue")
          : getColor(context, "unPaidUpcoming")
      : (transaction.type == TransactionSpecialType.credit ||
                  transaction.type == TransactionSpecialType.debt) &&
              transaction.paid
          ? transaction.type == TransactionSpecialType.credit
              ? getColor(context, "unPaidUpcoming")
              : transaction.type == TransactionSpecialType.debt
                  ? getColor(context, "unPaidOverdue")
                  : getColor(context, "textLight")
          : (transaction.type == TransactionSpecialType.credit ||
                      transaction.type == TransactionSpecialType.debt) &&
                  transaction.paid == false
              ? getColor(context, "textLight")
              : transaction.paid
                  ? transaction.income == true
                      ? getColor(context, "incomeAmount")
                      : getColor(context, "expenseAmount")
                  : transaction.skipPaid
                      ? getColor(context, "textLight")
                      : transaction.dateCreated.millisecondsSinceEpoch <=
                              DateTime.now().millisecondsSinceEpoch
                          ? getColor(context, "textLight")
                          // getColor(context, "unPaidOverdue")
                          : getColor(context, "textLight");
  if (transaction.paid == true && transaction.categoryFk == "0") {
    if (appStateSettings["balanceTransferAmountColor"] == "no-color") {
      return getColor(context, "black").withOpacity(0.95);
    } else {
      return dynamicPastel(context, color,
          inverse: true, amountLight: 0.3, amountDark: 0.25);
    }
  }
  return color;
}
