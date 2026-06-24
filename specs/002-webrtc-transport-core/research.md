# Phase 0 Research: WebRTC Transport & Transfer Protocol Core

**Feature**: `002-webrtc-transport-core` | **Date**: 2026-06-24

Resolves every candidate "settled at planning" item from the spec's Assumptions plus the dependency/native verifications required by Constitution XV/VII. Format per decision: **Decision · Rationale · Alternatives considered**.

---

## Dependency verification (Constitution XV)

All three packages verified on pub.dev on 2026-06-24.

| Package | Version | Notes |
|---|---|---|
| `flutter_webrtc` | **1.5.2** | Android `minSdk ≥ 23` required (project = **26** ✓). iOS WebRTC framework OK at deployment target **13.0** ✓. Declares camera/mic permissions, but **data-channel-only** usage never calls `getUserMedia`, so no runtime prompts and no `NS*UsageDescription` strings needed for this feature. Release Android builds need Java 8 + Proguard keep rules (add at integration; no Dart impact). |
| `crypto` | **3.0.7** | `Sha256().startChunkedConversion(sink)` exposes a chunked `ByteConversionSink` — `add(chunk)` per read, `close()` finalizes. Exactly matches streamed per-file hashing (FR-019). |
| `uuid` | **4.5.3** | v4 UUIDs for session ids + quarantine temp-file names. |

**Decision**: Add all three with caret constraints (`flutter_webrtc: ^1.5.2`, `crypto: ^3.0.7`, `uuid: ^4.5.3`). Commit `pubspec.lock` (+ `ios/Podfile.lock` after first `pod install`).
**Rationale**: Native minimums already satisfied by the project; no transitive surprises expected for `crypto`/`uuid` (pure Dart).
**Alternatives considered**: Hand-rolled WebRTC bindings (rejected — `flutter_webrtc` is the de-facto standard); `pointycastle` for hashing (rejected — heavier, `crypto` is dart.dev-published and has the streaming sink).

---

## R-01 — Chunk size

**Decision**: **16 KiB** (16384 bytes) payload per data-channel binary message; defined as a single constant `kChunkSize` in `transfer_constants.dart` and easily tunable.
**Rationale**: 16 KiB is broadly safe across SCTP/WebRTC implementations (well under the 64 KiB single-message guidance and far under native max-message limits), keeps per-message overhead negligible, and bounds the read buffer. Throughput at this size is ample for a phone link; the real-link tuning point is validated by the deferred two-device smoke, not guessed now.
**Alternatives considered**: 256 KiB (higher throughput but risks exceeding portable message limits and enlarges the in-flight memory window); 64 KiB (viable; kept as the first tuning step if smoke testing shows throughput-bound behavior).

## R-02 — Protocol framing & ordering

**Decision**: One **reliable, ordered** `RTCDataChannel` (`ordered: true`, no `maxRetransmits`/`maxPacketLifeTime`). Every message is framed as **`[1-byte opcode][payload]`**. Control opcodes (`manifest`, `accept`, `reject`, `fileStart`, `fileComplete`, `sessionComplete`, `cancel`) carry a **UTF-8 JSON** payload; the `chunk` opcode carries **raw file bytes** as payload. Because the channel guarantees ordering, **no per-chunk sequence numbers** are sent.
**Rationale**: Reliable+ordered SCTP delivers bytes in order without loss, so sequence numbers/acks-for-ordering are redundant complexity (Constitution XIII). A 1-byte opcode discriminator is the minimal explicit, versioned framing that still satisfies "explicit protocol" (Constitution VIII / FR-014). JSON control frames are easy to version and validate; binary chunk frames avoid base64 bloat.
**Alternatives considered**: All-JSON (rejected — base64 of file bytes is ~33% overhead); length-prefixed multiplexed frames with sequence numbers (rejected — ordering already guaranteed, YAGNI); separate channels for control vs data (rejected — extra negotiation, no benefit for sequential transfer).

## R-03 — Backpressure / flow control

