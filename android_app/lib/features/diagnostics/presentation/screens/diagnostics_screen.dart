import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/icons.dart';
import '../../../../core/state/diagnostics_state.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diag = ref.watch(diagnosticsProvider);
    final metrics = diag.latest;
    final device = diag.deviceInfo;

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('DIAGNOSTICS',
                      style: AppTypography.h3Style(color: context.textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(AppIcons.devOverlay,
                        color: diag.devOverlayVisible
                            ? AppColors.primary
                            : context.textTertiary),
                    onPressed: () =>
                        ref.read(diagnosticsProvider.notifier).toggleDevOverlay(),
                    tooltip: 'Toggle Dev Overlay',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),

              // Metrics grid
              Row(
                children: [
                  _MetricCard(
                      icon: AppIcons.fps,
                      label: 'FPS',
                      value: metrics.fps.toStringAsFixed(1),
                      color: AppColors.accentGreen),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                      icon: AppIcons.timer,
                      label: 'FRAME',
                      value: '${metrics.frameTimeMs.toStringAsFixed(2)}ms',
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                      icon: AppIcons.frequency,
                      label: 'RATE',
                      value: '${metrics.actualUpdateRateHz.toStringAsFixed(0)}Hz',
                      color: AppColors.accentCyan),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                      icon: AppIcons.memory,
                      label: 'MEM',
                      value: '${metrics.memoryUsageMb}MB',
                      color: AppColors.accentAmber),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('DEVICE INFO',
                  style: AppTypography.controlLabelStyle(
                      color: context.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow('Model', device.displayName),
              _InfoRow('Android', device.androidVersion),
              _InfoRow('Refresh', device.refreshRateLabel),
              _InfoRow('DPI', '${device.displayDpi.round()}'),
              _InfoRow('Physical', device.isPhysicalDevice ? 'Yes' : 'Emulator'),

              const SizedBox(height: AppSpacing.xl),
              Text('History: ${diag.history.length} samples',
                  style: AppTypography.captionStyle(color: context.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSpacing.iconSizeSm),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: AppTypography.captionStyle(color: context.textTertiary)),
            Text(value,
                style: AppTypography.monoStyle(
                    fontSize: AppTypography.body, color: color)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String key;
  final String value;
  const _InfoRow(this.key, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(key,
                  style: AppTypography.captionStyle(color: context.textTertiary)),
            ),
            Text(value,
                style: AppTypography.bodyStyle(color: context.textSecondary)),
          ],
        ),
      );
}
