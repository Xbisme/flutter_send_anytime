import 'dart:io' show Platform;

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/foreground_service_controller.dart';
import 'package:safe_send/core/services/background/live_activity_controller.dart';

/// Binds the platform-appropriate [BackgroundSurfaceController] for the
/// `BackgroundTransferCoordinator`: iOS → Live Activity, Android (and any other
/// host) → foreground service. The coordinator depends on the interface only,
/// so tests inject a fake instead.
@module
abstract class BackgroundModule {
  @lazySingleton
  BackgroundSurfaceController surfaceController(AppConfig config) =>
      Platform.isIOS
      ? LiveActivityController(appGroupId: config.liveActivityAppGroupId)
      : ForegroundServiceController();
}
