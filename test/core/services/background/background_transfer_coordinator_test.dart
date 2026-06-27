import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/services/background/active_transfer_handle.dart';
import 'package:safe_send/core/services/background/background_execution_service.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_coordinator.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart';

/// Records iOS background-task assertions.
class _FakeBgTask implements BackgroundExecutionService {
  int began = 0;
  int ended = 0;
  @override
  Future<void> begin() async => began++;
  @override
  Future<void> end() async => ended++;
}

/// Records keep-open reminder scheduling without touching the OS.
class _FakeReminder implements IncomingFileNotifier {
  int scheduled = 0;
  int cancelled = 0;

  @override
  Future<void> init({void Function()? onTap}) async {}
  @override
  Future<void> showIncoming({required String senderName}) async {}
  @override
  Future<void> scheduleKeepOpenReminder({
    required String title,
    required String body,
    int afterSeconds = 5,
  }) async => scheduled++;
  @override
  Future<void> cancelKeepOpenReminder() async => cancelled++;
  @override
  Future<bool> requestNotificationPermission() async => true;
}

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
  late _FakeReminder reminder;
  late _FakeBgTask bgTask;
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
    keepOpenTitle: 'keep',
    keepOpenBody: 'open',
  );

  setUp(() {
    controller = _FakeController();
    reminder = _FakeReminder();
    bgTask = _FakeBgTask();
    views = StreamController<TransferView>.broadcast();
    clock = DateTime(2026);
    coordinator = BackgroundTransferCoordinator.forTest(
      controller,
      reminder,
      bgTask,
      now: () => clock,
    );
    cancelled = 0;
  });

  tearDown(() async {
    coordinator.dispose();
    await views.close();
  });

  test(
    'starts a surface when the transfer becomes active (transferring)',
    () async {
      coordinator.attach(handle());
      views.add(_view(TransferPhase.transferring));
      await pumpEventQueue();
      expect(controller.calls, contains('start'));
    },
  );

  test(
    'does not start a surface before the transfer is transferring',
    () async {
      coordinator.attach(handle());
      views.add(_view(TransferPhase.connecting));
      await pumpEventQueue();
      expect(controller.calls, isEmpty);
    },
  );

  test('updates the surface as progress advances', () async {
    coordinator.attach(handle());
    views.add(_view(TransferPhase.transferring, progress: 0.30));
    await pumpEventQueue();
    views.add(_view(TransferPhase.transferring, progress: 0.60));
    await pumpEventQueue();
    expect(controller.calls.where((c) => c == 'update'), isNotEmpty);
  });

  test(
    'throttles repeated same-percent snapshots within the window (T036)',
    () async {
      coordinator.attach(handle());
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
      coordinator.attach(handle());
      views.add(_view(TransferPhase.transferring, progress: 0.30));
      await pumpEventQueue();
      clock = clock.add(const Duration(milliseconds: 600));
      views.add(_view(TransferPhase.transferring, progress: 0.30));
      await pumpEventQueue();
      expect(controller.calls.where((c) => c == 'update'), isNotEmpty);
    },
  );

  test('ends + dismisses the surface on a terminal snapshot', () async {
    coordinator.attach(handle());
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    views.add(_view(TransferPhase.done));
    await pumpEventQueue();
    expect(controller.calls.last, 'end');
  });

  test('ends the surface on detach', () async {
    coordinator.attach(handle());
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    coordinator.detach();
    await pumpEventQueue();
    expect(controller.calls, contains('end'));
  });

  test(
    'repeated transferring snapshots create at most one surface (FR-018)',
    () async {
      coordinator.attach(handle());
      views
        ..add(_view(TransferPhase.transferring, progress: 0.10))
        ..add(_view(TransferPhase.transferring, progress: 0.20))
        ..add(_view(TransferPhase.transferring, progress: 0.30));
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
    coordinator.attach(handle());
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    expect(controller.calls, isEmpty);
  });

  test(
    'a controller failure never blocks the transfer (FR-019/degradation)',
    () async {
      controller.throwOnStart = true;
      coordinator.attach(handle());
      views.add(_view(TransferPhase.transferring));
      await pumpEventQueue();
      // The throwing start was swallowed; subsequent views keep flowing.
      views.add(_view(TransferPhase.transferring, progress: 0.5));
      await pumpEventQueue();
      expect(controller.calls, contains('start'));
      // No exception propagated out of the coordinator.
    },
  );

  test(
    'schedules the keep-open reminder when backgrounded mid-transfer',
    () async {
      coordinator
        ..attach(handle())
        ..didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(reminder.scheduled, 1);
    },
  );

  test('cancels the keep-open reminder when returning to foreground', () async {
    coordinator
      ..attach(handle())
      ..didChangeAppLifecycleState(AppLifecycleState.paused)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(reminder.cancelled, greaterThanOrEqualTo(1));
  });

  test('no keep-open reminder when no transfer is active', () async {
    coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
    await pumpEventQueue();
    expect(reminder.scheduled, 0);
  });

  test(
    'grabs the bg-task grace on background, releases on foreground (T032)',
    () async {
      coordinator
        ..attach(handle())
        ..didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(bgTask.began, 1);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(bgTask.ended, greaterThanOrEqualTo(1));
    },
  );

  test('cancels the keep-open reminder on a terminal transfer', () async {
    coordinator.attach(handle());
    views.add(_view(TransferPhase.transferring));
    await pumpEventQueue();
    coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
    await pumpEventQueue();
    views.add(_view(TransferPhase.done));
    await pumpEventQueue();
    expect(reminder.cancelled, greaterThanOrEqualTo(1));
  });
}
