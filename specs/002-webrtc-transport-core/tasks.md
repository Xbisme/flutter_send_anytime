---
description: "Task list for #002 WebRTC Transport & Transfer Protocol Core"
---

# Tasks: WebRTC Transport & Transfer Protocol Core

**Input**: Design documents from `specs/002-webrtc-transport-core/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: REQUIRED for this feature. Constitution XII mandates unit/integration coverage for the transfer protocol, state machine, signaling handling, chunking/reassembly, and integrity; the engine is exercised end-to-end via the in-process **loopback `SignalingChannel`** (no server, no second device). Spec SC-009 enumerates the required test matrix.

**Organization**: Tasks are grouped by user story. The stories here are **layered** (each builds on the previous), reflecting an engine rather than independent UI slices — see Dependencies. US1 is the MVP.

> ## ⚠️ Status banner — deferred (device-only) tasks
> - **T050 Two-physical-device smoke test** (real NAT traversal + >1 GB throughput) — REQUIRED but **DEFERRED**; cannot run in CI (Constitution XII). The real-signaling version lands with #003.
> - **Gate note**: `flutter analyze` crashes on this detached-HEAD Flutter checkout (AOT snapshot) — use **`dart analyze lib test`** (gate-equivalent).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1–US5 (maps to spec user stories); Setup/Foundational/Polish carry no story label
- All paths are repo-relative

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add verified dependencies and create the engine's directory skeleton.

- [x] T001 Add `flutter_webrtc: ^1.5.2`, `crypto: ^3.0.7`, `uuid: ^4.5.3` to `pubspec.yaml` (versions verified in [research.md](research.md)); run `flutter pub get`; commit updated `pubspec.lock`
- [x] T002 Configure `flutter_webrtc` native requirements: confirm Android `minSdk = 26` in `android/app/build.gradle.kts` (≥ 23 ✓), add Java 8 + Proguard keep rules for release; run `pod install` in `ios/` and commit `ios/Podfile.lock` (no camera/mic usage-description strings — data-channel-only)
- [x] T003 [P] Create source skeleton dirs `lib/core/domain/transfer/`, `lib/core/services/signaling/`, `lib/core/services/transport/` and test dirs `test/core/services/transport/`, `test/core/services/signaling/`, `test/helpers/`

**Checkpoint**: Dependencies resolve; project builds; directories exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared primitives every story needs — failures, constants, domain entities, signaling abstraction + loopback, WebRTC wrapper, protocol codec, DI/config. **No engine orchestration yet** (that starts in US1).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 Extend `lib/core/domain/failures/app_failure.dart` with the transfer variants — `peerUnreachable`, `iceFailed`, `connectionLost`, `dataChannelClosed`, `transferCancelled`, `transferRejected`, `integrityCheckFailed({int fileIndex})`, `fileReadFailed`, `fileWriteFailed`, `storageFull`, `networkError` (keep `unexpected`/`notImplemented`); run `build_runner` to regen `app_failure.freezed.dart`
- [x] T005 [P] Create `lib/core/constants/transfer_constants.dart` — `kProtocolVersion`, `kDataChannelLabel`, `kChunkSize` (16 KiB), `kLowWaterMark` (256 KiB), `kHighWaterMark` (1 MiB), `kConnectTimeout`/`kHandshakeTimeout`/`kStallTimeout`, `kQuarantineDirName`, and the named opcodes `0x01`–`0x08` (per [contracts/transfer-protocol.md](contracts/transfer-protocol.md))
- [x] T006 [P] Create `lib/core/domain/transfer/file_source.dart` — abstract `FileSource` (`name`/`size`/`mimeType`/`openRead()`) + `DiskFileSource` (path held privately, never logged; basename-only `name`)
- [x] T007 [P] Create `lib/core/domain/transfer/transfer_state.dart` — `TransferPhase`, `FileItemStatus`, `TransferRole` enums + `TransferProgress` + `TransferSnapshot` (immutable)
- [x] T008 [P] Create `lib/core/domain/transfer/file_transfer_item.dart` — `@freezed` per-file model (index/name/size/mime/sha256/bytesTransferred/status/failure/quarantinePath/finalPath)
- [x] T009 [P] Create `lib/core/domain/transfer/transfer_manifest.dart` — `@freezed` + JSON manifest (`v`, `sessionId`, `fileCount`, `totalBytes`, `files[]`) with validation helpers (version, count, Σsizes, basename/path-traversal reject)
- [x] T010 Create `lib/core/domain/transfer/transfer_session.dart` — `TransferSession` (id via `uuid`, ordered `items`, `totalBytes`, `fileCount`) + `fromSources(...)` factory (depends on T008)
- [x] T011 [P] Create `lib/core/services/signaling/signaling_channel.dart` — `SignalingChannel` abstract interface (`incoming`/`send`→`Result`/`close`) + `@freezed`+JSON sealed `SignalingMessage` (offer/answer/iceCandidate/bye; **no byte variant**) per [contracts/signaling-channel.md](contracts/signaling-channel.md)
- [x] T012 Create `lib/core/services/signaling/loopback_signaling_channel.dart` — `LoopbackSignalingChannel.pair()` (cross-wired broadcast controllers, microtask-async delivery, optional delay + drop-after-N for resilience tests) (depends on T011)
- [x] T013 Create `lib/core/services/transport/transfer_protocol.dart` — encode/decode `[opcode][payload]` frames + control message models (`ManifestMessage`/`AcceptMessage`/`RejectMessage`/`FileStartMessage`/`FileCompleteMessage`/`SessionCompleteMessage`/`CancelMessage`) + decode-side validation (unknown opcode, malformed JSON) (depends on T005, T009)
- [x] T014 [P] Create `lib/core/services/transport/rtc_peer_connection.dart` — `flutter_webrtc` lifecycle wrapper (create offer/answer, set local/remote SDP, add/collect ICE, create/observe `RTCDataChannel`, connection-state stream, `bufferedAmount`/`onBufferedAmountLow` exposure, teardown) + `@lazySingleton RtcPeerConnectionFactory`
- [x] T015 Extend `lib/core/config/app_config.dart` with `iceServers` (empty default both flavors) and register `RtcPeerConnectionFactory` in DI; run `build_runner` to regen `injection.config.dart` (depends on T014)
- [x] T016 [P] Create `test/helpers/temp_files.dart` — temp-file/dir builders, deterministic byte generators, and a fake slow/dropping channel helper; run `dart run build_runner build --delete-conflicting-outputs` once to settle all freezed/json/injectable codegen
- [x] T017 [P] Foundational test `test/core/services/transport/transfer_protocol_test.dart` — frame encode/decode round-trip for every opcode + unknown-opcode and malformed-JSON rejection
- [x] T018 [P] Foundational test `test/core/services/signaling/loopback_signaling_channel_test.dart` — pair delivers in order, `send` after `close` returns failure, late message ignored (FR-008)

**Checkpoint**: All primitives compile, codegen is clean, protocol + loopback unit tests pass. Engine orchestration can begin.

---

## Phase 3: User Story 1 — Single-file direct transfer, verified intact (Priority: P1) 🎯 MVP

**Goal**: Two engines connect over loopback and transfer ONE file: stream from disk → encrypted channel → quarantine → verify SHA-256 → atomic placement, with both sides walking `idle → connecting → handshaking → transferring → done`.

**Independent Test**: Loopback round-trip of one temp file → received file byte-identical, hash matches, file exists only at destination, both engines reach `done`.

### Implementation for User Story 1

- [x] T019 [US1] Create `lib/core/services/transport/transfer_engine.dart` skeleton — `@injectable`; holds `TransferPhase` state machine, emits `TransferSnapshot` on a broadcast `snapshots` stream (closes after terminal), `current` getter, `dispose()` teardown; constructor injects `RtcPeerConnectionFactory` + `AppConfig`
- [x] T020 [US1] Implement `startSend({session, signaling})` single-file happy path in `transfer_engine.dart` — sender=offerer: create data channel + offer, exchange SDP/ICE via `signaling`, send `manifest`, await `accept`, then `fileStart` → stream `openRead()` as `chunk`s → compute SHA-256 streaming → `fileComplete(sha256)` → `sessionComplete` → `done`
- [x] T021 [US1] Implement `startReceive({signaling, destinationDir, onManifest=autoAccept})` single-file happy path — answerer: validate manifest (T009 helpers), auto-accept, stream chunks to `<dest>/.safesend_tmp/<uuid>.part` while hashing, verify against `fileComplete.sha256`, then collision-safe atomic `rename` into destination (`name (n).ext` if exists — never overwrite); `done` on `sessionComplete`
- [x] T022 [US1] Wire per-file + overall byte-progress emission into `snapshots` during `transferring` (monotonic, reaches 100% at completion) in `transfer_engine.dart`
- [x] T023 [P] [US1] Test `test/core/services/transport/transfer_engine_single_file_test.dart` — loopback round-trip: byte-identical received file, hash match, phase sequence `idle→connecting→handshaking→transferring→done` on both ends, monotonic progress to 100%
- [x] T024 [P] [US1] Test `test/core/services/transport/transfer_engine_placement_test.dart` — file exists ONLY at destination (no leftover `.part`, none mid-transfer at final path); integrity gates completion
- [x] T025 [P] [US1] Test `test/core/services/transport/transfer_engine_teardown_test.dart` — after `done`, peer connection closed, controllers/file handles released, `snapshots` closed, engine spent

**Checkpoint**: MVP — a single file moves end-to-end, verified and atomically placed, fully in CI. **STOP and VALIDATE.**

---

## Phase 4: User Story 2 — Multi-file session as a single unit (Priority: P2)

**Goal**: One manifest, N files transferred sequentially in order; overall progress spans all bytes; session `done` only after the last file verifies; **fail-fast** on any file failure.

**Independent Test**: Loopback send of several differing-size temp files → each byte-identical & verified, in order; overall progress accounts for all bytes; `done` after last; corrupting one file → whole session `failed` with no partial files.

### Implementation for User Story 2

- [x] T026 [US2] Add multi-file sequential orchestration to `startSend`/`startReceive` in `transfer_engine.dart` — loop session items in manifest order (one fully before next), accumulate overall vs per-file progress, reset per-file counters between files
- [x] T027 [US2] Implement fail-fast in `transfer_engine.dart` — first item failure (integrity/read/write) → session `failed`, remaining items stay `pending` and are never written, delete any in-flight `.part`, emit terminal snapshot with the `AppFailure` (FR-013A)
- [x] T028 [P] [US2] Test `test/core/services/transport/transfer_engine_multi_file_test.dart` — order preserved, per-file resets, overall progress correct, `done` only after final verify
- [x] T029 [P] [US2] Test `test/core/services/transport/transfer_engine_fail_fast_test.dart` — one corrupt file → session `failed`, remaining untransferred, zero files at destination
- [x] T030 [P] [US2] Test `test/core/services/transport/transfer_engine_collision_test.dart` — two same-named files in one session land as `a.txt` + `a (1).txt`; a pre-existing destination file is never overwritten

**Checkpoint**: Multi-file batches transfer atomically as one verified unit; failures are all-or-nothing.

---

## Phase 5: User Story 3 — Cancel and clean teardown from either side (Priority: P2)

**Goal**: Either side can cancel promptly; both reach `cancelled`, connection torn down, handles released, no partial file or `.part` left behind.

**Independent Test**: Start a transfer over loopback; cancel from sender (one run) and receiver (another) → both `cancelled`, connection closed, no destination file, no quarantine artifact.

### Implementation for User Story 3

- [x] T031 [US3] Implement `cancel()` in `transfer_engine.dart` — send `cancel(origin)` frame, stop the read/write pump promptly, delete in-flight `.part`(s), close data channel + peer connection, emit terminal `cancelled` snapshot (`AppFailure.transferCancelled`); idempotent
- [x] T032 [US3] Handle an inbound `cancel` frame on both roles in `transfer_engine.dart` — mirror teardown + `cancelled` on the remote side; also resolve cancel-during-handshake (before bytes)
- [x] T033 [P] [US3] Test `test/core/services/transport/transfer_engine_cancel_test.dart` — cancel-from-sender AND cancel-from-receiver: both reach `cancelled`, no file at destination, no `.part`, no leaked resources
- [x] T034 [P] [US3] Test (same file) cancel-during-handshake case → `cancelled` with full teardown, no files

**Checkpoint**: Abort is safe and prompt from both ends; no corrupt artifacts.

---

## Phase 6: User Story 4 — Failures detected, named, no corrupt artifact (Priority: P3)

**Goal**: Manifest reject, corrupted file, malformed/path-traversal manifest, peer disconnect, and failed negotiation each resolve to an explicit named `AppFailure` within a bounded time (no crash, no hang), leaving nothing corrupt at the destination.

**Independent Test**: Inject reject / corrupted chunk / malformed manifest / mid-transfer drop over loopback → each yields the corresponding `AppFailure`, engine settles `failed` (or `transferRejected`) without hanging; corruption leaves no file.

### Implementation for User Story 4

- [x] T035 [US4] Implement manifest reject path in `transfer_engine.dart` — `onManifest` returns false (or throws → treated as reject) → send `reject` → sender surfaces `AppFailure.transferRejected`, both tear down, no file written (FR-014A)
- [x] T036 [US4] Implement engine-level manifest validation rejection in `transfer_engine.dart` — version mismatch, count/Σsize mismatch, basename/path-traversal violation → named failure, no write, no crash (FR-015/023)
- [x] T037 [US4] Implement integrity-mismatch handling in `transfer_engine.dart` — received hash ≠ `fileComplete.sha256` → `integrityCheckFailed(fileIndex)`, delete `.part`, fail-fast (no file at destination)
- [x] T038 [US4] Implement resilience timeouts + disconnect mapping in `transfer_engine.dart` — `kConnectTimeout`→`peerUnreachable`/`iceFailed`, `kHandshakeTimeout`/`kStallTimeout`+datachannel-close→`connectionLost`/`dataChannelClosed`; stall watchdog; never hang (FR-027)
- [x] T039 [P] [US4] Test `test/core/services/transport/transfer_engine_reject_test.dart` — reject → `transferRejected`, no files on either side
- [x] T040 [P] [US4] Test `test/core/services/transport/transfer_engine_malformed_test.dart` — bad version / wrong counts / `../` path traversal → named failure, no crash, nothing written
- [x] T041 [P] [US4] Test `test/core/services/transport/transfer_engine_integrity_test.dart` — corrupted chunk → `integrityCheckFailed`, no file at destination, no `.part`
- [x] T042 [P] [US4] Test `test/core/services/transport/transfer_engine_disconnect_test.dart` — loopback drop mid-transfer → `connectionLost` within bounded time (fake clock / short timeout), no hang

**Checkpoint**: Every ordinary failure mode is a typed, bounded, artifact-free outcome.

---

## Phase 7: User Story 5 — Large-file transfer within a bounded memory budget (Priority: P3)

**Goal**: Multi-GB files transfer with peak memory independent of file size, the sender respecting data-channel backpressure.

**Independent Test**: Loopback transfer of a large/simulated file with a slow consumer → completes intact; sender pauses when `bufferedAmount > kHighWaterMark` and resumes on `onBufferedAmountLow`; peak buffered ≈ high-water + chunk, not ∝ size.

### Implementation for User Story 5

- [x] T043 [US5] Implement backpressure in `startSend` (`transfer_engine.dart`) — set `bufferedAmountLowThreshold = kLowWaterMark`; pause the file-read pump when `bufferedAmount > kHighWaterMark`, `await` `onBufferedAmountLow`, resume; ensure receiver write path also streams without buffering whole file
- [x] T044 [P] [US5] Test `test/core/services/transport/transfer_engine_backpressure_test.dart` — slow consumer: sender pauses above high-water, completes intact, ordering preserved
- [x] T045 [P] [US5] Test `test/core/services/transport/transfer_engine_memory_test.dart` — large/simulated file: peak buffered file bytes ≤ `kHighWaterMark + kChunkSize`, no growth proportional to file size

**Checkpoint**: "No size limit" is real and memory-bounded.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Privacy/log audit, the no-bytes-on-signaling guarantee, gates, and docs.

- [x] T046 [P] Privacy/log audit across `signaling/` + `transport/` — ensure `AppLogger` logs only phase/opcode/size/count/typed-failure; assert no file names/paths, IPs, SDP/ICE, or payload bytes appear (SC-008); fix any leaks
- [x] T047 [P] Test `test/core/services/signaling/signaling_no_bytes_test.dart` — structurally assert `SignalingMessage` exposes no byte-carrying variant and a session can complete with signaling carrying only SDP/ICE/control (SC-007)
- [x] T048 Run the gate: `dart format --set-exit-if-changed .` · `dart analyze lib test` (0 issues) · `flutter test` (all green; `--test-randomize-ordering-seed random`) · `dart run bloc_tools:bloc lint .` (no cubits added → expect 0)
- [x] T049 Execute [quickstart.md](quickstart.md) round-trip and confirm the SC-009 test matrix is all green
- [ ] T050 **[DEFERRED — device-only]** Two-physical-device smoke test — wire a temporary/manual SDP exchange on two real devices on one LAN, send a multi-file batch incl. a >1 GB file, confirm integrity + bounded memory + real-link completion; cannot run in CI (Constitution XII). Keep tracked in the status banner; real-signaling version follows in #003

---

## Dependencies & Execution Order

### Phase dependencies
- **Setup (P1)**: no deps — start immediately.
- **Foundational (P2)**: depends on Setup — **BLOCKS all user stories**.
- **US1 (P3)**: depends on Foundational. **MVP.**
- **US2 (P4)**: depends on US1 (extends `startSend`/`startReceive` orchestration).
- **US3 (P5)**: depends on US1 (cancel tears down the US1 pipeline). Independent of US2.
- **US4 (P6)**: depends on US1 (failure paths around the US1 pipeline); integrity-fast-fail also touches US2's fail-fast.
- **US5 (P7)**: depends on US1 (backpressure on the US1 send pump).
- **Polish (P8)**: depends on all desired stories.

> Note: unlike independent UI stories, these are **layered around one engine file** (`transfer_engine.dart`). US2–US5 each modify it, so they are best done in priority order, not concurrently, to avoid same-file conflicts. Their **tests** ([P]) are independent.

### Within each story
- Implementation (engine edits, sequential) → then the story's `[P]` tests (independent files, parallel).
- Foundational entity/codec tasks marked `[P]` are independent files and parallelize; `transfer_session` (T010) waits on `file_transfer_item` (T008); `loopback` (T012) waits on `signaling_channel` (T011); `protocol` (T013) waits on constants+manifest; DI (T015) waits on the RTC wrapper (T014).

### Parallel opportunities
- Setup: T003 alongside T001/T002 prep.
- Foundational: T005, T006, T007, T008, T009, T011, T014 in parallel; then T010/T012/T013/T015; tests T016/T017/T018 in parallel.
- Each story's test tasks (`[P]`) run together once that story's engine edits land.

---

## Parallel Example: Foundational entities

```bash
# After T004 (failures) lands, these independent files can be built in parallel:
Task: "T005 transfer_constants.dart"
Task: "T006 file_source.dart"
Task: "T007 transfer_state.dart"
Task: "T008 file_transfer_item.dart"
Task: "T009 transfer_manifest.dart"
Task: "T011 signaling_channel.dart (+ SignalingMessage)"
Task: "T014 rtc_peer_connection.dart"
```

## Parallel Example: User Story 1 tests

```bash
# After T019–T022 (engine single-file path) land:
Task: "T023 single-file round-trip test"
Task: "T024 placement/integrity test"
Task: "T025 teardown/no-leak test"
```

---

## Implementation Strategy

### MVP first (US1 only)
1. Phase 1 Setup → 2. Phase 2 Foundational (CRITICAL, blocks everything) → 3. Phase 3 US1 → 4. **STOP & VALIDATE** single-file loopback round-trip → that is the demonstrable engine MVP.

### Incremental delivery
US1 (MVP: one file) → US2 (multi-file + fail-fast) → US3 (cancel) → US4 (named failures) → US5 (bounded memory) → Polish. Each phase keeps prior tests green.

### Notes
- `[P]` = different files, no incomplete dependency.
- `[Story]` label traces a task to its spec user story.
- Engine orchestration tasks (US1–US5) touch the same `transfer_engine.dart` → do them in order; their tests are parallel.
- Commit after each task or logical group. Run codegen (`build_runner`) after any freezed/json/injectable change.
- Gate every commit: `dart format` · `dart analyze lib test` (0) · `flutter test` · `bloc lint` (0).

## Task summary

- **Total**: 50 tasks (T001–T050)
- **Setup**: 3 (T001–T003) · **Foundational**: 15 (T004–T018) · **US1**: 7 (T019–T025) · **US2**: 5 (T026–T030) · **US3**: 4 (T031–T034) · **US4**: 8 (T035–T042) · **US5**: 3 (T043–T045) · **Polish**: 5 (T046–T050)
- **Tests**: 17 test tasks across foundational + every story + polish (loopback-driven; SC-009 matrix)
- **Deferred**: T050 two-physical-device smoke (device-only, tracked in banner)
- **MVP scope**: Phases 1–3 (through T025).
