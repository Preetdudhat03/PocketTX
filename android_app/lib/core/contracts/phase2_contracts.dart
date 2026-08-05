// ─────────────────────────────────────────────
// PocketTX – Phase 2 Interface Contracts
// Stub interfaces for companion communication.
// NOTHING is implemented in Phase 1 — these exist
// so the architecture is ready for Phase 2.
// ─────────────────────────────────────────────

import '../../models/channel_data.dart';
import '../../models/controller_profile.dart';
import '../../models/diagnostic_metrics.dart';
import '../compatibility/protocol_version.dart';

/// Manages connection lifecycle to the Windows Companion.
abstract interface class IConnectionManager {
  /// Whether a companion connection is currently active.
  bool get isConnected;

  /// Current connection type.
  ConnectionType get connectionType;

  /// Attempt to connect using the specified [type].
  Future<bool> connect(ConnectionType type);

  /// Disconnect from the companion.
  Future<void> disconnect();

  /// Scan for available devices on all supported interfaces.
  Future<List<String>> scanDevices();
}

/// Transmits RC channel data to the Windows Companion.
abstract interface class IVirtualTransmitter {
  /// Send the latest [channelData] packet to the companion.
  Future<void> sendChannelData(ChannelData channelData);

  /// Send a heartbeat to keep the connection alive.
  Future<void> sendHeartbeat();
}

/// Receives telemetry back from the Windows Companion.
abstract interface class ITelemetryRepository {
  /// Stream of incoming diagnostic metrics from companion.
  Stream<DiagnosticMetrics> get metricsStream;

  /// Last known latency in milliseconds.
  int get lastLatencyMs;
}

/// Synchronizes profiles with the Windows Companion.
abstract interface class ICommunicationRepository {
  /// Upload [profile] to companion for use.
  Future<void> uploadProfile(ControllerProfile profile);

  /// Download profiles available on the companion.
  Future<List<ControllerProfile>> downloadProfiles();

  /// Current protocol version negotiated with companion.
  String get negotiatedProtocolVersion;
}
