// ─────────────────────────────────────────────
// PocketTX – ARM Button Widget
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/radius.dart';
import '../../../../core/design/icons.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/services/haptic_service.dart';

class ArmButton extends ConsumerWidget {
  final bool isArmed;

  const ArmButton({super.key, required this.isArmed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: isArmed ? 'Armed. Tap to disarm.' : 'Disarmed. Tap to arm.',
      button: true,
      child: GestureDetector(
        onTap: () {
          ref.read(appStateProvider.notifier).toggleArmed();
          HapticService().medium();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: AppSpacing.touchTarget,
          decoration: BoxDecoration(
            color: isArmed
                ? AppColors.accentRed.withValues(alpha: 0.2)
                : AppColors.primaryContainer,
            borderRadius: AppRadius.buttonBorder,
            border: Border.all(
              color: isArmed ? AppColors.accentRed : AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isArmed ? AppIcons.arm : AppIcons.disarm,
                  color: isArmed ? AppColors.accentRed : AppColors.primary,
                  size: AppSpacing.iconSizeSm,
                ),
                const SizedBox(height: 2),
                Text(
                  isArmed ? 'DISARM' : 'ARM',
                  style: AppTypography.controlLabelStyle(
                    color: isArmed ? AppColors.accentRed : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
