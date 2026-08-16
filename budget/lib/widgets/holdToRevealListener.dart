import 'dart:async';

import 'package:budget/struct/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Global "reveal all" state: when true, every HoldToRevealListener in the app
// reports isRevealed == true. Triggered by an authenticated action (see the
// eye icon on the home page) and automatically collapses after a timeout.
final ValueNotifier<bool> globalRevealAllNotifier = ValueNotifier<bool>(false);
Timer? _globalRevealTimer;

void revealAllAmountsTemporarily({
  Duration duration = const Duration(seconds: 60),
}) {
  _globalRevealTimer?.cancel();
  globalRevealAllNotifier.value = true;
  _globalRevealTimer = Timer(duration, () {
    globalRevealAllNotifier.value = false;
  });
}

void cancelRevealAllAmounts() {
  _globalRevealTimer?.cancel();
  globalRevealAllNotifier.value = false;
}

// Wraps [builder]'s subtree in a raw [Listener] implementing the
// hold-to-reveal gesture used by the privacy obfuscation feature:
// pressing down reveals obscured amounts (with haptic feedback) and
// releasing starts a timer that re-obscures them after [revealDuration].
// A raw [Listener] is used instead of a [GestureDetector] so the gesture
// coexists with taps, long-presses and scrolling in the subtree.
class HoldToRevealListener extends StatefulWidget {
  const HoldToRevealListener({
    Key? key,
    required this.builder,
    this.revealDuration = const Duration(seconds: 2),
  }) : super(key: key);

  final Widget Function(BuildContext context, bool isRevealed) builder;
  final Duration revealDuration;

  @override
  State<HoldToRevealListener> createState() => _HoldToRevealListenerState();
}

class _HoldToRevealListenerState extends State<HoldToRevealListener>
    with WidgetsBindingObserver {
  bool _isRevealed = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    globalRevealAllNotifier.addListener(_onGlobalRevealChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    globalRevealAllNotifier.removeListener(_onGlobalRevealChanged);
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Also collapse the app-wide "reveal all" state. Without this a global
      // reveal keeps amounts visible in the OS app switcher for the remainder
      // of its 60 second window, which is exactly what obscuring guards against.
      cancelRevealAllAmounts();
      if (_isRevealed) {
        _revealTimer?.cancel();
        setState(() {
          _isRevealed = false;
        });
      }
    }
  }

  void _onGlobalRevealChanged() {
    if (mounted) setState(() {});
  }

  void _startCollapseTimer() {
    _revealTimer?.cancel();
    _revealTimer = Timer(widget.revealDuration, () {
      if (mounted) setState(() => _isRevealed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (appStateSettings["obscureAmounts"] == true) {
          HapticFeedback.selectionClick();
          setState(() => _isRevealed = true);
          _revealTimer?.cancel();
        }
      },
      onPointerUp: (_) {
        if (appStateSettings["obscureAmounts"] == true) {
          _startCollapseTimer();
        }
      },
      onPointerCancel: (_) {
        if (appStateSettings["obscureAmounts"] == true) {
          _startCollapseTimer();
        }
      },
      child: widget.builder(
        context,
        _isRevealed || globalRevealAllNotifier.value,
      ),
    );
  }
}
