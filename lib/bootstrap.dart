import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:safe_send/app/app.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// Shared pre-runApp setup, parameterized by flavor [config].
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error('FlutterError', details.exception, details.stack);
  };

  await configureDependencies(config);

  runApp(const SafeSendApp());
}
