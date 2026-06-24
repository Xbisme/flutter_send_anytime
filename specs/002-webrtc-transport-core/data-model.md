# Phase 1 Data Model: WebRTC Transport & Transfer Protocol Core

**Feature**: `002-webrtc-transport-core` | **Date**: 2026-06-24

All types live in `lib/core/domain/transfer/` (entities, immutable) and `lib/core/services/signaling/` (signaling message). Immutable models use `@freezed`; JSON-serializable ones (manifest, signaling/protocol control messages) add `json_serializable`. Enums and value objects without serialization can be plain Dart.

---

## Enums & value objects

### `TransferPhase` (enum) — `transfer_state.dart`
The single source-of-truth state machine value.

```
idle → connecting → handshaking → transferring → done
                                              ↘ failed
   (any non-terminal) ───────────────────────→ cancelled
```

| Value | Meaning |
|---|---|
| `idle` | Engine created, nothing started. |
| `connecting` | Peer connection + ICE establishing. |
| `handshaking` | Connected; exchanging manifest + accept/reject. |
| `transferring` | Streaming file chunks. |
| `done` | All files transferred & verified (terminal). |
| `failed` | A typed failure occurred (terminal; carries `AppFailure`). |
| `cancelled` | Either side cancelled (terminal). |

**Transition rules**: forward-only through the happy path; `cancelled` reachable from any non-terminal phase; `failed` reachable from any non-terminal phase; terminal phases are final (FR-026) — a new transfer needs a new engine instance.

### `FileItemStatus` (enum) — `file_transfer_item.dart`
`pending` → `transferring` → `verifying` → `completed` | `failed`.

### `TransferRole` (enum)
`sender` | `receiver`.

---

## Entities

### `FileSource` (abstract) + `DiskFileSource` — `file_source.dart`
The engine's input abstraction (decouples from any file-picker, FR-018).

| Member | Type | Notes |
|---|---|---|
| `name` | `String` | Display file name (basename only; no directory). |
| `size` | `int` | Bytes; `>= 0` (0 allowed — edge case). |
| `mimeType` | `String?` | Best-effort content type; nullable. |
| `openRead()` | `Stream<List<int>>` | Streamed read; MUST NOT load whole file. |

- `DiskFileSource(path)`: wraps a `dart:io` `File`; `openRead()` → `File.openRead()`; `size` from `File.length()`; `name` from basename. The raw path is held privately and **never logged**.
- **Validation**: `name` must be a basename — any path separators are stripped/rejected (defense for the receiver side too).

### `TransferSession` — `transfer_session.dart`
One unit of work; owns exactly one manifest's worth of files.

| Field | Type | Rules |
|---|---|---|
| `id` | `String` | UUID v4. |
| `items` | `List<FileTransferItem>` | `length >= 1`; order = transfer order (FR-013). |
| `totalBytes` | `int` | Σ item sizes. |
| `fileCount` | `int` | `== items.length`. |
| `protocolVersion` | `int` | `kProtocolVersion`. |

Derived: `overallBytesTransferred` = Σ item `bytesTransferred`.

### `FileTransferItem` — `file_transfer_item.dart`
One file within a session (mutable progress fields modeled via `copyWith` on a freezed class).

| Field | Type | Rules |
|---|---|---|
| `index` | `int` | Position in session (0-based). |
| `name` | `String` | Basename; collision-resolved at finalize (receiver). |
| `size` | `int` | Declared total bytes. |
| `mimeType` | `String?` | Optional. |
| `sha256` | `String?` | Sender: filled after streaming. Receiver: the expected value from `fileComplete`. |
| `bytesTransferred` | `int` | `0..size`. |
| `status` | `FileItemStatus` | See enum. |
| `failure` | `AppFailure?` | Set when `status == failed`. |
| `quarantinePath` | `String?` | Receiver only; private, never logged. |
| `finalPath` | `String?` | Receiver only; set after atomic rename. |

### `TransferManifest` — `transfer_manifest.dart` (`@freezed` + JSON)
Sent once before bytes flow; basis for the receiver's accept/reject (FR-012). **Does not contain hashes** (R-04).

```jsonc
{
  "v": 1,                 // protocol version
  "sessionId": "uuid",
  "fileCount": 3,
  "totalBytes": 12345678,
  "files": [
    { "i": 0, "name": "report.pdf", "size": 204800, "mime": "application/pdf" }
  ]
}
```
- **Validation on receive**: `v == kProtocolVersion` (else `AppFailure.unexpected`/version failure); `fileCount == files.length`; each `name` is a basename (reject path traversal — FR-023); `size >= 0`; `totalBytes == Σ sizes`. Any breach → reject as a named failure, no crash (FR-015).

### `TransferProgress` — `transfer_state.dart`
Progress snapshot for consumers to compute %/speed/ETA (FR-025).

