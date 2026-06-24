---
description: "Task list for #003 Signaling Server & 6-Digit Key Pairing"
---

# Tasks: Signaling Server & 6-Digit Key Pairing

**Input**: Design documents from `specs/003-signaling-6digit/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: REQUIRED for this feature. Constitution XII mandates unit/integration coverage for signaling message handling and pairing-code logic; spec SC-006 mandates the full pairing + handshake loop be covered by an in-process test (real relay + two real clients), and SC-002/003/004/005 are each verifiable test assertions. No physical devices needed for CI.

**Organization**: Tasks are grouped by the three user stories from spec.md. The stories are **layered** (US2 failures and US3 cleanup build on the US1 happy path) — reflecting a transport/service feature rather than independent UI slices (see Dependencies). **US1 is the MVP.**

> ## ⚠️ Status banner — deferred (device-only) tasks
> - **T055 Two-physical-device smoke test** (real NAT traversal + STUN across different networks, real RTCDataChannel open via the dev debug screen) — REQUIRED but **DEFERRED**; cannot run in CI (Constitution XII). Procedure in [quickstart.md](quickstart.md) §6.
> - **Gate note**: `flutter analyze` crashes on this detached-HEAD Flutter checkout (AOT snapshot) — use **`dart analyze lib test`** for the app (gate-equivalent); `dart analyze` inside `server/` and `packages/safesend_signaling/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1–US3 (maps to spec user stories); Setup/Foundational/Polish carry no story label
- All paths are repo-relative

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the verified dependency, scaffold the first multi-package layout (app + relay + shared protocol pkg), and create directory skeletons.

