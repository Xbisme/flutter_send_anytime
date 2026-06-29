import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/constants/signaling_constants.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_role.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart';
import 'package:safe_send/core/services/signaling/signaling_client.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';

/// Wires the [SignalingClient] (6-digit rendezvous) to the #002 [PeerConnector]
/// (WebRTC handshake). Forwards the client's lifecycle and, once both peers are
/// present, runs the connection — emitting `connected` when the data channel
/// opens (#003 stops here; transfer is #004/#005).
@Injectable(as: PairingRepository)
class PairingRepositoryImpl implements PairingRepository {
  PairingRepositoryImpl(
    this._client,
    this._connector,
    this._hostingRegistry,
  );

  final SignalingClient _client;
  final PeerConnector _connector;
  final ActiveHostingRegistry _hostingRegistry;

  final _state = StreamController<PairingState>.broadcast();
  StreamSubscription<PairingState>? _clientSub;
  DataTransport? _transport;
  var _connecting = false;

  /// Non-null once this session has issued a hosting code — so [dispose] clears
  /// the registry only for a session that actually set it (#008, FR-015).
  String? _hostingCode;

  @override
  Stream<PairingState> get state => _state.stream;

  @override
  Future<Result<PairingCode>> host() {
    _bind(PairingRole.sender);
    return _client.host();
  }

  @override
  Future<Result<void>> join(String code) {
    _bind(PairingRole.receiver);
    return _client.join(code);
  }

  @override
  DataTransport? takeTransport() {
    final transport = _transport;
    _transport = null; // ownership leaves the repo; dispose won't close it
    return transport;
  }

  @override
  Future<void> dispose() async {
    // Clear the registry only if this session is the one that set it (#008).
    if (_hostingCode != null) _hostingRegistry.clear();
    await _clientSub?.cancel();
    await _transport?.close();
    await _client.dispose();
    if (!_state.isClosed) await _state.close();
  }

  void _bind(PairingRole role) {
    _clientSub ??= _client.state.listen((state) {
      // Track the live hosting code so a deep-link self-invite can be detected
      // (#008, FR-015). Set as the sender's code is issued / rotates.
      if (state is PairingHosting) {
        _hostingCode = state.code.value;
        _hostingRegistry.setHosting(state.code.value);
      }
      _emit(state);
      if (state is PairingPeerPresent && !_connecting) {
        _connecting = true;
        unawaited(_establish(role));
      }
    });
  }

  Future<void> _establish(PairingRole role) async {
    final result = await _connector.connect(
      role: role == PairingRole.sender
          ? TransferRole.sender
          : TransferRole.receiver,
      signaling: _client.channel,
      // #014: static per-flavor ICE config + any ephemeral TURN relay the
      // server issued for this session (captured before `peer-joined`).
      iceServers: _client.sessionIceServers,
      timeout: SignalingTimeouts.handshake,
    );
    result.fold(
      (transport) {
        _transport = transport;
        _emit(const PairingState.connected());
      },
      (failure) => _emit(PairingState.failed(failure)),
    );
  }

  void _emit(PairingState state) {
    if (!_state.isClosed) _state.add(state);
  }
}
