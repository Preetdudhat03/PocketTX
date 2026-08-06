import 'package:flutter_test/flutter_test.dart';
import 'package:pockettx_app/services/communication/connection_state_machine.dart';
import 'package:pockettx_app/core/compatibility/protocol_version.dart';

void main() {
  group('ConnectionStateMachine', () {
    test('starts in Disconnected state by default', () {
      final notifier = ConnectionStateMachineNotifier();
      expect(notifier.debugState.fsmState, equals(ConnectionFsmState.disconnected));
      expect(notifier.debugState.isConnected, isFalse);
    });

    test('transitions through finite state machine lifecycle correctly', () {
      final notifier = ConnectionStateMachineNotifier();

      notifier.transitionTo(ConnectionFsmState.scanning);
      expect(notifier.debugState.fsmState, equals(ConnectionFsmState.scanning));

      notifier.transitionTo(
        ConnectionFsmState.connected,
        type: ConnectionType.wifi,
        deviceName: '192.168.1.10',
        latencyMs: 12,
      );
      expect(notifier.debugState.fsmState, equals(ConnectionFsmState.connected));
      expect(notifier.debugState.isConnected, isTrue);
      expect(notifier.debugState.deviceName, equals('192.168.1.10'));

      notifier.transitionTo(ConnectionFsmState.reconnecting);
      expect(notifier.debugState.fsmState, equals(ConnectionFsmState.reconnecting));
      expect(notifier.debugState.isConnected, isFalse);
    });
  });
}
