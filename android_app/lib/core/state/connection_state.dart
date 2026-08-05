// ─────────────────────────────────────────────
// PocketTX – Connection State (Riverpod)
// Tracks companion connection status.
// ─────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/compatibility/protocol_version.dart';

/// Connection state – symmetric with Windows Companion ConnectionState.
class AppConnectionState {
  final bool isConnected;
  final ConnectionType connectionType;
  final String? deviceName;
  final int latencyMs;
  final String protocolVersion;

  const AppConnectionState({
    this.isConnected = false,
    this.connectionType = ConnectionType.none,
    this.deviceName,
    this.latencyMs = 0,
    this.protocolVersion = ProtocolVersion.version,
  });

  AppConnectionState copyWith({
    bool? isConnected,
    ConnectionType? connectionType,
    String? deviceName,
    int? latencyMs,
    String? protocolVersion,
  }) =>
      AppConnectionState(
        isConnected: isConnected ?? this.isConnected,
        connectionType: connectionType ?? this.connectionType,
        deviceName: deviceName ?? this.deviceName,
        latencyMs: latencyMs ?? this.latencyMs,
        protocolVersion: protocolVersion ?? this.protocolVersion,
      );

  String get statusLabel =>
      isConnected ? 'CONNECTED' : 'DISCONNECTED';

  String get connectionLabel =>
      connectionType.name.toUpperCase();
}

class ConnectionStateNotifier extends StateNotifier<AppConnectionState> {
  ConnectionStateNotifier() : super(const AppConnectionState());

  void setConnected({
    required ConnectionType type,
    String? deviceName,
    int latencyMs = 0,
  }) {
    state = state.copyWith(
      isConnected: true,
      connectionType: type,
      deviceName: deviceName,
      latencyMs: latencyMs,
    );
  }

  void setDisconnected() {
    state = const AppConnectionState();
  }

  void updateLatency(int ms) {
    state = state.copyWith(latencyMs: ms);
  }
}

final connectionStateProvider =
    StateNotifierProvider<ConnectionStateNotifier, AppConnectionState>(
  (ref) => ConnectionStateNotifier(),
);
