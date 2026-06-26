# Phase 1 Data Model: Share Link

This feature introduces **no persisted data** and **no database schema change**. The "entities" below
are transient in-memory types / additive core seams. The history schema is reused as-is
(`PairingMethod.shareLink` was reserved in #006).

## Reused (no change)

### Invite link payload — `ConnectLink` (existing, #007)
The versioned pairing descriptor exchanged as a tappable link. Reused **verbatim**.
- Canonical form: `safesend://connect?v=1&code=NNNNNN`
- `ConnectLink.build(String code) → String` — requires a valid 6-digit code.
- `ConnectLink.parse(String raw) → Result<String>` — accepts only `safesend` scheme + `connect`
  target + known version + syntactically valid 6-digit code (reuses `SignalingProtocol.isValidCode`);
  any deviation → `AppFailure.invalidCode`.
- Carries **only** version + 6-digit code (FR-008) — no file data, paths, identity, or endpoint.

### Transfer record (existing, #006)
No new fields. The existing `pairingMethod` attribute now takes `PairingMethod.shareLink` when a
transfer was paired via the link. `PairingMethod` enum already = `{ sixDigitCode, qr, shareLink,
nearby }`. History detail already renders it via `PairingMethodL10n.label` (uses the existing
`historyMethodShareLink` ARB key).

## New transient types / seams

### `DeepLinkService` (core service, `lib/core/services/deeplink/`)
Pure-core wrapper over `app_links`. Imports no features.
| Member | Type | Purpose |
|---|---|---|
| `getInitialLink()` | `Future<Uri?>` | The URL that cold-started the app (FR-010/011). |
| `links` | `Stream<Uri>` | Subsequent links while running — warm start (FR-010). |

Impl (`@LazySingleton`) delegates to `AppLinks().getInitialLink()` / `AppLinks().uriLinkStream`.

### `ActiveHostingRegistry` (core service, `lib/core/services/pairing/`)
Smallest state needed for self-invite detection (FR-015). `@LazySingleton`.
| Member | Type | Purpose |
|---|---|---|
| `activeHostingCode` | `String?` | The device's current hosting code, or null when not hosting. |
| `setHosting(String code)` | `void` | Called by `PairingRepositoryImpl` when hosting starts / code rotates. |
| `clear()` | `void` | Called on pairing dispose / session end. |

Lifecycle: written by the pairing layer (feature → core, allowed); read by the deep-link coordinator.
Holds no secret beyond the already-ephemeral 6-digit code; never logged (Constitution I).

### `ConnectRequest.autoJoinCode` (additive field, `core/domain/pairing/connect_handoff.dart`)
| Field | Type | Default | Purpose |
|---|---|---|---|
| `role` | `TransferRole` | — | (existing) sender / receiver |
| `openScanner` | `bool` | `false` | (existing, #007) receiver opens QR scanner immediately |
| **`autoJoinCode`** | `String?` | `null` | **NEW** — receiver-only; when set, the Connect panel auto-joins this code and records `method = shareLink` |

Validation: a non-null `autoJoinCode` MUST be a syntactically valid 6-digit code (the coordinator only
sets it from a successful `ConnectLink.parse`). Ignored in the sender role.

### `ReceiveEntryRequest` (new core type, replaces the receive route's bare `bool` extra)
The receive route (`AppRoutes.receive`) currently passes `extra` as `bool openScanner`. Widen to a
small core struct so it can also carry an auto-join code.
| Field | Type | Default | Purpose |
|---|---|---|---|
| `openScanner` | `bool` | `false` | (existing behavior) open the QR scanner on entry (#007) |
| `autoJoinCode` | `String?` | `null` | the link-delivered code to auto-join (FR-012) |

`ReceiveEntryPage(request)` threads `autoJoinCode` into the receiver `ConnectRequest`. Existing call
sites updated: Home "Nhận" → `ReceiveEntryRequest()`; Home "Quét QR" → `ReceiveEntryRequest(openScanner: true)`.

### `ConnectResult.method` (existing field — value extended)
No type change. Both pairing paths set `method = PairingMethod.shareLink` (FR-017):
- **Receiver**: the auto-join path sets it → `ReceiveProgressArgs.method` →
  `ReceiveHistoryMapper.toRecord(pairingMethod:)`.
- **Sender**: tapping **Chia sẻ link mời** sets the sender Connect panel's pending paired-method to
  `shareLink` (last-action-wins — switching to the QR tab afterwards would set `qr`, exactly like the
  #007 `_pairedViaQr` flag) → `SendProgressArgs.method` → `SendHistoryMapper.toRecord(pairingMethod:)`.

No mapper signature change.

## State / flow (no state machine change)

```
Incoming Uri (cold: getInitialLink / warm: links stream)
   │
   ▼  ConnectLink.parse(uri)
 ┌──────────────┴──────────────┐
 failure                      success(code)
 │                             │
 AppToast(invalidInvite)       ├─ code == ActiveHostingRegistry.activeHostingCode?
 + go(Home)   (FR-013)         │     └─ yes → AppToast(ownInviteLink) + stop   (FR-015)
                               ├─ current route is send/receiveProgress?
                               │     └─ yes → confirm dialog                    (FR-014)
                               │            ├─ cancel → stop (stay in transfer)
                               │            └─ confirm → proceed ↓
                               └─ go(receive, ReceiveEntryRequest(autoJoinCode: code))
                                     → ReceiveEntryPage → ConnectRequest(autoJoinCode)
                                     → joinWithCode(code) → [join ok] accept/reject prompt (FR-012)
                                                          → [roomExpired/invalidCode] toast + go(Home) (FR-013)
```

Latest-wins serialization guarantees a single in-flight join (FR-016).
