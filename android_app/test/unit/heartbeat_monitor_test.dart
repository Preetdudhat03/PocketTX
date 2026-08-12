import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/services/communication/heartbeat_monitor.dart';

void main() {
  group('HeartbeatMonitor', () {
    test('starts and registers pulses without immediate timeout', () {
      bool timedOut = false;
      final monitor = HeartbeatMonitor(onTimeout: () {
        timedOut = true;
      });

      monitor.start();
      monitor.registerPulse();
      expect(timedOut, isFalse);

      monitor.stop();
    });
  });
}