**Decision**: Set `dataChannel.bufferedAmountLowThreshold = kLowWaterMark` (256 KiB). The sender's file-read pump checks `dataChannel.bufferedAmount`; when it exceeds `kHighWaterMark` (1 MiB) it **pauses** reading and `await`s the `onBufferedAmountLow` event before resuming. Combined with 16 KiB chunks this bounds in-flight memory to ≈ high-water + one chunk.
**Rationale**: Directly implements FR-011 and the bounded-memory guarantee (FR-017) using the channel's native signal rather than arbitrary sleeps. Keeps a fast sender from overrunning a slow receiver or the OS send buffer.
**Alternatives considered**: Fixed-delay pacing (rejected — either too slow or still overruns); application-level credit/ACK windowing (rejected — duplicates SCTP flow control, more protocol surface).

## R-04 — Where the per-file SHA-256 travels

**Decision**: The SHA-256 is **computed streaming on the sender as the file is read** and delivered to the receiver in the **`fileComplete`** frame. The `manifest` carries name/size/mime/count/total-bytes **but not the hash**. The receiver hashes streaming as it writes the quarantine file and compares to the `fileComplete` hash before finalizing.
**Rationale**: Putting the hash in the manifest would force a **full extra read of every file up front** (multi-GB → doubled I/O) just to populate the manifest. Computing during the single send pass and transmitting at file end is per-file integrity (FR-019/020) with no double-read. The manifest still gives the receiver everything it needs to decide accept/reject and to show sizes.
**Alternatives considered**: Hash in manifest (rejected — double read of large files); hash per chunk (rejected — over-granular; ordered channel + final whole-file hash already guarantees integrity); session-level hash (rejected by spec clarification — per-file only).

## R-05 — Atomic delivery & quarantine

**Decision**: Receiver writes incoming bytes to `"<destDir>/.safesend_tmp/<uuid>.part"` (a hidden quarantine subdir **on the destination volume**), `flush`/`close`es, verifies the hash, then **`File.rename`s** into the final destination path. On any failure/cancel the `.part` file (and empty quarantine dir) are deleted. Quarantine subdir is created lazily and cleaned on terminal states.
**Rationale**: `File.rename` is atomic within a single filesystem, so the final path never exists in a truncated/unverified state (FR-021/022, Constitution IX). Keeping the temp file on the **same volume** as the destination guarantees rename stays a metadata op (no cross-device copy).
**Alternatives considered**: System temp dir then move (rejected — likely a different volume → non-atomic cross-device copy); write directly to destination + delete on failure (rejected — a crash leaves a truncated real file).

## R-06 — Timeouts (no indefinite hangs)

**Decision**: Three configurable constants: `kConnectTimeout` (30 s) for ICE/connection establishment → `peerUnreachable`/`iceFailed`; `kHandshakeTimeout` (15 s) for manifest+accept exchange → `connectionLost`; `kStallTimeout` (30 s) of **zero byte progress** during `transferring` → `connectionLost`. A periodic/stall watchdog drives the last one.
**Rationale**: FR-027 requires bounded-time detection and no hangs. Explicit, named timeouts make every stuck state resolve to a typed `AppFailure`. Values are constants tuned later (and on real links during smoke).
**Alternatives considered**: Rely solely on WebRTC `iceConnectionState`/`connectionState` callbacks (kept for fast-path detection, but insufficient alone — a peer can stop sending without a state change, so the stall watchdog is still needed).

## R-07 — Filename collision auto-rename

**Decision**: If `name.ext` exists at the destination, append ` (n)` before the extension, incrementing `n` from 1 until a free name is found: `report.pdf` → `report (1).pdf` → `report (2).pdf`. Files with no extension get ` (n)` appended at the end. The collision check is performed at finalize time (just before rename), and also disambiguates two same-named files within one session.
**Rationale**: Confirmed in clarification (never overwrite). Matches the familiar Downloads/Files convention on both platforms; keeps existing user files safe (Constitution IX, data minimization of destructive ops).
**Alternatives considered**: ` (1)`-style with timestamp suffix (rejected — uglier, no benefit); overwrite (rejected by clarification); prompt user (rejected — engine has no UI; the consumer may add its own policy later).

