# Data Model: Signaling Server & 6-Digit Key Pairing (#003)

Phase 1 output. Entities, fields, validation, and state transitions derived from the spec's Key Entities + Functional Requirements. Wire-frame shapes are the contract in [contracts/signaling-protocol.md](contracts/signaling-protocol.md).

Conventions: app/domain models are immutable `@freezed`; the shared package + server use plain Dart classes (no Flutter/freezed dependency). Codes are **always strings**, never ints (R-04).

---

## Shared package (`packages/safesend_signaling/`)

### `SignalingFrame` (sealed) — the wire protocol message

One sealed type with a `type` discriminator and a protocol version. Encodes to/decodes from JSON `{"v":1,"type":...,...}`. Single source of truth for both app and server (R-03).

| Variant | Direction | Fields | Purpose |
|---|---|---|---|
| `Host` | client→server | — | Sender requests a new room + code. |
| `CodeIssued` | server→client | `code: String`, `ttlSeconds: int` | Room created; here is the 6-digit code + remaining life. |
| `Join` | client→server | `code: String` | Receiver asks to join the room for `code`. |
| `PeerJoined` | server→client | — | The other peer is now present (sent to both). |
| `RoomFull` | server→client | — | Code valid but room already has two peers. |
| `CodeExpired` | server→client | — | Code's TTL elapsed (or room torn down). |
| `InvalidCode` | server→client | — | Code unknown / malformed. |
| `Relay` | both | `kind: RelayKind`, `sdp: String?`, `candidate: String?`, `sdpMid: String?`, `sdpMLineIndex: int?` | Forward one SDP/ICE item to the peer. |
| `PeerLeft` | server→client | — | The other peer disconnected; room is gone. |
| `Bye` | client→server | — | Graceful leave. |
| `RateLimited` | server→client | `retryAfterSeconds: int` | Too many invalid joins on this connection. |

**`RelayKind`** enum: `offer` · `answer` · `ice`. Maps 1:1 to the #002 `SignalingMessage` variants (`offer`→`SignalingOffer`, `answer`→`SignalingAnswer`, `ice`→`SignalingIceCandidate`; `Bye`↔`SignalingBye`).

