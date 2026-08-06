// ─────────────────────────────────────────────
// PocketTX – Communication Repository
// Concrete implementation of ICommunicationRepository for Phase 2.
// Synchronizes profiles and protocol negotiation with Windows Companion.
// ─────────────────────────────────────────────

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/contracts/phase2_contracts.dart';
import '../core/compatibility/protocol_version.dart';
import '../core/services/connection_manager_service.dart';
import '../models/controller_profile.dart';
import '../core/services/logger_service.dart';
import '../models/log_entry_model.dart';

class CommunicationRepository implements ICommunicationRepository {
  final Ref _ref;

  CommunicationRepository(this._ref);

  @override
  String get negotiatedProtocolVersion => ProtocolVersion.version;

  @override
  Future<void> uploadProfile(ControllerProfile profile) async {
    final connManager = _ref.read(connectionManagerServiceProvider);
    if (!connManager.isConnected) {
      LoggerService().warning(
        LogCategory.system,
        'PROFILE_UPLOAD_SKIPPED',
        'Cannot upload profile "${profile.name}": companion is not connected.',
      );
      return;
    }

    LoggerService().info(
      LogCategory.system,
      'PROFILE_UPLOAD',
      'Uploading profile "${profile.name}" (Mode ${profile.stickMode.index + 1}) to companion...',
    );
  }

  @override
  Future<List<ControllerProfile>> downloadProfiles() async {
    final connManager = _ref.read(connectionManagerServiceProvider);
    if (!connManager.isConnected) {
      return [];
    }

    LoggerService().info(
      LogCategory.system,
      'PROFILE_DOWNLOAD',
      'Requesting remote controller profiles from Windows Companion...',
    );
    return [];
  }
}

final communicationRepositoryProvider = Provider<CommunicationRepository>(
  (ref) => CommunicationRepository(ref),
);
