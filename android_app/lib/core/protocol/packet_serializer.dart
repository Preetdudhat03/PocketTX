// ─────────────────────────────────────────────
// PocketTX – Binary Packet Serializer
// Encodes and decodes binary packets for companion communication.
// Symmetric layout with Windows Companion PacketHeader (20-byte header).
// ─────────────────────────────────────────────

import 'dart:typed_data';

enum PacketType {
  heartbeat(0x01),
  channelData(0x02),
  telemetryRequest(0x03),
  telemetryResponse(0x04),
  profileSync(0x05),
  ack(0x06),
  disconnect(0x07);

  final int code;
  const PacketType(this.code);

  static PacketType fromCode(int code) {
    return PacketType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PacketType.channelData,
    );
  }
}

class PacketHeader {
  static const List<int> magicBytes = [0x50, 0x54]; // 'P', 'T'
  static const int headerSize = 20;

  final int version;
  final int flags;
  final int reserved;
  final PacketType type;
  final int sequence;
  final int timestampMs;
  final int payloadLength;

  const PacketHeader({
    this.version = 0x01,
    this.flags = 0x00,
    this.reserved = 0x00,
    required this.type,
    required this.sequence,
    required this.timestampMs,
    required this.payloadLength,
  });

  Uint8List toBytes() {
    final buffer = Uint8List(headerSize);
    final bd = ByteData.sublistView(buffer);

    buffer[0] = magicBytes[0];
    buffer[1] = magicBytes[1];
    buffer[2] = version;
    buffer[3] = flags;
    buffer[4] = reserved;
    buffer[5] = type.code;

    bd.setUint32(6, sequence, Endian.big);
    bd.setUint64(10, timestampMs, Endian.big);
    bd.setUint16(18, payloadLength, Endian.big);

    return buffer;
  }

  static PacketHeader? fromBytes(Uint8List data) {
    if (data.length < headerSize) return null;
    if (data[0] != magicBytes[0] || data[1] != magicBytes[1]) return null;

    final bd = ByteData.sublistView(data);

    return PacketHeader(
      version: data[2],
      flags: data[3],
      reserved: data[4],
      type: PacketType.fromCode(data[5]),
      sequence: bd.getUint32(6, Endian.big),
      timestampMs: bd.getUint64(10, Endian.big),
      payloadLength: bd.getUint16(18, Endian.big),
    );
  }
}

class BinaryPacket {
  final PacketHeader header;
  final Uint8List payload;

  const BinaryPacket({
    required this.header,
    required this.payload,
  });

  Uint8List encode() {
    final headerBytes = header.toBytes();
    final result = Uint8List(headerBytes.length + payload.length);
    result.setAll(0, headerBytes);
    result.setAll(headerBytes.length, payload);
    return result;
  }

  static BinaryPacket? decode(Uint8List data) {
    final header = PacketHeader.fromBytes(data);
    if (header == null) return null;

    final expectedLength = PacketHeader.headerSize + header.payloadLength;
    if (data.length < expectedLength) return null;

    final payload = data.sublist(
      PacketHeader.headerSize,
      expectedLength,
    );

    return BinaryPacket(header: header, payload: payload);
  }
}
