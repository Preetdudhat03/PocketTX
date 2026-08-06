// ─────────────────────────────────────────────
// PocketTX – Device Scan & Connection Dialog
// Discovers Windows Companion devices on LAN / USB using UdpDiscoveryService & CompanionDeviceInfo.
// Supports both Automatic Discovery & Direct Manual IP Entry.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/theme_tokens.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/design/radius.dart';
import '../../core/design/icons.dart';
import '../../core/protocol/protocol_constants.dart';
import '../../services/communication/udp_discovery_service.dart';
import '../../services/communication/companion_service.dart';
import '../../services/communication/connection_state_machine.dart';

class DeviceScanDialog extends ConsumerStatefulWidget {
  const DeviceScanDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const DeviceScanDialog(),
    );
  }

  @override
  ConsumerState<DeviceScanDialog> createState() => _DeviceScanDialogState();
}

class _DeviceScanDialogState extends ConsumerState<DeviceScanDialog> {
  bool _isScanning = false;
  List<CompanionDeviceInfo> _foundDevices = [];
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: '192.168.29.48');
    _startScan();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    final companionService = ref.read(companionServiceProvider);
    final devices = await companionService.scanDevices();

    if (mounted) {
      setState(() {
        _foundDevices = devices;
        _isScanning = false;
      });
    }
  }

  Future<void> _connectTo(CompanionDeviceInfo device) async {
    final companionService = ref.read(companionServiceProvider);
    final success = await companionService.connectToCompanion(device);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected to ${device.displayName}!'
                : 'Connection failed. Verify Windows Companion is running.',
          ),
          backgroundColor: success ? AppColors.accentGreen : AppColors.error,
        ),
      );
    }
  }

  void _connectManualIp() {
    final rawIp = _ipController.text.trim();
    if (rawIp.isEmpty) return;

    final manualDev = CompanionDeviceInfo(
      deviceId: 'MANUAL_$rawIp',
      deviceName: 'PocketTX Companion (Manual IP)',
      companionVersion: '1.0.0',
      protocolVersion: ProtocolConstants.protocolVersion,
      osName: 'Windows PC',
      ipAddress: rawIp,
      port: ProtocolConstants.discoveryPort,
      pingMs: 1,
      lastSeen: DateTime.now(),
    );

    _connectTo(manualDev);
  }

  @override
  Widget build(BuildContext context) {
    final currentConn = ref.watch(connectionStateMachineProvider);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
        side: BorderSide(color: context.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(AppIcons.signal, color: AppColors.primary, size: AppSpacing.iconSizeLg),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'COMPANION DISCOVERY',
                    style: AppTypography.h3Style(color: context.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),

              Text(
                'Search local network / USB ports, or enter your PC IP address directly.',
                style: AppTypography.bodyStyle(color: context.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_isScanning)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text('Scanning UDP Broadcast & USB ports...'),
                      ],
                    ),
                  ),
                )
              else if (_foundDevices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: context.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'No companion device automatically detected.',
                        style: AppTypography.bodyStyle(color: AppColors.accentOrange),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'You can connect directly by entering your PC IP below.',
                        style: AppTypography.captionStyle(color: context.textTertiary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _foundDevices
                      .map(
                        (dev) => Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: context.background,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: context.border),
                          ),
                          child: ListTile(
                            leading: Icon(
                              dev.ipAddress == '127.0.0.1' ? Icons.usb : Icons.wifi,
                              color: AppColors.accentCyan,
                            ),
                            title: Text(dev.displayName, style: AppTypography.bodyStyle(color: context.textPrimary)),
                            subtitle: Text('Ping: ${dev.pingMs}ms | OS: ${dev.osName}',
                                style: AppTypography.captionStyle(color: context.textTertiary)),
                            trailing: ElevatedButton(
                              onPressed: () => _connectTo(dev),
                              child: const Text('CONNECT'),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // Manual IP Input Section
              Text(
                'MANUAL DIRECT IP CONNECTION',
                style: AppTypography.captionStyle(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        hintText: 'e.g. 192.168.29.48 or 127.0.0.1',
                        prefixIcon: const Icon(Icons.computer),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      style: AppTypography.bodyStyle(color: context.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _connectManualIp,
                    icon: const Icon(Icons.bolt),
                    label: const Text('CONNECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action Row
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isScanning ? null : _startScan,
                    icon: const Icon(Icons.refresh),
                    label: const Text('REFRESH SCAN'),
                  ),
                  const Spacer(),
                  if (currentConn.isConnected)
                    TextButton(
                      onPressed: () async {
                        await ref.read(companionServiceProvider).disconnect();
                        if (mounted) Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('DISCONNECT'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
