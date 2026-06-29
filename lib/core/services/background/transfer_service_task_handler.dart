import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point for the Android foreground-service isolate. MUST be a top-level
/// function annotated with `@pragma('vm:entry-point')` so it survives tree
/// shaking and can be invoked by the plugin on a fresh isolate.
@pragma('vm:entry-point')
void startTransferServiceCallback() {
  FlutterForegroundTask.setTaskHandler(TransferServiceTaskHandler());
}

/// Minimal foreground-service task handler.
///
/// It deliberately does NOT run the transfer — the WebRTC transfer stays on the
/// main isolate; the foreground service exists only to keep the process alive.
/// Its sole job is to forward the "Huỷ" notification-button tap from the service
/// isolate back to the main isolate (`sendDataToMain`), where the
/// `BackgroundTransferCoordinator` invokes the real cancel path.
class TransferServiceTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }
}
