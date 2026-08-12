import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/services/communication/failsafe_engine.dart';

void main() {
  group('FailsafeEngine', () {
    test('resets channels to safe defaults when failsafe is triggered', () {
      final engine = FailsafeEngine();
      expect(engine.isFailsafeActive, isFalse);

      final safeState = engine.triggerFailsafe('Test signal loss');
      expect(engine.isFailsafeActive, isTrue);

      // Failsafe state: Throttle = -1.0 (1000us), Roll/Pitch/Yaw = 0.0 (1500us)
      expect(safeState.throttle, equals(-1.0));
      expect(safeState.throttlePwm, equals(1000));
      expect(safeState.roll, equals(0.0));
      expect(safeState.rollPwm, equals(1500));
    });

    test('clears failsafe state cleanly', () {
      final engine = FailsafeEngine();
      engine.triggerFailsafe('Test disconnect');
      expect(engine.isFailsafeActive, isTrue);

      engine.clearFailsafe();
      expect(engine.isFailsafeActive, isFalse);
    });
  });
}
