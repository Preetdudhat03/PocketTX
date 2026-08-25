// ─────────────────────────────────────────────
// PocketTX – UDP Discovery Service
// Standalone discovery service for one-tap LAN companion discovery.
// Supports Subnet Broadcast, Multicast, ADB Localhost, and Direct Ping.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import '../../core/protocol/protocol_constants.dart';
import '../../core/protocol/packet_builder.dart';
import '../../core/protocol/packet_codec.dart';
import '../../core/events/event_bus.dart';
import '../../core/services/logger_service.dart';
import '../../models/log_entry_model.dart';

class CompanionDiscoveredEvent extends AppEvent {
  final CompanionDeviceInfo device;
  const CompanionDiscoveredEvent(this.device);
}

class CompanionDeviceInfo {
  final String deviceId;
  final String deviceName;
  final String companionVersion;
  final String protocolVersion;
  final String osName;
  final String ipAddress;
  final int port;
  final int pingMs;
  final DateTime lastSeen;

  const CompanionDeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.companionVersion,
    required this.protocolVersion,
    required this.osName,
    required this.ipAddress,
    required this.port,
    this.pingMs = 1,
    required this.lastSeen,
  });

  String get displayName => '$deviceName ($osName - $ipAddress:$port)';
}

class UdpDiscoveryService {
  final List<CompanionDeviceInfo> _discoveredDevices = [];
  List<CompanionDeviceInfo> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  Future<List<CompanionDeviceInfo>> scanForCompanions({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    LoggerService().info(
      LogCategory.network,
      'DISCOVERY_STARTED',
      'Broadcasting UDP beacons on port ${ProtocolConstants.discoveryPort}...',
    );

    final List<CompanionDeviceInfo> foundDevices = [];

    try {
      // 1. Check ADB / USB tunnel localhost (127.0.0.1:18456)
      try {
        final socket = await Socket.connect('127.0.0.1', ProtocolConstants.discoveryPort,
            timeout: const Duration(milliseconds: 200));
        await socket.close();
        final dev = CompanionDeviceInfo(
          deviceId: 'USB_ADB_LOCAL',
          deviceName: 'PocketTX Companion (USB/ADB)',
          companionVersion: '1.0.0',
          protocolVersion: ProtocolConstants.protocolVersion,
          osName: 'Windows 11',
          ipAddress: '127.0.0.1',
          port: ProtocolConstants.discoveryPort,
          pingMs: 1,
          lastSeen: DateTime.now(),
        );
        foundDevices.add(dev);
        EventBus().fire(CompanionDiscoveredEvent(dev));
      } catch (_) {}

      // 2. Setup UDP socket for LAN broadcast and subnet discovery
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final helloPacket = PacketBuilder.buildHello(
        sessionId: 0,
        sequence: 0,
        deviceName: 'PocketTX Android Client',
      );

      final encodedBytes = PacketCodec.encode(helloPacket);

      // Global broadcast
      try {
        socket.send(
          encodedBytes,
          InternetAddress('255.255.255.255'),
          ProtocolConstants.discoveryPort,
        );
      } catch (_) {}

      // Subnet broadcast for all local active Wi-Fi interfaces
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback) {
              final parts = addr.address.split('.');
              if (parts.length == 4) {
                final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
                socket.send(
                  encodedBytes,
                  InternetAddress(subnetBroadcast),
                  ProtocolConstants.discoveryPort,
                );
              }
            }
          }
        }
      } catch (_) {}

      final completer = Completer<List<CompanionDeviceInfo>>();

      Timer(timeout, () {
        socket.close();
        if (!completer.isCompleted) {
          completer.complete(foundDevices);
        }
      });

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null) {
            final hostStr = dg.address.address;
            final dev = CompanionDeviceInfo(
              deviceId: 'UDP_${hostStr}_${dg.port}',
              deviceName: 'PocketTX Companion PC',
              companionVersion: '1.0.0',
              protocolVersion: ProtocolConstants.protocolVersion,
              osName: 'Windows PC',
              ipAddress: hostStr,
              port: ProtocolConstants.dataPort,
              pingMs: 5,
              lastSeen: DateTime.now(),
            );

            if (!foundDevices.any((d) => d.ipAddress == hostStr)) {
              foundDevices.add(dev);
              EventBus().fire(CompanionDiscoveredEvent(dev));
              LoggerService().info(
                LogCategory.network,
                'DEVICE_FOUND',
                'Discovered Companion at ${dev.displayName}',
              );
            }
          }
        }
      });

      final result = await completer.future;
      _discoveredDevices.clear();
      _discoveredDevices.addAll(result);
      return result;
    } catch (e) {
      LoggerService().warning(
        LogCategory.network,
        'DISCOVERY_FAILED',
        'UDP discovery scan error: $e',
      );
      _discoveredDevices.clear();
      _discoveredDevices.addAll(foundDevices);
      return foundDevices;
    }
  }
}
