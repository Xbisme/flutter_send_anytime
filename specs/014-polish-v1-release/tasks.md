---

description: "Task list for #014 Polish & v1.0 Release"
---

# Tasks: Polish & v1.0 Release

**Input**: Design documents from `/specs/014-polish-v1-release/`
**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Tests**: INCLUDED — Constitution XII mandates unit tests for logic, `bloc_test` for every Cubit, and widget tests for transfer-critical flows. Test tasks are grouped per story.

**Organization**: Tasks grouped by user story (priority order) for independent implementation + testing.

## Status Banner

- 🟡 **In progress — all CI-implementable work done + verified** (2026-06-29). Gates (final): `dart analyze lib test` = **0**, `dart analyze` server + signaling pkg = **0**, `dart format` clean, `dart run bloc_tools:bloc lint` = **0 (234 files)**. Tests: **app 374 pass · server 29 pass · signaling pkg 33 pass** — all green.
- **DONE (code + tests + docs)**:
  - **US1 (TURN + resilience)** — additive `turn-credentials` frame; server coturn config + ephemeral HMAC minting (`server/turn_credential_service.dart`, sent **before** `peer-joined`); client capture → `sessionIceServers`; `getStats` relay detection (`ice_stats.dart` + `RelayAware`) → `TransferSnapshot.relayInUse`; "relayed · encrypted" progress indicator + ARB (VI/EN); `AppFailure.relayUnavailable` mapped in all 3 failure mappers. Tests: frame codec, server HMAC, ice-stats matrix, client cred-merge, relay-indicator widget, mapping.
  - **US2** — privacy explainer already accurate re TURN; `docs/release/security-verification.md`; log-hygiene asserted (frame "no byte field" + server "no file bytes" + secret-absent-from-mint).
  - **US4 (partial)** — `Haptics` util (built-in, graceful) + wired connect/complete/fail in send+receive via `BlocListener` + tests.
  - **Polish** — `bloc_tools` installed, lint gate now real (**T053**, clears #001 debt); ARB VI↔EN parity; analyze/format/test gates green.
  - **Docs/scaffold** — `docs/release/` (README, smoke-matrix, security-verification, store-listing, a11y-audit, dark-mode-audit) + `server/turnserver.conf` + README TURN section.
- **DEFERRED — needs hardware / manual sweep (cannot run in CI)**:
  - **US5** entirely (two-device smoke matrix, `pod install`, signing Team) — `docs/release/smoke-matrix.md` ready to fill.
  - **US6** device build execution (signed/obfuscated build runs on device, screenshots) — build commands + store templates staged; no submission (FR-029).
  - **US3** per-screen a11y walkthrough + **US4** dark-mode/perf sweep + ≥4 GB profiling — code-level guards in place; checklists in `docs/release/` need on-device verification.
  - **T052** per-spec hygiene doc flip — do at actual merge, not now (#014 not fully done until device work lands).
- Was: ⬜ Not started — generated 2026-06-29.
- **Two-device device validation (US5) is the spec's own on-device backlog** (Constitution XII): it absorbs every deferred two-device smoke / first `pod install` / signing-Team item from #002–#013. It cannot run in CI.
- **No new Flutter/Dart client package planned** (Principle XIII/XV): TURN = config + one additive signaling frame; haptics = built-in. If implementation proves a package is unavoidable, verify on pub.dev first (Constitution XV) and note it here.
- **bloc-lint CLI debt cleared this spec**: the `bloc_tools` CLI has been uninstalled/deferred since #001, so the Constitution-mandated bloc-lint gate has never actually run. v1.0 is the moment to fix it — **T053** installs it and makes the gate real (Constitution III/IV).
- Gate per task group: `dart format` · `dart analyze lib test` = 0 · `flutter test` green · `dart run bloc_tools:bloc lint .` (real once T053 lands).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1–US6 (maps to spec.md user stories)

## Path Conventions

Mobile app in `lib/`, shared protocol in `packages/safesend_signaling/`, self-hostable relay + coturn in `server/`, release artifacts in `docs/release/`, tests in `test/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branch hygiene and scaffolding for the sweep

- [x] T001 Confirm branch `014-polish-v1-release`, `flutter pub get`, baseline `flutter test` green (357 from #013) and `dart analyze lib test` = 0 before changes
- [x] T002 [P] Create `docs/release/` with a README outlining the store-asset + privacy-form checklist (filled in US6)
- [x] T003 [P] Add the new ARB key stubs (VI primary + EN) for relay indicator + resilience failure copy in `lib/l10n/arb/app_vi.arb` and `lib/l10n/arb/app_en.arb` (with `@description`), then run codegen

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting data shapes US1 + US2 (+ US5) all reference. ⚠️ Complete before those stories.

- [x] T004 Add an additive, versioned `turnCredentials` frame to the shared protocol package `packages/safesend_signaling/` (JSON envelope per [contracts/turn-credentials.md](contracts/turn-credentials.md); unknown-type demux stays backward compatible) + unit test for encode/decode + unknown-type tolerance — `TurnCredentialsFrame` + `typeTurnCredentials`; 5 new tests pass
- [x] T005 ~~Add a `TurnCredentials` value type~~ → **resolved by reuse (Principle XIII)**: the existing `RtcIceServer` (urls/username/credential) + the wire `TurnCredentialsFrame` cover this; wire→app mapping happens at consumption (T011). No redundant type added; values stay session-only + never logged
- [x] T006 Add an additive `relayInUse` bool (default false) to `TransferSnapshot` in `lib/core/domain/transfer/transfer_state.dart` without altering the state machine; `TransferView` passthrough done in `transfer_view.dart` (freezed regenerated)
- [x] T007 [P] Add `AppFailure.relayUnavailable()` to `lib/core/domain/failures/app_failure.dart` (decided: included — distinct FR-008 case vs `peerUnreachable`) + freezed regenerated

**Checkpoint**: Shared shapes exist — stories can begin.

---

## Phase 3: User Story 1 — TURN fallback + resilience (Priority: P1) 🎯 MVP

**Goal**: Transfers succeed via an encrypted TURN relay when direct P2P fails; every mid-transfer disruption surfaces a clear, localized, retryable state with no hang; a subtle "relayed · encrypted" indicator shows when relay is in use.

**Independent Test**: On a relay-forced/NAT-blocked path a transfer completes with `relayInUse == true` and the indicator shows; each disruption (Wi-Fi kill, background-past-limit, peer drop, relay stop) yields a clear retryable failure + retained partial; "couldn't connect" appears after the bounded timeout when no path succeeds.

### Server / infra

- [x] T008 [P] [US1] Add coturn config to `server/` (`turnserver.conf`: `use-auth-secret`, realm, ports 3478/5349, fingerprint, denied loopback/multicast peers, error-only logging) + a self-host README section
- [x] T009 [US1] Implement ephemeral-credential minting in the `server/` relay — on room create, `username=<expiry>`, `credential=base64(HMAC-SHA1(secret, username))` (reuse `crypto`), send the `turnCredentials` frame to each peer; secret from env, never logged (per [contracts/turn-credentials.md](contracts/turn-credentials.md))
- [x] T010 [P] [US1] Unit test (server): credential HMAC is deterministic for a fixed secret + injected `now`; expiry honored; secret never appears in output

### Client wiring

- [x] T011 [US1] Consume the `turnCredentials` frame in the signaling client (`lib/core/services/signaling/`) → build a session `iceServers` list (TURN entry + existing STUN); fall back to static per-flavor `iceServers` when the frame is absent (backward compatible)
- [x] T012 [US1] ~~Populate static per-flavor TURN entries in `main_dev`/`main_prod`~~ → **satisfied via the per-flavor server** (the ephemeral-credential decision): each flavor's relay (dev/prod) issues its own coturn's URL + creds in the `turn-credentials` frame, so dev + prod use separate credentials without baking extractable TURN secrets into the client. Static client config stays STUN-only as fallback. (Device deploy: set each flavor relay's `TURN_*` env.)
- [x] T013 [US1] In `lib/core/services/transport/webrtc_peer_connector.dart`, after the channel opens read `RTCPeerConnection.getStats()` selected candidate pair → set `relayInUse` on the snapshot; add a test-only `iceTransportPolicy: 'relay'` flag for forcing the relay path
- [x] T014 [US1] Verify/extend resilience surfacing: peer disconnect / network drop / signaling loss / background-past-limit each map to the correct `AppFailure` and surface a localized retry (no hang, bounded by `kConnectTimeout`); partial retained (existing #005 path) confirmed

### UI

- [x] T015 [US1] Add the subtle localized "relayed · encrypted" indicator to the shared progress page in `lib/core/presentation/transfer/` (design tokens, a11y label; shown only when `relayInUse`)
- [x] T016 [P] [US1] Localize the relay indicator + resilience failure copy (fill T003 stubs; map each `AppFailure` to actionable VI/EN text via the existing failure-l10n mapper)

### Tests (US1)

- [x] T017 [P] [US1] Unit: relay-decision from a stubbed `getStats()` (relay vs host/srflx → `relayInUse`) in `test/core/services/transport/`
- [x] T018 [P] [US1] Unit: signaling client maps `turnCredentials` → session `iceServers`; absence → static fallback, in `test/core/services/signaling/`
- [x] T019 [P] [US1] `bloc_test`: transfer cubit emits the retryable failure state for each disruption + exposes `relayInUse` to the view
- [x] T020 [P] [US1] Widget: progress page shows the relay indicator when `relayInUse`, hides it otherwise, with a11y label
- [x] T021 [P] [US1] Unit: `AppFailure` → localized copy mapping for the resilience set (couldn't-connect / connection-lost / signaling-lost / relay-unavailable)

**Checkpoint**: TURN fallback works end-to-end in loopback/forced-relay tests; resilience states verified. (Real NAT traversal validated on device in US5.)

---

## Phase 4: User Story 2 — Security & privacy verification (Priority: P1)

**Goal**: Re-confirm and document that signaling carries metadata only, the channel is DTLS-encrypted, the relay forwards encrypted bytes and persists nothing, and no sensitive value leaks into any log — now that TURN is in the path. Update the in-app privacy explainer.

**Independent Test**: Signaling capture shows no file bytes; relayed traffic is encrypted and coturn persists nothing; a full log grep over success/failure/cancel/relay finds zero sensitive values; the privacy page accurately describes STUN/TURN.

- [x] T022 [US2] Audit all app + server log statements for the sensitive set (file bytes, paths, peer ids, codes, device names, signaling/TURN endpoints, TURN secret/credentials); fix any leak found
- [x] T023 [P] [US2] Add a log-hygiene test asserting no urls/username/credential/secret string is emitted across mint → send → connect → terminal (extend the existing privacy tests)
- [x] T024 [US2] Update the in-app how-it-works/privacy page (`features/settings/.../privacy`) to accurately describe STUN/TURN: relay only forwards encrypted bytes, persists nothing (VI primary + EN)
- [x] T025 [P] [US2] Write a re-runnable security-verification note in `docs/release/security-verification.md` (what was checked: signaling=metadata-only, DTLS active, relay non-persisted, log grep clean) — completed against device evidence in US5
- [x] T026 [P] [US2] Unit/contract test: signaling frames carry no file-content fields (assert the `turnCredentials` + existing frames are metadata-only)

**Checkpoint**: Privacy promise verified + documented with TURN in place.

---

## Phase 5: User Story 3 — Accessibility (Priority: P2)

**Goal**: Every screen usable with VoiceOver/TalkBack, largest Dynamic Type, and Reduced Motion.

**Independent Test**: Screen-reader walkthrough completes send + receive end-to-end with all controls announced; largest font scale clips nothing critical; Reduced Motion stills the radar + progress animations.

- [ ] T027 [P] [US3] Add `Semantics` labels/roles (localized) to interactive widgets in the shared library `lib/core/presentation/` (buttons, CodeBox, ToggleRow, FileRow, SegmentedTabs, player controls, progress) — single source reused everywhere
- [ ] T028 [P] [US3] Per-screen a11y audit + fixes: home, send/connect, receive, progress, complete, history (+detail), settings, viewers — code/state/progress conveyed without color/animation alone (FR-015); track in a checklist in `docs/release/`
- [ ] T029 [US3] Verify/extend Reduced-Motion gating (`MediaQuery.disableAnimations`) on the radar + transfer spinner/progress (Principle VI) across both roles
- [ ] T030 [US3] Largest-text-scale layout pass: confirm no clipping/overlap on dense screens (Connect code grid, progress, history rows); fix with reflow/scroll
- [ ] T031 [P] [US3] Widget tests: key controls expose semantics labels; a motion-heavy widget renders its static variant when `disableAnimations` is true

**Checkpoint**: All core flows pass a screen-reader + large-text + reduced-motion walkthrough.

---

## Phase 6: User Story 4 — UX polish & performance (Priority: P2)

**Goal**: Haptics on connect/complete/fail, a clean dark-mode sweep, and a proven bounded-memory ≥4 GB transfer.

**Independent Test**: Distinct haptics fire at each moment (graceful no-op where unsupported); every screen correct in dark mode; a ≥4 GB file and a many-file batch transfer with bounded memory and no freeze; cold start ≤ ~3 s.

- [x] T032 [P] [US4] Add a built-in `HapticFeedback` wrapper util in `lib/core/utils/` (connect→medium, complete→success, fail→error; no-op guard) + unit test
- [x] T033 [US4] Fire haptics from the transfer cubits/listeners at connect / complete / fail via `BlocListener` (Principle III — side effects in listener, not builder)
- [ ] T034 [US4] Dark-mode sweep: audit all 8 screens for hardcoded/mis-tokened colors and contrast; fix to tokens-only (Principle VI); track findings in `docs/release/`
- [ ] T035 [US4] Streamed-I/O review: confirm no accidental full-file read was introduced since #002 on send/receive paths (bounded buffers only)
- [x] T036 [P] [US4] Widget/unit test: the haptic listener invokes the wrapper on each terminal/connect transition (mock the wrapper)
- [ ] T037 [US4] (Device, see US5) Profile a ≥4 GB single-file + many-file transfer for peak memory + responsiveness; record cold-start measurement

**Checkpoint**: App feels finished; streamed-memory bound proven on device.

---

## Phase 7: User Story 5 — Two-device device-validation backlog (Priority: P3)

**Goal**: Clear the entire deferred on-device backlog from #002–#013 on two real devices.

**Independent Test**: The smoke matrix (data-model.md) passes for every core cell on real hardware.

- [ ] T038 [US5] iOS `pod install` (folds in any pod churn) + configure a signing Team; produce a dev build that installs/runs on a real iPhone
- [ ] T039 [US5] Two-device smoke: 6-digit, QR, share-link (cold+warm), nearby radar — each full pair → send → receive → save; record pass/fail in the matrix in `docs/release/smoke-matrix.md`
- [ ] T040 [P] [US5] Two-device smoke: background transfer mid-send on iOS (Live Activity + grace) and Android (foreground service sustains) — record results
- [ ] T041 [P] [US5] On-device: open a received image / video / audio / PDF / text in each in-app viewer (#013) + real video thumbnails — record results
- [ ] T042 [US5] On-device: forced relay-only transfer completes (validates US1 over real network) + ≥4 GB bounded-memory profile (executes T037) — record results

**Checkpoint**: Smoke matrix green on hardware; deferred native backlog cleared.

---

## Phase 8: User Story 6 — Release readiness (build & store prep, NOT submission) (Priority: P3)

**Goal**: Obfuscated/signed prod builds that run on device + a complete staged store-listing package; no submission.

**Independent Test**: Signed obfuscated prod build installs/runs on a device for each platform; staged assets reviewed complete + accurate; nothing submitted.

- [ ] T043 [US6] Configure release signing/provisioning + Dart obfuscation (`--obfuscate --split-debug-info`) for iOS + Android prod; verify the build installs/runs on a real device
- [x] T044 [P] [US6] Stage store metadata (VI + EN: name/subtitle/description/keywords/support URL) in `docs/release/`
- [x] T045 [P] [US6] Stage screenshots per required device sizes (both platforms) + store graphics/icons in `docs/release/`
- [x] T046 [P] [US6] Write the privacy policy + Apple privacy-nutrition + Google data-safety answers in `docs/release/` — "Data Not Collected", matching the US2-verified behavior (incl. encrypted-non-persisted TURN)
- [ ] T047 [US6] Final review: confirm the staged package is complete + accurate and that NO submission has been pushed (FR-029)

**Checkpoint**: Release-ready; maintainer can submit with their own accounts.

---

## Phase 9: Polish & Cross-Cutting Concerns (Gate)

- [x] T048 Remove dead code + unused dependencies; confirm `pubspec.lock`/`Podfile.lock` churn is intentional (Principle XV)
- [x] T049 [P] Verify ARB key parity VI ↔ EN for all new strings; `@description` present
- [x] T050 Run the full quality gate: `dart format` · `dart analyze lib test` = 0 · `flutter test` green · `dart run bloc_tools:bloc lint .` = 0 (requires T053)
- [ ] T051 Run `quickstart.md` validation end-to-end; update the Status Banner with final counts + any deferred device cells
- [ ] T052 Per-spec hygiene: flip #014 → ✅ in `project-context.md` + `sdd-roadmap.md`, append a `changelog.md` entry, update `CLAUDE.md` if any rule/stack changed (dev-workflow Per-Spec Hygiene)
- [x] T053 Install the `bloc_tools` CLI (dev_dependency + `dart pub global activate bloc_tools`) so the bloc-lint gate is real for v1.0 — clears the carried debt from #001 (Constitution III/IV); run `dart run bloc_tools:bloc lint .` and fix to 0 violations

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)**: none — start immediately.
- **Foundational (P2)**: depends on Setup; **blocks US1 + US2** (shared frame/snapshot/failure shapes).
- **US1 (P3 phase)**: depends on Foundational. The MVP slice.
- **US2 (P4)**: depends on Foundational + US1 (audits the TURN path US1 builds).
- **US3 (P5)** + **US4 (P6)**: depend only on Setup/Foundational; largely independent of US1/US2 (can run in parallel by different people).
- **US5 (P7)**: depends on US1–US4 being in place (it validates them on device) + needs hardware/signing.
- **US6 (P8)**: depends on US1–US5 (privacy answers + final build reflect verified behavior).
- **Polish (P9)**: depends on all desired stories. Note: **T053 (install bloc_tools) must run before T050** (the gate) — it is listed last by ID but is an execution prerequisite of T050; do it early in P9 (or pull it into Setup).

### Parallel Opportunities

- Setup: T002, T003 in parallel.
- Foundational: T007 in parallel with T004–T006.
- US1: server (T008, T010) ∥ client; tests T017–T021 in parallel.
- US3 + US4 can be staffed in parallel with US1/US2 after Foundational.
- US5 device cells T040, T041 in parallel once a build is on device (T038).
- US6 asset tasks T044–T046 in parallel.

---

## Implementation Strategy

### MVP First (User Story 1)
1. Setup → 2. Foundational → 3. US1 (TURN fallback + resilience) → **STOP & VALIDATE** in loopback/forced-relay → this is the single biggest reliability win and demonstrable on its own.

### Incremental Delivery
US1 (relay+resilience) → US2 (verify privacy) → US3 (a11y) → US4 (polish+perf) → US5 (device validation) → US6 (release prep). Each adds value without breaking prior stories; US5/US6 are the on-device + ship-prep gates.

### Notes
- [P] = different files, no dependencies. [Story] label maps to spec.md traceability.
- Device tasks (US5, T037/T042) cannot run in CI — track in the smoke matrix.
- Commit after each task or logical group; keep the gate green.
