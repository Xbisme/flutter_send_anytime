# Data Model: Background Transfer (#011)

**Date**: 2026-06-27 · **Branch**: `011-background-transfer`

This feature introduces **no persisted data** (no drift tables, no shared_preferences keys) and **no protocol/manifest fields**. It defines in-memory, derived view models that project the existing #002 transfer snapshot onto the OS background surfaces. All types live in `lib/core/` and are pure Dart (testable without platform plugins).

---

## Existing types consumed (not modified)

- **`TransferSnapshot`** (#002, `core/domain/transfer/`) — the single source of truth emitted by the transfer state machine: phase (`idle → connecting → handshaking → transferring → done | failed | cancelled`), per-file + overall byte progress, current file index/count, and timing inputs. The surfaces read from this; they do not extend it.
- **`TransferView`** (#005, `core/domain/transfer/`) — the role-neutral projection already used to render the in-app progress/complete screens (percent, speed, ETA, bytes done/total, current file). The background surfaces reuse the **same** projection logic (`TransferProgressProjector`) so they never disagree with the in-app screen.
- **`DataTransport`** / transfer direction enum — already core-typed; direction (send/receive) is read for accent + icon + verb.

## New types (in-memory only)

### `ActiveTransferHandle` (core)
Published by a Send/Receive cubit to the coordinator when a transfer enters `transferring`; cleared on terminal state. Lets `core/` drive the surfaces without importing features (Constitution XI).

| Field | Type | Notes |
|---|---|---|
| `snapshots` | `Stream<TransferSnapshot>` | the live #002 stream for this transfer (single source of truth) |
| `direction` | `TransferDirection` | send / receive — chooses accent, icon, verb |
| `peerName` | `String` | device/peer label (from #010 senderName / generic fallback) |
| `fileCount` | `int` | number of files in the session |
| `progressRoute` | `String` | `AppRoutes.sendProgress` or `receiveProgress` — where a surface tap returns |
| `onCancel` | `void Function()` | invokes the same cancel path as the in-app Cancel button |

> `onCancel` is the only behavioral coupling back into the feature; it is a plain callback, not a cubit reference (Constitution III: no direct cubit-to-cubit refs).

### `BackgroundTransferState` (core) — the surface view model
A pure projection of one `TransferSnapshot` + the handle's static metadata. Recomputed on each snapshot; handed to both platform controllers.

| Field | Type | Derivation |
|---|---|---|
| `direction` | `TransferDirection` | from handle |
| `peerName` | `String` | from handle |
| `fileCount` | `int` | from handle |
| `phase` | `BackgroundPhase` | `transferring \| done \| failed \| cancelled` (mapped from snapshot phase) |
| `percent` | `int` (0–100) | from `TransferView` |
| `speedLabel` | `String` | localized mono, e.g. "2.4 MB/s" (intl) |
| `bytesLabel` | `String` | localized mono, e.g. "153 / 240 MB" (intl) |
| `etaLabel` | `String` | localized mono, e.g. "còn 0:48" (intl) |
| `title` | `String` | localized from ARB, e.g. "Đang gửi · 18 tệp" |
| `peerLine` | `String` | localized, e.g. "tới Minh's iPhone" / "từ MacBook của Linh" |

> All numeric labels are pre-formatted in Dart so the native iOS widget renders given strings only (Constitution XIV — no strings duplicated in Swift).

### `BackgroundPhase` (core enum)
`transferring` · `done` · `failed` · `cancelled`. Drives whether the surface shows live progress, a final state, or is dismissed.

## Surface lifecycle (state transitions)

The coordinator owns one surface lifecycle at a time (single active transfer — FR-018).

```
            app backgrounded / locked
 (no surface) ───────────────────────────► SHOWING(transferring)
      ▲                                          │
      │                                          │ each snapshot → update(BackgroundTransferState)
      │                                          │
      │  app foregrounded                        ▼
      └──────────────  surface ended  ◄──── terminal snapshot (done/failed/cancelled)
                       + cleaned up           → update to final state, then dismiss
                                              (FR-010)
```

- **Enter SHOWING**: app moves to background/locked while a handle is active and `phase == transferring` → start the platform surface (iOS: start Live Activity; Android: start foreground service + ongoing notification).
- **Update**: every `TransferSnapshot` → recompute `BackgroundTransferState` → push to the active controller. Throttled to a sane cadence (see quickstart) to avoid surface spam.
- **Terminal**: a `done/failed/cancelled` snapshot → push the final state briefly, then end/dismiss the surface and clear the handle (FR-010). On Android, terminal also stops the foreground service.
- **Foreground return**: app returns to foreground → reconcile (the in-app screen and surface share the same snapshots, so they already agree, FR-009); surfaces created during the background stint are ended so nothing lingers in-app.
- **Cancel from surface (Android)**: notification "Huỷ" → `handle.onCancel()` (immediate) → engine cancels on both peers → terminal snapshot flows through the normal path → surface dismissed.
- **OS-suspend (iOS, mid-background)**: the transfer fails via the existing engine interruption detection; on next foreground the in-app failure + retry is shown (US3) and any stale Live Activity is ended.

## Validation / invariants

- **At most one surface** exists at any time (single active transfer) — re-entrancy guarded against rapid background/foreground toggles (FR-018).
- **No surface without an active `transferring` handle** — a terminal or absent transfer never has a live surface.
- **Surfaces never outlive the transfer** — every terminal snapshot ends the surface (FR-010); a foreground return ends any background-created surface.
- **No logging** of `peerName`, byte counts, or file metadata by the coordinator/controllers (Principle I / FR-014). Logs carry phase + surface-lifecycle events only (e.g., "live-activity start failed", error-type only).

## Persistence / migrations

None. No drift schema change, no `shared_preferences` keys, no manifest/protocol fields. (History records are still written by the existing #006 `RecordTransferUseCase` on terminal state — unchanged by this feature.)
