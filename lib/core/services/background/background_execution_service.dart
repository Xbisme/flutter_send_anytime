import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// Requests a short iOS background-execution window (`beginBackgroundTask`) so an
/// in-flight WebRTC transfer survives a brief minimize instead of being
/// suspended instantly (#011, T032). iOS grants ~30s; long transfers still get
/// suspended (Android is the sustained path). No-op off iOS.
abstract interface class BackgroundExecutionService {
  /// Start the background-task assertion (idempotent).
  Future<void> begin();

  /// End the assertion (on foreground / transfer end).
  Future<void> end();
}

@LazySingleton(as: BackgroundExecutionService)
class IosBackgroundExecutionService implements BackgroundExecutionService {
  static const _channel = MethodChannel('app.safesend/bgtask');

  @override
  Future<void> begin() => _invoke('begin');

  @override
  Future<void> end() => _invoke('end');

  Future<void> _invoke(String method) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>(method);
    } on Object catch (e) {
      AppLogger.warning('bgtask $method failed: ${e.runtimeType}');
    }
  }
}
