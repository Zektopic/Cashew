import 'package:flutter_test/flutter_test.dart';
import 'package:budget/widgets/selectAmount.dart';

void main() {
  group('countNonTrailingZeroes', () {
    test('integer values (no decimal)', () {
      expect(countNonTrailingZeroes('123'), 0);
      expect(countNonTrailingZeroes('0'), 0);
    });

    test('no non-trailing zeroes after decimal', () {
      expect(countNonTrailingZeroes('1.0'), 0);
      expect(countNonTrailingZeroes('1.00'), 0);
      expect(countNonTrailingZeroes('0.0'), 0);
    });

    test('simple cases with zeroes and non-zeroes', () {
      expect(countNonTrailingZeroes('1.23'), 2);
    });

    test('leading zeroes', () {
      expect(countNonTrailingZeroes('0.5'), 1);
    });

    test('zeroes in the middle of decimal part', () {
      // Current behavior logic is somewhat weird.
      // input = "1.05", decimalIndex = 1
      // loop i = 2: '0', count = 0
      // loop i = 3: '5', count++ = 1
      // Returns 1
      expect(countNonTrailingZeroes('1.05'), 1);

      // input = "1.005"
      // loop i = 2: '0', count = 0
      // loop i = 3: '0', count = 0
      // loop i = 4: '5', count++ = 1
      // Returns 1
      expect(countNonTrailingZeroes('1.005'), 1);

      // input = "1.505"
      // loop i = 2: '5', count++ = 1
      // loop i = 3: '0', count > 0 -> break
      // Returns 1
      expect(countNonTrailingZeroes('1.505'), 1);
    });

    test('non-trailing zeroes', () {
      // input = "1.500"
      // loop i = 2: '5', count++ = 1
      // loop i = 3: '0', count > 0 -> break
      // Returns 1
      expect(countNonTrailingZeroes('1.500'), 1);
    });

    test('trailing zeroes after non-zeroes', () {
      // input = "1.050"
      // loop i = 2: '0', count = 0
      // loop i = 3: '5', count++ = 1
      // loop i = 4: '0', count > 0 -> break
      // Returns 1
      expect(countNonTrailingZeroes('1.050'), 1);

      // input = "1.0500"
      // Returns 1
      expect(countNonTrailingZeroes('1.0500'), 1);
    });

    test('empty string and only decimal', () {
      expect(countNonTrailingZeroes(''), 0);
      expect(countNonTrailingZeroes('.'), 0);
    });

    test('number ending in decimal', () {
      expect(countNonTrailingZeroes('1.'), 0);
    });
  });
}
