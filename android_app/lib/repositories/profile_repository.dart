// ─────────────────────────────────────────────
// PocketTX – ProfileRepository
// Local Hive-backed profile persistence.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/controller_profile.dart';
import 'package:pockettx_app/core/constants/app_constants.dart';
import 'package:pockettx_app/core/services/logger_service.dart';
import '../../models/log_entry_model.dart';

class ProfileRepository {
  static final ProfileRepository _instance = ProfileRepository._internal();
  factory ProfileRepository() => _instance;
  ProfileRepository._internal();

  final _log = LoggerService();
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.profilesBox);
    _log.info(LogCategory.storage, 'ProfileRepository.init', 'Opened profiles box');
  }

  /// Load all profiles. Falls back to built-in presets if empty.
  Future<List<ControllerProfile>> loadAll() async {
    try {
      if (_box.isEmpty) {
        await _seedDefaults();
      }
      return _box.values
          .map((raw) => ControllerProfile.fromJson(
              jsonDecode(raw as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.error(LogCategory.storage, 'ProfileRepository.loadAll', e.toString());
      return BuiltInProfiles.all();
    }
  }

  Future<ControllerProfile?> loadById(String id) async {
    try {
      final raw = _box.get(id) as String?;
      if (raw == null) return null;
      return ControllerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.error(LogCategory.storage, 'ProfileRepository.loadById', e.toString());
      return null;
    }
  }

  Future<void> save(ControllerProfile profile) async {
    try {
      await _box.put(profile.id, jsonEncode(profile.toJson()));
      _log.info(LogCategory.storage, 'ProfileRepository.save', 'Saved: ${profile.name}');
    } catch (e) {
      _log.error(LogCategory.storage, 'ProfileRepository.save', e.toString());
    }
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
      _log.info(LogCategory.storage, 'ProfileRepository.delete', 'Deleted profile: $id');
    } catch (e) {
      _log.error(LogCategory.storage, 'ProfileRepository.delete', e.toString());
    }
  }

  Future<void> _seedDefaults() async {
    for (final p in BuiltInProfiles.all()) {
      await _box.put(p.id, jsonEncode(p.toJson()));
    }
    _log.info(LogCategory.storage, 'ProfileRepository.seed', 'Seeded ${BuiltInProfiles.all().length} default profiles');
  }
}
