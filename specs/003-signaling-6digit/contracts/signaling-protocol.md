# Contract: Signaling Wire Protocol (client ↔ server)

Versioned JSON-text frames over a single WebSocket. Defined once in `packages/safesend_signaling/` and shared by app + relay (R-03). This is the authority for FR-012.

- **Transport**: one WebSocket per device. dev `ws://`, prod `wss://` (R-08).
- **Encoding**: UTF-8 JSON text frames. Every frame: `{"v":1,"type":"<name>", ...}`.
- **Version**: `v` is `1`. A frame with a different `v` is rejected (server ignores; client → protocol error).
- **Privacy invariant**: there is **no frame field that carries file bytes or arbitrary binary**. Only the message types below exist. This enforces SC-002 / Constitution I by construction (mirrors the #002 `SignalingMessage`).
- **Validation**: any unrecognized `type`, missing required field, or `code` not matching `^\d{6}$` is an invalid frame — the server ignores it (and counts it toward rate limiting if it is a malformed/invalid `join`); the client surfaces a typed failure. Frames never crash either side (FR-011, Constitution IX).

## Client → Server

### `host`
Request a new room + code (caller is the sender).
```json
{ "v": 1, "type": "host" }
```
Server replies `code-issued` (or closes on rate/abuse).

### `join`
Join the room bound to `code` (caller is the receiver).
```json
{ "v": 1, "type": "join", "code": "012345" }
```
Server replies `peer-joined` | `room-full` | `code-expired` | `invalid-code` | `rate-limited`.

### `relay`
Forward one handshake item to the peer in the same room. `kind` ∈ `offer|answer|ice`.
```json
{ "v": 1, "type": "relay", "kind": "offer",  "sdp": "v=0\r\n..." }
{ "v": 1, "type": "relay", "kind": "answer", "sdp": "v=0\r\n..." }
{ "v": 1, "type": "relay", "kind": "ice",
  "candidate": "candidate:...", "sdpMid": "0", "sdpMLineIndex": 0 }
```
- `offer`/`answer` MUST include `sdp`. `ice` MUST include `candidate` (`sdpMid`/`sdpMLineIndex` optional).
- Server forwards verbatim to the **other** peer only; it does not parse or store the payload.

### `bye`
Graceful leave; server tears the room down and sends `peer-left` to the other peer.
```json
{ "v": 1, "type": "bye" }
```

## Server → Client

### `code-issued`
```json
{ "v": 1, "type": "code-issued", "code": "012345", "ttlSeconds": 300 }
```

### `peer-joined`
Both peers receive this when the room becomes full (the handshake may begin).
```json
{ "v": 1, "type": "peer-joined" }
```

### `room-full`
The code is valid but the room already holds two peers (third joiner rejected; existing pair undisturbed).
```json
{ "v": 1, "type": "room-full" }
```

### `code-expired`
The code's TTL elapsed (or its room was torn down). Sent to a survivor / late joiner.
```json
{ "v": 1, "type": "code-expired" }
```

### `invalid-code`
The submitted code is unknown or malformed.
```json
{ "v": 1, "type": "invalid-code" }
```

### `relay`
A handshake item forwarded from the peer (same shape as the client `relay`).

### `peer-left`
The other peer disconnected; the room is gone.
```json
{ "v": 1, "type": "peer-left" }
```

### `rate-limited`
Too many invalid `join`s on this connection (FR-011a). After this, the server throttles and may close.
```json
{ "v": 1, "type": "rate-limited", "retryAfterSeconds": 30 }
```

## Canonical sequences

**Happy path**
```
Sender                         Server                         Receiver
  │ ── host ───────────────────▶ │                              │
  │ ◀──────────── code-issued ── │  (room Open, TTL 300s)        │
  │   (shows "012345")           │                              │
  │                              │ ◀──────────────── join(012345)│
  │ ◀───────────── peer-joined ─ │ ── peer-joined ─────────────▶ │  (room Paired)
  │ ── relay(offer) ───────────▶ │ ── relay(offer) ────────────▶ │
  │ ◀──────────── relay(answer) ─│ ◀─────────────── relay(answer)│
  │ ── relay(ice) ⇄ ───────────▶ │ ⇄ relay(ice) ⇄ ─────────────▶ │   (trickle both ways)
  │           … RTCDataChannel opens directly, peer-to-peer …    │
  │ ── bye ────────────────────▶ │ ── peer-left ───────────────▶ │  (room removed)
```

**Failure variants** (receiver side):
```
join(badcode)      → invalid-code
join(expiredcode)  → code-expired
join(fullroom)     → room-full
join × N invalid   → rate-limited (then throttle/close)
peer disconnects   → peer-left   (to survivor; room removed)
TTL elapses        → code-expired (to host; room removed)
```

## Mapping to #002 `SignalingMessage`

| Wire `relay.kind` / type | #002 `SignalingMessage` |
|---|---|
| `relay` + `offer` | `SignalingMessage.offer(sdp)` |
| `relay` + `answer` | `SignalingMessage.answer(sdp)` |
| `relay` + `ice` | `SignalingMessage.iceCandidate(candidate, sdpMid, sdpMLineIndex)` |
| `bye` / `peer-left` | `SignalingMessage.bye()` |

The `WebSocketSignalingChannel` performs exactly this mapping in both directions; control frames (`host`/`join`/`code-issued`/`peer-joined`/`room-full`/`code-expired`/`invalid-code`/`rate-limited`) are consumed by the `SignalingClient` and never reach the engine.
