import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';

/// Drives the pairing flow for the UI (#003 dev debug screen; reused by #004
/// Connect and #005 Receive). Holds the latest [PairingState] in the 4-state
/// [AppCubit]: `loaded` carries the active lifecycle value, `error` carries the
/// failure. The repository's stream is the source of truth.
///
/// Depends on a SINGLE [PairingRepository] so the host/join actions and the
/// state subscription operate on the same session instance (the repository is
/// factory-scoped — injecting it more than once would yield divergent streams).
@injectable
class PairingCubit extends AppCubit<PairingState> {
  PairingCubit(this._repository);

  final PairingRepository _repository;

  StreamSubscription<PairingState>? _sub;

  /// Sender: generate a code and wait for a peer to connect.
  Future<void> host() async {
    emitLoading();
    _listen();
    final result = await _repository.host();
    result.fold((_) {}, emitError);
  }

  /// Receiver: join with [code] and connect.
  Future<void> joinWithCode(String code) async {
    emitLoading();
    _listen();
    final result = await _repository.join(code);
    result.fold((_) {}, emitError);
  }

  /// Transfer ownership of the connected data channel to the caller (#004).
  /// Returns null if not yet connected. Single-use.
  DataTransport? takeTransport() => _repository.takeTransport();

  void _listen() {
    _sub ??= _repository.state.listen((state) {
      switch (state) {
        case PairingFailed(:final failure):
          emitError(failure);
        case PairingIdle():
        case PairingConnecting():
        case PairingHosting():
        case PairingJoining():
        case PairingPeerPresent():
        case PairingConnected():
        case PairingClosed():
          emitLoaded(state);
      }
    });
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _repository.dispose();
    return super.close();
  }
}
