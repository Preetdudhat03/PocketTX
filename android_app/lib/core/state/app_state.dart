// ─────────────────────────────────────────────
// PocketTX – App State (Riverpod)
// Top-level app state: settings, armed status, active profile ID.
// ─────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';

class AppState {
  final AppSettings settings;
  final bool isArmed;
  final bool beeperActive;
  final bool isInitialized;
  final String? errorMessage;

  const AppState({
    this.settings = const AppSettings(),
    this.isArmed = false,
    this.beeperActive = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  AppState copyWith({
    AppSettings? settings,
    bool? isArmed,
    bool? beeperActive,
    bool? isInitialized,
    String? errorMessage,
  }) =>
      AppState(
        settings: settings ?? this.settings,
        isArmed: isArmed ?? this.isArmed,
        beeperActive: beeperActive ?? this.beeperActive,
        isInitialized: isInitialized ?? this.isInitialized,
        errorMessage: errorMessage,
      );
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void initialize(AppSettings settings) {
    state = state.copyWith(settings: settings, isInitialized: true);
  }

  void arm() => state = state.copyWith(isArmed: true);
  void disarm() => state = state.copyWith(isArmed: false, beeperActive: false);

  void toggleArmed() {
    if (state.isArmed) {
      disarm();
    } else {
      arm();
    }
  }

  void setBeeperActive(bool active) {
    state = state.copyWith(beeperActive: active);
  }

  void updateSettings(AppSettings settings) {
    state = state.copyWith(settings: settings);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

/// Convenience selectors to minimize rebuilds
final isArmedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider.select((s) => s.isArmed));
});

final appSettingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(appStateProvider.select((s) => s.settings));
});
