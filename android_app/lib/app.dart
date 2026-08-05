// ─────────────────────────────────────────────
// PocketTX – Application Root Widget
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/state/theme_state.dart';
import 'app_router.dart';

class PocketTxApp extends ConsumerWidget {
  const PocketTxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(flutterThemeModeProvider);

    return MaterialApp.router(
      title: 'PocketTX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
