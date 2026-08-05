// ─────────────────────────────────────────────
// PocketTX – AppSettings Model
// Symmetric with Windows Companion AppSettings.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import '../core/constants/channel_constants.dart';

enum AppThemeMode { dark, light, system }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final int updateRateHz;
  final bool hapticsEnabled;
  final bool devOverlayEnabled;
  final String activeProfileId;
  final bool keepScreenOn;
  final double textScaleFactor;
  final int schemaVersion;

  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.updateRateHz = ChannelConstants.defaultUpdateRateHz,
    this.hapticsEnabled = true,
    this.devOverlayEnabled = false,
    this.activeProfileId = 'preset_default_acro',
    this.keepScreenOn = true,
    this.textScaleFactor = 1.0,
    this.schemaVersion = 1,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? updateRateHz,
    bool? hapticsEnabled,
    bool? devOverlayEnabled,
    String? activeProfileId,
    bool? keepScreenOn,
    double? textScaleFactor,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        updateRateHz: updateRateHz ?? this.updateRateHz,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        devOverlayEnabled: devOverlayEnabled ?? this.devOverlayEnabled,
        activeProfileId: activeProfileId ?? this.activeProfileId,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        textScaleFactor: textScaleFactor ?? this.textScaleFactor,
        schemaVersion: schemaVersion,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'updateRateHz': updateRateHz,
        'hapticsEnabled': hapticsEnabled,
        'devOverlayEnabled': devOverlayEnabled,
        'activeProfileId': activeProfileId,
        'keepScreenOn': keepScreenOn,
        'textScaleFactor': textScaleFactor,
        'schemaVersion': schemaVersion,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values[json['themeMode'] as int? ?? 0],
        updateRateHz: json['updateRateHz'] as int? ?? ChannelConstants.defaultUpdateRateHz,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        devOverlayEnabled: json['devOverlayEnabled'] as bool? ?? false,
        activeProfileId: json['activeProfileId'] as String? ?? 'preset_default_acro',
        keepScreenOn: json['keepScreenOn'] as bool? ?? true,
        textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
        schemaVersion: json['schemaVersion'] as int? ?? 1,
      );

  @override
  List<Object?> get props => [
        themeMode, updateRateHz, hapticsEnabled,
        devOverlayEnabled, activeProfileId, keepScreenOn, textScaleFactor,
      ];
}
