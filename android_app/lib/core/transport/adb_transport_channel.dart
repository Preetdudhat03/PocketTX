// ─────────────────────────────────────────────
// PocketTX – ADB / USB Transport Channel
// Tunneling over ADB forward / USB localhost connection (127.0.0.1).
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';
import 'i_transport_channel.dart';
import 'tcp_transport_channel.dart';
import '../compatibility/protocol_version.dart';

class AdbTransportChannel implements ITransportChannel {
  final TcpTransportChannel _tcpChannel = TcpTransportChannel();

  @override
  ConnectionType get type => ConnectionType.adb;

  @override
  bool get isConnected => _tcpChannel.isConnected;

  @override
  Stream<Uint8List> get packetStream => _tcpChannel.packetStream;

  @override
  Stream<bool> get connectionStateStream => _tcpChannel.connectionStateStream;

  @override
  Future<bool> open({String? host, int? port}) async {
    return _tcpChannel.open(
      host: host ?? '127.0.0.1',
      port: port ?? 18456,
    );
  }

  @override
  Future<bool> sendData(Uint8List data) => _tcpChannel.sendData(data);

  @override
  Future<void> close() => _tcpChannel.close();
}
