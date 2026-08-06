// ─────────────────────────────────────────────
// PocketTX – Virtual Transmitter Service
// Implements IVirtualTransmitter for Phase 2 binary channel streaming.
// ─────────────────────────────────────────────

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/phase2_contracts.dart';
import '../protocol/packet_serializer.dart';
import '../protocol/binary_channel_encoder.dart';
import '../../models/channel_data.dart';
import 'connection_manager_service.dart';

class VirtualTransmitterService implements IVirtualTransmitter {
  final Ref _ref;
  int _sequenceNumber = 0;

  VirtualTransmitterService(this._ref);

  @override
  Future<void> sendChannelData(ChannelData channelData) async {
    final connManager = _ref.read(connectionManagerServiceProvider);
    if (!connManager.isConnected || connManager.activeTransport == null) {
      return;
    }

    final payload = BinaryChannelEncoder.encodePwm(channelData.pwm);

    final header = PacketHeader(
      type: PacketType.channelData,
      sequence: _sequenceNumber++,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadLength: payload.length,
    );

    final packet = BinaryPacket(header: header, payload: payload).encode();
    await connManager.activeTransport?.sendData(packet);
  }

  @override
  Future<void> sendHeartbeat() async {
    final connManager = _ref.read(connectionManagerServiceProvider);
    if (!connManager.isConnected || connManager.activeTransport == null) {
      return;
    }

    final header = PacketHeader(
      type: PacketType.heartbeat,
      sequence: _sequenceNumber++,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      payloadLength: 0,
    );

    final packet = BinaryPacket(header: header, payload: Uint8List(0)).encode();
    await connManager.activeTransport?.sendData(packet);
  }
}

final virtualTransmitterServiceProvider = Provider<VirtualTransmitterService>(
  (ref) => VirtualTransmitterService(ref),
);
