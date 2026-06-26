import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:safe_send/core/constants/nearby_constants.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// `nsd`-backed mDNS implementation (#009). Advertises via `register` and
/// browses via `startDiscovery` (the plugin manages the found/lost list and the
/// Android MulticastLock). Logs only phase/error-type — never the code, device
/// name, or address (FR-018, Constitution I).
@LazySingleton(as: NearbyDiscoveryService)
class NsdNearbyDiscoveryService implements NearbyDiscoveryService {
  final StreamController<List<NearbyDevice>> _controller =
      StreamController<List<NearbyDevice>>.broadcast();

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;
  void Function()? _listener;

  /// The code we are advertising, so we can suppress our own service from the
  /// discovered list (FR-004).
  String? _ownCode;

  @override
  Future<Result<void>> advertise({
    required String code,
    required String displayName,
  }) async {
    try {
      await stopAdvertise();
      _ownCode = code;
      _registration = await nsd.register(
        nsd.Service(
          name: displayName,
          type: kNearbyServiceType,
          port: kNearbyPort,
          txt: NearbyDevice.toTxt(code: code),
        ),
      );
      return const Result.success(null);
    } on Object {
      _ownCode = null;
      AppLogger.warning('nearby.advertise failed');
      return const Result.failure(AppFailure.networkError());
    }
  }

  @override
  Future<void> stopAdvertise() async {
    final registration = _registration;
    _registration = null;
    _ownCode = null;
    if (registration == null) return;
    try {
      await nsd.unregister(registration);
    } on Object {
      // Best-effort teardown; nothing actionable on failure.
    }
  }

  @override
  Stream<List<NearbyDevice>> discover() {
    unawaited(_startDiscovery());
    return _controller.stream;
  }

  Future<void> _startDiscovery() async {
    if (_discovery != null) return;
    try {
      final discovery = await nsd.startDiscovery(kNearbyServiceType);
      _discovery = discovery;
      void onChange() => _emit(discovery);
      _listener = onChange;
      discovery.addListener(onChange);
      _emit(discovery);
    } on Object {
      AppLogger.warning('nearby.discover failed');
      if (!_controller.isClosed) {
        _controller.addError(const AppFailure.networkError());
      }
    }
  }

  void _emit(nsd.Discovery discovery) {
    final now = DateTime.now();
    final devices = <NearbyDevice>[];
    final seen = <String>{};
    for (final service in discovery.services) {
      final code = NearbyDevice.codeFromTxt(service.txt);
      if (code == null) continue;
      if (code == _ownCode) continue; // self-suppression (FR-004)
      final id = service.name ?? code;
      if (!seen.add(id)) continue;
      devices.add(
        NearbyDevice(
          id: id,
          displayName: service.name ?? code,
          code: code,
          lastSeen: now,
        ),
      );
    }
    if (!_controller.isClosed) _controller.add(devices);
  }

  @override
  Future<void> stopDiscover() async {
    final discovery = _discovery;
    final listener = _listener;
    _discovery = null;
    _listener = null;
    if (discovery == null) return;
    if (listener != null) discovery.removeListener(listener);
    try {
      await nsd.stopDiscovery(discovery);
    } on Object {
      // Best-effort teardown.
    }
  }
}
