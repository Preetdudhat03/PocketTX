import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/icons.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/channel_state.dart';
import '../../../../core/state/connection_state.dart';
import '../../../../widgets/shared/status_badge.dart';
import '../../../../widgets/shared/device_scan_dialog.dart';
import '../../../../core/constants/channel_constants.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionStateProvider);
    final isArmed = ref.watch(isArmedProvider);
    final channels = ref.watch(channelStateProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text('DASHBOARD',
                      style: AppTypography.h3Style(color: context.textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh / Scan Mobile Device Connection',
                    onPressed: () => DeviceScanDialog.show(context),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusBadge(
                    label: connection.statusLabel,
                    variant: connection.isConnected
                        ? BadgeVariant.success
                        : BadgeVariant.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Quick stats row
              Row(
                children: [
                  _StatCard(
                    icon: AppIcons.arm,
                    label: 'STATUS',
                    value: isArmed ? 'ARMED' : 'DISARMED',
                    color: isArmed ? AppColors.accentRed : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.base),
                  _StatCard(
                    icon: AppIcons.throttle,
                    label: 'THROTTLE',
                    value: '${channels.throttlePwm}us',
                    color: AppColors.ch3Throttle,
                  ),
                  const SizedBox(width: AppSpacing.base),
                  _StatCard(
                    icon: AppIcons.signal,
                    label: 'LATENCY',
                    value: '${connection.latencyMs}ms',
                    color: AppColors.accentGreen,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Channel overview
              Text('CHANNELS',
                  style: AppTypography.controlLabelStyle(
                      color: context.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              ...List.generate(ChannelConstants.channelCount, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(ChannelConstants.channelNames[i],
                              style: AppTypography.captionStyle(
                                  color: context.textTertiary)),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (channels.normalized[i] + 1) / 2,
                            color: AppColors.channelColors[i],
                            backgroundColor: context.border,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('${channels.pwm[i]}',
                            style: AppTypography.monoStyle(
                                fontSize: 10,
                                color: AppColors.channelColors[i])),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: AppSpacing.iconSizeSm),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: AppTypography.captionStyle(color: context.textTertiary)),
            Text(value,
                style: AppTypography.monoStyle(
                    fontSize: AppTypography.body, weight: AppTypography.semiBold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
