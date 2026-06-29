import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/services/background/active_transfer_handle.dart';
import 'package:safe_send/core/services/background/background_execution_service.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// Orchestrates the OS background surfaces from the existing transfer-state
/// stream (the single source of truth — Constitution VIII / FR-005). It owns no
/// parallel progress model: it observes the active transfer's view stream and
/// forwards projections to one platform controller.
///
/// The surface is created as soon as the transfer is **active (transferring)**,
/// while the app is still in the foreground, and kept until the transfer ends.
/// This is required by the platforms: an iOS Live Activity can only be
/// `request()`-ed in the foreground, and an Android 12+ foreground service can
/// only be started while the app is foreground. It is most useful once the user
/// backgrounds/locks (Lock Screen / Dynamic Island / ongoing notification), but
/// it must be started before that happens.
///
/// Core-pure: imports no features. The active transfer is published in via an
/// [ActiveTransferHandle] (additive seam, like #006/#008). At most one surface
/// exists at a time — there is one active transfer (FR-018).
@lazySingleton
class BackgroundTransferCoordinator with WidgetsBindingObserver {
  BackgroundTransferCoordinator(this._controller, this._reminder, this._bgTask)
    : _now = DateTime.now,
      _throttle = const Duration(milliseconds: 500) {
    _subscribeActions();
  }

  /// Test-only constructor: inject a fake clock + throttle window. (The
  /// injectable graph uses the default constructor; a `DateTime Function()`
  /// param can't be resolved as a dependency.)
  @visibleForTesting
  BackgroundTransferCoordinator.forTest(
    this._controller,
    this._reminder,
    this._bgTask, {
    DateTime Function()? now,
    Duration throttle = const Duration(milliseconds: 500),
  }) : _now = now ?? DateTime.now,
       _throttle = throttle {
    _subscribeActions();
  }

  void _subscribeActions() {
    // The controller is a stable singleton; subscribe to its action stream
    // once. A "Huỷ" tap routes to the active transfer's cancel immediately.
    _actionSub = _controller.actions.listen(_onAction);
  }

  final BackgroundSurfaceController _controller;

  /// Used for the iOS keep-app-open reminder (#011): when the app is
  /// backgrounded during an active transfer, schedule a notification nudging the
  /// user to reopen the app (iOS suspends the backgrounded transfer). No-op on
  /// Android (the foreground service keeps it running).
  final IncomingFileNotifier _reminder;

  /// iOS background-task assertion (#011, T032): grabs ~30s of extra runtime
  /// when backgrounded mid-transfer so a brief minimize doesn't drop the
  /// transfer instantly. No-op off iOS.
  final BackgroundExecutionService _bgTask;

  /// Clock (injectable for tests) + minimum interval between surface updates.
  /// Updates push when the percent changes OR [_throttle] has elapsed — so the
  /// surface stays in step with the in-app screen (FR-006) without thrashing
  /// ActivityKit / the notification manager on every raw snapshot (T036).
  final DateTime Function() _now;
  final Duration _throttle;

  ActiveTransferHandle? _handle;
  StreamSubscription<TransferView>? _viewSub;
  StreamSubscription<BackgroundServiceAction>? _actionSub;
  bool _surfaceShowing = false;
  int? _lastPushedPercent;
  DateTime? _lastPushAt;

  /// Published by a Send/Receive feature when a transfer enters `transferring`.
  /// Replaces any prior handle (single active transfer).
  void attach(ActiveTransferHandle handle) {
    detach();
    _handle = handle;
    _viewSub = handle.views.listen(_onView, onError: (_) {});
  }

  /// Cleared by the feature on terminal state / page dispose. Ends any surface.
  void detach() {
    unawaited(_viewSub?.cancel());
    _viewSub = null;
    if (_surfaceShowing) {
      _surfaceShowing = false;
      unawaited(_controller.end());
    }
    unawaited(_reminder.cancelKeepOpenReminder());
    unawaited(_bgTask.end());
    _handle = null;
    _lastPushedPercent = null;
    _lastPushAt = null;
  }

  /// App lifecycle (wired via [WidgetsBindingObserver]). Drives the iOS
  /// keep-app-open reminder + background-task grace — the surface itself is
  /// transfer-driven.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_handle == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Grab the iOS grace window so the transfer survives a brief minimize,
      // and nudge the user to come back before it elapses.
      unawaited(_bgTask.begin());
      unawaited(
        _reminder.scheduleKeepOpenReminder(
          title: _handle!.keepOpenTitle,
          body: _handle!.keepOpenBody,
        ),
      );
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_reminder.cancelKeepOpenReminder());
      unawaited(_bgTask.end());
    }
  }

  void _onView(TransferView view) {
    if (isTerminalPhase(view.phase)) {
      _onTerminal(view);
    } else if (_surfaceShowing) {
      final state = _project(view);
      if (_shouldPush(state)) {
        _recordPush(state);
        unawaited(_safe(() => _controller.update(state)));
      }
    } else if (view.phase == TransferPhase.transferring) {
      unawaited(_startSurface(view));
    }
  }

  /// Start the surface for an active transfer (must run while foreground — see
  /// the class doc). No-op if unsupported (e.g. iOS < 16.1).
  Future<void> _startSurface(TransferView view) async {
    if (_surfaceShowing || _handle == null) return;
    if (!await _controller.isSupported) return;
    if (_surfaceShowing || _handle == null) return; // re-check post-await
    _surfaceShowing = true;
    final state = _project(view);
    _recordPush(state);
    await _safe(() => _controller.start(state));
  }

  /// Push an update when the percent changed OR the throttle window elapsed.
  bool _shouldPush(BackgroundTransferState state) {
    final last = _lastPushAt;
    return _lastPushedPercent == null ||
        state.percent != _lastPushedPercent ||
        last == null ||
        _now().difference(last) >= _throttle;
  }

  void _recordPush(BackgroundTransferState state) {
    _lastPushedPercent = state.percent;
    _lastPushAt = _now();
  }

  void _onTerminal(TransferView view) {
    if (_surfaceShowing) {
      _surfaceShowing = false;
      unawaited(
        _safe(
          () => _controller.update(_project(view)),
        ).then((_) => _safe(_controller.end)),
      );
    }
    unawaited(_reminder.cancelKeepOpenReminder());
    unawaited(_bgTask.end());
    unawaited(_viewSub?.cancel());
    _viewSub = null;
    _handle = null;
    _lastPushedPercent = null;
    _lastPushAt = null;
  }

  void _onAction(BackgroundServiceAction action) {
    if (action == BackgroundServiceAction.cancel) {
      _handle?.onCancel();
    }
  }

  BackgroundTransferState _project(TransferView view) => _handle!.project(view);

  /// Swallow + log surface errors (phase/error-type only — never peer/bytes,
  /// Principle I / FR-014) so a surface failure never blocks the transfer.
  Future<void> _safe(Future<void> Function() op) async {
    try {
      await op();
    } on Object catch (e) {
      AppLogger.warning('background-surface op failed: ${e.runtimeType}');
    }
  }

  @disposeMethod
  void dispose() {
    unawaited(_actionSub?.cancel());
    detach();
  }
}
