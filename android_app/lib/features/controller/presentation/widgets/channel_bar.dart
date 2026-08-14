// ─────────────────────────────────────────────
// PocketTX – Channel Bar Widget
// Displays a single PWM channel with label and value.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/radius.dart';
import '../../../../core/constants/channel_constants.dart';

class ChannelBar extends StatelessWidget {
  final int channelIndex;
  final double value;   // normalized -1.0 to +1.0
  final int pwm;        // 1000–2000us

  const ChannelBar({
    super.key,
    required this.channelIndex,
    required this.value,
    required this.pwm,
  });

  Color get _color => AppColors.channelColors[channelIndex];
  String get _label => ChannelConstants.channelNames[channelIndex];

  @override
  Widget build(BuildContext context) {
    // Fill fraction: map -1.0..+1.0 to 0.0..1.0
    final fill = ((value + 1.0) / 2.0).clamp(0.0, 1.0);

    return Semantics(
      label: '$_label channel: ${pwm}us',
      child: Row(
        children: [
          // Label
          Flexible(
            flex: 0,
            child: SizedBox(
              width: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _label,
                  style: AppTypography.controlLabelStyle(color: context.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Bar track
          Expanded(
            child: Stack(
              children: [
                // Track background
                Container(
                  height: AppSpacing.channelBarHeight,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: AppSpacing.channelBarHeight,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: AppRadius.pillBorder,
                      boxShadow: [
                        BoxShadow(
                          color: _color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // Center marker
                Positioned(
                  left: null,
                  right: null,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      height: AppSpacing.channelBarHeight,
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 1,
                        color: context.borderSubtle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // PWM value
          Flexible(
            flex: 0,
            child: SizedBox(
              width: 36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '$pwm',
                  style: AppTypography.monoStyle(
                      fontSize: AppTypography.caption, color: _color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
