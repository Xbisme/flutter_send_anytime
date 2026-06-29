# Data Model: Polish & v1.0 Release (#014)

No persisted-storage (drift) changes. The "entities" here are in-memory config/state and release artifacts. Existing types are reused; additions are marked **(new)** or **(additive field)**.

## RtcIceServer (existing — already TURN-capable)

`lib/core/config/app_config.dart`. No change needed structurally; TURN entries simply populate it.

| Field | Type | Notes |
|---|---|---|
| `urls` | `List<String>` | `stun:` and/or `turn:`/`turns:` URLs |
| `username` | `String?` | TURN username (= ephemeral expiry timestamp) |
| `credential` | `String?` | TURN credential (= HMAC) |

## TurnCredentials (new)

Ephemeral, session-scoped TURN credentials issued by the `server/` relay and delivered over signaling. Held only in memory for the session; **never logged, never persisted** (Principle I).

| Field | Type | Validation / Notes |
|---|---|---|
| `urls` | `List<String>` | coturn `turn:`/`turns:` endpoints for this flavor |
| `username` | `String` | Unix expiry timestamp (coturn `use-auth-secret` convention) |
| `credential` | `String` | `base64(HMAC-SHA1(secret, username))` |
| `ttlSeconds` | `int` | Lifetime hint (~600); client must (re)connect before expiry |

Lifecycle: created by server on room-create → sent to each peer via the `turnCredentials` signaling frame → mapped into the session's `iceServers` → discarded at session teardown. If absent (older server / not configured), the client falls back to its static per-flavor STUN/TURN `iceServers` (backward compatible).

## TransferSnapshot.relayInUse (additive field)

`lib/core/domain/transfer/` snapshot — the single source of truth (Principle VIII).

| Field | Type | Notes |
|---|---|---|
| `relayInUse` | `bool` (default `false`) | Set true when `getStats()` shows the selected candidate pair is a `relay` type. Drives the FR-004a "relayed · encrypted" indicator. Additive — does not alter the transfer state machine. |

## Resilience failure states (mostly existing)

Maps to `AppFailure` (`lib/core/domain/failures/app_failure.dart`) + localized copy:

| Scenario (FR) | AppFailure variant | Copy intent |
|---|---|---|
| Couldn't connect, direct+relay both fail after timeout (FR-007) | `peerUnreachable` / `iceFailed` | "Couldn't connect — try again" |
| Mid-transfer drop / peer disconnect (FR-005/006) | `connectionLost` / `dataChannelClosed` | "Connection lost — N files saved, retry" |
| Signaling lost during setup (FR-005) | `signalingUnreachable` / `signalingTimeout` | "Lost connection to the matching service" |
| TURN unreachable/misconfigured but should be transparent (FR-008) | `relayUnavailable` **(new, only if needed)** else `peerUnreachable` | direct still works; only surfaced when no path succeeds |

All retain already-verified files as a partial result (existing #005 behavior) and offer retry. No silent hang — bounded by `TransferConstants.kConnectTimeout`.

## Device-validation smoke matrix (release artifact — not in-app)

Recorded in `quickstart.md` / a tracked checklist. Shape: rows = scenario, columns = platform, cells = pass/fail/notes.

| Scenario | iOS | Android |
|---|---|---|
| 6-digit pair → send → receive → save | | |
| QR pair → … | | |
| Share link (cold + warm) → … | | |
| Nearby radar → … | | |
| Background transfer mid-send | | |
| Open received image/video/audio/PDF/text viewer | | |
| ≥4 GB file (bounded memory) | | |
| Relay-only fallback (forced) | | |
| `pod install` + signed prod build runs on device | | (n/a) |

## Store-listing package (release artifact — not in-app)

Staged under `docs/release/`. Shape:

| Item | Notes |
|---|---|
| Metadata (VI + EN) | name, subtitle, description, keywords, support URL |
| Screenshots | per required device sizes, both platforms |
| Privacy policy | hosted/text — reflects no-server-holds-data + encrypted-non-persisted TURN |
| Apple privacy nutrition | "Data Not Collected" consistent with verified behavior |
| Google data safety | matching answers |
| App icons / store graphics | from brand assets |
