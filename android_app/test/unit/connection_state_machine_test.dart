import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/services/communication/connection_state_machine.dart';
import 'package:PocketTX/core/compatibility/protocol_version.dart';

void main() {
  group('ConnectionStateMachine', () {
    test('starts in Disconnected state by default', () {
      final notifier = ConnectionStateMachineNotifier();
      expect(notifier.state.fsmState, equals(ConnectionFsmState.disconnected));
      expect(notifier.state.isConnected, isFalse);
    });

    test('transitions through finite state machine lifecycle correctly', () {
      final notifier = ConnectionStateMachineNotifier();

      notifier.transitionTo(ConnectionFsmState.scanning);
      expect(notifier.state.fsmState, equals(ConnectionFsmState.scanning));

      notifier.transitionTo(
        ConnectionFsmState.connected,
        type: ConnectionType.wifi,
        deviceName: '192.168.1.10',
        latencyMs: 12,
      );
      expect(notifier.state.fsmState, equals(ConnectionFsmState.connected));
      expect(notifier.state.isConnected, isTrue);
      expect(notifier.state.deviceName, equals('192.168.1.10'));

      notifier.transitionTo(ConnectionFsmState.reconnecting);
      expect(notifier.state.fsmState, equals(ConnectionFsmState.reconnecting));
      expect(notifier.state.isConnected, isFalse);
    });
  });
}
