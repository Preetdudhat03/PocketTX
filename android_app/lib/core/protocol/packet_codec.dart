// ─────────────────────────────────────────────
// PocketTX – Packet Codec
// Pure encoding, decoding, version validation, and framing.
// ─────────────────────────────────────────────

import 'dart:typed_data';
import 'packet_header.dart';
import 'packet_payload.dart';

class BinaryPacket {
  final PacketHeader header;
  final PacketPayload payload;

  const BinaryPacket({
    required this.header,
    required this.payload,
  });

  Uint8List encode() {
    final headerBytes = header.toBytes();
    final result = Uint8List(headerBytes.length + payload.length);
    result.setAll(0, headerBytes);
    result.setAll(headerBytes.length, payload.data);
    return result;
  }

  static BinaryPacket? decode(Uint8List rawBytes) {
    final header = PacketHeader.fromBytes(rawBytes);
    if (header == null) return null;

    final expectedTotal = PacketHeader.headerSize + header.payloadLength;
    if (rawBytes.length < expectedTotal) return null;

    final payloadBytes = rawBytes.sublist(
      PacketHeader.headerSize,
      expectedTotal,
    );

    return BinaryPacket(
      header: header,
      payload: PacketPayload(payloadBytes),
    );
  }
}

abstract final class PacketCodec {
  static Uint8List encode(BinaryPacket packet) => packet.encode();

  static BinaryPacket? decode(Uint8List rawBytes) => BinaryPacket.decode(rawBytes);

  static bool isVersionCompatible(int version) => version == 0x01;
}
