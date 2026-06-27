import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:safe_send/app/app.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:safe_send/core/services/background/background_transfer_coordinator.dart';
import 'package:safe_send/core/services/deeplink/deep_link_service.dart';
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// Shared pre-runApp setup, parameterized by flavor [config].
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error('FlutterError', details.exception, details.stack);
  };

  // flutter_webrtc can deliver a final native data-channel event AFTER we tear
  // the transport down, hitting its already-closed internal broadcast stream
  // ("Cannot add new events after calling close"). The transfer is already
  // complete, so this teardown race is benign — swallow it rather than let it
  // surface as an unhandled crash. All other async errors are reported.
  PlatformDispatcher.instance.onError = (error, stack) {
    final trace = stack.toString();
    if (error is StateError &&
        error.message.contains('Cannot add new events after calling close') &&
        (trace.contains('rtc_data_channel') ||
            trace.contains('flutter_webrtc'))) {
      AppLogger.warning('ignored webrtc teardown event after close');
      return true;
    }
    AppLogger.error('uncaught async error', error, stack);
    return false;
  };

  await configureDependencies(config);

  // Load persisted preferences into memory before the first frame so theme +
  // language render correctly with no flash, and the device name is ready for
  // pairing/advertise (#010).
  await getIt<SettingsRepository>().init();

  // Initialize the local-notification plugin so an incoming-file notification
  // can fire while backgrounded (#010, FR-009). The OS foregrounds the app on
  // tap; the receive flow is already the active route.
  await getIt<IncomingFileNotifier>().init();

  // Instantiate the deep-link service early so the plugin is listening for the
  // launching invite link before the first frame (#008, cold start).
  getIt<DeepLinkService>();

  // Register the background-transfer coordinator as an app-lifecycle observer so
  // it can raise/dismiss the OS surface (iOS Live Activity / Android foreground
  // service) when a transfer is backgrounded or returns to foreground (#011).
  WidgetsBinding.instance.addObserver(getIt<BackgroundTransferCoordinator>());

  runApp(const SafeSendApp());
}
