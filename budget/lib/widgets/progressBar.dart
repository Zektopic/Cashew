import 'dart:async';
import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProgressBar extends StatefulWidget {
  final double currentPercent;
  final Color color;
  final double height;

  const ProgressBar({
    required this.currentPercent,
    required this.color,
    this.height = 10,
    Key? key,
  }) : super(key: key);

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  bool _isRevealed = false;
  Timer? _revealTimer;

  void _startRevealTimer() {
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isRevealed = false);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool obscureAmounts = appStateSettings["obscureAmounts"] == true;
    double effectivePercent =
        obscureAmounts && !_isRevealed ? 0 : widget.currentPercent;

    return Listener(
      onPointerDown: (event) {
        if (obscureAmounts) {
          HapticFeedback.selectionClick();
          setState(() => _isRevealed = true);
          _revealTimer?.cancel();
        }
      },
      onPointerUp: (event) {
        if (obscureAmounts) {
          _startRevealTimer();
        }
      },
      onPointerCancel: (event) {
        if (obscureAmounts) {
          _startRevealTimer();
        }
      },
      child: LayoutBuilder(
        builder: (_, boxConstraints) {
          double x = boxConstraints.maxWidth;
          double progressWidth = (effectivePercent / 100) * x;
          return Stack(
            children: [
              Container(
                width: x,
                height: widget.height,
                decoration: BoxDecoration(
                  color: getColor(context, "lightDarkAccentHeavy"),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadiusDirectional.circular(100),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 100),
                width: progressWidth,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadiusDirectional.circular(100),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
