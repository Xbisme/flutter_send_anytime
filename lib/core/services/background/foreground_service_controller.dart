import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/core/services/background/transfer_service_task_handler.dart';

/// Android [BackgroundSurfaceController] over `flutter_foreground_task`.
///
/// Runs a `dataSync` foreground service that keeps the app process alive while a
/// transfer is backgrounded (the transfer itself stays on the main isolate —
/// the service only prevents the OS from killing the process). Renders the
/// ongoing, non-dismissible progress notification with a single "Huỷ" action.
///
/// The notification-button tap is delivered to the background service isolate
/// (`TransferServiceTaskHandler`), which forwards it to the main isolate via
/// `sendDataToMain`; the main
/// isolate receives it through `addTaskDataCallback` → [actions] emits
/// [BackgroundServiceAction.cancel]. Runtime behavior is verified on device (T040).
class ForegroundServiceController implements BackgroundSurfaceController {
  static const _channelId = 'safesend_transfer_progress';
  static const _channelName = 'Safe Send · Transfer';
  static const _cancelButtonId = 'safesend_cancel';
  static const _serviceId = 4011;

  final StreamController<BackgroundServiceAction> _actions =
      StreamController<BackgroundServiceAction>.broadcast();

  bool _inited = false;
  bool _callbackRegistered = false;

  @override
  Stream<BackgroundServiceAction> get actions => _actions.stream;

  @override
  Future<bool> get isSupported async =>
      defaultTargetPlatform == TargetPlatform.android;

  void _ensureInit() {
    if (_inited) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWifiLock: true,
      ),
    );
    _inited = true;
  }

  void _registerCallback() {
    if (_callbackRegistered) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onData);
    _callbackRegistered = true;
  }

  void _onData(Object data) {
    if (data == _cancelButtonId) {
      _actions.add(BackgroundServiceAction.cancel);
    }
  }

  @override
  Future<void> start(BackgroundTransferState state) async {
    _ensureInit();
    _registerCallback();
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: state.title,
      notificationText: _notificationText(state),
      notificationButtons: [
        NotificationButton(id: _cancelButtonId, text: state.cancelLabel),
      ],
      callback: startTransferServiceCallback,
    );
  }

  @override
  Future<void> update(BackgroundTransferState state) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: state.title,
      notificationText: _notificationText(state),
      notificationButtons: [
        NotificationButton(id: _cancelButtonId, text: state.cancelLabel),
      ],
    );
  }

  @override
  Future<void> end() async {
    if (_callbackRegistered) {
      FlutterForegroundTask.removeTaskDataCallback(_onData);
      _callbackRegistered = false;
    }
    await FlutterForegroundTask.stopService();
  }

  /// One-line progress summary shown under the title (the plugin renders no
  /// native progress bar in this version — progress is conveyed in the text;
  /// device polish tracked in T040).
  String _notificationText(BackgroundTransferState s) {
    final parts = <String>[
      '${s.percent}%',
      s.bytesLabel,
      s.speedLabel,
      if (s.etaLabel.isNotEmpty) s.etaLabel,
    ];
    return parts.join(' · ');
  }
}
