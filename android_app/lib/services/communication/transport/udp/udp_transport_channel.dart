// ─────────────────────────────────────────────
// PocketTX – UDP Transport Channel
// Data socket transport for live packet transmission over UDP.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/protocol/protocol_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../models/log_entry_model.dart';

class UdpTransportChannel {
  RawDatagramSocket? _socket;
  InternetAddress? _remoteAddress;
  int _remotePort = ProtocolConstants.dataPort;
  bool _isConnected = false;

  final _packetController = StreamController<Uint8List>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  bool get isConnected => _isConnected;
  Stream<Uint8List> get packetStream => _packetController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  Future<bool> open({String? host, int? port}) async {
    try {
      await close();

      _remotePort = port ?? ProtocolConstants.dataPort;
      if (host != null && host.isNotEmpty) {
        _remoteAddress = InternetAddress(host);
      } else {
        _remoteAddress = InternetAddress('255.255.255.255');
      }

      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket?.broadcastEnabled = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket?.receive();
          if (dg != null) {
            _packetController.add(dg.data);
          }
        }
      });

      _isConnected = true;
      _connectionStateController.add(true);
      return true;
    } catch (e) {
      LoggerService().error(
        LogCategory.network,
        'UDP_OPEN_FAILED',
        'Failed to bind UDP socket channel: $e',
      );
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }

  Future<bool> sendData(Uint8List data) async {
    if (_socket == null || _remoteAddress == null) return false;
    try {
      final sent = _socket!.send(data, _remoteAddress!, _remotePort);
      return sent > 0;
    } catch (e) {
      return false;
    }
  }

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
