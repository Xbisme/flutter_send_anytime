import 'dart:async';

import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart';

/// In-process fake [NearbyDiscoveryService] for CI (#009, research D8). Tests
/// push discovered device lists via [emit]; advertising is recorded for
/// assertions without touching real mDNS or a second device.
class FakeNearbyDiscoveryService implements NearbyDiscoveryService {
  final StreamController<List<NearbyDevice>> _controller =
      StreamController<List<NearbyDevice>>.broadcast();

  /// The code passed to the most recent [advertise] call (null when stopped).
  String? advertisedCode;

  /// The display name passed to the most recent [advertise] call.
  String? advertisedName;

  /// Whether [advertise] is currently active.
  bool advertising = false;

  /// Whether [discover] has been subscribed.
  bool discovering = false;

  /// Result the next [advertise] call returns (override to test failures).
  Result<void> advertiseResult = const Result.success(null);

  /// Push a discovered device list to subscribers.
  void emit(List<NearbyDevice> devices) {
    if (!_controller.isClosed) _controller.add(devices);
  }

  /// Push an error to the discovery stream.
  void emitError(Object error) {
    if (!_controller.isClosed) _controller.addError(error);
  }

  @override
  Future<Result<void>> advertise({
    required String code,
    required String displayName,
  }) async {
    final result = advertiseResult;
    if (result is Failure<void>) return result;
    advertisedCode = code;
    advertisedName = displayName;
    advertising = true;
    return const Result.success(null);
  }

  @override
  Future<void> stopAdvertise() async {
    advertising = false;
    advertisedCode = null;
  }

  @override
  Stream<List<NearbyDevice>> discover() {
    discovering = true;
    return _controller.stream;
  }

  @override
  Future<void> stopDiscover() async {
    discovering = false;
  }

  /// Close the underlying controller (call from test teardown).
  Future<void> dispose() => _controller.close();
}
