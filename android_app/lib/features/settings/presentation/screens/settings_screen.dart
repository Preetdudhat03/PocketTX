import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/icons.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/theme_state.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../models/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final appNotifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SETTINGS',
                  style: AppTypography.h3Style(color: context.textPrimary)),
              const SizedBox(height: AppSpacing.xl),

              // Theme Toggle
              _SettingRow(
                icon: AppIcons.theme,
                label: 'Dark Mode',
                child: Switch(
                  value: settings.themeMode == AppThemeMode.dark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    final mode = v ? AppThemeMode.dark : AppThemeMode.light;
                    appNotifier.updateSettings(settings.copyWith(themeMode: mode));
                    ref.read(themeStateProvider.notifier).setMode(mode);
                  },
                ),
              ),

              // Haptics Toggle
              _SettingRow(
                icon: AppIcons.haptics,
                label: 'Haptic Feedback',
                child: Switch(
                  value: settings.hapticsEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    appNotifier.updateSettings(settings.copyWith(hapticsEnabled: v));
                    HapticService().setEnabled(v);
                  },
                ),
              ),

              // Update Rate
              _SettingRow(
                icon: AppIcons.frequency,
                label: 'Update Rate',
                child: DropdownButton<int>(
                  value: settings.updateRateHz,
                  dropdownColor: context.cardBg,
                  style: AppTypography.bodyStyle(color: context.textPrimary),
                  underline: const SizedBox(),
                  items: const [250, 500, 750, 1000]
                      .map((hz) => DropdownMenuItem(
                            value: hz,
                            child: Text('${hz}Hz'),
                          ))
                      .toList(),
                  onChanged: (hz) {
                    if (hz != null) {
                      appNotifier.updateSettings(
                          settings.copyWith(updateRateHz: hz));
                    }
                  },
                ),
              ),

              // Dev Overlay Toggle
              _SettingRow(
                icon: AppIcons.devOverlay,
                label: 'Dev Overlay',
                child: Switch(
                  value: settings.devOverlayEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    appNotifier.updateSettings(
                        settings.copyWith(devOverlayEnabled: v));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSpacing.iconSizeSm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: AppTypography.bodyStyle(color: context.textPrimary)),
          ),
          child,
        ],
      ),
    );
  }
}
