# Phase 1 Data Model: Nearby Radar (Gần đây)

**Feature**: #009 | **Date**: 2026-06-26 | **Plan**: [plan.md](plan.md)

No database schema change. History reuses `transfer_records` with the already-reserved
`PairingMethod.nearby` value (#006) — **no drift migration**. All entities below are in-memory /
runtime only (Clarification: nothing about discovery is persisted).

---

## Core domain models

### `NearbyDevice` (core/domain/pairing/nearby_device.dart)

A Safe Send device currently advertising on the local network, as seen by a browsing receiver.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Stable per-advertisement identity (mDNS service instance name/key). Distinguishes same-named devices; used for self-suppression and stale removal. |
| `displayName` | `String` | Human-recognizable name to show (generated default until #010 — see research D5). |
| `code` | `String` | The 6-digit #003 rendezvous code, read from the TXT `c` record. Validated via `SignalingProtocol.isValidCode` before exposure/join. |
| `lastSeen` | `DateTime` | Freshness for stale removal (SC-003); refreshed on re-resolve. |

- **Immutable** `@freezed`. Equality by `id`.
- **TXT codec** (static helpers, reusing version `v=1`):
  - `Map<String, String> toTxt({required String code})` → `{ 'v': '1', 'c': code }` (encoded to `Uint8List` at the `nsd` boundary).
  - `String? codeFromTxt(Map<String, Uint8List?> txt)` → decode + validate (`v==1`, `isValidCode(c)`); returns null on mismatch (entry skipped).
- **Avatar derivation**: leading character(s) of `displayName` → reuses the existing `DeviceRow` gradient-avatar logic (no new model field).

### Constants (core/constants/nearby_constants.dart)

| Constant | Value | Notes |
|---|---|---|
| `kNearbyServiceType` | `'_safesend._tcp'` | mDNS service type (also listed in iOS `NSBonjourServices`). |
| `kNearbyTxtVersionKey` / `kNearbyTxtCodeKey` | `'v'` / `'c'` | TXT record keys. |
| `kNearbyTxtVersion` | `'1'` | Current payload version. |
| `kNearbyStaleTimeout` | `Duration` (~10 s) | Freshness window for removing un-refreshed devices (SC-003). |

---

## Additive core seam fields (no breaking change)

### `ConnectResult.method` (core/domain/pairing/connect_handoff.dart)

`PairingMethod` already includes `nearby` (reserved #006). #009 only **sets** it on the nearby receiver
path and threads it through the existing `ConnectResult.method` → transfer cubits → #006 mappers (same
shape as #007 `qr` / #008 `shareLink`). No new field — an additive use of the existing enum value.

### `ReceiveEntryRequest.openNearby` (core/domain/pairing/receive_entry_request.dart)

The existing #008 `ReceiveEntryRequest` (`{bool openScanner, String? autoJoinCode}`) gains an additive
`bool openNearby = false`. Home "Thiết bị gần" passes `openNearby: true` so the existing Receive entry
surface (ui-design §Screen 04) emphasizes/scrolls to the nearby device-row section. No new route.

---

## Cubit state shapes (BLoC 4-state, Constitution III)

### `NearbyAdvertiseCubit` / `NearbyAdvertiseState` (features/pairing/presentation/connect/)

Screen-scoped (`@injectable`). Drives the sender's "Gần đây" tab advertising.

```
initial
loading                                   // requesting permission / starting advertise
loadedAdvertising({required String code}) // broadcasting the live hosting code
error({required AppFailure failure})      // permissionDenied / networkError
```

- `start(String liveHostingCode)` on tab-enter (after permission) → `advertise`. `stop()` on
  tab-leave/background. Reuses the live #003 code (FR-009) — never generates a code.

### `NearbyDiscoveryCubit` / `NearbyDiscoveryState` (features/receive/presentation/)

Screen-scoped (`@injectable`). Drives the receiver's browse surface.

```
initial
loading                                                  // requesting permission / starting discovery
loadedDiscovering({required List<NearbyDevice> devices}) // live self-updating list (may be empty → empty-state)
error({required AppFailure failure})                     // permissionDenied (→ blocked state) / networkError
```

- Subscribes to `NearbyDiscoveryService.discover()` stream; applies self-suppression + stale removal.
- `tap(NearbyDevice)` → hands `device.code` to the existing `joinWithCode` path (no state of its own beyond
  forwarding); join failures surface via the existing receive/pairing failure handling + remove the stale
  entry (FR-017).
- Empty `devices` list renders the same-Wi-Fi empty-state (FR-016); `error(permissionDenied)` renders the
  permission-blocked state with retry/open-Settings (FR-012) — distinct surfaces.

---

## State transitions (lifecycle)

```
Sender (advertise):
  enter "Gần đây" tab ──ensurePermission──▶ loading ──advertise(liveCode)──▶ loadedAdvertising
  leave tab / background / receiver-connected ──stopAdvertise──▶ (cubit closed / idle)
  permission denied ──▶ error(permissionDenied)  [Android 13+; iOS relies on OS prompt]

Receiver (browse):
  enter nearby surface ──ensurePermission──▶ loading ──discover()──▶ loadedDiscovering(devices…)
    device resolved ──▶ add/refresh in list
    service lost / stale timeout ──▶ remove from list
    tap(device) ──isValidCode──▶ joinWithCode(code) ──▶ existing accept/reject prompt
       join fails (expired/full/unreachable) ──▶ toast + remove entry, stay on radar
  leave surface / background ──stopDiscover──▶ (cubit closed / idle)
  permission denied ──▶ error(permissionDenied) → blocked state (retry / open Settings)
```

No persisted state; closing a cubit tears down its `nsd` advertise/discovery handle and stream
subscription (Constitution III: all cubits closed).
