# Contract — Transfer Engine Seam: `startReceiveOnTransport`

The single additive edit to merged engine code for #005. Mirror of #004's `startSendOnTransport`. **Additive + body-extracting refactor only** — no protocol, state-machine, or existing-API change; existing loopback receive tests must stay green.

## Current (before #005)

```dart
// lib/core/services/transport/transfer_engine.dart
Future<Result<void>> startReceive({
  required SignalingChannel signaling,
  required Directory destinationDir,
  Future<bool> Function(TransferManifest manifest) onManifest = _autoAccept,
}) async {
  _role = TransferRole.receiver;
  _setPhase(TransferPhase.connecting);
  final transport = await _establish(signaling);   // ← opens the WebRTC channel
  if (transport == null) return _result();
  // … large frame loop: manifest→accept/reject→fileStart→chunks→fileComplete(hash)→sessionComplete …
}
```

## After #005

Extract the frame loop into a shared private body; add a transport-adopting entry. `startReceive` keeps its exact behavior.

```dart
/// Receive over [signaling] (opens its own channel). Unchanged public behavior.
Future<Result<void>> startReceive({
  required SignalingChannel signaling,
  required Directory destinationDir,
  Future<bool> Function(TransferManifest manifest) onManifest = _autoAccept,
}) async {
  _role = TransferRole.receiver;
  _setPhase(TransferPhase.connecting);
  final transport = await _establish(signaling);
  if (transport == null) return _result();
  return _runReceive(transport, destinationDir, onManifest);
}

/// #005 — Receive over an ALREADY-OPEN [transport] produced by the pairing layer.
/// Adopts the transport (ownership transfers to this engine — it closes it on
/// terminal/dispose) and runs the receive protocol from handshaking onward; NO
/// second WebRTC handshake. Mirror of [startSendOnTransport].
Future<Result<void>> startReceiveOnTransport({
  required DataTransport transport,
  required Directory destinationDir,
  Future<bool> Function(TransferManifest manifest) onManifest = _autoAccept,
}) async {
  _role = TransferRole.receiver;
  _setPhase(TransferPhase.connecting);
  _adoptTransport(transport);                       // existing private helper (used by send seam)
  return _runReceive(transport, destinationDir, onManifest);
}

/// Shared receive body — the existing frame loop, verbatim, moved here.
Future<Result<void>> _runReceive(
  DataTransport transport,
  Directory destinationDir,
  Future<bool> Function(TransferManifest manifest) onManifest,
) async {
  _setPhase(TransferPhase.handshaking);
  // … the current startReceive frame loop, unchanged …
}
```

## Ownership & teardown

- `startReceiveOnTransport` **takes ownership** of `transport`: the engine closes it on any terminal phase (`done`/`failed`/`cancelled`) and on `dispose()`. The pairing layer must have already relinquished it via `PairingRepository.takeTransport()` (no double-close — same rule as #004).
- `cancel()` is unchanged: it tears down the connection and deletes the in-flight `.part`; already-finalized files are kept (FR-013a).
- The connecting→handshaking phase emission is preserved so the receive UI shows a "preparing" state before bytes (the cubit maps `isPreparing`).

## Behavior preserved (no change)

- Manifest validation + path-traversal rejection; `onManifest` accept/reject gate **before** any write.
- Per-file streamed write to `.part` → SHA-256 verify → atomic rename with non-overwriting collision handling.
- Integrity mismatch / write error / cancel / remote-cancel / stream-end → typed `AppFailure` terminal; only `_activePart` discarded.
- `_autoAccept` default retained for existing tests; the receive flow passes a real `onManifest` (the cubit bridge).

## Tests (Constitution XII)

- **New loopback round-trip** `core/services/transport`: pair two engines over a loopback `DataTransport` (as the #004 `startSendOnTransport` test does); sender runs `startSendOnTransport`, receiver runs `startReceiveOnTransport` into a temp dir; assert all files arrive, hashes match, files exist at destination, single + multi-file, and a forced mid-transfer drop yields a **partial** (earlier files kept, `.part` gone).
- **Existing `startReceive` loopback tests**: unchanged and still green (they exercise `_runReceive` via the refactored entry).
