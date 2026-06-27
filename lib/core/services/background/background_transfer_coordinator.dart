import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/services/background/active_transfer_handle.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// Orchestrates the OS background surfaces from the existing transfer-state
/// stream (the single source of truth — Constitution VIII / FR-005). It owns no
/// parallel progress model: it observes app lifecycle + the active transfer's
/// view stream and forwards projections to one platform controller.
///
/// Core-pure: imports no features. The active transfer is published in via an
/// [ActiveTransferHandle] (additive seam, like #006/#008). At most one surface
/// exists at a time — there is one active transfer (FR-018).
@lazySingleton
class BackgroundTransferCoordinator with WidgetsBindingObserver {
  BackgroundTransferCoordinator(
    this._controller, {
    DateTime Function()? now,
    Duration throttle = const Duration(milliseconds: 500),
  }) : _now = now ?? DateTime.now,
       _throttle = throttle {
    // The controller is a stable singleton; subscribe to its action stream
    // once. A "Huỷ" tap routes to the active transfer's cancel immediately.
    _actionSub = _controller.actions.listen(_onAction);
  }

  final BackgroundSurfaceController _controller;

  /// Clock (injectable for tests) + minimum interval between surface updates.
  /// Updates push when the percent changes OR [_throttle] has elapsed — so the
  /// surface stays in step with the in-app screen (FR-006) without thrashing
  /// ActivityKit / the notification manager on every raw snapshot (T036).
  final DateTime Function() _now;
  final Duration _throttle;

  ActiveTransferHandle? _handle;
  StreamSubscription<TransferView>? _viewSub;
  StreamSubscription<BackgroundServiceAction>? _actionSub;
  TransferView? _lastView;
  bool _surfaceShowing = false;
  bool _isBackground = false;
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
    _handle = null;
    _lastView = null;
    _lastPushedPercent = null;
    _lastPushAt = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      onAppLifecycleChanged(state);

  /// Forwarded from [didChangeAppLifecycleState]; idempotent. Public so tests
  /// can drive lifecycle transitions directly.
  void onAppLifecycleChanged(AppLifecycleState state) {
    final wasBackground = _isBackground;
    _isBackground =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (_isBackground && !wasBackground) {
      unawaited(_maybeStartSurface());
    } else if (!_isBackground && wasBackground) {
      // Foreground takes over; the in-app screen renders the same state.
      _endSurfaceIfShowing();
    }
  }

  void _onView(TransferView view) {
    _lastView = view;
    if (isTerminalPhase(view.phase)) {
      _onTerminal(view);
    } else if (_surfaceShowing) {
      final state = _project(view);
      if (_shouldPush(state)) {
        _recordPush(state);
        unawaited(_safe(() => _controller.update(state)));
      }
    } else if (_isBackground) {
      unawaited(_maybeStartSurface());
    }
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

  Future<void> _maybeStartSurface() async {
    final view = _lastView;
    final handle = _handle;
    if (_surfaceShowing || handle == null || view == null) return;
    if (view.phase != TransferPhase.transferring) return;
    if (!await _controller.isSupported) {
      // e.g. iOS < 16.1 — degrade silently; transfer logic untouched.
      return;
    }
    if (_surfaceShowing || _handle == null) return; // re-check post-await
    _surfaceShowing = true;
    final state = _project(view);
    _recordPush(state);
    await _safe(() => _controller.start(state));
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
    unawaited(_viewSub?.cancel());
    _viewSub = null;
    _handle = null;
    _lastView = null;
  }

  void _endSurfaceIfShowing() {
    if (!_surfaceShowing) return;
    _surfaceShowing = false;
    unawaited(_safe(_controller.end));
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
