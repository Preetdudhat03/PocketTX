// ─────────────────────────────────────────────
// PocketTX – ControllerProfile Model
// Symmetric with Windows Companion ControllerProfile.
// Includes full profile metadata for versioning.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import 'calibration_data.dart';
import '../core/constants/channel_constants.dart';
import '../core/compatibility/model_versions.dart';

/// Stick mode mapping (same as EdgeTX/OpenTX convention).
enum StickMode {
  mode1, // Right: Throttle+Yaw, Left: Pitch+Roll
  mode2, // Left: Throttle+Yaw, Right: Pitch+Roll (default)
  mode3, // Right: Throttle+Roll, Left: Pitch+Yaw
  mode4, // Left: Throttle+Roll, Right: Pitch+Yaw
}

/// A named RC controller profile with all tuning parameters.
/// Schema version: 1 (see ModelVersions.controllerProfile)
class ControllerProfile extends Equatable {
  final String id;
  final String name;
  final String description;
  final String author;
  final int version;
  final DateTime created;
  final DateTime modified;
  final StickMode stickMode;
  final List<double> expo;      // per-channel expo [0.0 – 1.0]
  final List<double> deadband;  // per-channel deadband [0.0 – 0.2]
  final CalibrationData calibration;
  final int updateRateHz;
  final bool hapticsEnabled;
  final bool isDefault;
  final int schemaVersion;

  const ControllerProfile({
    required this.id,
    required this.name,
    this.description = '',
    this.author = 'PocketTX',
    this.version = 1,
    required this.created,
    required this.modified,
    this.stickMode = StickMode.mode2,
    required this.expo,
    required this.deadband,
    this.calibration = const CalibrationData(),
    this.updateRateHz = ChannelConstants.defaultUpdateRateHz,
    this.hapticsEnabled = true,
    this.isDefault = false,
    this.schemaVersion = 1,
  });

  /// Creates a factory-default profile with linear response.
  factory ControllerProfile.defaultProfile({
    required String id,
    required String name,
    String description = '',
    double expo = ChannelConstants.defaultExpo,
    double deadband = ChannelConstants.defaultDeadband,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return ControllerProfile(
      id: id,
      name: name,
      description: description,
      created: now,
      modified: now,
      expo: List.filled(ChannelConstants.channelCount, expo),
      deadband: List.filled(ChannelConstants.channelCount, deadband),
      isDefault: isDefault,
    );
  }

  ControllerProfile copyWith({
    String? name,
    String? description,
    String? author,
    StickMode? stickMode,
    List<double>? expo,
    List<double>? deadband,
    CalibrationData? calibration,
    int? updateRateHz,
    bool? hapticsEnabled,
  }) {
    return ControllerProfile(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      version: version + 1,
      created: created,
      modified: DateTime.now(),
      stickMode: stickMode ?? this.stickMode,
      expo: expo ?? this.expo,
      deadband: deadband ?? this.deadband,
      calibration: calibration ?? this.calibration,
      updateRateHz: updateRateHz ?? this.updateRateHz,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      isDefault: isDefault,
      schemaVersion: ModelVersions.controllerProfile,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'author': author,
        'version': version,
        'created': created.toIso8601String(),
        'modified': modified.toIso8601String(),
        'stickMode': stickMode.index,
        'expo': expo,
        'deadband': deadband,
        'calibration': calibration.toJson(),
        'updateRateHz': updateRateHz,
        'hapticsEnabled': hapticsEnabled,
        'isDefault': isDefault,
        'schemaVersion': schemaVersion,
      };

  factory ControllerProfile.fromJson(Map<String, dynamic> json) {
    return ControllerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'PocketTX',
      version: json['version'] as int? ?? 1,
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      stickMode: StickMode.values[json['stickMode'] as int? ?? 1],
      expo: (json['expo'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
          List.filled(ChannelConstants.channelCount, ChannelConstants.defaultExpo),
      deadband: (json['deadband'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
          List.filled(ChannelConstants.channelCount, ChannelConstants.defaultDeadband),
      calibration: json['calibration'] != null
          ? CalibrationData.fromJson(json['calibration'] as Map<String, dynamic>)
          : const CalibrationData(),
      updateRateHz: json['updateRateHz'] as int? ?? ChannelConstants.defaultUpdateRateHz,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, name, version, stickMode, expo, deadband];
}

/// Six built-in EdgeTX-style preset profiles.
abstract final class BuiltInProfiles {
  static List<ControllerProfile> all() => [
        ControllerProfile.defaultProfile(
          id: 'preset_default_acro',
          name: 'Default Acro',
          description: 'Standard acrobatic FPV profile. Mode 2, 30% expo.',
          expo: 0.3,
          deadband: 0.02,
          isDefault: true,
        ),
        ControllerProfile.defaultProfile(
          id: 'preset_indoor',
          name: 'Indoor',
          description: 'Tight deadband and low expo for precise indoor flying.',
          expo: 0.15,
          deadband: 0.015,
        ),
        ControllerProfile.defaultProfile(
          id: 'preset_liftoff',
          name: 'Liftoff',
          description: 'Tuned for Liftoff simulator. High expo for cinematic feel.',
          expo: 0.5,
          deadband: 0.03,
        ),
        ControllerProfile.defaultProfile(
          id: 'preset_velocidrone',
          name: 'Velocidrone',
          description: 'Racing profile for Velocidrone simulator.',
          expo: 0.2,
          deadband: 0.02,
        ),
        ControllerProfile.defaultProfile(
          id: 'preset_fpv_skydive',
          name: 'FPV SkyDive',
          description: 'Gentle expo for wing/glider simulation.',
          expo: 0.45,
          deadband: 0.04,
        ),
        ControllerProfile.defaultProfile(
          id: 'preset_picasim',
          name: 'PicaSim',
          description: 'Classic fixed-wing profile for PicaSim.',
          expo: 0.35,
          deadband: 0.03,
        ),
      ];
}
