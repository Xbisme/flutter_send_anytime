# Implementation Plan: Signaling Server & 6-Digit Key Pairing

**Branch**: `003-signaling-6digit` | **Date**: 2026-06-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/003-signaling-6digit/spec.md`

## Summary

Add the **rendezvous layer** that lets two real devices find each other and exchange the WebRTC handshake so the #002 transfer engine can open a real peer-to-peer `RTCDataChannel`. Three deliverables:

1. **A lightweight, stateless, self-hostable signaling relay** (`server/`, Dart `shelf` + WebSocket). It holds ephemeral in-memory "rooms" keyed by a 6-digit code, admits exactly two peers per room, relays only SDP/ICE/control between them, rate-limits join attempts, expires codes after 5 minutes, and discards everything on disconnect/expiry. **It never sees file bytes.**
2. **An app-side signaling client** (`lib/core/services/signaling/`) that owns the WebSocket connection, drives the 6-digit pairing protocol (host → code; join → room), and exposes a `WebSocketSignalingChannel implements SignalingChannel` — the real network implementation of the seam #002 already defines. The #002 engine works unchanged.
3. **A thin pairing feature** (`lib/features/pairing/`) — repository + use cases + a 4-state `PairingCubit` — plus a **dev-flavor-only debug screen** to drive the deferred manual two-device smoke (FR-021a).

A **pure-Dart shared package** (`packages/safesend_signaling/`) holds the wire-protocol message types + JSON codec + constants, depended on by both the server and the app via path — so the protocol is defined in exactly one place (Constitution VIII) and the in-process integration test can run the real server against the real client with a single source of truth.

Technical approach: one WebSocket per device carries a **versioned, JSON-framed control + relay protocol** (`host`/`code-issued` → `join`/`peer-joined`|`room-full`|`code-expired`|`invalid-code` → `relay`(offer/answer/ice) ↔ `relay` → `peer-left`/`bye`, plus `rate-limited`). The client demultiplexes inbound frames: control frames drive a `PairingState` stream; `relay` frames feed the `SignalingChannel.incoming` stream the engine consumes. STUN is Google's free public servers (per flavor); TURN is a documented, empty, configurable hook (no relay stood up — #011). Everything fallible returns `Result<T>`; logs carry only phase/error-type (Constitution I/II). Validated by integration tests running the real server in-process with two real clients; the two-physical-device smoke is deferred.

## Technical Context

**Language/Version**: Dart (SDK `^3.11.0`) / Flutter (latest stable 3.x). Server + shared package are **pure Dart** (no Flutter) so the relay runs as a plain `dart run` process and the shared codec is importable by both.

**Primary Dependencies** (latest stable verified on pub.dev 2026-06-24 — Constitution XV):
- **App (already present)**: `flutter_webrtc` 1.5.2, `crypto` 3.0.7, `uuid` 4.5.3, `flutter_bloc` 9.1.1, `get_it` 9.2.1, `injectable` 3.0.0.
- **App (new)**: `web_socket_channel` **3.0.3** — WebSocket client implementing the connection that backs `WebSocketSignalingChannel`. Pure Dart, no native code (no new pods/permissions).
- **Server (new package)**: `shelf` **1.4.2** (HTTP pipeline + `shelf_io` server), `shelf_web_socket` **3.0.0** (WebSocket upgrade handler; depends on `web_socket_channel >=2.0.0 <4.0.0`, satisfied by 3.0.3 → one shared transport library across client, server, and tests).
- **Shared package** `packages/safesend_signaling`: depends only on `meta` (and optionally `web_socket_channel` types are NOT needed — it deals in plain maps/strings). No third-party runtime deps.

**Storage**: **None.** The relay is in-memory only — no database, no files, no persistence (FR-015). Rooms/codes live in a `Map` and are removed on expiry/disconnect. The app persists nothing from pairing (Constitution II ephemerality).

**Testing**: `flutter_test` + `mocktail` 1.0.5 for the app client/cubit; `test` (pure Dart) for the server package. The headline integration test runs the **real `shelf` server in-process** (bound to an ephemeral `localhost` port) with **two real `web_socket_channel` clients**, exercising the full pairing + SDP/ICE relay loop. The app's `dev_dependencies` add a **path dependency on the `server` package** so the in-process server is importable from `test/`. Command: `very_good test --test-randomize-ordering-seed random` (gate-equivalent locally: `dart test` / `flutter test`; `cd server && dart test` for the relay).

**Target Platform**: App: iOS 13.0+ / Android 8.0 (API 26)+ (unchanged). Relay: any Dart-capable host (localhost for dev/LAN this feature; public host deferred).

**Project Type**: Mobile app (Flutter) **+ a companion Dart service** (`server/`) **+ a shared Dart package** (`packages/safesend_signaling/`). First multi-package layout in the repo.

**Performance Goals**: Pairing handshake to DataChannel-open within a few seconds on a normal network (gated by ICE, not the relay). Relay forwards small control/SDP/ICE frames (≤ a few KB) — throughput is a non-goal; it must stay responsive with many concurrent independent rooms on minimal resources. No hard latency SLA set here (Deferred — revisit at #011).

**Constraints**: No file bytes over signaling (FR-011, SC-002); relay carries only recognized control/relay frames and rejects anything else; no file contents/paths/peer-ids/IPs/SDP/ICE payloads in any log on either side (FR-022); per-connection join rate limiting (FR-011a); codes single-use, 5-min TTL, discarded after use (Constitution I); all fallible ops return `Result<T>`; `lib/core/` MUST NOT import `lib/features/`; reuse the #002 `SignalingChannel` seam unchanged; deterministic, non-flaky tests (no wall-clock sleeps for TTL — inject a clock/short TTL).

**Scale/Scope**: Two-party rooms; one active code per host; full `000000`–`999999` code space (FR-002). ~10–12 new app source files (`core/services/signaling/*`, `core/domain/pairing/*`, `core/constants` additions, `core/config` additions, `features/pairing/*`, dev debug screen) + the `server/` package (~6 files + README) + the `packages/safesend_signaling/` package (~3 files). New ARB strings for pairing failures.

**Resolved unknowns** (candidate NEEDS CLARIFICATION → settled in [research.md](research.md)):
- Where room/code semantics live vs. the 1:1 `SignalingChannel` → a `SignalingClient` owns the socket + room protocol and **produces** a `WebSocketSignalingChannel`; the engine still depends only on the seam (R-01).
- Protocol shape & framing → versioned JSON text frames, `{v,type,...}`; one shared codec package (R-02).
- Avoiding protocol drift across two programs → pure-Dart shared package via path dependency (R-03).
- 6-digit code generation, uniqueness, leading zeros → `Random.secure()` over `000000`–`999999`, regenerate on collision, stored/sent as zero-padded string (R-04).
- TTL enforcement testably → per-room timer + injectable `Duration`/clock; tests use a short TTL, not real 5-min waits (R-05).
- Rate-limit policy → per-connection sliding cap on invalid `join`s + throttle then close (R-06).
- STUN/TURN config → Google public STUN in `AppConfig.iceServers` per flavor; TURN documented empty hook (R-07).
- Signaling endpoint per flavor → `AppConfig.signalingEndpoint` (`Uri`), dev `ws://` localhost/LAN, prod `wss://` placeholder (R-08).
- Reconnect/ICE-restart → out of scope; disconnect tears the room down (R-09).
- `AppFailure` gaps → add `signalingUnreachable`, `signalingTimeout`, `roomExpired`, `roomFull`, `invalidCode`, `rateLimited` (R-10).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution v1.0.0 (15 principles). Relevance for a signaling/pairing spec (engine + service + a dev-only screen):

| # | Principle | Applies to #003? | Compliance approach | Gate |
|---|---|---|---|---|
| I | Privacy-First P2P | **Yes (core)** | Relay carries SDP/ICE/rendezvous control only, never bytes (FR-011, SC-002); rooms/codes ephemeral, single-use, 5-min TTL, no rejoin (FR-013, Constitution I); no contents/paths/peer-ids/IPs/SDP in logs on client **or** server (FR-022); every boundary validated — codes, join attempts, every inbound frame (FR-011/011a); TURN documented as encrypted-relay-only hook though none is stood up (FR-019) | ✅ PASS |
| II | Direct Transfer & Data Min. | **Yes** | Signaling state ephemeral, nothing persisted (FR-015); pairing secret not persisted after pairing; relay forwards & forgets; no content telemetry | ✅ PASS |
| III | BLoC 4-state | **Yes** | `PairingCubit` follows `initial → loading → loaded → error`; extended variants prefix the base (`loadedWaitingForPeer`, `loadedConnecting`); side effects via `BlocListener`; cubit injects **use cases**, not the client/repo; `@injectable` screen-scoped; cubit closed | ✅ PASS |
| IV | Code Quality & Dart Safety | **Yes** | `very_good_analysis` zero-warning across app, server, shared pkg; strict casts/raw-types/inference; immutable freezed models; explicit public types; localized user errors | ✅ PASS |
| V | Result\<T\> Error Handling | **Yes** | All fallible client ops return `Result<T>`; **extend `AppFailure`** with `signalingUnreachable`/`signalingTimeout`/`roomExpired`/`roomFull`/`invalidCode`/`rateLimited` (R-10, FR-022 mapping); cubit folds Results; services catch+wrap, no throwing | ✅ PASS |
| VI | Design System & Theming | **Partial (dev only)** | Only surface is the **dev-flavor debug screen**; it MUST use shared widgets/tokens (`CodeBox`, buttons, `AppToast`) — no hardcoded hex, no ad-hoc snackbars. It never ships in prod (FR-021a). The real "Mã 6 số" screen is #004 | ✅ PASS |
| VII | Cross-Platform Native | **Partial** | `web_socket_channel` is pure Dart → no new pods/entitlements/permission prompts. `ws://` (cleartext) to localhost/LAN in dev needs Android `usesCleartextTraffic`/iOS ATS exception **scoped to the dev flavor only**; prod uses `wss://` (R-08) | ✅ PASS |
| VIII | Transport & Signaling | **Yes (core)** | Three layers honored — pairing feeds **one** signaling/transport path; `SignalingChannel` seam reused unchanged, real WebSocket impl added (FR-017); **versioned** wire protocol, message types centralized in the shared package, never duplicated literals; signaling endpoint + STUN/TURN per-flavor in `AppConfig`, never hardcoded at call sites (FR-020); relay self-hostable in `server/` | ✅ PASS |
| IX | Transfer Reliability | **Yes** | Pairing failures detected & surfaced, never hang (FR-002 stories, SC-003): expired/invalid/room-full/peer-left each map to a distinct `AppFailure`; malformed frames rejected, not crash (FR-011); disconnect tears down room + releases socket; connect/handshake timeouts as constants | ✅ PASS |
| X | go_router Navigation | **Partial (dev only)** | Debug route registered via `AppRoutes` constant, `context.push`; **only mounted when `AppConfig.flavor.isDev`** so it cannot appear in prod nav (FR-021a). No deep links here (`safesend://` pairing is #008) | ✅ PASS |
| XI | Feature-First Modularity | **Yes** | Signaling client/channel/protocol live in `lib/core/services/signaling` + `core/domain/pairing` + `core/config`/`core/constants`; pairing repo/use-cases/cubit/debug-page in `lib/features/pairing`; `core/` MUST NOT import `features/`; repo→repo forbidden (use cases orchestrate); DI `@injectable`/`@lazySingleton` only | ✅ PASS |
| XII | Testing Discipline | **Yes (core)** | Unit tests: code gen/uniqueness/TTL, rate limiter, room lifecycle, frame codec, client demux, `PairingCubit` (`bloc_test`); **integration test = real in-process server + two real clients** through full pair → SDP/ICE relay → (loopback engine) channel-open; deterministic via injected short TTL/clock; **two-device smoke = REQUIRED but deferred**, tracked in tasks.md banner | ✅ PASS |
| XIII | Simplicity & YAGNI | **Yes** | One WebSocket per device (control + relay multiplexed); JSON frames (human-debuggable, no codegen needed server-side); no auth/accounts/reconnect/resume; shared package justified (crosses a process boundary — see R-03) rather than a heavier monorepo tool; only `web_socket_channel` added to the app, `shelf`/`shelf_web_socket` to the server | ✅ PASS |
| XIV | i18n by Default | **Yes** | New pairing failure/user strings (code expired, invalid code, room full, signaling unreachable, rate-limited) via ARB, **Vietnamese primary** + English, with `@description`; mapped from `AppFailure` (FR-023). Server is headless — no l10n | ✅ PASS |
| XV | Dependency Hygiene | **Yes** | `web_socket_channel` 3.0.3 / `shelf` 1.4.2 / `shelf_web_socket` 3.0.0 verified on pub.dev at plan time; transitive `web_socket_channel` range of `shelf_web_socket` confirmed compatible with 3.0.3; all pure-Dart (no native verification needed); caret constraints; new `server/pubspec.lock` + `packages/safesend_signaling/pubspec.lock` committed; no fictional packages | ✅ PASS |

**Result**: No violations. Complexity Tracking empty. Proceed to Phase 0.

**Post-Design re-check (after Phase 1)**: Still PASS — the data model, wire-protocol contract, and client API introduce no dependencies beyond the three verified pure-Dart ones; keep `core/` free of `features/` imports; reuse the #002 `SignalingChannel` unchanged; add only typed failures + ARB strings (no hardcoded user text); preserve signaling-carries-no-bytes, ephemerality, single-source-of-protocol, and dev-only-surface invariants. The shared package is the single justified structural addition (Constitution VIII over XIII, documented in research R-03). Complexity Tracking remains empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-signaling-6digit/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output (run the relay + integration test)
├── contracts/
│   ├── signaling-protocol.md      # client↔server wire protocol (versioned frames)
│   └── signaling-client-api.md    # app-side SignalingClient + WebSocketSignalingChannel
├── checklists/
│   └── requirements.md  # spec quality checklist (from /speckit.specify)
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
packages/
└── safesend_signaling/                 # NEW — pure-Dart shared wire protocol (one source of truth)
    ├── lib/
    │   ├── safesend_signaling.dart      # barrel export
    │   └── src/
    │       ├── signaling_frame.dart     # frame types + JSON encode/decode + protocol version
    │       └── signaling_constants.dart # message-type names, code length, default TTL
    ├── test/
    │   └── signaling_frame_test.dart    # codec round-trip + version/validation
    └── pubspec.yaml

server/                                  # NEW — self-hostable shelf signaling relay
├── bin/
│   └── server.dart                      # entrypoint: parse host/port/TTL → start relay
├── lib/
│   ├── signaling_server.dart            # shelf handler + WebSocket upgrade
│   ├── room_manager.dart                # rooms map, code gen/uniqueness, TTL timers, lifecycle
│   ├── peer_connection.dart             # one connected socket: send/receive frames, demux
│   └── rate_limiter.dart                # per-connection join-attempt cap + throttle
├── test/
│   ├── room_manager_test.dart           # code gen/collision/TTL/room-full/cleanup
│   ├── rate_limiter_test.dart
│   └── signaling_server_test.dart       # real server in-process + two real ws clients
├── README.md                            # self-hosting docs (run, config, privacy notes)
└── pubspec.yaml                         # shelf, shelf_web_socket, safesend_signaling (path)

lib/
├── core/
│   ├── config/
│   │   └── app_config.dart              # EDIT — add signalingEndpoint (Uri); iceServers per flavor
│   ├── constants/
│   │   └── signaling_constants.dart     # NEW — re-export shared consts + app-side timeouts
│   ├── domain/
│   │   ├── failures/app_failure.dart    # EDIT — add signaling/pairing failure variants (R-10)
│   │   └── pairing/                      # NEW — pairing domain models
│   │       ├── pairing_role.dart         # sender | receiver
│   │       ├── pairing_code.dart         # value (6-digit) + expiresAt
│   │       └── pairing_state.dart        # @freezed lifecycle (idle…waitingForPeer…paired…failed)
│   └── services/
│       └── signaling/
│           ├── signaling_channel.dart            # UNCHANGED (#002 seam)
│           ├── loopback_signaling_channel.dart   # UNCHANGED (#002 tests)
│           ├── signaling_client.dart             # NEW — owns ws, drives pairing, demuxes frames
│           └── web_socket_signaling_channel.dart # NEW — implements SignalingChannel over the ws
├── features/
│   └── pairing/                          # NEW
│       ├── domain/
│       │   ├── pairing_repository.dart   # interface
│       │   └── usecases/
│       │       ├── host_session_usecase.dart   # generate code + wait for peer
│       │       └── join_session_usecase.dart   # enter code + join
│       ├── data/
│       │   └── pairing_repository_impl.dart     # wraps SignalingClient (+ engine handshake)
│       └── presentation/
│           ├── cubit/
│           │   ├── pairing_cubit.dart            # 4-state, injects use cases
│           │   └── pairing_state.dart
│           └── debug/
│               └── pairing_debug_page.dart       # dev-flavor-only manual smoke surface
├── core/router/                          # EDIT — mount debug route only when flavor.isDev
├── main_dev.dart                         # EDIT — AppConfig(dev): ws:// endpoint + STUN
├── main_prod.dart                        # EDIT — AppConfig(prod): wss:// endpoint + STUN
└── l10n/arb/                             # EDIT — VI/EN pairing failure strings

test/
├── core/services/signaling/             # client demux, WebSocketSignalingChannel adapter
├── features/pairing/                     # PairingCubit (bloc_test), use cases
└── integration/
    └── pairing_handshake_test.dart       # real server (path dep) + two clients + loopback engine

pubspec.yaml                             # EDIT — add web_socket_channel; dev path dep on server
```

**Structure Decision**: This is the repo's first **multi-package** layout. Three Dart units cooperate: the Flutter **app** (`lib/`), the headless **relay** (`server/`), and a **shared pure-Dart protocol package** (`packages/safesend_signaling/`) that both depend on by path. The shared package exists to satisfy Constitution VIII (protocol types defined in exactly one place) across a real process boundary, and to let the in-process integration test drive the real server with the same codec the production client uses. App-internal layering follows Constitution XI: transport-level signaling (client, channel adapter, domain models, config, constants) lives in `lib/core/`; the pairing repository, use cases, cubit, and the dev-only debug screen live in `lib/features/pairing/`. The #002 `SignalingChannel` seam is reused verbatim — the new `WebSocketSignalingChannel` is just its real network implementation.

## Complexity Tracking

> No constitution violations. The one structural addition — a shared `packages/safesend_signaling/` package — is **not** a violation: it is the mechanism by which Constitution VIII ("protocol message types defined in one place — NEVER duplicated") is honored across the app/server process boundary. Rationale and the rejected alternative (duplicate constants in each program) are recorded in [research.md](research.md) R-03. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
