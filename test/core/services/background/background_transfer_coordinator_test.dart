import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/services/background/active_transfer_handle.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_coordinator.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';

/// In-memory [BackgroundSurfaceController] recording the calls the coordinator
/// makes (no plugins / no platform).
class _FakeController implements BackgroundSurfaceController {
  final StreamController<BackgroundServiceAction> _actions =
      StreamController<BackgroundServiceAction>.broadcast();
  final List<String> calls = <String>[];
  bool supported = true;
  bool throwOnStart = false;

  @override
  Future<bool> get isSupported async => supported;

  @override
  Future<void> start(BackgroundTransferState state) async {
    calls.add('start');
    if (throwOnStart) throw Exception('boom');
  }

  @override
  Future<void> update(BackgroundTransferState state) async =>
      calls.add('update');

  @override
  Future<void> end() async => calls.add('end');

  @override
  Stream<BackgroundServiceAction> get actions => _actions.stream;

  void emitCancel() => _actions.add(BackgroundServiceAction.cancel);
}

TransferView _view(TransferPhase phase, {double progress = 0}) => TransferView(
  phase: phase,
  role: TransferRole.sender,
  overallProgress: progress,
  fileCount: 3,
);

BackgroundTransferState _state(int percent) => BackgroundTransferState(
  direction: TransferDirection.sent,
  peerName: 'peer',
  fileCount: 3,
  phase: BackgroundPhase.transferring,
  percent: percent,
  title: 't',
  peerLine: 'p',
  speedLabel: 's',
  bytesLabel: 'b',
  etaLabel: 'e',
  cancelLabel: 'Huỷ',
);

void main() {
  late _FakeController controller;
  late StreamController<TransferView> views;
  late BackgroundTransferCoordinator coordinator;
  var cancelled = 0;
  // Controllable clock so the update-throttle (T036) is deterministic.
  var clock = DateTime(2026);

  ActiveTransferHandle handle() => ActiveTransferHandle(
    views: views.stream,
    direction: TransferDirection.sent,
    progressRoute: '/send/progress',
    onCancel: () => cancelled++,
    // Percent tracks the view so the throttle (percent-delta) is exercised.
    project: (view) => _state((view.overallProgress * 100).round()),
  );

  setUp(() {
    controller = _FakeController();
    views = StreamController<TransferView>.broadcast();
    clock = DateTime(2026);
    coordinator = BackgroundTransferCoordinator(controller, now: () => clock);
    cancelled = 0;
  });

  tearDown(() async {
    coordinator.dispose();
    await views.close();
  });

  test('starts a surface only when backgrounded while transferring', () async {
    coordinator.attach(handle());
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    // Still foreground → no surface yet.
    expect(controller.calls, isEmpty);

    coordinator.onAppLifecycleChanged(AppLifecycleState.paused);
    await pumpEventQueue();
    expect(controller.calls, contains('start'));
  });

  test('updates the surface as progress advances while showing', () async {
    coordinator
      ..attach(handle())
      ..onAppLifecycleChanged(AppLifecycleState.paused);
    views.add(_view(TransferPhase.transferring, progress: 0.30));
    await pumpEventQueue();
    views.add(_view(TransferPhase.transferring, progress: 0.60));
    await pumpEventQueue();
    expect(controller.calls.where((c) => c == 'update'), isNotEmpty);
  });

  test(
    'throttles repeated same-percent snapshots within the window (T036)',
    () async {
      coordinator
        ..attach(handle())
        ..onAppLifecycleChanged(AppLifecycleState.paused);
      views.add(_view(TransferPhase.transferring, progress: 0.30));
      await pumpEventQueue();
      // Two more snapshots at the SAME percent, no time advance → throttled.
      views
        ..add(_view(TransferPhase.transferring, progress: 0.30))
        ..add(_view(TransferPhase.transferring, progress: 0.30));
      await pumpEventQueue();
      expect(controller.calls.where((c) => c == 'update'), isEmpty);
    },
  );

  test(
    'pushes a same-percent snapshot once the throttle window elapses (T036)',
    () async {
      coordinator
        ..attach(handle())
        ..onAppLifecycleChanged(AppLifecycleState.paused);
      views.add(_view(TransferPhase.transferring, progress: 0.30));
      await pumpEventQueue();
      clock = clock.add(const Duration(milliseconds: 600));
      views.add(_view(TransferPhase.transferring, progress: 0.30));
      await pumpEventQueue();
      expect(controller.calls.where((c) => c == 'update'), isNotEmpty);
    },
  );

  test('ends + dismisses the surface on a terminal snapshot', () async {
    coordinator
      ..attach(handle())
      ..onAppLifecycleChanged(AppLifecycleState.paused);
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    views.add(_view(TransferPhase.done));
    await pumpEventQueue();
    expect(controller.calls.last, 'end');
  });

  test('ends the surface when the app returns to the foreground', () async {
    coordinator
      ..attach(handle())
      ..onAppLifecycleChanged(AppLifecycleState.paused);
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    coordinator.onAppLifecycleChanged(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(controller.calls, contains('end'));
  });

  test(
    'rapid background/foreground toggles create at most one surface (FR-018)',
    () async {
      coordinator.attach(handle());
      views.add(_view(TransferPhase.transferring));
      await pumpEventQueue();
      coordinator
        ..onAppLifecycleChanged(AppLifecycleState.paused)
        ..onAppLifecycleChanged(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(controller.calls.where((c) => c == 'start').length, 1);
    },
  );

  test(
    'Android Cancel action routes immediately to onCancel (no confirm)',
    () async {
      coordinator.attach(handle());
      controller.emitCancel();
      await pumpEventQueue();
      expect(cancelled, 1);
    },
  );

  test('unsupported platform (e.g. iOS < 16.1) shows no surface', () async {
    controller.supported = false;
    coordinator
      ..attach(handle())
      ..onAppLifecycleChanged(AppLifecycleState.paused);
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    expect(controller.calls, isEmpty);
  });

  test(
    'a controller failure never blocks the transfer (FR-019/degradation)',
    () async {
      controller.throwOnStart = true;
      coordinator
        ..attach(handle())
        ..onAppLifecycleChanged(AppLifecycleState.paused);
      views.add(_view(TransferPhase.transferring));
      await pumpEventQueue();
      // The throwing start was swallowed; subsequent views keep flowing.
      views.add(_view(TransferPhase.transferring));
      await pumpEventQueue();
      expect(controller.calls, contains('start'));
      // No exception propagated out of the coordinator.
    },
  );
}
