// ─────────────────────────────────────────────
// PocketTX – Device Scan & Connection Dialog
// Discovers Windows Companion devices on LAN / USB using UdpDiscoveryService & CompanionDeviceInfo.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/theme_tokens.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/design/radius.dart';
import '../../core/design/icons.dart';
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

  @override
  void initState() {
    super.initState();
    _startScan();
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
              'Searching local network and USB ports for active PocketTX Windows Companion app.',
              style: AppTypography.bodyStyle(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_isScanning)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
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
                      'Ensure Windows Companion is open and on the same Wi-Fi.',
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
    );
  }
}
