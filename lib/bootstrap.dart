import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:safe_send/app/app.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/services/deeplink/deep_link_service.dart';
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

  // Instantiate the deep-link service early so the plugin is listening for the
  // launching invite link before the first frame (#008, cold start).
  getIt<DeepLinkService>();

  runApp(const SafeSendApp());
}
