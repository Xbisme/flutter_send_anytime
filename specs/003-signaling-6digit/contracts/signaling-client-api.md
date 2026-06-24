# Contract: App-side Signaling Client & Channel Adapter

The Dart surface added to `lib/core/services/signaling/`. The #002 `SignalingChannel` / `SignalingMessage` are reused **unchanged**; this contract adds the room/pairing layer above them.

## `SignalingClient`

Owns one WebSocket connection, drives the 6-digit pairing protocol, demultiplexes inbound frames (control → `PairingState`; `relay` → the channel), and **produces** a `SignalingChannel` for the engine. All fallible methods return `Result<T>` — never throw (Constitution V).

```dart
abstract interface class SignalingClient {
  /// Pairing lifecycle (broadcast). See PairingState in data-model.
  Stream<PairingState> get state;

  /// Sender path: open the socket, request a room, and receive a 6-digit code.
  /// On success the [state] stream moves to `hosting(code)` then `peerPresent`.
  Future<Result<PairingCode>> host();

  /// Receiver path: open the socket and join the room bound to [code].
  /// Validates `^\d{6}$` locally first → `invalidCode` without a round-trip.
  /// Failures: invalidCode | roomFull | roomExpired | rateLimited |
  ///           signalingUnreachable | signalingTimeout.
  Future<Result<void>> join(String code);

  /// The transport-agnostic seam the #002 engine consumes. Available once the
  /// room is paired (`peerPresent`); relay frames flow through it. Returns the
  /// same instance for the life of the session.
  SignalingChannel get channel;

  /// Graceful leave: sends `bye`, tears down, closes the socket (idempotent).
  Future<void> dispose();
}
```

**Behavioral contract**
- `host()`/`join()` open the socket against `AppConfig.signalingEndpoint`; an unreachable server → `signalingUnreachable`; no `code-issued`/`peer-joined` within the configured timeout → `signalingTimeout` (Constitution IX: never hang).
- Exactly one of `host()` / `join()` is called per client instance.
- Inbound demux: `code-issued`→`hosting`; `peer-joined`→`peerPresent`; `room-full`/`invalid-code`/`code-expired`/`rate-limited`/`peer-left`→corresponding `failed(...)`; `relay`→`channel.incoming`.
- After `peerPresent`, the caller (pairing repository) wires `channel` into the #002 engine to run the WebRTC handshake; when the engine reports the data channel open, the client surfaces `connected`.
- No file bytes ever traverse this client (SC-002); logs carry phase/error-type only (FR-022).

## `WebSocketSignalingChannel implements SignalingChannel`

The real network implementation of the #002 seam, produced by `SignalingClient`. It does **not** own the socket — it shares the client's socket and only handles `relay`/`bye`.

```dart
class WebSocketSignalingChannel implements SignalingChannel {
  @override
  Stream<SignalingMessage> get incoming;          // mapped from inbound `relay`/`peer-left`

  @override
  Future<Result<void>> send(SignalingMessage m);  // mapped to outbound `relay`/`bye`

  @override
  Future<void> close();                           // idempotent; messages after close ignored
}
```

- `send(offer/answer/iceCandidate/bye)` → encodes the matching `relay`/`bye` frame (per the protocol mapping table) and writes it to the shared socket; transport error → `Result.failure(...)`, never throws.
- `incoming` emits `SignalingMessage` decoded from inbound `relay` frames; `peer-left` surfaces as `SignalingBye` so the engine tears down (Constitution IX).
- Mirrors `LoopbackSignalingChannel`'s semantics (async delivery, drop-after-close) so the engine behaves identically against loopback (tests) and WebSocket (real) — Constitution VIII/XII.

## `features/pairing/` surface (consumed by #004/#005)

- `PairingRepository` (domain interface) + `PairingRepositoryImpl` (data) wrapping `SignalingClient` and the #002 engine handshake.
- Use cases injected into the cubit (Constitution III): `HostSessionUseCase`, `JoinSessionUseCase`.
- `PairingCubit` (`@injectable`, 4-state): `initial → loading → loaded(PairingView) → error(AppFailure)`, with extended variants prefixed (`loadedHosting`, `loadedWaitingForPeer`, `loadedConnected`). Side effects via `BlocListener`. This is the reusable primitive #004's Connect screen and #005's Receive screen consume (FR-021).

## DI registration

- `SignalingClient` → `@injectable` (per-session; a new instance per pairing attempt). Depends on `AppConfig` (already provided at startup).
- `PairingRepository`/use cases → `@injectable`/`@lazySingleton` per Constitution XI (no eager `@singleton`).

## Dev-only debug surface (FR-021a)

- `PairingDebugPage` under `features/pairing/presentation/debug/`, driven by `PairingCubit`.
- Route constant in `AppRoutes`; **mounted only when `AppConfig.flavor.isDev`** (router checks the flavor) → absent from prod builds.
- Buttons: "Host (get code)" and "Join (enter code)"; renders the code via the shared `CodeBox`, the TTL countdown, and the live `PairingState`. Uses `AppToast` for errors. Sole purpose: drive the deferred two-physical-device smoke.
