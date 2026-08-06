// ─────────────────────────────────────────────
// PocketTX – Controller Screen
// The main RC transmitter interface.
// Dual 2D gimbals + 8 channel bars + ARM/BEEPER.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/icons.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/channel_state.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../widgets/shared/dev_overlay.dart';
import '../../../../widgets/shared/status_badge.dart';
import '../widgets/gimbal_widget.dart';
import '../widgets/channel_bar.dart';
import '../widgets/arm_button.dart';

class ControllerScreen extends ConsumerStatefulWidget {
  const ControllerScreen({super.key});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen> {
  @override
  Widget build(BuildContext context) {
    final isArmed = ref.watch(isArmedProvider);
    final channels = ref.watch(channelStateProvider);
    final size = MediaQuery.sizeOf(context);

    return DevOverlay(
      child: Scaffold(
        backgroundColor: context.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────
              _TopBar(isArmed: isArmed),

              // ── Main Controller Area ─────────────────
              Expanded(
                child: Row(
                  children: [
                    // Left Gimbal (Throttle + Yaw in Mode 2)
                    SizedBox(
                      width: size.width * 0.28,
                      child: Center(
                        child: GimbalWidget(
                          isLeft: true,
                          semanticLabel: 'Left gimbal: Throttle and Yaw',
                        ),
                      ),
                    ),

                    // Center: Channel bars
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ARM / BEEPER buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ArmButton(isArmed: isArmed),
                                _BeeperButton(),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.base),
                            // 8 Channel Bars
                            ...List.generate(ChannelConstants.channelCount, (i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs),
                                child: ChannelBar(
                                  channelIndex: i,
                                  value: channels.normalized[i],
                                  pwm: channels.pwm[i],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Right Gimbal (Pitch + Roll in Mode 2)
                    SizedBox(
                      width: size.width * 0.28,
                      child: Center(
                        child: GimbalWidget(
                          isLeft: false,
                          semanticLabel: 'Right gimbal: Pitch and Roll',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom Nav ───────────────────────────
              const _BottomNav(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isArmed;
  const _TopBar({required this.isArmed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'POCKETTX',
            style: AppTypography.controlLabelStyle(color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'LOCAL TEST MODE',
            style: AppTypography.controlLabelStyle(
                color: AppColors.darkTextTertiary),
          ),
          const Spacer(),
          StatusBadge(
            label: isArmed ? 'ARMED' : 'DISARMED',
            variant: isArmed ? BadgeVariant.warning : BadgeVariant.neutral,
            pulse: isArmed,
          ),
        ],
      ),
    );
  }
}

class _BeeperButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beeperOn = ref.watch(appStateProvider.select((s) => s.beeperActive));
    final notifier = ref.read(appStateProvider.notifier);

    return Semantics(
      label: beeperOn ? 'Beeper active, tap to deactivate' : 'Tap to activate beeper',
      button: true,
      child: GestureDetector(
        onTap: () => notifier.setBeeperActive(!beeperOn),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: AppSpacing.touchTarget,
          height: AppSpacing.touchTarget,
          decoration: BoxDecoration(
            color: beeperOn
                ? AppColors.accentAmber.withValues(alpha: 0.2)
                : context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(
              color: beeperOn ? AppColors.accentAmber : context.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            beeperOn ? AppIcons.beeper : AppIcons.beeperOff,
            color: beeperOn ? AppColors.accentAmber : context.textSecondary,
            size: AppSpacing.iconSize,
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: AppIcons.dashboard, label: 'DASH', route: '/'),
          _NavItem(icon: AppIcons.controller, label: 'FLY', route: '/controller', active: true),
          _NavItem(icon: AppIcons.profiles, label: 'PROFILES', route: '/profiles'),
          _NavItem(icon: AppIcons.settings, label: 'SETTINGS', route: '/settings'),
          _NavItem(icon: AppIcons.diagnostics, label: 'DIAG', route: '/diagnostics'),
          _NavItem(icon: AppIcons.logs, label: 'LOGS', route: '/logs'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : context.textTertiary;
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: () {
          if (!active) Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSpacing.iconSizeSm, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTypography.captionStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
