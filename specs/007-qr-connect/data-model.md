# Phase 1 Data Model — #007 QR Connect

**Date**: 2026-06-25 · **Branch**: `007-qr-connect`

QR Connect adds **no persistent storage** and **no database schema change**. The only durable
field it touches — `TransferRecord.pairingMethod` — already exists (#006) and already reserves the
`qr` enum value. Everything else here is transient (a payload encoding + UI/permission state).

## 1. ConnectLink (transient payload codec)

The visual QR encoding of the existing pairing code. Pure value + codec, no persistence.

| Field | Type | Rules |
|-------|------|-------|
| `version` | int | Currently `1`. Parser accepts only known versions; unknown → reject. |
| `code` | String | 6-digit pairing code; MUST pass `SignalingProtocol.isValidCode`. |

- **Canonical form**: `safesend://connect?v=1&code=NNNNNN`.
- **Build**: `ConnectLink.build(String code) → String uri` (asserts a valid code).
- **Parse**: `ConnectLink.parse(String raw) → Result<String code>` — succeeds only when scheme =
  `safesend`, target = `connect`, `v` is a supported version, and `code` is valid. All other
  inputs → `AppFailure.invalidCode` (foreign/malformed QR). Parse is **syntactic only**; an
  expired-but-well-formed code passes parse and is rejected later by the existing join path
  (`roomExpired`).
- **Location**: `lib/core/domain/pairing/connect_link.dart` (core — reused by #008).
- **Privacy**: carries only `version` + `code` — never file data, paths, or peer identity
  (Constitution I; FR-008).

## 2. QrScanState (transient UI state — `QrScanCubit`, 4-state)

Drives the full-screen scanner page. Follows the mandatory 4-state pattern (Constitution III);
the loaded payload is a permission/scan view-model.

`AppState<QrScanView>`:

| Variant | Meaning |
|---------|---------|
| `initial` | before permission is resolved |
| `loading` | requesting camera permission / analyzing a picked image |
| `loaded(QrScanView)` | camera-ready, or a recoverable view state (see below) |
| `error(AppFailure)` | unrecoverable scanner error |

`QrScanView` (loaded payload):

| Field | Type | Notes |
|-------|------|-------|
| `permission` | `CameraPermissionStatus` | `granted` / `denied` / `permanentlyDenied` / `restricted` |
| `torchOn` | bool | torch toggle; only meaningful when `granted` |
| `handled` | bool | latch — true once a valid code is accepted, to enforce single join (FR-014) |

- **Outcome**: on a valid scan/parse the page pops with the **code String** (not via the cubit) so
  the owning receiver panel calls the existing `PairingCubit.joinWithCode`.
- **Foreign/empty QR** (`AppFailure.invalidCode`): surfaced as a non-blocking toast; the cubit
  stays in `loaded` (keeps scanning) — never transitions to terminal `error` (FR-012).
- **Camera blocked**: `loaded` with `permanentlyDenied`/`restricted` → page shows Open-Settings +
  pick-from-photo, not a dead preview (FR-016).

### CameraPermissionStatus (enum)

`granted · denied · permanentlyDenied · restricted` — maps from `permission_handler`'s
`PermissionStatus`; `denied`/`permanentlyDenied`/`restricted` map to localized
`AppFailure.permissionDenied` / `cameraUnavailable` for any error text.

## 3. ConnectRequest (existing core type — additive field)

`lib/core/domain/pairing/connect_handoff.dart`:

| Field | Type | Change |
|-------|------|--------|
| `role` | `TransferRole` | unchanged |
| `openScanner` | bool | **new**, default `false` — when true (Home "Quét QR"), the receiver panel auto-opens the scanner once |

## 4. ConnectResult (existing core type — additive field)

`lib/core/domain/pairing/connect_handoff.dart`:

| Field | Type | Change |
|-------|------|--------|
| `transport` | `DataTransport` | unchanged |
| `method` | `PairingMethod` | **new**, default `sixDigitCode` — the method this device used (`qr` when paired via the QR tab / scanner) |

- Flows: Connect hub sets `method` at `PairingConnected` → `send_selection_page` /
  `receive_entry_page` pass it to the transfer cubit → `send_history_mapper` /
  `receive_history_mapper` write it (replacing the hardcoded `sixDigitCode`). FR-018.

## 5. TransferRecord (existing — no schema change)

- `pairingMethod` column already stores the enum `.name`; value `qr` already round-trips through
  `TransferHistoryRepositoryImpl._pairingMethod`. **No migration.** Constitution IX (migrations)
  is not engaged by this feature.
