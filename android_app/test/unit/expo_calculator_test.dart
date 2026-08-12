import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/core/utils/expo_calculator.dart';

void main() {
  group('ExpoCalculator', () {
    test('zero expo returns linear (identity)', () {
      expect(ExpoCalculator.apply(0.5, 0.0), closeTo(0.5, 0.0001));
      expect(ExpoCalculator.apply(-0.5, 0.0), closeTo(-0.5, 0.0001));
      expect(ExpoCalculator.apply(1.0, 0.0), closeTo(1.0, 0.0001));
      expect(ExpoCalculator.apply(-1.0, 0.0), closeTo(-1.0, 0.0001));
    });

    test('center input always returns 0.0 for any expo', () {
      expect(ExpoCalculator.apply(0.0, 0.0), 0.0);
      expect(ExpoCalculator.apply(0.0, 0.5), 0.0);
      expect(ExpoCalculator.apply(0.0, 1.0), 0.0);
    });

    test('full deflection always returns ±1.0 for any expo', () {
      expect(ExpoCalculator.apply(1.0, 0.5), closeTo(1.0, 0.0001));
      expect(ExpoCalculator.apply(-1.0, 0.5), closeTo(-1.0, 0.0001));
      expect(ExpoCalculator.apply(1.0, 1.0), closeTo(1.0, 0.0001));
      expect(ExpoCalculator.apply(-1.0, 1.0), closeTo(-1.0, 0.0001));
    });

    test('expo softens center response (smaller output for same input)', () {
      final linear = ExpoCalculator.apply(0.3, 0.0);
      final expoApplied = ExpoCalculator.apply(0.3, 0.5);
      expect(expoApplied, lessThan(linear));
    });

    test('output is always in [-1.0, +1.0]', () {
      for (final input in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
        for (final expo in [0.0, 0.3, 0.7, 1.0]) {
          final out = ExpoCalculator.apply(input, expo);
          expect(out, greaterThanOrEqualTo(-1.0));
          expect(out, lessThanOrEqualTo(1.0));
        }
      }
    });

    test('output clamps inputs outside [-1, 1]', () {
      expect(ExpoCalculator.apply(1.5, 0.3), closeTo(1.0, 0.0001));
      expect(ExpoCalculator.apply(-2.0, 0.3), closeTo(-1.0, 0.0001));
    });

    test('centerSensitivity returns 1 - expo', () {
      expect(ExpoCalculator.centerSensitivity(0.0), 1.0);
      expect(ExpoCalculator.centerSensitivity(0.3), closeTo(0.7, 0.0001));
      expect(ExpoCalculator.centerSensitivity(1.0), 0.0);
    });

    test('applyAll processes list with per-channel expo', () {
      final inputs = [0.5, -0.5, 1.0];
      final expos = [0.0, 0.5, 1.0];
      final result = ExpoCalculator.applyAll(inputs, expos);
      expect(result.length, 3);
      expect(result[0], closeTo(0.5, 0.0001)); // linear
      expect(result[2], closeTo(1.0, 0.0001)); // full deflection = 1.0
    });
  });
}
