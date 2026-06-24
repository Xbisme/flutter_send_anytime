# Data Model: Send Flow (Gửi)

Presentation-layer entities introduced by #004. The transfer/session/manifest/progress entities already exist in `core/domain/transfer` (#002) and are **reused unchanged**; this feature adds only the selection model and the progress projection the UI binds to.

## Reused (from #002 — not redefined here)

- `FileSource` / `DiskFileSource` — streamed read seam (`name`, `size`, `mimeType`, `openRead()`).
- `TransferSession` (`fromSources`, `totalBytes`, `fileCount`, `toManifest()`).
- `TransferSnapshot` (`phase`, `role`, `progress`, `items`, `failure`, `isTerminal`) + `TransferProgress`, `TransferPhase`, `TransferRole`, `FileTransferItem`/`FileItemStatus`.
- `PairingCode` (`value`, `expiresAt`, `remaining`, `isExpired`) + `PairingState` (#003).
- `AppFailure` (#001/#002/#003) — all needed variants already exist (see §Failure mapping).

## New — `SelectedFile`

A single user-picked file in the selection tray.

| Field | Type | Notes |
|---|---|---|
| `source` | `FileSource` | The streamable source (a `DiskFileSource` from the picker). |
| `name` | `String` | `source.name` (basename only; never a full path — Constitution I). |
| `size` | `int` | `source.size` in bytes (`>= 0`; 0 allowed). |
| `mimeType` | `String?` | Best-effort type from the picker (drives the file-type chip color). |

Derived: `extension` (uppercased, for the `FileChip` label + color lookup).

## New — `SendSelection`

The whole selection the user is assembling (the `loaded` payload of `SendSelectionCubit`). Immutable (`@freezed`).

| Field | Type | Notes |
|---|---|---|
| `files` | `List<SelectedFile>` | Insertion order; may contain duplicate names (engine resolves collisions). |

Derived getters:
- `count : int` = `files.length`.
- `totalBytes : int` = sum of `files[].size`.
- `isEmpty : bool` — gates the "Tiếp tục" CTA (FR-005).
- `toSources() : List<FileSource>` — what gets handed to `/connect` then `StartSendUseCase`.

**Validation / rules**:
- Continue is allowed only when `!isEmpty` (FR-005).
- Removing a file rebuilds the list and recomputes `count`/`totalBytes` (FR-004).
- The selection survives navigation into pairing/transfer (back-stack), so a retry preserves it (FR-025a / Clarification Q2).

## New — `SendTransferView`

The projection of the engine's `TransferSnapshot` that the Progress/Complete screens bind to (the `loaded` payload of `SendTransferCubit`). Computed, never authoritative — the engine stream is the source of truth (Constitution VIII).

| Field | Type | Derivation |
|---|---|---|
| `phase` | `TransferPhase` | from snapshot. |
| `overallProgress` | `double` (0–1) | `overallBytesTransferred / overallTotalBytes` (guard /0). |
| `bytesSent` / `bytesTotal` | `int` | from `progress`. |
| `speedBytesPerSec` | `double` | moving-average of Δbytes/Δt across snapshots (R5). |
| `etaSeconds` | `int?` | `remainingBytes / speed`; null until a stable speed exists. |
| `currentIndex` | `int?` | `progress.currentFileIndex`. |
| `currentFileName` | `String?` | `items[currentIndex].name`. |
| `fileCount` | `int` | `items.length`. |
| `items` | `List<FileTransferItem>` | from snapshot (per-file status). |
| `peerLabel` | `String` | **generic localized label** until #010 (Clarification Q1). |
| `elapsed` | `Duration` | wall-clock since `transferring` began (for the Complete summary). |
| `failure` | `AppFailure?` | set on `failed`. |

**Terminal mapping** (drives which view renders + side effects via `BlocListener`):
- `done` → Complete view ("Đã gửi N files · X MB tới <peerLabel> trong m:ss"); success haptic.
- `failed` → Failure view: localized message + **Retry** (preserves selection → re-pair) and **Return**.
- `cancelled` → exit the flow (after the confirm dialog).

## State flow (the send pipeline)

```
SendSelectionCubit            PairingCubit (Connect)             SendTransferCubit
─────────────────             ──────────────────────            ─────────────────
AppInitial
  │ pickFiles()
  ▼
AppLoaded(SendSelection)
  │ "Tiếp tục" (count>0)
  │  push /connect ───────────► host(): hosting(code)
  │                              countdown (PairingCode.remaining)
  │                              peerPresent → connected
  │                              takeTransport() ──┐
  │  ◄── ConnectResult(transport)                 │
  │ push /send/progress(sources, transport) ──────┴──► startSend(sources, transport)
  │                                                     connecting? handshaking → transferring
  │                                                     (snapshot stream → SendTransferView)
  │                                                     ├─ done → Complete
  │                                                     ├─ failed → Failure (Retry → pop to selection)
  │                                                     └─ cancelled → exit
  ▼
"Gửi tiếp" → reset to empty SendSelection
```

## Failure mapping (all variants already exist in `AppFailure`)

| Condition (spec) | `AppFailure` variant | UI |
|---|---|---|
| Code expired before peer (FR-011) | `roomExpired` | "Mã đã hết hạn" + lấy mã mới. **Authoritative source = the relay's `roomExpired`** (server-side TTL), not the local countdown; `PairingCode.remaining` only drives the on-screen timer. |
| Relay unreachable (FR-012) | `signalingUnreachable` | retry |
| Relay/handshake timeout | `signalingTimeout` | retry |
| Room full | `roomFull` | retry |
| Invalid code (receiver-entered; mostly #005) | `invalidCode` | n/a on send |
| Rate-limited | `rateLimited` | retry later |
| Receiver declines (FR-024) | `transferRejected` | "Người nhận đã từ chối" + retry/return |
| Connection lost mid-transfer (FR-025) | `connectionLost` | "Mất kết nối" + retry |
| File unreadable at send time (FR-026) | `fileReadFailed` | specific read-failure message |
| Cancelled | `transferCancelled` | exit (no error toast) |

**Localization**: extend the existing `PairingFailureL10n` mapper (or add a parallel `SendFailureL10n`) to cover `transferRejected` / `connectionLost` / `fileReadFailed` with new ARB keys (VI primary + EN). No new `AppFailure` variants are required.
