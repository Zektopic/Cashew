import 'package:flutter_test/flutter_test.dart';
import 'package:budget/struct/throttler.dart';

void main() {
  group('Throttler', () {
    test('allows the first call immediately', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      expect(throttler.canProceed(), isTrue);
    });

    test('blocks subsequent calls within the duration', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));

      // First call allowed
      expect(throttler.canProceed(), isTrue);

      // Immediate second call blocked
      expect(throttler.canProceed(), isFalse);

      // Call after a short delay (still within duration) blocked
      await Future.delayed(const Duration(milliseconds: 50));
      expect(throttler.canProceed(), isFalse);
    });

    test('allows calls after the duration has passed', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));

      // First call allowed
      expect(throttler.canProceed(), isTrue);

      // Wait for duration to pass
      await Future.delayed(const Duration(milliseconds: 150));

      // Call after duration allowed
      expect(throttler.canProceed(), isTrue);
    });

    test('resets throttling state correctly after the duration', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));

      // First call allowed
      expect(throttler.canProceed(), isTrue);

      // Wait for duration to pass
      await Future.delayed(const Duration(milliseconds: 150));

      // Second call allowed
      expect(throttler.canProceed(), isTrue);

      // Immediate third call blocked (throttling should be active again)
      expect(throttler.canProceed(), isFalse);
    });
  });
}
