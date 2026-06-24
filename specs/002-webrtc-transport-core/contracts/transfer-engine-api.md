# Contract: TransferEngine API

**Feature**: `002-webrtc-transport-core`

The public engine API consumed by Send (#004) and Receive (#005). `@injectable` (one instance per transfer — Constitution XI). All fallible operations return `Result<T>`; progress flows on a single broadcast stream (FR-024/025). No UI, no localized strings.

## Construction (DI)

```dart
@injectable
class TransferEngine {
  TransferEngine(this._peerFactory, this._config); // iceServers from AppConfig
  // ...
}
```

- `RtcPeerConnectionFactory` (`@lazySingleton`) wraps `createPeerConnection`; injected so tests can supply a fake/real peer connection.
- `iceServers` read from `AppConfig` (empty this feature, R-08).

## State stream

```dart
/// Single source of truth. Broadcast; closes after a terminal snapshot.
Stream<TransferSnapshot> get snapshots;

/// Convenience: current snapshot (last emitted).
TransferSnapshot get current;
```

`TransferSnapshot` = `{ phase, role, progress, items, failure? }` (see data-model). Phase order: `idle → connecting → handshaking → transferring → done|failed|cancelled`.

## Sender API

```dart
/// Begin sending [session] over [signaling]. Drives offer/ICE/manifest →
/// per-file streamed chunks (with backpressure) → fileComplete(sha256) →
/// sessionComplete. Returns when the session reaches a terminal phase.
Future<Result<void>> startSend({
  required TransferSession session,
  required SignalingChannel signaling,
});
```

Behavior:
- Builds the manifest (no hashes), creates the data channel + SDP offer, exchanges SDP/ICE via `signaling`.
- Awaits `accept`; on `reject` → `Result.failure(AppFailure.transferRejected())`.
- For each file in order: `fileStart` → stream `openRead()` as `chunk`s, pausing on `bufferedAmount > kHighWaterMark` until `onBufferedAmountLow`, hashing streaming → `fileComplete(sha256)`.
- Fail-fast: a source read error fails the whole session (`fileReadFailed`).

## Receiver API

```dart
/// Begin receiving over [signaling], saving accepted files under [destinationDir].
/// [onManifest] decides accept/reject (return true to accept). Defaults to
/// auto-accept for tests/in-process use.
Future<Result<void>> startReceive({
  required SignalingChannel signaling,
  required Directory destinationDir,
  Future<bool> Function(TransferManifest manifest) onManifest =
      _autoAccept,
});
```

Behavior:
- Answers the offer; on `manifest`, validates it (version, counts, path-traversal — FR-015/023) then calls `onManifest`.
- Accept → send `accept`; each file streams to `<destinationDir>/.safesend_tmp/<uuid>.part` while hashing; on `fileComplete`, verify hash → atomic `rename` to a collision-resolved final name (R-05/R-07).
- Reject → send `reject`, teardown, `Result.failure(transferRejected)`.
- On `sessionComplete` → `done`.

## Cancellation

```dart
/// Cancel an in-progress transfer from this side. Idempotent.
Future<void> cancel();
```

- Sends `cancel`, stops the pump, deletes any in-flight `.part` file(s), closes the data channel + peer connection, emits a final `cancelled` snapshot (`AppFailure.transferCancelled`). Honored promptly on both ends (FR-028).

## Teardown / lifecycle

```dart
Future<void> dispose(); // close peer connection, controllers, file handles
```

- Called automatically on every terminal phase; safe to call again. After terminal, the instance is spent (FR-026) — a new transfer needs a new `TransferEngine`.

## Error mapping (FR-029/030)

| Situation | Result |
|---|---|
| No connection within `kConnectTimeout` | `peerUnreachable` |
| ICE negotiation fails | `iceFailed` |
| Mid-session disconnect / handshake or stall timeout | `connectionLost` |
| Data channel closes unexpectedly | `dataChannelClosed` |
| Receiver rejects manifest | `transferRejected` |
| Either side cancels | `transferCancelled` |
| Received hash ≠ expected | `integrityCheckFailed(fileIndex)` |
| Source unreadable | `fileReadFailed` |
| Destination unwritable | `fileWriteFailed` |
| Out of space | `storageFull` |
| Other transport error | `networkError` |
| Unknown | `unexpected` |

## Invariants (asserted by tests)

- The same `snapshots` stream is the only progress source (no parallel state).
- A file appears at `finalPath` only after verified atomic rename.
- Cancel/failure leaves no `.part` and no destination file.
- Peak buffered file bytes ≤ `kHighWaterMark + kChunkSize` regardless of file size.
