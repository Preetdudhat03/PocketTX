// ─────────────────────────────────────────────
// PocketTX – Session Manager
// Active connection session controller orchestrating handshakes, continuous channel stream,
// heartbeats, sequence validation, and metrics tracking.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compatibility/protocol_version.dart' hide PacketType;
import '../../core/protocol/packet_builder.dart';
import '../../core/protocol/packet_codec.dart';
import '../../core/protocol/packet_types.dart';
import '../../core/services/logger_service.dart';
import '../../core/state/channel_state.dart';
import '../../models/channel_data.dart';
import '../../models/log_entry_model.dart';
import 'connection_state_machine.dart';
import 'failsafe_engine.dart';
import 'heartbeat_monitor.dart';
import 'transport_metrics.dart';
import 'transport/udp/udp_transport_channel.dart';
import 'transport/tcp/tcp_transport_channel.dart';
import 'udp_discovery_service.dart';
import 'companion_service.dart';

class SessionManager {
  final Ref _ref;
  UdpTransportChannel? _udpChannel;
  TcpTransportChannel? _tcpChannel;
  bool _usingTcp = false;
  late final FailsafeEngine _failsafeEngine;
  late final TransportMetricsTracker _metricsTracker;
  late final HeartbeatMonitor _heartbeatMonitor;

  int _sessionId = 0;
  int _sequenceNumber = 0;
  StreamSubscription? _packetSub;
  Timer? _transmissionTimer;

  int get sessionId => _sessionId;
  FailsafeEngine get failsafeEngine => _failsafeEngine;
  TransportMetricsTracker get metricsTracker => _metricsTracker;

  SessionManager(this._ref) {
    _failsafeEngine = FailsafeEngine();
    _metricsTracker = TransportMetricsTracker();
    _heartbeatMonitor = HeartbeatMonitor(onTimeout: _handleHeartbeatTimeout);
  }

  // ── Transport helpers ──────────────────────────────────────────────────────
  bool get _transportConnected =>
      _usingTcp ? (_tcpChannel?.isConnected ?? false) : (_udpChannel?.isConnected ?? false);

  Stream<Uint8List> get _packetStream =>
      _usingTcp ? _tcpChannel!.packetStream : _udpChannel!.packetStream;

  Future<bool> _sendRaw(Uint8List data) =>
      _usingTcp ? _tcpChannel!.sendData(data) : _udpChannel!.sendData(data);

  Future<void> _closeTransport() async {
    await _udpChannel?.close();
    await _tcpChannel?.close();
  }

  Future<bool> startSession({required String targetHost, int? port}) async {
    final notifier = _ref.read(connectionStateMachineProvider.notifier);
    notifier.transitionTo(ConnectionFsmState.connecting, deviceName: targetHost);

    _sessionId = Random().nextInt(0x7FFFFFFF);
    _sequenceNumber = 0;
    _metricsTracker.reset();

    // Auto-select transport: TCP for USB (127.0.0.1), UDP for Wi-Fi
    _usingTcp = (targetHost == '127.0.0.1' || targetHost == 'localhost');

    LoggerService().info(
      LogCategory.network,
      'SESSION_STARTING',
      'Starting session [$_sessionId] with Companion ($targetHost) via ${_usingTcp ? 'TCP/USB' : 'UDP/WiFi'}...',
    );

    bool opened;
    if (_usingTcp) {
      _tcpChannel = TcpTransportChannel();
      opened = await _tcpChannel!.open(host: targetHost);

      // Auto-Fallback: If USB 127.0.0.1 failed (e.g. adb reverse missing), check if a Wi-Fi Companion was discovered
      if (!opened && (targetHost == '127.0.0.1' || targetHost == 'localhost')) {
        final wifiDevs = _ref.read(companionServiceProvider).discoveryService.discoveredDevices;
        if (wifiDevs.isNotEmpty) {
          final wifiDev = wifiDevs.firstWhere(
            (d) => d.ipAddress != '127.0.0.1',
            orElse: () => wifiDevs.first,
          );
          if (wifiDev.ipAddress.isNotEmpty && wifiDev.ipAddress != '127.0.0.1') {
            LoggerService().warning(
              LogCategory.network,
              'USB_FAIL_FALLBACK_WIFI',
              '[USB Connection Failed] Automatically falling back to Wi-Fi Companion at ${wifiDev.ipAddress}:${wifiDev.port}...',
            );
            _usingTcp = false;
            _udpChannel = UdpTransportChannel();
            opened = await _udpChannel!.open(host: wifiDev.ipAddress, port: wifiDev.port);
          }
        }
      }
    } else {
      _udpChannel = UdpTransportChannel();
      opened = await _udpChannel!.open(host: targetHost, port: port);
    }

    if (!opened) {
      notifier.transitionTo(ConnectionFsmState.disconnected);
      _failsafeEngine.triggerFailsafe('Failed to open transport socket');
      return false;
    }

    _packetSub?.cancel();
    _packetSub = _packetStream.listen(_handleIncomingRawPacket);

    String realDeviceName = 'PocketTX Phone';
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      realDeviceName = '${androidInfo.manufacturer.toUpperCase()} ${androidInfo.model}';
    } catch (_) {}

