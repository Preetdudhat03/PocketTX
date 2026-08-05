import 'package:flutter_test/flutter_test.dart';
import 'package:pockettx_app/core/utils/deadband_calculator.dart';

void main() {
  group('DeadbandCalculator', () {
    test('zero deadband returns input unchanged', () {
      expect(DeadbandCalculator.apply(0.5, 0.0), closeTo(0.5, 0.0001));
      expect(DeadbandCalculator.apply(-0.5, 0.0), closeTo(-0.5, 0.0001));
    });

    test('inputs within deadband return 0.0', () {
      expect(DeadbandCalculator.apply(0.01, 0.02), 0.0);
      expect(DeadbandCalculator.apply(-0.01, 0.02), 0.0);
      expect(DeadbandCalculator.apply(0.0, 0.02), 0.0);
      expect(DeadbandCalculator.apply(0.02, 0.02), 0.0);
      expect(DeadbandCalculator.apply(-0.02, 0.02), 0.0);
    });

    test('full deflection always returns ±1.0', () {
      expect(DeadbandCalculator.apply(1.0, 0.02), closeTo(1.0, 0.001));
      expect(DeadbandCalculator.apply(-1.0, 0.02), closeTo(-1.0, 0.001));
    });

    test('output rescales remaining range to [0, 1]', () {
      // Just outside deadband should be small positive
      final justOutside = DeadbandCalculator.apply(0.03, 0.02);
      expect(justOutside, greaterThan(0.0));
      expect(justOutside, lessThan(0.1));
    });

    test('output is always in [-1.0, +1.0]', () {
      for (final input in [-1.0, -0.5, -0.01, 0.0, 0.01, 0.5, 1.0]) {
        final out = DeadbandCalculator.apply(input, 0.05);
        expect(out, greaterThanOrEqualTo(-1.0));
        expect(out, lessThanOrEqualTo(1.0));
      }
    });

    test('sign is preserved', () {
      expect(DeadbandCalculator.apply(0.5, 0.02), greaterThan(0));
      expect(DeadbandCalculator.apply(-0.5, 0.02), lessThan(0));
    });

    test('isInDeadband detects correctly', () {
      expect(DeadbandCalculator.isInDeadband(0.01, 0.02), isTrue);
      expect(DeadbandCalculator.isInDeadband(0.05, 0.02), isFalse);
    });

    test('applyAll processes per-channel deadbands', () {
      final result = DeadbandCalculator.applyAll([0.01, 0.5], [0.02, 0.02]);
      expect(result[0], 0.0); // in deadband
      expect(result[1], greaterThan(0.0)); // outside deadband
    });
  });
}