**Validation (decode)**:
- Unknown `type` → decode returns a typed failure (server ignores/closes; client surfaces `signalingUnreachable`/protocol error). Never throws across the boundary.
- `v` mismatch → reject (future-proofing; only `v:1` accepted now).
- `Relay.kind == ice` requires `candidate`; `offer`/`answer` require `sdp`. Missing required field → invalid frame.
- `code` must match `^\d{6}$`.
- **No frame variant may carry file bytes or arbitrary binary** — there is structurally no such field (Constitution I; SC-002 enforced by construction, mirroring #002's `SignalingMessage`).

### `SignalingProtocol` constants

`protocolVersion = 1`; message-type name strings; `codeLength = 6`; `defaultTtl = Duration(minutes: 5)`. Imported by both programs so literals are never duplicated.

---

## Server (`server/`) — in-memory only, nothing persisted (FR-015)

### `Room`

| Field | Type | Notes |
|---|---|---|
| `code` | `String` | 6-digit key; the map key. Immutable for the room's life. |
| `host` | `PeerConnection` | The creator (sender). Set at creation. |
| `guest` | `PeerConnection?` | The joiner (receiver). Null until someone joins. |
| `expiry` | `Timer` | Fires at creation + TTL → expire + cleanup. Cancelled on teardown. |

**Invariants**: at most one `host` + one `guest` (FR-008); `code` unique among active rooms (FR-003); removed from the registry on expiry, either disconnect, or `Bye` from both (FR-013).

**State transitions**:
```
(none) --Host--> Open{host, guest:null}            // code issued, waiting
Open --Join(valid,this code)--> Paired{host,guest}  // both notified PeerJoined
Open|Paired --expiry fires--> (removed) + CodeExpired→survivors
Open|Paired --peer disconnect--> (removed) + PeerLeft→survivor
Paired --Join(third)--> RoomFull→third (room unchanged)
```

### `RoomManager`

Owns `Map<String, Room>`. Responsibilities: `createRoom()` (generate unique code via `Random.secure()`, install TTL timer), `join(code, conn)` → `joined | invalidCode | roomFull | codeExpired`, `remove(code)`, and relay routing (forward a `Relay`/`Bye` frame from one peer to the room's other peer only). Holds no state beyond the map.

### `PeerConnection`

Wraps one upgraded WebSocket. Fields: the socket sink/stream, the `code` it belongs to (once hosting/joined), and a `RateLimiter`. Sends/receives `SignalingFrame`s; on socket close → notify `RoomManager` to tear down its room.

### `RateLimiter` (per connection)

| Field | Type | Notes |
|---|---|---|
| `invalidJoinCount` | `int` | Consecutive invalid `Join`s. |
| `window` | `Duration` | Sliding window for counting. |
| `threshold` | `int` | e.g. 5 → then `RateLimited`. |

Reset on a valid join. Exceeding the threshold → emit `RateLimited(retryAfter)`, throttle, and close on continued abuse (FR-011a, R-06).

---

## App domain (`lib/core/domain/pairing/`)

### `PairingRole` (enum)
`sender` · `receiver`. Selects host-vs-join behavior and the role shown to the future UI.

### `PairingCode` (`@freezed`)

| Field | Type | Notes |
|---|---|---|
| `value` | `String` | 6 digits, leading zeros preserved (FR-002). |
| `expiresAt` | `DateTime` | Now + ttl; drives the countdown the UI/debug screen renders (FR-005). |

Helper: `Duration get remaining` (clamped ≥ 0). Validation on inbound entry: `^\d{6}$`.

### `PairingState` (`@freezed`, sealed) — signaling-client lifecycle stream

Drives `PairingCubit` and the debug screen (the cubit's 4-state wraps this).

```
idle
connecting                       // opening the WebSocket
hosting(PairingCode code)        // code issued, waiting for peer (sender)
joining                          // code submitted, awaiting room (receiver)
peerPresent                      // both in room → handing off to the WebRTC handshake
connected                        // RTCDataChannel open (engine reports ready)
failed(AppFailure failure)       // signalingUnreachable | signalingTimeout | roomExpired
                                 //  | roomFull | invalidCode | rateLimited | connectionLost
closed
```

Transition map (happy paths + failures):
```
idle --connect--> connecting --ws open, role=sender--> hosting
idle --connect--> connecting --ws open, role=receiver, Join--> joining
hosting --PeerJoined--> peerPresent
joining --PeerJoined--> peerPresent
joining --InvalidCode--> failed(invalidCode)
joining --RoomFull--> failed(roomFull)
joining|hosting --CodeExpired--> failed(roomExpired)
peerPresent --engine DataChannel open--> connected
any --PeerLeft / socket drop--> failed(connectionLost)
any --RateLimited--> failed(rateLimited)
connecting --no server--> failed(signalingUnreachable)
connecting/handshake --timeout--> failed(signalingTimeout)
* --dispose--> closed
```

---

## App failures (`lib/core/domain/failures/app_failure.dart` — EDIT, R-10)

Add variants (with the existing ones): `signalingUnreachable`, `signalingTimeout`, `roomExpired`, `roomFull`, `invalidCode`, `rateLimited`. Each maps to a localized VI-primary/EN string (FR-022/023). No raw exception text reaches the user (Constitution IV/V).

---

## Config (`lib/core/config/app_config.dart` — EDIT)

| New/changed field | Type | dev | prod |
|---|---|---|---|
| `signalingEndpoint` | `Uri` | `ws://<localhost/LAN>:8080` | `wss://<placeholder>` |
| `iceServers` | `List<RtcIceServer>` | Google STUN | Google STUN |

`RtcIceServer` (existing) already supports `urls` + optional `username`/`credential` → TURN hook needs no new type (R-07). Endpoint + ICE config set in `main_dev.dart` / `main_prod.dart`, never at call sites (Constitution VIII).

---

## Relationships (one diagram)

```
PairingCubit (features/pairing, 4-state)
   └─injects→ Host/JoinSessionUseCase ─→ PairingRepository
                                            └─impl wraps→ SignalingClient (core/services/signaling)
                                                              │ owns one WebSocket (web_socket_channel)
                                                              │ speaks SignalingFrame (shared pkg)  ←──┐
                                                              ├─emits→ Stream<PairingState>            │ same
                                                              └─produces→ WebSocketSignalingChannel    │ codec
                                                                            implements SignalingChannel (#002 seam)
                                                                            └─consumed by→ TransferEngine (#002, unchanged)

server/ RoomManager ── Map<code, Room{host,guest,expiry}> ── PeerConnection{RateLimiter} ── speaks SignalingFrame ──┘
```
