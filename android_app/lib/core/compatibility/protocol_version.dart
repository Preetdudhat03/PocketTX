// ─────────────────────────────────────────────
// PocketTX – Protocol Version
// Shared compatibility layer for Phase 2 companion communication
// ─────────────────────────────────────────────

/// The current protocol version used when communicating with the Windows Companion.
/// Increment MAJOR on breaking changes, MINOR on backward-compatible additions.
abstract final class ProtocolVersion {
  static const int major = 1;
  static const int minor = 0;
  static const int patch = 0;

  static const String version = '$major.$minor.$patch';

  /// Minimum companion app version this client is compatible with.
  static const String minCompatibleCompanionVersion = '1.0.0';

  /// Checks whether [remoteVersion] is compatible with the local protocol.
  static bool isCompatible(String remoteVersion) {
    final parts = remoteVersion.split('.').map(int.tryParse).toList();
    if (parts.length < 3 || parts.any((p) => p == null)) return false;
    final remoteMajor = parts[0]!;
    // Breaking change: different major version = incompatible
    return remoteMajor == major;
  }
}

/// Packet types for Phase 2 companion communication protocol.
/// Must remain symmetric with Windows Companion PacketType enum.
enum PacketType {
  handshake,
  channelData,
  telemetry,
  profileSync,
  heartbeat,
  disconnect,
  error,
}

/// Connection types supported in Phase 2.
/// Must remain symmetric with Windows Companion ConnectionType enum.
enum ConnectionType {
  none,
  usb,
  wifi,
  bluetooth,
  adb,
}
