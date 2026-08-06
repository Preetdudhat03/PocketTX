// ─────────────────────────────────────────────
// PocketTX – Packet Header
// Defines binary packet header layout carrying Magic Bytes, Session ID, Sequence, and Type.
// ─────────────────────────────────────────────

import 'dart:typed_data';
import 'packet_types.dart';

class PacketHeader {
  static const List<int> magicBytes = [0x50, 0x54]; // 'P', 'T'
  static const int headerSize = 24; // 2+1+1+4+4+8+2+2

  final int version;
  final PacketType type;
  final int sessionId;
  final int sequence;
  final int timestampMs;
  final int payloadLength;

  const PacketHeader({
    this.version = 0x01,
    required this.type,
    required this.sessionId,
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
    buffer[3] = type.code;

    bd.setUint32(4, sessionId, Endian.big);
    bd.setUint32(8, sequence, Endian.big);
    bd.setUint64(12, timestampMs, Endian.big);
    bd.setUint16(20, payloadLength, Endian.big);

    return buffer;
  }

  static PacketHeader? fromBytes(Uint8List data) {
    if (data.length < headerSize) return null;
    if (data[0] != magicBytes[0] || data[1] != magicBytes[1]) return null;

    final bd = ByteData.sublistView(data);

    return PacketHeader(
      version: data[2],
      type: PacketType.fromCode(data[3]),
      sessionId: bd.getUint32(4, Endian.big),
      sequence: bd.getUint32(8, Endian.big),
      timestampMs: bd.getUint64(12, Endian.big),
      payloadLength: bd.getUint16(20, Endian.big),
    );
  }
}
