# Contract: SignalingChannel

**Feature**: `002-webrtc-transport-core`

The abstraction the engine uses to exchange connection-setup metadata with the remote peer. The engine depends ONLY on this interface (FR-006); the real WebSocket implementation arrives in #003, and an in-process loopback ships here for tests (FR-007). It carries **metadata only — never file bytes** (FR-002/031, Constitution I/VIII).

## Interface

```dart
abstract interface class SignalingChannel {
  /// Messages arriving from the remote peer. Broadcast stream.
  Stream<SignalingMessage> get incoming;

  /// Send a message to the remote peer. Returns a Result — transport errors
  /// surface as AppFailure (networkError / signaling*), never thrown.
  Future<Result<void>> send(SignalingMessage message);

  /// Release the channel (idempotent). Late/duplicate messages after close
  /// MUST be ignored, not delivered (FR-008).
  Future<void> close();
}
```

## `SignalingMessage` (sealed, JSON-serializable)

| Variant | Fields | Notes |
|---|---|---|
| `offer` | `sdp: String` | sender → receiver |
| `answer` | `sdp: String` | receiver → sender |
| `iceCandidate` | `candidate: String, sdpMid: String?, sdpMLineIndex: int?` | trickle ICE, both ways |
| `bye` | — | optional graceful close |

- **No byte-carrying variant exists** — structurally enforces "no bytes over signaling" (testable invariant, SC-007).
- SDP and ICE candidate strings contain IP addresses → they are **never** passed to `AppLogger` (FR-032).

## Behavioral contract

1. `incoming` is a broadcast stream (engine + tests may both listen).
2. Messages are delivered in send order per peer (loopback preserves order; the #003 WebSocket impl must too).
3. `send` after `close` returns a failure `Result`, does not throw.
4. Duplicate/late/out-of-order messages MUST NOT corrupt or reopen a finished session — the engine guards via session id + phase (FR-008).
5. The channel never inspects, transforms, or persists message contents.

## `LoopbackSignalingChannel` (this feature)

In-process implementation used by all engine tests and any in-process demo.

```dart
// Factory returns a connected pair.
final (senderSide, receiverSide) = LoopbackSignalingChannel.pair();
```

- Each side holds a reference to the other's inbound `StreamController`.
- `send(m)` on one side enqueues `m` on the other side's `incoming` (microtask-async to mimic real delivery; never synchronous re-entry).
- Optional test affordances: injectable delivery delay and a "drop after N messages" switch to simulate `connectionLost` (used by the resilience tests).
- `close()` closes both controllers and makes further `send` return failure.

## Out of scope (here)

- Real WebSocket transport, rooms, 6-digit/QR/link/radar rendezvous → #003 (a new `WebSocketSignalingChannel implements SignalingChannel`, no engine change).
