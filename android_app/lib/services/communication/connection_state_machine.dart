// ─────────────────────────────────────────────
// PocketTX – Connection State Machine
// Finite state machine tracking companion connection states:
// Disconnected -> Scanning -> Connecting -> Connected -> Reconnecting.
// ─────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/compatibility/protocol_version.dart';
import '../../core/events/event_bus.dart';

enum ConnectionFsmState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
}

class ConnectionStateChangedEvent extends AppEvent {
  final ConnectionFsmState oldState;
  final ConnectionFsmState newState;
  final String? deviceName;

  const ConnectionStateChangedEvent({
    required this.oldState,
    required this.newState,
    this.deviceName,
  });
}

class ConnectionFsmData {
  final ConnectionFsmState fsmState;
  final ConnectionType connectionType;
  final String? deviceName;
  final int latencyMs;

  const ConnectionFsmData({
    this.fsmState = ConnectionFsmState.disconnected,
    this.connectionType = ConnectionType.none,
    this.deviceName,
    this.latencyMs = 0,
  });

  bool get isConnected => fsmState == ConnectionFsmState.connected;

  String get statusLabel => fsmState.name.toUpperCase();

  ConnectionFsmData copyWith({
    ConnectionFsmState? fsmState,
    ConnectionType? connectionType,
    String? deviceName,
    int? latencyMs,
  }) {
    return ConnectionFsmData(
      fsmState: fsmState ?? this.fsmState,
      connectionType: connectionType ?? this.connectionType,
      deviceName: deviceName ?? this.deviceName,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}

class ConnectionStateMachineNotifier extends StateNotifier<ConnectionFsmData> {
  ConnectionStateMachineNotifier() : super(const ConnectionFsmData());

  void transitionTo(
    ConnectionFsmState newState, {
    ConnectionType? type,
    String? deviceName,
    int? latencyMs,
  }) {
    if (state.fsmState == newState &&
        type == null &&
        deviceName == null &&
        latencyMs == null) {
      return;
    }

    final oldState = state.fsmState;
    state = state.copyWith(
      fsmState: newState,
      connectionType: type ?? state.connectionType,
      deviceName: deviceName ?? state.deviceName,
      latencyMs: latencyMs ?? state.latencyMs,
    );

    EventBus().fire(
      ConnectionStateChangedEvent(
        oldState: oldState,
        newState: newState,
        deviceName: state.deviceName,
      ),
    );
  }

  void updateLatency(int ms) {
    state = state.copyWith(latencyMs: ms);
  }
}

final connectionStateMachineProvider =
    StateNotifierProvider<ConnectionStateMachineNotifier, ConnectionFsmData>(
  (ref) => ConnectionStateMachineNotifier(),
);
