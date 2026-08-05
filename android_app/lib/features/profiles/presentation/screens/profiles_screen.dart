import 'package:flutter/material.dart';
import '../../../../core/design/theme_tokens.dart';
import '../../../../core/design/spacing.dart';
import '../../../../core/design/typography.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROFILES',
                  style: AppTypography.h3Style(color: context.textPrimary)),
              const SizedBox(height: AppSpacing.xl),
              Text('Profiles feature coming in next phase.',
                  style: AppTypography.bodyStyle(color: context.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
