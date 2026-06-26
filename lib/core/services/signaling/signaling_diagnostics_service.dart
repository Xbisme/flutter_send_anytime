import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A function that attempts to reach [uri] within [timeout]; throws on failure.
typedef EndpointProbe = Future<void> Function(Uri uri, Duration timeout);

/// Tests whether the active signaling endpoint is reachable (#010, US4,
/// FR-015), without sending any bytes. Reuses `web_socket_channel` (#003).
// ignore: one_member_abstracts
abstract interface class SignalingDiagnosticsService {
  /// Returns success if [endpoint] accepts a WebSocket connection within
  /// [timeout], else [AppFailure.signalingUnreachable].
  Future<Result<void>> probe(
    Uri endpoint, {
    Duration timeout = const Duration(seconds: 5),
  });
}

@LazySingleton(as: SignalingDiagnosticsService)
class WebSocketSignalingDiagnostics implements SignalingDiagnosticsService {
  /// DI constructor — uses the real WebSocket probe.
  WebSocketSignalingDiagnostics() : _open = _real;

  /// Test seam: inject a fake probe.
  @visibleForTesting
  WebSocketSignalingDiagnostics.withProbe(this._open);

  final EndpointProbe _open;

  @override
  Future<Result<void>> probe(
    Uri endpoint, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      await _open(endpoint, timeout);
      return const Result.success(null);
    } on Object catch (_) {
      return const Result.failure(AppFailure.signalingUnreachable());
    }
  }

  static Future<void> _real(Uri uri, Duration timeout) async {
    final channel = WebSocketChannel.connect(uri);
    await channel.ready.timeout(timeout);
    await channel.sink.close();
  }
}
