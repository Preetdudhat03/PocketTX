// ─────────────────────────────────────────────
// PocketTX – Dev Overlay Widget
// Toggleable diagnostic overlay for debug builds.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pockettx_app/core/design/theme_tokens.dart';
import 'package:pockettx_app/core/design/spacing.dart';
import 'package:pockettx_app/core/design/radius.dart';
import 'package:pockettx_app/core/design/typography.dart';
import 'package:pockettx_app/core/state/diagnostics_state.dart';
import 'package:pockettx_app/core/state/app_state.dart';

class DevOverlay extends ConsumerWidget {
  final Widget child;

  const DevOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diag = ref.watch(diagnosticsProvider);
    final isVisible = diag.devOverlayVisible;

    return Stack(
      children: [
        child,
        if (isVisible) const Positioned(top: 8, right: 8, child: _OverlayPanel()),
      ],
    );
  }
}

class _OverlayPanel extends ConsumerWidget {
  const _OverlayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(diagnosticsProvider.select((s) => s.latest));
    final profile = ref.watch(appSettingsProvider).activeProfileId;
    final device = ref.watch(diagnosticsProvider.select((s) => s.deviceInfo));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.92),
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: DefaultTextStyle(
        style: AppTypography.monoStyle(fontSize: 10, color: AppColors.accentGreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('FPS', metrics.fps.toStringAsFixed(1)),
            _row('FRAME', '${metrics.frameTimeMs.toStringAsFixed(2)}ms'),
            _row('RATE', '${metrics.actualUpdateRateHz.toStringAsFixed(0)}Hz'),
            _row('MEM', '${metrics.memoryUsageMb}MB'),
            _row('PROFILE', profile.replaceAll('preset_', '')),
            _row('DEVICE', '${device.model}'),
            _row('REFRESH', device.refreshRateLabel),
          ],
        ),
      ),
    );
  }

  Widget _row(String key, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              child: Text(key,
                  style: AppTypography.monoStyle(
                      fontSize: 10, color: AppColors.darkTextSecondary)),
            ),
            Text(value),
          ],
        ),
      );
}
