// ─────────────────────────────────────────────
// PocketTX – TCP Transport Channel
// Reliable framed packet transport over TCP for wired USB (ADB reverse) connection.
// Phone connects to 127.0.0.1 via ADB reverse tunnel → TCP socket → Windows Companion.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/protocol/protocol_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../models/log_entry_model.dart';

class TcpTransportChannel {
  Socket? _socket;
  bool _isConnected = false;

  // 4-byte length prefix framing: [len_hi, len_lo, payload...]
  // This lets us reconstruct packet boundaries over TCP stream.
  final _packetController = StreamController<Uint8List>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Accumulation buffer for partial TCP reads
  final List<int> _rxBuffer = [];

  bool get isConnected => _isConnected;
  Stream<Uint8List> get packetStream => _packetController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  static const int _tcpPort = ProtocolConstants.tcpPort; // 18458

  Future<bool> open({required String host}) async {
    try {
      await close();
      _rxBuffer.clear();

      LoggerService().info(
        LogCategory.network,
        'TCP_CONNECTING',
        '[TCP TX] Connecting to $host:$_tcpPort via ADB USB tunnel...',
      );

      _socket = await Socket.connect(
        host,
        _tcpPort,
        timeout: const Duration(seconds: 3),
      );

      LoggerService().info(
        LogCategory.network,
        'TCP_CONNECTED',
        '[TCP] Socket connected to ${_socket!.remoteAddress.address}:${_socket!.remotePort}',
      );

      _socket!.listen(
        _onData,
        onError: (e) {
          LoggerService().error(
            LogCategory.network,
            'TCP_RX_ERROR',
            '[TCP RX Error] $e',
          );
          _handleDisconnect();
        },
        onDone: () {
          LoggerService().warning(
            LogCategory.network,
            'TCP_DISCONNECTED',
            '[TCP] Remote host closed the connection.',
          );
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _connectionStateController.add(true);
      return true;
    } catch (e) {
      LoggerService().error(
        LogCategory.network,
        'TCP_OPEN_FAILED',
        '[TCP] Failed to connect to $host:$_tcpPort — $e',
      );
      _isConnected = false;
      _connectionStateController.add(false);
      return false;
    }
  }

  void _onData(List<int> incoming) {
    _rxBuffer.addAll(incoming);

    // Parse length-prefixed frames: [2-byte big-endian length][payload]
    while (_rxBuffer.length >= 2) {
      final len = (_rxBuffer[0] << 8) | _rxBuffer[1];
      if (_rxBuffer.length < 2 + len) break; // Wait for full frame

      final payload = Uint8List.fromList(_rxBuffer.sublist(2, 2 + len));
      _rxBuffer.removeRange(0, 2 + len);

      LoggerService().info(
        LogCategory.network,
        'TCP_RAW_RX',
        '[TCP RX] Received frame: $len bytes -> Hex: $payload',
      );

      _packetController.add(payload);
    }
  }

  Future<bool> sendData(Uint8List data) async {
    if (_socket == null || !_isConnected) return false;
    try {
      // Length-prefix frame: 2-byte big-endian length + payload
      final frame = Uint8List(2 + data.length);
      frame[0] = (data.length >> 8) & 0xFF;
      frame[1] = data.length & 0xFF;
      frame.setRange(2, frame.length, data);

      _socket!.add(frame);
      await _socket!.flush();

      LoggerService().info(
        LogCategory.network,
        'TCP_RAW_TX',
        '[TCP TX] Sent ${data.length} bytes (frame ${frame.length}) -> Hex: $data',
      );
      return true;
    } catch (e) {
      LoggerService().error(
        LogCategory.network,
        'TCP_TX_FAILED',
        '[TCP TX Error] $e',
      );
      _handleDisconnect();
      return false;
    }
  }

  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      _connectionStateController.add(false);
    }
    _socket?.destroy();
    _socket = null;
  }

  Future<void> close() async {
    _handleDisconnect();
    _rxBuffer.clear();
  }

  void dispose() {
    close();
    _packetController.close();
    _connectionStateController.close();
  }
}
