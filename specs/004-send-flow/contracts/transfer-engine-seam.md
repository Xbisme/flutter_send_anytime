# Contract: Transfer-engine & pairing seam (the only edits to merged engine code)

Both changes are **additive** and preserve every existing #002/#003 test path.

## 1. `TransferEngine.startSendOnTransport`

```dart
/// Begin sending [session] over an ALREADY-OPEN [transport] (produced by the
/// pairing layer). Adopts the transport (wires its `closed` watcher, owns its
/// teardown) and runs the send protocol from the handshaking phase onward —
/// it does NOT call the PeerConnector (no second WebRTC handshake). Resolves
/// when the session reaches a terminal phase.
Future<Result<void>> startSendOnTransport({
  required DataTransport transport,
  required TransferSession session,
});
```

**Refactor** the existing `startSend` so the two share one body:

```dart
Future<Result<void>> startSend({
  required TransferSession session,
  required SignalingChannel signaling,
}) async {
  _role = TransferRole.sender;
  _initSession(session);
  _setPhase(TransferPhase.connecting);
  final transport = await _establish(signaling);   // unchanged path (loopback tests)
  if (transport == null) return _result();
  return _runSend(transport, session);             // shared body
}

Future<Result<void>> startSendOnTransport({
  required DataTransport transport,
  required TransferSession session,
}) async {
  _role = TransferRole.sender;
  _initSession(session);
  _adoptTransport(transport);   // store, wire `closed` → connectionLost watcher (as _establish does)
  return _runSend(transport, session);
}
```

Where `_runSend(transport, session)` is the current body of `startSend` from the
accept-listener setup through `handshaking → transferring → ... → _terminate(done)`
(everything after `_establish` today), and `_initSession` sets `_items`/`_progress`.

**Rules**:
- `startSendOnTransport` starts emitting from `handshaking` (the connection already exists). The first snapshot the cubit sees may be `handshaking`; the progress UI treats `connecting`/`handshaking` as a single "đang kết nối/chuẩn bị" state.
- Ownership: the engine wires `transport.closed` → `connectionLost` and closes the transport in `_disposeInternal()` exactly as `_establish` does. The caller MUST NOT close the transport itself after handing it over.
- All existing guarantees hold unchanged: 16 KiB chunking, backpressure (`bufferedAmount`), per-file SHA-256, sequential multi-file fail-fast, cancel both sides, stall timer.

**Test**: a loopback round-trip — pair a `LoopbackDataTransport` to a receiver engine, call `startSendOnTransport(transport, session)` on the sender engine, assert files arrive + integrity matches + terminal `done` (mirrors the existing `startSend` round-trip but via the new entry point).

## 2. `PairingRepository.takeTransport`

```dart
/// Transfer ownership of the connected data channel out of the pairing layer.
/// Returns the open transport and clears the repo's reference so [dispose] will
/// NOT close it. Returns null if not connected. Single-use.
DataTransport? takeTransport();
```

Impl in `PairingRepositoryImpl`:

```dart
DataTransport? takeTransport() {
  final t = _transport;
  _transport = null;        // repo no longer owns/closes it
  return t;
}
```

- `dispose()` already does `await _transport?.close()`; after `takeTransport()` clears `_transport`, dispose closes only the still-owned signaling socket/client — never the handed-off transport (prevents double-close).
- Exposed to the UI through `PairingCubit` (e.g. `DataTransport? takeTransport() => _repository.takeTransport();`) so the Connect screen can retrieve it on `PairingConnected` without importing the repository directly.

**Post-connect signaling teardown**: for a data-channel-only transfer there is no renegotiation, so the Connect screen disposing its `PairingCubit` (closing the WebSocket) after `takeTransport()` does not affect the live transport. The transport now flows to the send Progress route and is owned by the `TransferEngine`.

## Invariants preserved (Constitution)

- **VIII** — still one transfer state machine; the new entry point reuses the same `_runSend` body and `snapshots` stream. No parallel progress notion.
- **I/II** — no bytes on signaling; the transport is the same encrypted DTLS channel; logs unchanged (phase/error-type only).
- **IX** — exactly-once teardown: ownership moves from pairing → engine via `takeTransport()`; the engine closes it on terminal/dispose.
- **XII** — `startSend` (and its loopback tests) unchanged; new behavior covered by an added loopback test for `startSendOnTransport`.
