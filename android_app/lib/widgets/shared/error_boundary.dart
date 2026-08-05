// ─────────────────────────────────────────────
// PocketTX – Error Boundary Widget
// Isolates failures so they never crash the controller screen.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:pockettx_app/core/design/theme_tokens.dart';
import 'package:pockettx_app/core/design/spacing.dart';
import 'package:pockettx_app/core/design/typography.dart';
import 'package:pockettx_app/core/design/radius.dart';
import 'package:pockettx_app/core/design/icons.dart';

/// Wraps a child widget and catches errors, showing a contained
/// error card instead of crashing the app.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? label;
  final Widget? fallback;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.label,
    this.fallback,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _DefaultFallback(label: widget.label, error: _error!);
    }
    return widget.child;
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      setState(() => _error = null);
    }
  }
}

class _DefaultFallback extends StatelessWidget {
  final String? label;
  final Object error;
  const _DefaultFallback({this.label, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.error, color: AppColors.error, size: AppSpacing.iconSize),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label != null ? '${label!} error' : 'Component error',
                  style: AppTypography.labelStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  error.toString().take(120),
                  style: AppTypography.captionStyle(
                      color: AppColors.error.withValues(alpha: 0.7)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _StringTake on String {
  String take(int n) => length > n ? '${substring(0, n)}…' : this;
}
