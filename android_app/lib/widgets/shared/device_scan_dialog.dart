// ─────────────────────────────────────────────
// PocketTX – Device Scan & Connection Dialog
// Discovers Windows Companion devices on LAN / USB / ADB.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/theme_tokens.dart';
import '../../core/design/spacing.dart';
import '../../core/design/typography.dart';
import '../../core/design/radius.dart';
import '../../core/design/icons.dart';
import '../../core/compatibility/protocol_version.dart';
import '../../core/services/connection_manager_service.dart';
import '../../core/state/connection_state.dart';

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
  List<String> _foundDevices = [];
  final TextEditingController _customIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _customIpController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    final connManager = ref.read(connectionManagerServiceProvider);
    final devices = await connManager.scanDevices();

    if (mounted) {
      setState(() {
        _foundDevices = devices;
        _isScanning = false;
      });
    }
  }

  Future<void> _connectTo(String deviceString) async {
    final connManager = ref.read(connectionManagerServiceProvider);
    ConnectionType type = ConnectionType.wifi;
    String? host;

    if (deviceString.contains('127.0.0.1') || deviceString.contains('USB')) {
      type = ConnectionType.adb;
      host = '127.0.0.1';
    } else {
      type = ConnectionType.wifi;
      final match = RegExp(r'\((.*?)\)').firstMatch(deviceString);
      if (match != null) {
        final rawHostPort = match.group(1)!;
        host = rawHostPort.split(':').first;
      }
    }

    final success = await connManager.connect(type, targetHost: host);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected to companion endpoint!'
                : 'Connection failed. Please verify Windows Companion is running.',
          ),
          backgroundColor: success ? AppColors.accentGreen : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentConn = ref.watch(connectionStateProvider);

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

            // Scan indicator / device list
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
                            dev.contains('USB') ? Icons.usb : Icons.wifi,
                            color: AppColors.accentCyan,
                          ),
                          title: Text(dev, style: AppTypography.bodyStyle(color: context.textPrimary)),
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
                      await ref.read(connectionManagerServiceProvider).disconnect();
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