| Field | Type |
|---|---|
| `overallBytesTransferred` | `int` |
| `overallTotalBytes` | `int` |
| `currentFileIndex` | `int?` |
| `currentFileBytesTransferred` | `int` |
| `currentFileTotalBytes` | `int` |

### `TransferSnapshot` — `transfer_state.dart` (emitted on the engine's stream)

| Field | Type | Notes |
|---|---|---|
| `phase` | `TransferPhase` | Current state-machine value. |
| `role` | `TransferRole` | sender/receiver. |
| `progress` | `TransferProgress` | Byte counters. |
| `items` | `List<FileTransferItem>` | Per-file view. |
| `failure` | `AppFailure?` | Non-null iff `phase == failed`. |

---

## Signaling types — `signaling_channel.dart`

### `SignalingMessage` (`@freezed` sealed + JSON) — metadata only (FR-002/031)

| Variant | Payload | Notes |
|---|---|---|
| `offer` | `sdp: String` | From sender. |
| `answer` | `sdp: String` | From receiver. |
| `iceCandidate` | `candidate, sdpMid, sdpMLineIndex` | Trickle ICE. |
| `bye` | — | Optional graceful close. |

> Carries **no file bytes ever**. SDP/ICE contents are **never logged** (they contain IPs).

### `SignalingChannel` (abstract interface)
```dart
abstract interface class SignalingChannel {
  Stream<SignalingMessage> get incoming;        // messages from the remote peer
  Future<void> send(SignalingMessage message);  // to the remote peer
  Future<void> close();
}
```
- `LoopbackSignalingChannel`: created as a connected **pair**; each instance's `send` pushes into the other's `incoming` controller (FR-007). Used by all engine tests and any in-process demo.

---

## Wire protocol types — `transfer_protocol.dart`

Control-message payloads (JSON, after the 1-byte opcode). See [contracts/transfer-protocol.md](contracts/transfer-protocol.md) for opcodes & framing.

| Message | Fields |
|---|---|
| `ManifestMessage` | the `TransferManifest` above |
| `AcceptMessage` | `sessionId` |
| `RejectMessage` | `sessionId`, optional `reason` (enum code, not free text) |
| `FileStartMessage` | `index`, `name`, `size` |
| `FileCompleteMessage` | `index`, `sha256` |
| `SessionCompleteMessage` | `sessionId` |
| `CancelMessage` | `sessionId`, `origin` (sender/receiver) |

(`chunk` is not a JSON message — it is opcode + raw bytes.)

---

## `AppFailure` extension (FR-029/030) — `failures/app_failure.dart`

Add these freezed variants to the existing sealed class (keep `unexpected`, `notImplemented`):

| Variant | Trigger |
|---|---|
| `peerUnreachable` | Connection never establishes within `kConnectTimeout`. |
| `iceFailed` | ICE negotiation fails. |
| `connectionLost` | Mid-session disconnect / handshake or stall timeout. |
| `dataChannelClosed` | Data channel closes unexpectedly. |
| `transferCancelled` | Either side cancelled. |
| `transferRejected` | Receiver rejected the manifest (FR-014A). |
| `integrityCheckFailed({int fileIndex})` | Received file hash ≠ expected (FR-020). |
| `fileReadFailed` | Sender cannot read a source file. |
| `fileWriteFailed` | Receiver cannot write quarantine/destination. |
| `storageFull` | Write failed for lack of space. |
| `networkError` | Generic transport/network error. |

> These are **typed only** — no user-facing strings; localization happens at the UI layer (#004/#005), Constitution XIV.

---

## Relationships

```
TransferEngine ──drives──▶ TransferPhase (state machine)
      │ emits Stream<TransferSnapshot>
      │ uses
      ├─▶ SignalingChannel (abstract)  ──impl──▶ LoopbackSignalingChannel
      ├─▶ RtcPeerConnection (wraps flutter_webrtc) ──opens──▶ RTCDataChannel
      └─▶ TransferSession 1──*▶ FileTransferItem
                  │ describes
                  └─▶ TransferManifest (sent first)
       sender reads ──▶ FileSource (DiskFileSource)
       receiver writes ──▶ quarantine .part ──atomic rename──▶ finalPath
```

## Invariants (enforced & tested)

1. **No bytes over signaling** — `SignalingMessage` has no byte-carrying variant (FR-031).
2. **Hash gates completion** — a `FileTransferItem` reaches `completed` only after `verifying` passes (FR-020).
3. **No truncated destination** — `finalPath` is set only via atomic rename from a fully-verified quarantine file (FR-021/022).
4. **Fail-fast session** — first item `failed` ⇒ session `failed`, remaining items stay `pending` and are never written (FR-013A).
5. **Bounded memory** — at most `kHighWaterMark + kChunkSize` of file bytes buffered at once, regardless of `size` (FR-017).
6. **Terminal is final** — once `done`/`failed`/`cancelled`, no further snapshots; reuse requires a new engine (FR-026).
7. **No sensitive data in logs** — names/paths/IPs/SDP/ICE/payload never logged (FR-032).
