// ─────────────────────────────────────────────
// PocketTX – Connection Manager Service
// Concrete implementation of IConnectionManager for Phase 2 companion connectivity.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/phase2_contracts.dart';
import '../compatibility/protocol_version.dart';
import '../transport/i_transport_channel.dart';
import '../transport/udp_transport_channel.dart';
import '../transport/tcp_transport_channel.dart';
import '../transport/adb_transport_channel.dart';
import '../protocol/packet_serializer.dart';
import '../state/connection_state.dart';
import 'logger_service.dart';
import '../../models/log_entry_model.dart';

class ConnectionManagerService implements IConnectionManager {
  final Ref _ref;

  ITransportChannel? _activeTransport;
  ConnectionType _currentType = ConnectionType.none;
  bool _isConnected = false;
  int _lastLatencyMs = 0;
  String? _connectedDeviceHost;

  StreamSubscription? _packetSub;
  StreamSubscription? _stateSub;
  Timer? _heartbeatTimer;

  int _sequenceNumber = 0;

  ConnectionManagerService(this._ref);

  @override
  bool get isConnected => _isConnected;

  @override
  ConnectionType get connectionType => _currentType;

  ITransportChannel? get activeTransport => _activeTransport;

  int get lastLatencyMs => _lastLatencyMs;

  @override
  Future<bool> connect(ConnectionType type, {String? targetHost, int? port}) async {
    await disconnect();

    _currentType = type;
    LoggerService().info(
      LogCategory.network,
      'CONNECTING',
      'Initiating companion connection using ${type.name.toUpperCase()} (Host: ${targetHost ?? "broadcast"})',
    );

    ITransportChannel channel;
    switch (type) {
      case ConnectionType.wifi:
        channel = UdpTransportChannel();
      case ConnectionType.adb:
        channel = AdbTransportChannel();
      case ConnectionType.usb:
        channel = TcpTransportChannel(); // Local TCP bridge over USB
      case ConnectionType.none:
      default:
        _updateConnectionState(connected: false, type: ConnectionType.none);
        return false;
    }

    final success = await channel.open(host: targetHost, port: port);
    if (success) {
      _activeTransport = channel;
      _isConnected = true;
      _connectedDeviceHost = targetHost ?? 'Companion PC';

      _updateConnectionState(
        connected: true,
        type: type,
        deviceName: _connectedDeviceHost,
        latencyMs: 12,
      );

      _packetSub = channel.packetStream.listen(_handleIncomingPacket);
      _startHeartbeat();

      LoggerService().info(
        LogCategory.network,
        'CONNECTED',
        'Companion connected over ${type.name.toUpperCase()} to $_connectedDeviceHost',
      );
      return true;
    } else {
      _updateConnectionState(connected: false, type: ConnectionType.none);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _stopHeartbeat();
    await _packetSub?.cancel();
    _packetSub = null;

    await _stateSub?.cancel();
    _stateSub = null;

    if (_activeTransport != null) {
      await _activeTransport!.close();
      _activeTransport = null;
    }

    _isConnected = false;
    _currentType = ConnectionType.none;
    _connectedDeviceHost = null;

    _updateConnectionState(connected: false, type: ConnectionType.none);

    LoggerService().info(
      LogCategory.network,
      'DISCONNECTED',
      'Disconnected from Windows Companion.',
    );
  }

  @override
  Future<List<String>> scanDevices() async {
    LoggerService().info(
      LogCategory.network,
      'SCAN_START',
      'Scanning local network & USB for Windows Companion endpoints...',
    );

    final discoveredDevices = <String>[];

    try {
      // 1. Try local loopback (ADB/USB tunnel port 18456)
      try {
        final testSocket = await Socket.connect('127.0.0.1', 18456,
            timeout: const Duration(milliseconds: 300));
        await testSocket.close();
        discoveredDevices.add('USB / ADB Companion (127.0.0.1:18456)');
      } catch (_) {}

      // 2. Broadcast UDP ping for LAN Companion PC
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final beaconHeader = PacketHeader(
        type: PacketType.heartbeat,
        sequence: _sequenceNumber++,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        payloadLength: 0,
      );
      final beaconPacket = BinaryPacket(header: beaconHeader, payload: Uint8List(0)).encode();

      socket.send(beaconPacket, InternetAddress('255.255.255.255'), 18456);

      final completer = Completer<List<String>>();
      Timer(const Duration(milliseconds: 750), () {
        socket.close();
        if (!completer.isCompleted) {
          completer.complete(discoveredDevices);
        }
      });

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final hostStr = '${datagram.address.address}:${datagram.port}';
            if (!discoveredDevices.contains(hostStr)) {
              discoveredDevices.add('Windows PC Companion ($hostStr)');
            }
          }
        }
      });

      final result = await completer.future;
      LoggerService().info(
        LogCategory.network,
        'SCAN_COMPLETE',
        'Scan found ${result.length} companion endpoint(s).',
      );
      return result;
    } catch (e) {
      LoggerService().warning(
        LogCategory.network,
        'SCAN_FAILED',
        'Device scan completed with fallback: $e',
      );
      return discoveredDevices;
    }
  }

  void _handleIncomingPacket(Uint8List rawBytes) {
    final packet = BinaryPacket.decode(rawBytes);
    if (packet == null) return;

    if (packet.header.type == PacketType.heartbeat ||
        packet.header.type == PacketType.telemetryResponse) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rtt = (now - packet.header.timestampMs).clamp(1, 999);
      _lastLatencyMs = rtt;
      _ref.read(connectionStateProvider.notifier).updateLatency(rtt);
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isConnected || _activeTransport == null) return;

      final header = PacketHeader(
        type: PacketType.heartbeat,
        sequence: _sequenceNumber++,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        payloadLength: 0,
      );
      final packet = BinaryPacket(header: header, payload: Uint8List(0)).encode();
      _activeTransport?.sendData(packet);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updateConnectionState({
    required bool connected,
    required ConnectionType type,
    String? deviceName,
    int latencyMs = 0,
  }) {
    final notifier = _ref.read(connectionStateProvider.notifier);
    if (connected) {
      notifier.setConnected(
        type: type,
        deviceName: deviceName,
        latencyMs: latencyMs,
      );
    } else {
      notifier.setDisconnected();
    }
  }

  void dispose() {
    disconnect();
  }
}

final connectionManagerServiceProvider = Provider<ConnectionManagerService>(
  (ref) => ConnectionManagerService(ref),
);
