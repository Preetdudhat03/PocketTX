// ─────────────────────────────────────────────
// PocketTX – Packet Types & Capability Flags
// Protocol enum definitions and feature capability bitfields.
// ─────────────────────────────────────────────

enum PacketType {
  hello(0x01),
  heartbeat(0x02),
  channelData(0x03),
  telemetry(0x04),
  ack(0x05),
  disconnect(0x06);

  final int code;
  const PacketType(this.code);

  static PacketType fromCode(int code) {
    return PacketType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PacketType.channelData,
    );
  }
}

abstract final class CapabilityFlags {
  static const int supportsTelemetry  = 1 << 0;
  static const int supportsProfiles   = 1 << 1;
  static const int supportsUsb        = 1 << 2;
  static const int supportsBluetooth  = 1 << 3;
  static const int supportsWifi       = 1 << 4;
  static const int supportsCalibration = 1 << 5;

  static const int defaultCapabilities =
      supportsTelemetry | supportsWifi | supportsCalibration;
}
