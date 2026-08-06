import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockettx_app/core/protocol/packet_serializer.dart';

void main() {
  group('PacketSerializer', () {
    test('encodes and decodes packet header with magic bytes "PT"', () {
      final header = PacketHeader(
        type: PacketType.channelData,
        sequence: 42,
        timestampMs: 1690000000000,
        payloadLength: 16,
      );

      final bytes = header.toBytes();
      expect(bytes.length, equals(PacketHeader.headerSize));
      expect(bytes[0], equals(0x50)); // 'P'
      expect(bytes[1], equals(0x54)); // 'T'

      final decoded = PacketHeader.fromBytes(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.type, equals(PacketType.channelData));
      expect(decoded.sequence, equals(42));
      expect(decoded.timestampMs, equals(1690000000000));
      expect(decoded.payloadLength, equals(16));
    });

    test('encodes and decodes complete binary packet', () {
      final header = PacketHeader(
        type: PacketType.heartbeat,
        sequence: 100,
        timestampMs: 123456789,
        payloadLength: 4,
      );
      final payload = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);

      final packet = BinaryPacket(header: header, payload: payload);
      final encoded = packet.encode();

      final decoded = BinaryPacket.decode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.header.type, equals(PacketType.heartbeat));
      expect(decoded.header.sequence, equals(100));
      expect(decoded.payload, equals(payload));
    });

    test('returns null when decoding truncated or invalid magic bytes', () {
      final invalid = Uint8List.fromList([0x00, 0x00, 0x01]);
      expect(PacketHeader.fromBytes(invalid), isNull);
      expect(BinaryPacket.decode(invalid), isNull);
    });
  });
}
