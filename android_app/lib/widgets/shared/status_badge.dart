// ─────────────────────────────────────────────
// PocketTX – Status Badge Widget
// Compact pill badge for connection/arm status.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:pockettx_app/core/design/theme_tokens.dart';
import 'package:pockettx_app/core/design/spacing.dart';
import 'package:pockettx_app/core/design/radius.dart';
import 'package:pockettx_app/core/design/typography.dart';

enum BadgeVariant { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final bool pulse;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.pulse = false,
  });

  Color get _color => switch (variant) {
        BadgeVariant.success => AppColors.success,
        BadgeVariant.warning => AppColors.warning,
        BadgeVariant.error => AppColors.error,
        BadgeVariant.info => AppColors.info,
        BadgeVariant.neutral => AppColors.primary,
      };

  Color get _bgColor => _color.withValues(alpha: 0.15);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DotIndicator(color: _color, pulse: pulse),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelStyle(color: _color),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _DotIndicator({required this.color, required this.pulse});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.pulse ? _opacity : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: AppSpacing.statusDotSize,
        height: AppSpacing.statusDotSize,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
