// ─────────────────────────────────────────────
// PocketTX – Packet Builder
// Pure helper to construct BinaryPackets for Hello, ChannelData, Heartbeat, and Disconnect.
// ─────────────────────────────────────────────

import 'dart:typed_data';
import 'packet_types.dart';
import 'packet_header.dart';
import 'packet_payload.dart';
import 'packet_codec.dart';
import '../../models/channel_data.dart';
import '../constants/channel_constants.dart';

abstract final class PacketBuilder {
  static BinaryPacket buildChannelData({
    required ChannelData data,
    required int sessionId,
    required int sequence,
  }) {
    final payloadBuffer = Uint8List(ChannelConstants.channelCount * 2);
    final bd = ByteData.sublistView(payloadBuffer);

    for (var i = 0; i < ChannelConstants.channelCount; i++) {
      final pwmVal = (i < data.pwm.length) ? data.pwm[i] : 1500;
      bd.setUint16(i * 2, pwmVal.clamp(1000, 2000), Endian.big);
    }

    final header = PacketHeader(
      type: PacketType.channelData,
      sessionId: sessionId,
      sequence: sequence,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadLength: payloadBuffer.length,
    );

    return BinaryPacket(
      header: header,
      payload: PacketPayload(payloadBuffer),
    );
  }

  static BinaryPacket buildHeartbeat({
    required int sessionId,
    required int sequence,
  }) {
    final header = PacketHeader(
      type: PacketType.heartbeat,
      sessionId: sessionId,
      sequence: sequence,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadLength: 0,
    );

    return BinaryPacket(
      header: header,
      payload: const PacketPayload(Uint8List(0)),
    );
  }

  static BinaryPacket buildDisconnect({
    required int sessionId,
    required int sequence,
  }) {
    final header = PacketHeader(
      type: PacketType.disconnect,
      sessionId: sessionId,
      sequence: sequence,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadLength: 0,
    );

    return BinaryPacket(
      header: header,
      payload: const PacketPayload(Uint8List(0)),
    );
  }

  static BinaryPacket buildHello({
    required int sessionId,
    required int sequence,
    required String deviceName,
  }) {
    final nameBytes = Uint8List.fromList(deviceName.codeUnits);
    final header = PacketHeader(
      type: PacketType.hello,
      sessionId: sessionId,
      sequence: sequence,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadLength: nameBytes.length,
    );

    return BinaryPacket(
      header: header,
      payload: PacketPayload(nameBytes),
    );
  }
}