- [x] T001 Add `web_socket_channel: ^3.0.3` to `pubspec.yaml` dependencies and a `dev_dependencies` path dep `server: {path: server}` (for the in-process integration test); run `flutter pub get`; commit updated `pubspec.lock` (version verified in [research.md](research.md))
- [x] T002 [P] Create the shared protocol package `packages/safesend_signaling/`: `pubspec.yaml` (name `safesend_signaling`, `environment.sdk: ^3.11.0`, dep `meta`; dev_deps `test`, `very_good_analysis`), `analysis_options.yaml` (include `very_good_analysis`), and `lib/src/` + `test/` dirs
- [x] T003 [P] Create the relay package `server/`: `pubspec.yaml` (deps `shelf: ^1.4.2`, `shelf_web_socket: ^3.0.0`, `web_socket_channel: ^3.0.3`, `safesend_signaling: {path: ../packages/safesend_signaling}`; dev_deps `test`, `very_good_analysis`), `analysis_options.yaml`, and `bin/` + `lib/` + `test/` dirs
- [x] T004 [P] Create app source/test dirs: `lib/core/domain/pairing/`, `lib/features/pairing/{domain/usecases,data,presentation/cubit,presentation/debug}/`, `test/features/pairing/`, `test/integration/` (signaling dirs already exist from #002)
- [x] T005 Scope dev-flavor cleartext for `ws://` LAN testing: add `android:usesCleartextTraffic="true"` to the **dev** Android manifest (`android/app/src/dev/AndroidManifest.xml`) and an iOS ATS exception in the **dev** config only; prod manifests/Info.plist untouched (R-08). Android dev manifest done (android/app/src/dev/AndroidManifest.xml); iOS ATS folded into the deferred on-device build (like #001/#002 iOS native steps)

**Checkpoint**: `flutter pub get`, `cd server && dart pub get`, `cd packages/safesend_signaling && dart pub get` all resolve; directories exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared wire protocol (used by both relay and app), the failure/config/constants surface, and the pairing domain models. **No room logic or pairing orchestration yet** — that starts in US1.

**⚠️ CRITICAL**: Both the server and the app client depend on the shared protocol package; nothing in US1–US3 can proceed until this phase is complete.

- [x] T006 Implement the `SignalingFrame` sealed type + `RelayKind` enum + JSON `encode`/`decode` + validation (unknown type / `v` mismatch / missing required field / `code` not `^\d{6}$` → typed failure, never throws) in `packages/safesend_signaling/lib/src/signaling_frame.dart` (per [contracts/signaling-protocol.md](contracts/signaling-protocol.md))
- [x] T007 [P] Implement `SignalingProtocol` constants (`protocolVersion = 1`, message-type name strings, `codeLength = 6`, `defaultTtl = 5 min`) in `packages/safesend_signaling/lib/src/signaling_constants.dart` and the barrel export `packages/safesend_signaling/lib/safesend_signaling.dart`
- [x] T008 [P] Unit test the codec: round-trip every frame variant, reject unknown type / bad version / missing field / bad code, assert no binary/byte field exists structurally, in `packages/safesend_signaling/test/signaling_frame_test.dart`
- [x] T009 Add `AppFailure` variants `signalingUnreachable`, `signalingTimeout`, `roomExpired`, `roomFull`, `invalidCode`, `rateLimited` in `lib/core/domain/failures/app_failure.dart` (R-10)
- [x] T010 [P] Extend `AppConfig` with `signalingEndpoint` (`Uri`) in `lib/core/config/app_config.dart` (`RtcIceServer` already supports the TURN hook)
- [x] T011 Set per-flavor `signalingEndpoint` + Google public STUN `iceServers` in `lib/main_dev.dart` (`ws://…:8080`) and `lib/main_prod.dart` (`wss://…` placeholder) — depends on T010
- [x] T012 [P] App-side signaling constants (connect/handshake timeouts) + re-export shared consts in `lib/core/constants/signaling_constants.dart`
- [x] T013 [P] Create `PairingRole` enum (`sender`/`receiver`) in `lib/core/domain/pairing/pairing_role.dart`
- [x] T014 [P] Create `PairingCode` `@freezed` (`value`, `expiresAt`, `Duration get remaining`) in `lib/core/domain/pairing/pairing_code.dart`
- [x] T015 [P] Create `PairingState` `@freezed` sealed lifecycle (idle/connecting/hosting/joining/peerPresent/connected/failed/closed) in `lib/core/domain/pairing/pairing_state.dart`
- [x] T016 Run `dart run build_runner build --delete-conflicting-outputs` to generate freezed parts for `AppFailure`, `PairingCode`, `PairingState` — depends on T009, T014, T015

**Checkpoint**: shared protocol codec passes tests; app analyzes clean with new failures/config/models. User-story work can begin.

---

## Phase 3: User Story 1 - Pair two devices & open a direct connection (Priority: P1) 🎯 MVP

**Goal**: Sender requests a 6-digit code; receiver enters it; both join one room; SDP/ICE relays through the server; a direct (loopback-engine) DataChannel reaches open — with zero file bytes through signaling.

**Independent Test**: Run the real relay in-process with two real WebSocket clients; A `host()` → code, B `join(code)` → both `peerPresent`; relay an offer/answer/ICE; assert the #002 engine (over loopback transport) reports the channel open and that nothing the relay handled carried bytes (SC-001, SC-002, SC-006 happy path).

### Server (happy path)

- [x] T017 [P] [US1] `PeerConnection` — wrap one upgraded socket: send/receive `SignalingFrame`, expose stream, hold its room code, in `server/lib/peer_connection.dart`
- [x] T018 [US1] `RoomManager` happy path — `createRoom()` (secure 6-digit gen, zero-padded, store in `Map`), `join(code, conn)` valid → `Paired` + `peer-joined` to both, relay routing (forward `relay`/`bye` to the room's *other* peer only), `remove(code)`, in `server/lib/room_manager.dart` — depends on T017
- [x] T019 [US1] `SignalingServer` — shelf pipeline + `shelf_web_socket` upgrade, decode inbound frames → `RoomManager`, encode outbound; logs phase/error-type only, in `server/lib/signaling_server.dart` — depends on T018
- [x] T020 [US1] `bin/server.dart` entrypoint — parse `--port`/`--ttl`, start `SignalingServer` via `shelf_io`, print listening line (no codes/IPs/SDP), in `server/bin/server.dart` — depends on T019
- [x] T021 [P] [US1] Server test — `host` → `code-issued`; `join` → `peer-joined` to both; `relay` forwarded to the other peer only (never echoed), in `server/test/signaling_server_test.dart`
- [x] T022 [P] [US1] Server test — `RoomManager` create/join happy path + code is 6 digits with leading zeros preserved + uniqueness across active rooms, in `server/test/room_manager_test.dart`

### App (happy path)

- [x] T023 [P] [US1] `WebSocketSignalingChannel implements SignalingChannel` — map `relay`↔`SignalingMessage` (offer/answer/ice) and `bye`/`peer-left`↔`SignalingBye`; async delivery + drop-after-close mirroring loopback; never throws (returns `Result`), in `lib/core/services/signaling/web_socket_signaling_channel.dart`
- [x] T024 [US1] `SignalingClient` — open the WebSocket to `AppConfig.signalingEndpoint`, `host()`/`join()` happy path, demux inbound (`code-issued`→`hosting`, `peer-joined`→`peerPresent`, `relay`→channel), expose `Stream<PairingState>` + produce the channel, in `lib/core/services/signaling/signaling_client.dart` — depends on T023
- [x] T025 [P] [US1] App test — `WebSocketSignalingChannel` mapping both directions + `SignalingClient` demux (happy host & join) using a fake socket, in `test/core/services/signaling/`
- [x] T026 [P] [US1] `PairingRepository` interface in `lib/features/pairing/domain/pairing_repository.dart`
- [x] T027 [US1] `PairingRepositoryImpl` — wrap `SignalingClient` and wire its produced channel into the #002 transfer engine handshake; surface `connected` when the channel opens, in `lib/features/pairing/data/pairing_repository_impl.dart` — depends on T024, T026
- [x] T028 [P] [US1] `HostSessionUseCase` + `JoinSessionUseCase` in `lib/features/pairing/domain/usecases/` — depends on T026
- [x] T029 [US1] `PairingCubit` (4-state, extended variants prefixed `loadedHosting`/`loadedWaitingForPeer`/`loadedConnected`) injecting the use cases, + its state, in `lib/features/pairing/presentation/cubit/` — depends on T027, T028
- [x] T030 [P] [US1] `bloc_test` for `PairingCubit` happy paths (host emits code→waiting→connected; join emits joining→connected) in `test/features/pairing/pairing_cubit_test.dart`
- [x] T031 [US1] DI registration — `@injectable` `SignalingClient`, `PairingRepository`, use cases, `PairingCubit`; run `build_runner` for injectable, in `lib/core/di/` — depends on T029
- [x] T032 [US1] Dev-only debug surface — `PairingDebugPage` (Host/Join buttons, `CodeBox` + TTL countdown + live `PairingState`, `AppToast` for errors) in `lib/features/pairing/presentation/debug/pairing_debug_page.dart`; add `AppRoutes` constant; router mounts the route **only when `AppConfig.flavor.isDev`**, in `lib/core/router/` — depends on T029 (FR-021a)
- [x] T033 [US1] Integration test (the SC-006 headline) — start the real relay in-process on an ephemeral port + two real clients → `host`→code→`join`→`peer-joined`→relay offer/answer/ICE→#002 loopback engine DataChannel **open**; assert **no bytes traversed signaling** (SC-002), in `test/integration/pairing_handshake_test.dart` — depends on T020, T024

**Checkpoint**: MVP — two clients pair and open a channel end-to-end in CI; the dev debug screen drives the same flow on-device.

---

## Phase 4: User Story 2 - Pairing fails clearly and safely (Priority: P2)

**Goal**: Expired code, invalid code, room-full, and join-abuse each produce a distinct, actionable outcome — never a silent hang.

**Independent Test**: Drive each failure against the in-process relay and assert the joining client receives the correct distinct `AppFailure` (`roomExpired`/`invalidCode`/`roomFull`/`rateLimited`) while room state stays consistent (SC-003).

### Server (failure paths)

- [x] T034 [US2] `RoomManager` TTL — per-room expiry `Timer` sized by a **configurable** `Duration` (default 5 min) → remove room + send `code-expired` to survivors, plus lazy expiry check on `join`, in `server/lib/room_manager.dart` — depends on T018
- [x] T035 [US2] `RoomManager.join` — `invalid-code` (unknown/malformed) and `room-full` (third peer; existing pair undisturbed) responses, in `server/lib/room_manager.dart`. Note: a `join` whose host already disconnected (room torn down) yields `invalid-code`/`code-expired` (not a dedicated "peer gone") — the receiver is never left waiting (spec edge case "Sender never returns")
- [x] T036 [US2] Code-collision regeneration (bounded retry against active codes) in `createRoom()`, in `server/lib/room_manager.dart`
- [x] T036a [US2] One-active-code-per-sender (FR-006) — track the room a connection hosts; a fresh `host` from a connection that already owns a room tears the old room down (→ `code-expired` to any survivor) and invalidates the old code before issuing the new one, in `server/lib/room_manager.dart` (+ `server/lib/peer_connection.dart` if the host-room link lives on the connection)
- [x] T037 [P] [US2] `RateLimiter` — per-connection consecutive invalid-`join` cap + sliding window → `rate-limited(retryAfter)` then throttle/close; reset on valid join; wire into the join path, in `server/lib/rate_limiter.dart` (FR-011a)
- [x] T038 [P] [US2] Server tests — TTL expiry via short injected `Duration` (no real wait), `invalid-code`, `room-full` for a third peer, collision regen, **one-active-code-per-sender (FR-006: a second `host` invalidates the prior code → `code-expired`)**, **race-on-join (two concurrent `join`s for one code → exactly one `peer-joined`, the other `room-full`)**, and rate-limit trip, in `server/test/room_manager_test.dart` + `server/test/rate_limiter_test.dart`

### App (failure mapping)

- [x] T039 [US2] `SignalingClient` — map `room-full`/`invalid-code`/`code-expired`/`rate-limited` and connect/handshake timeout + unreachable host → `PairingState.failed(AppFailure)` (roomFull/invalidCode/roomExpired/rateLimited/signalingTimeout/signalingUnreachable), in `lib/core/services/signaling/signaling_client.dart` — depends on T024
- [x] T040 [US2] Local `^\d{6}$` validation in `SignalingClient.join()` → `invalidCode` without a round-trip, in `lib/core/services/signaling/signaling_client.dart`
- [x] T041 [P] [US2] Localized failure mapping + ARB strings (Vietnamese primary + English, with `@description`) for code expired / invalid code / room full / signaling unreachable / rate-limited, in `lib/l10n/arb/` + the `AppFailure`→message mapper
- [x] T042 [P] [US2] App tests — `SignalingClient` failure mapping (fake socket) + `PairingCubit` error states (`bloc_test`), in `test/core/services/signaling/` + `test/features/pairing/`
- [x] T043 [US2] Integration test — invalid / expired (short TTL) / room-full / rate-limited each yield the distinct `AppFailure` and leave the relay consistent (SC-003), in `test/integration/pairing_handshake_test.dart`

**Checkpoint**: every pairing failure is distinct and surfaced; US1 happy path still green.

---

## Phase 5: User Story 3 - Connections clean up & the service stays stateless (Priority: P3)

**Goal**: A disconnect or graceful leave tears down the room, notifies the survivor, and leaves no residue; the relay keeps nothing after a session ends.

**Independent Test**: Establish a room, forcibly disconnect one peer → survivor gets `peer-left`, room removed, the code no longer joinable; after both leave, assert no room/code/metadata remains (SC-004, SC-005).

### Server (lifecycle)

- [x] T044 [US3] Socket-close handler in `PeerConnection` → `RoomManager` tears down the peer's room + sends `peer-left` to the survivor, in `server/lib/peer_connection.dart` + `server/lib/room_manager.dart` — depends on T017, T018
- [x] T045 [US3] `bye` graceful-leave handling + both-peers-left room removal + assert-no-residue (registry empty), in `server/lib/room_manager.dart`
- [x] T046 [P] [US3] Server tests — peer disconnect → `peer-left` + room removed + code now `invalid-code`; both-leave → registry empty; expired room leaves nothing (SC-004/SC-005), in `server/test/room_manager_test.dart`

### App (teardown)

- [x] T047 [US3] `SignalingClient` — `peer-left` / socket drop → `failed(connectionLost)`; `dispose()` sends `bye`, closes the socket, idempotent, in `lib/core/services/signaling/signaling_client.dart` — depends on T024
- [x] T048 [P] [US3] App test — `peer-left` → `connectionLost`; `dispose()` idempotent and stops emitting, in `test/core/services/signaling/`
- [x] T049 [US3] Integration test — mid-handshake disconnect of one client → the other is notified (`connectionLost`) and the room is gone (re-join of the code fails), in `test/integration/pairing_handshake_test.dart`

**Checkpoint**: all three stories pass independently in CI.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Docs, privacy audit, gates, and per-spec hygiene.

- [x] T050 [P] Write `server/README.md` — self-hosting (run, `--port`/`--ttl`, `wss://` behind a reverse proxy), and the privacy guarantees (in-memory only, no bytes, logs carry phase/error-type only)
- [x] T051 [P] Privacy & log audit — confirm client **and** server logs contain no codes, file data, peer ids, IPs, or SDP/ICE payloads (FR-022); only phase/error-type via `AppLogger` / server logger
- [x] T052 Run all gates — `dart format .`; `dart analyze lib test` (0); `(cd server && dart analyze && dart test)`; `(cd packages/safesend_signaling && dart analyze && dart test)`; `flutter test`; `dart run bloc_tools:bloc lint .` (or note deferred as in #001)
- [x] T053 Run [quickstart.md](quickstart.md) end-to-end — start the relay, point the app, run all three test suites green
- [x] T054 [P] Per-spec hygiene — update `.claude/claude-app/changelog.md` (append #003 entry), `project-context.md` (move #003 to Implemented, next → #004), and `sdd-roadmap.md` (#003 status; mark #004 🟡 Next)

---

## Deferred (device-only — tracked in the status banner)

- [ ] T055 [DEFERRED] [US1] Two-physical-device smoke — deploy/forward the relay, build the **dev** flavor on two phones, pair via the debug screen across different networks (STUN), and verify channel-open plus the expiry / invalid-code / room-full / peer-left checks, per [quickstart.md](quickstart.md) §6. Manual; cannot run in CI (Constitution XII).

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: no dependencies — start immediately. T002/T003/T004 are [P].
- **Foundational (Phase 2)**: depends on Setup. The shared protocol (T006–T008) **blocks both** the server and the app. **No story work until Phase 2 is done.**
- **User stories (Phases 3–5)**: all depend on Foundational. They are **layered** here (not fully independent): US2 (failures) and US3 (cleanup) extend the US1 server/client files, so prefer US1 → US2 → US3. Each is still independently *testable* at its checkpoint.
- **Polish (Phase 6)**: depends on the desired stories being complete.

### Story dependencies

- **US1 (P1)**: the MVP. Establishes `RoomManager`, `SignalingServer`, `SignalingClient`, `WebSocketSignalingChannel`, the pairing feature, and the integration harness.
- **US2 (P2)**: extends `RoomManager`/`SignalingClient` (same files) → sequence after US1.
- **US3 (P3)**: extends `RoomManager`/`PeerConnection`/`SignalingClient` (same files) → sequence after US1 (independent of US2 in logic, but touches shared files — coordinate if parallelized).

### Within each story

- Tests are written alongside implementation (Constitution XII); the integration test for each story is the acceptance gate.
- Server frame handling → client demux → repository/use cases → cubit → debug surface.

---

## Parallel Opportunities

- **Setup**: T002, T003, T004 in parallel (distinct packages/dirs).
- **Foundational**: T007, T008 (shared pkg) ∥ T010, T012, T013, T014, T015 (distinct app files) — then T016 build_runner barrier.
- **US1**: T017 ∥ T023 ∥ T026 ∥ T028 (distinct files); server tests T021 ∥ T022; app test T025 ∥ cubit test T030.
- **US2**: T037 (rate_limiter.dart) ∥ T041 (ARB) ∥ T042 (tests); note T034/T035/T036/T036a all edit `room_manager.dart` → **sequential**.
- **US3**: T046 ∥ T048 (distinct test files).
- **Polish**: T050 ∥ T051 ∥ T054.

### Parallel example — US1 kickoff

```bash
# After Phase 2, launch the independent US1 scaffolds together:
Task: "PeerConnection in server/lib/peer_connection.dart"            # T017
Task: "WebSocketSignalingChannel in lib/core/services/signaling/..." # T023
Task: "PairingRepository interface in lib/features/pairing/domain/"  # T026
Task: "Host/JoinSessionUseCase in lib/features/pairing/domain/usecases/" # T028
```

---

## Implementation Strategy

### MVP first (User Story 1 only)

1. Phase 1 Setup → 2. Phase 2 Foundational (CRITICAL — shared protocol blocks everything) → 3. Phase 3 US1 → **STOP & VALIDATE**: the integration test (T033) proves two clients pair and open a channel with no bytes on signaling. Demo on two devices via the dev debug screen.

### Incremental delivery

1. Setup + Foundational → protocol + models ready.
2. US1 → pair & connect (MVP) → integration test green.
3. US2 → robust failure handling → distinct `AppFailure`s.
4. US3 → clean teardown & statelessness.
5. Polish → docs, privacy audit, gates, hygiene.

---

## Notes

- `[P]` = different files, no dependency on an incomplete task.
- This is the repo's first multi-package layout — keep the shared protocol as the single source of truth (Constitution VIII); never duplicate frame-type literals in the server or app.
- The #002 `SignalingChannel` seam is reused unchanged; `WebSocketSignalingChannel` is only its real network implementation.
- All fallible ops return `Result<T>`; tests inject a short TTL/clock (no real 5-minute waits) — Constitution XII determinism.
- Commit after each task or logical group; run the gates (T052) before opening the PR.
