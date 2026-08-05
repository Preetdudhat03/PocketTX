// ─────────────────────────────────────────────
// PocketTX – Theme State (Riverpod)
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';

class ThemeStateNotifier extends StateNotifier<AppThemeMode> {
  ThemeStateNotifier() : super(AppThemeMode.dark);

  void setMode(AppThemeMode mode) => state = mode;

  void toggle() {
    state = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
  }

  ThemeMode get flutterThemeMode => switch (state) {
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.system => ThemeMode.system,
      };
}

final themeStateProvider =
    StateNotifierProvider<ThemeStateNotifier, AppThemeMode>(
  (ref) => ThemeStateNotifier(),
);

/// Convenience provider to get Flutter ThemeMode directly.
final flutterThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeStateProvider.notifier).flutterThemeMode;
});