## R-08 — ICE configuration (STUN/TURN)

**Decision**: Add an `iceServers` field to `AppConfig` (a list of ICE-server descriptors), **defaulting to empty** for both flavors in this feature. The engine reads it and builds the `RTCConfiguration` passed to `RTCPeerConnection`. Loopback tests pass an empty list (no ICE needed in-process).
**Rationale**: FR-005 requires injectable, non-hardcoded config. Empty is correct now (loopback needs no STUN; no real signaling exists until #003). #003 fills per-flavor STUN and the documented encrypted-only TURN fallback without touching the engine.
**Alternatives considered**: Hardcode a public STUN server now (rejected — premature, untestable here, violates "no hardcoded endpoints"); a dedicated `ConnectionConfig` class (deferred — `AppConfig` already exists and is DI-registered; promote later only if it grows).

## R-09 — Receiver accept/reject hook

**Decision**: The receive entry point takes an `onManifest` callback of shape `Future<bool> Function(TransferManifest manifest)` — return `true` to accept, `false` to reject. The loopback/test default auto-accepts (`(_) async => true`). A `false` (or a thrown error, treated as reject) sends a `reject` frame; the sender surfaces `AppFailure.transferRejected()` and both ends tear down with no file written.
**Rationale**: Implements FR-014A as a clean seam #005 wires its Accept/Reject UI into, with zero protocol change later. Async return lets the UI await a user decision.
**Alternatives considered**: A `Stream`/event the UI must respond to out-of-band (rejected — more wiring, race-prone); synchronous bool (rejected — UI decisions are inherently async).

---

## Cross-cutting decisions

### Roles & negotiation
**Decision**: The **sender is the offerer** (creates the data channel + SDP offer); the **receiver is the answerer**. The data channel is created by the sender with label `kDataChannelLabel` ("safesend-transfer"), `ordered: true`.
**Rationale**: One side must initiate; the sender naturally owns the session it starts. Single pre-negotiated channel keeps setup minimal.

### State machine ownership
**Decision**: `TransferEngine` holds the authoritative `TransferPhase` and emits a `TransferSnapshot` (phase + per-file + overall progress + optional `AppFailure`) on a **broadcast `Stream`**. Terminal phases (`done`/`failed`/`cancelled`) close the stream after emission. No parallel progress notion anywhere (FR-024).
**Rationale**: Single source of truth (Constitution VIII); broadcast so Send/Receive UIs (later) and tests can both listen.

### Logging discipline
**Decision**: All engine logging goes through `AppLogger`, logging **phase transitions, opcodes, sizes, counts, and typed failure names only** — never file names/paths, peer identifiers, IP addresses, SDP/ICE contents, or payload bytes.
**Rationale**: FR-032 / Constitution I. SDP and ICE candidates contain IPs, so they are never logged.

### DI registration
**Decision**: `TransferEngine` is `@injectable` (session-scoped — a fresh instance per transfer); `RtcPeerConnectionFactory` (thin wrapper around `createPeerConnection`) is `@lazySingleton`. `iceServers` is read from the already-registered `AppConfig`. No eager `@singleton` (Constitution XI).
**Rationale**: A transfer is a unit of work with its own lifecycle/resources; engines must not be shared across concurrent transfers.

### Memory budget (verification target)
**Decision**: Peak per-transfer memory ≈ `kHighWaterMark` (1 MiB) + `kChunkSize` (16 KiB) + small fixed overhead — **independent of file size**. Validated by a large-file (or simulated-large) loopback test asserting no proportional growth (SC-004).
**Rationale**: Direct consequence of streamed I/O (R-04/R-05) + backpressure (R-03).

---

## Outstanding / deferred (correctly NOT resolved here)

- **Real STUN/TURN endpoints & self-hostable signaling relay** → #003.
- **Sustained real-link throughput & NAT-traversal behavior** → deferred two-device smoke test (cannot run in CI), tracked in tasks.md.
- **Resume of interrupted transfers / trusted-peer auto-accept** → post-v1.0 (out of scope).
