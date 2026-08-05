// ─────────────────────────────────────────────
// PocketTX – App Router (GoRouter)
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/controller/presentation/screens/controller_screen.dart';
import '../features/profiles/presentation/screens/profiles_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/diagnostics/presentation/screens/diagnostics_screen.dart';
import '../features/logs/presentation/screens/logs_screen.dart';

abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String controller = '/controller';
  static const String profiles = '/profiles';
  static const String settings = '/settings';
  static const String diagnostics = '/diagnostics';
  static const String logs = '/logs';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.controller,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      pageBuilder: (ctx, state) => _fade(ctx, state, const DashboardScreen()),
    ),
    GoRoute(
      path: AppRoutes.controller,
      name: 'controller',
      pageBuilder: (ctx, state) => _fade(ctx, state, const ControllerScreen()),
    ),
    GoRoute(
      path: AppRoutes.profiles,
      name: 'profiles',
      pageBuilder: (ctx, state) => _fade(ctx, state, const ProfilesScreen()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (ctx, state) => _fade(ctx, state, const SettingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.diagnostics,
      name: 'diagnostics',
      pageBuilder: (ctx, state) => _fade(ctx, state, const DiagnosticsScreen()),
    ),
    GoRoute(
      path: AppRoutes.logs,
      name: 'logs',
      pageBuilder: (ctx, state) => _fade(ctx, state, const LogsScreen()),
    ),
  ],
);

CustomTransitionPage<void> _fade(
  BuildContext context,
  GoRouterState state,
  Widget child,
) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