    final helloPacket = PacketBuilder.buildHello(
      sessionId: _sessionId,
      sequence: _sequenceNumber++,
      deviceName: realDeviceName,
    );
    final encodedHello = PacketCodec.encode(helloPacket);

    // Strict Handshake Verification: Wait for ACK response from Windows Companion
    final completer = Completer<bool>();
    StreamSubscription? ackSubscription;
    ackSubscription = _packetStream.listen((rawBytes) {
      final packet = PacketCodec.decode(rawBytes);
      if (packet != null && (packet.header.type == PacketType.ack || packet.header.type == PacketType.hello)) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    await _sendRaw(encodedHello);

    final ackReceived = await completer.future.timeout(
      const Duration(milliseconds: 3000),
      onTimeout: () => false,
    );
    await ackSubscription.cancel();

    if (!ackReceived) {
      notifier.transitionTo(ConnectionFsmState.disconnected);
      await _closeTransport();
      LoggerService().warning(
        LogCategory.network,
        'SESSION_HANDSHAKE_FAILED',
        'No ACK response received from Windows Companion ($targetHost). Host unreachable.',
      );
      return false;
    }

    notifier.transitionTo(
      ConnectionFsmState.connected,
      type: targetHost == '127.0.0.1' ? ConnectionType.usb : ConnectionType.wifi,
      deviceName: targetHost,
      latencyMs: targetHost == '127.0.0.1' ? 1 : 5,
    );

    _failsafeEngine.clearFailsafe();
    _heartbeatMonitor.start();

    // Auto-start continuous 100Hz background UDP channel packet transmission timer
    _transmissionTimer?.cancel();
    _transmissionTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final currentChannels = _ref.read(channelStateProvider);
      transmitChannelData(currentChannels);
    });

    LoggerService().info(
      LogCategory.network,
      'SESSION_ESTABLISHED',
      'Session Established! ID [$_sessionId] streaming continuous telemetry to $targetHost.',
    );

    return true;
  }

  void transmitChannelData(ChannelData channelData) {
    final fsm = _ref.read(connectionStateMachineProvider);
    if (!fsm.isConnected || !_transportConnected) return;

    final packet = PacketBuilder.buildChannelData(
      data: channelData,
      sessionId: _sessionId,
      sequence: _sequenceNumber++,
    );

    _sendRaw(PacketCodec.encode(packet));
    _metricsTracker.incrementTxPacket();
  }

  void _handleIncomingRawPacket(Uint8List rawBytes) {
    final packet = PacketCodec.decode(rawBytes);
    if (packet == null) return;

    // Reject stale packets from invalid sessions
    if (packet.header.sessionId != 0 && packet.header.sessionId != _sessionId) {
      return;
    }

    _metricsTracker.trackSequence(packet.header.sequence);
    _heartbeatMonitor.registerPulse();

    if (packet.header.type == PacketType.heartbeat) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rtt = (now - packet.header.timestampMs).clamp(1, 999);
      _ref.read(connectionStateMachineProvider.notifier).updateLatency(rtt);
    }
  }

  void _handleHeartbeatTimeout() {
    LoggerService().warning(
      LogCategory.network,
      'HEARTBEAT_TIMEOUT',
      'Heartbeat timeout detected from Windows Companion!',
    );
    _failsafeEngine.triggerFailsafe('Heartbeat timeout');
  }

  Future<void> endSession() async {
    _transmissionTimer?.cancel();
    _transmissionTimer = null;

    if (_transportConnected) {
      final disconnectPacket = PacketBuilder.buildDisconnect(
        sessionId: _sessionId,
        sequence: _sequenceNumber++,
      );
      await _sendRaw(PacketCodec.encode(disconnectPacket));
      await _closeTransport();
    }

    _heartbeatMonitor.stop();
    _packetSub?.cancel();

    _ref.read(connectionStateMachineProvider.notifier).transitionTo(ConnectionFsmState.disconnected);
    LoggerService().info(
      LogCategory.network,
      'SESSION_ENDED',
      'Session ID [$_sessionId] cleanly terminated.',
    );
  }

  void dispose() {
    endSession();
    _udpChannel?.dispose();
    _tcpChannel?.dispose();
    _heartbeatMonitor.stop();
  }
}

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(ref),
);
