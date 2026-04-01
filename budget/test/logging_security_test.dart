import 'package:test/test.dart';
import 'package:budget/struct/logging.dart';
import 'package:budget/struct/settings.dart';

void main() {
  group('LogService Security Tests', () {
    late LogService testLogService;

    setUp(() {
      testLogService = LogService();
      // Enable logging for testing
      appStateSettings["logging"] = true;
    });

    test('Log injection through newlines is prevented', () {
      final maliciousInput = 'Normal log message\n[2024-01-01 00:00:00.000] : Fake log entry';
      testLogService.log(maliciousInput);

      final logs = testLogService.getLogs();
      expect(logs.length, equals(1));
      expect(logs[0], isNot(contains('\n')));
      // The message itself should have newlines sanitized
      expect(logs[0], contains('Normal log message'));
      expect(logs[0], contains('Fake log entry'));

      // Check that it's all on one "line" in the logs list
      expect(logs[0].split('\n').length, equals(1));
    });
  });
}
