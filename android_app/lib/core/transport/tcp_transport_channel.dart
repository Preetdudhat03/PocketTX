// ─────────────────────────────────────────────
// PocketTX – TCP Transport Channel
// Reliable TCP stream transport for companion session control and profile sync.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'i_transport_channel.dart';
import '../compatibility/protocol_version.dart';
import '../services/logger_service.dart';
import '../../models/log_entry_model.dart';

class TcpTransportChannel implements ITransportChannel {
  static const int defaultPort = 18457;

  Socket? _socket;
  final _packetController = StreamController<Uint8List>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  bool _isConnected = false;

  @override
  ConnectionType get type => ConnectionType.wifi;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<Uint8List> get packetStream => _packetController.stream;

  @override
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  @override
  Future<bool> open({String? host, int? port}) async {
    if (host == null || host.isEmpty) return false;
    final targetPort = port ?? defaultPort;

    try {
      await close();

      _socket = await Socket.connect(
        host,
        targetPort,
        timeout: const Duration(seconds: 4),
      );

      _socket?.listen(
        (data) {
          _packetController.add(Uint8List.fromList(data));
        },
        onError: (err) {
          LoggerService().error(
            LogCategory.network,
            'TCP_ERROR',
            'TCP socket error: $err',
          );
          close();
        },
        onDone: () {
          close();
        },
      );

      _isConnected = true;
      _connectionStateController.add(true);
      LoggerService().info(
        LogCategory.network,
        'TCP_CONNECTED',
        'TCP connection established with $host:$targetPort',
      );
      return true;
    } catch (e) {
      LoggerService().error(
        LogCategory.network,
        'TCP_CONNECT_FAILED',
        'Failed to connect TCP socket to $host:$targetPort: $e',
      );
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }

  @override
  Future<bool> sendData(Uint8List data) async {
    if (_socket == null || !_isConnected) return false;
    try {
      _socket!.add(data);
      await _socket!.flush();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    if (_socket != null) {
      await _socket!.close();
      _socket?.destroy();
      _socket = null;
    }
    if (_isConnected) {
      _isConnected = false;
      _connectionStateController.add(false);
    }
  }

  void dispose() {
    close();
    _packetController.close();
    _connectionStateController.close();
  }
}
