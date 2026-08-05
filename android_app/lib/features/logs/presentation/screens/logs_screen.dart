import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/design/icons.dart';
import '../../../../core/design/radius.dart';
import '../../../../models/log_entry_model.dart';
import '../../../../core/bootstrap/dependency_injection.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  LogLevel? _filterLevel;
  LogCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final allEntries = DependencyInjection.logRepository.getAll();
    final filtered = allEntries.where((e) {
      if (_filterLevel != null && e.level != _filterLevel) return false;
      if (_filterCategory != null && e.category != _filterCategory) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Text('LOGS',
                      style: AppTypography.h3Style(color: context.textPrimary)),
                  const Spacer(),
                  Text('${filtered.length} / ${allEntries.length}',
                      style: AppTypography.captionStyle(
                          color: context.textTertiary)),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: Icon(AppIcons.clearLog, color: context.textTertiary),
                    onPressed: () {
                      DependencyInjection.logRepository.clear();
                      setState(() {});
                    },
                    tooltip: 'Clear logs',
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                children: [
                  _FilterChip(
                    label: 'ALL',
                    selected: _filterLevel == null,
                    onTap: () => setState(() => _filterLevel = null),
                  ),
                  ...LogLevel.values.map((l) => _FilterChip(
                        label: l.name.toUpperCase(),
                        selected: _filterLevel == l,
                        color: _levelColor(l),
                        onTap: () => setState(() => _filterLevel = l),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Log list
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final entry = filtered[filtered.length - 1 - i];
                  return _LogRow(entry: entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(LogLevel level) => switch (level) {
        LogLevel.info => AppColors.primary,
        LogLevel.warning => AppColors.warning,
        LogLevel.error => AppColors.error,
        LogLevel.debug => AppColors.accentCyan,
        LogLevel.verbose => AppColors.darkTextTertiary,
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs2),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.2) : context.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
              color: selected ? c : context.border, width: 1),
        ),
        child: Text(label,
            style: AppTypography.labelStyle(
                color: selected ? c : context.textTertiary)),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  Color _levelColor() => switch (entry.level) {
        LogLevel.info => AppColors.primary,
        LogLevel.warning => AppColors.warning,
        LogLevel.error => AppColors.error,
        LogLevel.debug => AppColors.accentCyan,
        LogLevel.verbose => AppColors.darkTextTertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.formattedTime,
              style: AppTypography.monoStyle(
                  fontSize: 9, color: context.textTertiary)),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: _levelColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(entry.levelLabel,
                style: AppTypography.monoStyle(
                    fontSize: 9, color: _levelColor())),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.monoStyle(
                    fontSize: 10, color: context.textSecondary),
                children: [
                  TextSpan(
                      text: '${entry.event}: ',
                      style: AppTypography.monoStyle(
                          fontSize: 10, color: context.textPrimary)),
                  TextSpan(text: entry.message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
