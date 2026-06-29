import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:live_activities/live_activities.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// iOS [BackgroundSurfaceController] over `live_activities` (ActivityKit).
///
/// Renders the Live Activity / Dynamic Island from the SwiftUI Widget Extension
/// target (see contracts/live_activity_state.md). The Activity is unsupported on
/// iOS < 16.1 → [isSupported] is false there and the coordinator no-ops the
/// surface, leaving the transfer untouched. The iOS surface has no action
/// buttons, so [actions] is empty (Cancel is Android-only — FR-007/FR-017).
///
/// Native target wiring + first `pod install` are verified on device (T041).
class LiveActivityController implements BackgroundSurfaceController {
  LiveActivityController({required String appGroupId, LiveActivities? plugin})
    : _appGroupId = appGroupId,
      _plugin = plugin ?? LiveActivities();

  /// App Group shared between Runner and the Widget Extension (flavor-specific,
  /// from `AppConfig.liveActivityAppGroupId`).
  final String _appGroupId;

  /// Stable channel id for the single active transfer activity.
  static const _channelId = 'safesend_transfer';

  final LiveActivities _plugin;
  final StreamController<BackgroundServiceAction> _actions =
      StreamController<BackgroundServiceAction>.broadcast();

  bool _inited = false;
  String? _activityId;

  @override
  Stream<BackgroundServiceAction> get actions => _actions.stream;

  @override
  Future<bool> get isSupported async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      await _ensureInit();
      return _plugin.areActivitiesEnabled();
    } on Object catch (e) {
      AppLogger.warning('live-activity isSupported failed: ${e.runtimeType}');
      return false;
    }
  }

  Future<void> _ensureInit() async {
    if (_inited) return;
    await _plugin.init(appGroupId: _appGroupId);
    _inited = true;
    AppLogger.info('live-activity init appGroup=$_appGroupId');
  }

  @override
  Future<void> start(BackgroundTransferState state) async {
    try {
      await _ensureInit();
      _activityId = await _plugin.createActivity(
        _channelId,
        state.toContentState(),
        // We update the activity locally (no server / APNs — Principle I), so
        // disable remote push updates: requesting them needs the Push
        // Notifications capability and makes ActivityKit throw without it.
        iOSEnableRemoteUpdates: false,
        removeWhenAppIsKilled: true,
      );
      AppLogger.info('live-activity started id=${_activityId != null}');
    } on PlatformException catch (e) {
      AppLogger.warning(
        'live-activity start failed: ${e.code} | ${e.message} | ${e.details}',
      );
      rethrow;
    }
  }

  @override
  Future<void> update(BackgroundTransferState state) async {
    final id = _activityId;
    if (id == null) return;
    try {
      await _plugin.updateActivity(id, state.toContentState());
    } on PlatformException catch (e) {
      AppLogger.warning(
        'live-activity update failed: ${e.code} | ${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<void> end() async {
    final id = _activityId;
    _activityId = null;
    if (id == null) return;
    try {
      await _plugin.endActivity(id);
      AppLogger.info('live-activity ended');
    } on PlatformException catch (e) {
      AppLogger.warning('live-activity end failed: ${e.code} | ${e.message}');
    }
  }
}
