// ─────────────────────────────────────────────
// PocketTX – UDP Transport Channel
// UDP socket transport for LAN discovery beaconing and 250Hz - 1000Hz channel streaming.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'i_transport_channel.dart';
import '../compatibility/protocol_version.dart';
import '../services/logger_service.dart';
import '../../models/log_entry_model.dart';

class UdpTransportChannel implements ITransportChannel {
  static const int defaultPort = 18456;

  RawDatagramSocket? _socket;
  InternetAddress? _remoteAddress;
  int _remotePort = defaultPort;

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
    try {
      await close();

      _remotePort = port ?? defaultPort;
      if (host != null && host.isNotEmpty) {
        _remoteAddress = InternetAddress(host);
      } else {
        _remoteAddress = InternetAddress('255.255.255.255');
      }

      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      _socket?.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final dg = _socket?.receive();
            if (dg != null) {
              _packetController.add(dg.data);
            }
          }
        },
        onError: (err) {
          LoggerService().error(
            LogCategory.network,
            'UDP_ERROR',
            'UDP socket error: $err',
          );
        },
      );

      _isConnected = true;
      _connectionStateController.add(true);
      LoggerService().info(
        LogCategory.network,
        'UDP_OPENED',
        'UDP transport bound on port ${_socket?.port}, remote: ${_remoteAddress?.address}:$_remotePort',
      );
      return true;
    } catch (e) {
      LoggerService().error(
        LogCategory.network,
        'UDP_BIND_FAILED',
        'Failed to bind UDP transport socket: $e',
      );
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }

  @override
  Future<bool> sendData(Uint8List data) async {
    if (_socket == null || _remoteAddress == null) return false;
    try {
      final sent = _socket!.send(data, _remoteAddress!, _remotePort);
      return sent > 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    if (_socket != null) {
      _socket!.close();
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
