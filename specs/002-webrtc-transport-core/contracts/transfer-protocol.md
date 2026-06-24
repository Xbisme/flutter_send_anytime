# Contract: Transfer Wire Protocol

**Feature**: `002-webrtc-transport-core` | **Version**: `kProtocolVersion = 1`

Defines the framing carried over the single reliable/ordered `RTCDataChannel`. Pure Dart, fully unit-testable without WebRTC (`transfer_protocol.dart` encode/decode round-trips). Satisfies FR-014 (explicit, versioned protocol) and Constitution VIII (centralized constants, no string-literal duplication).

## Channel

- Label: `kDataChannelLabel = "safesend-transfer"`.
- Config: `ordered: true`, reliable (no `maxRetransmits` / `maxPacketLifeTime`).
- Created by the **sender** (offerer). Receiver obtains it via `onDataChannel`.

## Frame format

Every message on the channel is binary: **`[1-byte opcode][payload]`**.

| Opcode | Name | Payload | Direction |
|---|---|---|---|
| `0x01` | `manifest` | UTF-8 JSON `ManifestMessage` | sender → receiver |
| `0x02` | `accept` | UTF-8 JSON `AcceptMessage` | receiver → sender |
| `0x03` | `reject` | UTF-8 JSON `RejectMessage` | receiver → sender |
| `0x04` | `fileStart` | UTF-8 JSON `FileStartMessage` | sender → receiver |
| `0x05` | `chunk` | **raw file bytes** (≤ `kChunkSize`) | sender → receiver |
| `0x06` | `fileComplete` | UTF-8 JSON `FileCompleteMessage` (incl. `sha256`) | sender → receiver |
| `0x07` | `sessionComplete` | UTF-8 JSON `SessionCompleteMessage` | sender → receiver |
| `0x08` | `cancel` | UTF-8 JSON `CancelMessage` | either → either |

Ordering is guaranteed by the channel; **no per-chunk sequence numbers**. A file's bytes are exactly the concatenation of every `chunk` frame received between its `fileStart` and `fileComplete`.

## Happy-path sequence (3-file session)

```
sender                                   receiver
  │ ── manifest ─────────────────────────▶ │  (onManifest hook decides)
  │ ◀──────────────────────────── accept ── │
  │ ── fileStart(0) ─────────────────────▶ │
  │ ── chunk … chunk ────────────────────▶ │  (stream to quarantine, hash streaming)
  │ ── fileComplete(0, sha256) ──────────▶ │  (verify → atomic rename) 
  │ ── fileStart(1) … fileComplete(1) ───▶ │
  │ ── fileStart(2) … fileComplete(2) ───▶ │
  │ ── sessionComplete ──────────────────▶ │
  ▼ done                                    ▼ done
```

## Reject sequence

```
sender ── manifest ─▶ receiver        (onManifest returns false)
sender ◀── reject ─── receiver
sender: AppFailure.transferRejected → teardown (no files)
receiver: teardown (no files)
```

## Cancel sequence (either side)

```
X ── cancel(origin) ─▶ Y
both: stop pump, delete any in-flight quarantine .part, close channel + peer conn,
      phase → cancelled, AppFailure.transferCancelled
```

## Validation rules (FR-015, FR-023) — reject as named failure, never crash

- Unknown opcode → `AppFailure.unexpected` (or `networkError`), teardown.
- `manifest.v != kProtocolVersion` → version-mismatch failure.
- `fileCount != files.length`, `totalBytes != Σ sizes`, negative size → reject.
- Any `name` containing a path separator or `..` (path traversal) → reject (no write outside the sanctioned destination).
- `chunk` received before `fileStart`, or bytes exceeding declared `size` → `connectionLost`/protocol failure.
- `fileComplete.sha256` mismatch with the receiver's streamed hash → `integrityCheckFailed(fileIndex)`; quarantine `.part` deleted; session fails (fail-fast, FR-013A).
- Malformed JSON in any control frame → named failure, teardown.

## Constants (`transfer_constants.dart`)

| Constant | Value | Purpose |
|---|---|---|
| `kProtocolVersion` | `1` | Manifest/version gate. |
| `kDataChannelLabel` | `"safesend-transfer"` | Channel id. |
| `kChunkSize` | `16 * 1024` | Per-`chunk` payload (R-01). |
| `kLowWaterMark` | `256 * 1024` | `bufferedAmountLowThreshold` (R-03). |
| `kHighWaterMark` | `1024 * 1024` | Pause threshold (R-03). |
| `kConnectTimeout` | `Duration(seconds: 30)` | Establish (R-06). |
| `kHandshakeTimeout` | `Duration(seconds: 15)` | Manifest+accept (R-06). |
| `kStallTimeout` | `Duration(seconds: 30)` | Zero-progress watchdog (R-06). |
| `kQuarantineDirName` | `".safesend_tmp"` | Quarantine subdir (R-05). |

> Opcodes are defined once as named constants (no magic numbers scattered) — Constitution VIII.
