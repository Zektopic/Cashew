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
  Timer? _hideTimer;

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRevealed = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isObscured = appStateSettings["obscureAmounts"] == true && !_isRevealed;

    return LayoutBuilder(
      builder: (_, boxConstraints) {
        double x = boxConstraints.maxWidth;
        double progressWidth = isObscured ? 0 : (widget.currentPercent / 100) * x;
        return Listener(
          onPointerDown: (event) {
            _hideTimer?.cancel();
            setState(() {
              _isRevealed = true;
            });
            HapticFeedback.selectionClick();
          },
          onPointerUp: (event) => _startHideTimer(),
          onPointerCancel: (event) => _startHideTimer(),
          child: Stack(
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
          ),
        );
      },
    );
  }
}
