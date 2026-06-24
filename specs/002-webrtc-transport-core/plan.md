# Implementation Plan: WebRTC Transport & Transfer Protocol Core

**Branch**: `002-webrtc-transport-core` | **Date**: 2026-06-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/002-webrtc-transport-core/spec.md`

## Summary

Build the **transport engine** that moves files directly between two devices over an encrypted WebRTC `RTCDataChannel`, with no intermediary server holding the data. This feature is **pure Dart in `lib/core/`**, has **no UI**, and ships **no real signaling server** — instead it defines an abstract `SignalingChannel` and an **in-process loopback** implementation so the entire engine is exercised end-to-end in CI without a server or a second device.

Technical approach: a single ordered/reliable data channel carries a **versioned, opcode-framed transfer protocol** (manifest → accept/reject → per-file streamed chunks → per-file completion with SHA-256 → session completion; plus cancel from either side). Files are **streamed from/to disk** in fixed-size chunks (never fully in memory), the sender **respects data-channel backpressure** via `bufferedAmount` thresholds, and the receiver writes to a **quarantine temp file**, verifies the per-file SHA-256 (computed with `crypto`'s chunked-conversion sink), then **atomically renames** into the destination with **non-overwriting auto-rename** on collision. A **single transfer state machine** (`idle → connecting → handshaking → transferring → done | failed | cancelled`) is exposed as a broadcast stream and is the sole source of truth for progress. The session is **fail-fast** (any file failure fails the whole session) and **two-party sequential** (one file fully before the next). Builds on #001 foundations (`Result<T>`, `AppFailure`, `AppLogger`, DI).

## Technical Context

**Language/Version**: Dart (SDK `^3.11.0`) / Flutter (latest stable 3.x)

**Primary Dependencies** (latest stable verified on pub.dev 2026-06-24 — Constitution XV):
- `flutter_webrtc` **1.5.2** — `RTCPeerConnection` + `RTCDataChannel`. Android requires `minSdk ≥ 23` (project is **26** ✓); iOS WebRTC framework fine at deployment target **13.0** ✓. The plugin declares camera/mic permissions, but **data-channel-only usage calls no `getUserMedia`**, so no camera/mic prompts are triggered and no usage-description strings are required for this feature.
- `crypto` **3.0.7** — SHA-256 via `Sha256().startChunkedConversion(...)` streaming sink (per-file streamed hashing, FR-019).
- `uuid` **4.5.3** — session ids and quarantine temp-file names.

**Storage**: N/A persistence (no `drift`). Transient quarantine temp files only; final destination directory is **injected by the caller** (tests use `Directory.systemTemp`). `path_provider` is deferred to #005 (real platform save locations).

**Testing**: `flutter_test` + `mocktail` 1.0.5; full engine round-trip via the in-process loopback `SignalingChannel`. Command: `very_good test --test-randomize-ordering-seed random` (gate-equivalent locally: `dart test` / `flutter test`).

**Target Platform**: iOS 13.0+ and Android 8.0 (API 26)+ (Flutter, single codebase).

**Project Type**: Mobile app (Flutter) — this feature is an internal engine layer in `lib/core/`.

**Performance Goals**: Bounded memory **independent of file size** (peak ≈ chunk size + in-flight backpressure window, a few MiB) so multi-GB transfers succeed; sustained throughput on a real link is validated only by the deferred two-device smoke test (CI cannot prove it).

**Constraints**: No file bytes over signaling; DTLS never weakened; no file contents/paths/peer-ids/IPs/secrets in logs; all fallible ops return `Result<T>`; engine `lib/core/` MUST NOT import `lib/features/`; deterministic, non-flaky tests.

**Scale/Scope**: Two-party sessions; 1..N files per session (sequential); ~8–10 new `core/` source files + protocol/constants + loopback harness; no screens.

**Resolved unknowns** (candidate NEEDS CLARIFICATION → settled in [research.md](research.md)):
- Chunk size & framing → 16 KiB binary chunks, 1-byte opcode framing, ordering trusted to the reliable/ordered channel (no per-chunk sequence numbers) (R-01, R-02)
- Backpressure mechanism → `bufferedAmountLowThreshold` + high-water pause/resume (R-03)
- Where the per-file SHA-256 travels → in the `fileComplete` frame (computed streaming during send), not pre-read into the manifest (R-04)
- Atomic delivery → quarantine temp file on the destination volume → `File.rename` (R-05)
- Timeouts → connect/handshake + stall-detection timeouts as configurable constants (R-06)
- Collision auto-rename format → `name (n).ext` (R-07)
- ICE config → injectable `RtcConfiguration` on `AppConfig` (empty list this feature) (R-08)
- Receiver accept/reject hook signature → `Future<bool> Function(TransferManifest)` (R-09)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution v1.0.0 (15 principles). Relevance for an engine-only, no-UI transport spec:

| # | Principle | Applies to #002? | Compliance approach | Gate |
|---|---|---|---|---|
| I | Privacy-First P2P | **Yes (core)** | Bytes only over DTLS `RTCDataChannel`; `SignalingChannel` carries SDP/ICE/control only (FR-002/031); `AppLogger` only, no contents/paths/peer-ids/IPs/secrets (FR-032); manifest path-traversal rejected (FR-023); TURN constraint documented though no real relay shipped (FR-033) | ✅ PASS |
| II | Direct Transfer & Data Min. | **Yes (core)** | DTLS not weakened (FR-010); per-file SHA-256 gates "complete" (FR-019/020); streamed I/O, never whole-file-in-RAM (FR-016/017); rendezvous state ephemeral; no content telemetry | ✅ PASS |
| III | BLoC 4-state | No | Engine exposes a `Stream<TransferSnapshot>`; **no cubits in this feature** (UIs in #004/#005 own the 4-state cubits) | ✅ N/A |
| IV | Code Quality & Dart Safety | Yes | `very_good_analysis` zero-warning; strict casts/raw-types/inference; immutable freezed models; explicit public types | ✅ PASS |
| V | Result\<T\> Error Handling | **Yes** | All fallible engine ops return `Result<T>`; `AppFailure` extended with the P2P/transfer/file variants (FR-029/030); services catch+wrap, no throwing for ordinary failures | ✅ PASS |
| VI | Design System & Theming | No | No UI in scope | ✅ N/A |
| VII | Cross-Platform Native | **Partial** | `flutter_webrtc` native config verified (Android minSdk 26 ≥ 23; iOS 13; no camera/mic usage → no extra entitlements); permissions degrade N/A (none requested) | ✅ PASS |
| VIII | Transport & Signaling | **Yes (core)** | Three layers honored; abstract `SignalingChannel` + loopback (FR-006/007); single transfer state machine as source of truth (FR-024); explicit **versioned** protocol (FR-014); backpressure respected (FR-011); ICE config per-flavor/injectable, never hardcoded (FR-005); channel/opcode/message-type constants centralized | ✅ PASS |
| IX | Transfer Reliability | **Yes (core)** | Per-file integrity gates completion (FR-020); interruptions detected & surfaced, no hangs (FR-027); quarantine → atomic move, no truncated file at destination (FR-021/022); malformed input rejected, not crash (FR-015); prompt cancel teardown (FR-028) | ✅ PASS |
| X | go_router Navigation | No | No navigation/UI | ✅ N/A |
| XI | Feature-First Modularity | **Yes** | Engine lives in `lib/core/` (services + domain + constants + config); MUST NOT import `lib/features/`; DI `@injectable`/`@lazySingleton` only, no eager `@singleton` | ✅ PASS |
| XII | Testing Discipline | **Yes (core)** | Loopback channel makes the engine fully testable in CI without server/2nd device; unit tests for protocol framing, chunking/reassembly, integrity, state machine, signaling handling; **two-device smoke test = REQUIRED but deferred**, tracked in tasks.md banner | ✅ PASS |
| XIII | Simplicity & YAGNI | **Yes** | Single reliable/ordered channel (no per-chunk seq numbers); sequential multi-file; per-file hash only; no resume/trusted-peer; `dart:io` streaming over extra packages; only 3 new deps, each justified | ✅ PASS |
| XIV | i18n by Default | No (indirect) | Engine emits **typed `AppFailure`**, not user strings; localization of failures happens at the UI layer (#004/#005) | ✅ N/A |
| XV | Dependency Hygiene | **Yes** | `flutter_webrtc` 1.5.2 / `crypto` 3.0.7 / `uuid` 4.5.3 verified on pub.dev at plan time; native minimums + permissions checked for `flutter_webrtc` before code; caret constraints; lock files committed; no fictional packages | ✅ PASS |

**Result**: No violations. Complexity Tracking empty. Proceed to Phase 0.

**Post-Design re-check (after Phase 1)**: Still PASS — the data model, protocol contract, and engine API introduce no new dependencies beyond the three verified ones, keep `core/` free of `features/` imports, add only typed failures (no user strings), and preserve the signaling-carries-no-bytes and quarantine→atomic-move invariants. No constitution deviation; Complexity Tracking remains empty.

## Project Structure

### Documentation (this feature)

```text
specs/002-webrtc-transport-core/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── signaling-channel.md      # SignalingChannel interface + message schema + loopback
│   ├── transfer-protocol.md      # Wire protocol: opcodes, framing, versioning, sequence
│   └── transfer-engine-api.md    # Public engine API (send/receive/cancel) + state stream
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/core/
├── config/
│   └── app_config.dart           # EXTEND: add `iceServers` (List<RtcIceServer-ish>), empty default
├── constants/
│   └── transfer_constants.dart   # NEW: chunk size, buffered-amount thresholds, data-channel label,
│                                  #      protocol version, opcodes, timeouts, quarantine dir name
├── domain/
│   ├── failures/
│   │   └── app_failure.dart      # EXTEND: peerUnreachable, iceFailed, connectionLost,
│   │                             #         dataChannelClosed, transferCancelled, transferRejected,
│   │                             #         integrityCheckFailed, fileReadFailed, fileWriteFailed,
│   │                             #         storageFull, networkError (+ existing unexpected/notImplemented)
│   └── transfer/
│       ├── transfer_state.dart        # NEW: TransferPhase enum + TransferSnapshot + TransferProgress
│       ├── transfer_session.dart      # NEW: TransferSession (id, items, totals)
│       ├── file_transfer_item.dart    # NEW: per-file metadata + progress + temp/final paths
│       ├── transfer_manifest.dart     # NEW: freezed/json manifest (sent before bytes)
│       └── file_source.dart           # NEW: abstract FileSource (name/size/mime/openRead);
│                                      #      DiskFileSource impl (path-based)
└── services/
    ├── signaling/
    │   ├── signaling_channel.dart           # NEW: abstract interface + SignalingMessage (freezed/json)
    │   └── loopback_signaling_channel.dart  # NEW: in-process two-peer wiring (FR-007)
    └── transport/
        ├── transfer_protocol.dart     # NEW: encode/decode framed protocol messages (pure Dart)
        ├── rtc_peer_connection.dart   # NEW: flutter_webrtc lifecycle wrapper + state stream
        ├── transfer_engine.dart       # NEW: orchestrator — state machine, send/receive,
        │                              #      backpressure, integrity, atomic move, cancel
        └── di/ (annotations inline)   # @injectable engine factory; iceServers from AppConfig

test/core/
├── services/
│   ├── transport/
│   │   ├── transfer_protocol_test.dart        # framing round-trip, malformed rejection
│   │   ├── transfer_engine_single_file_test.dart
│   │   ├── transfer_engine_multi_file_test.dart   # sequential + fail-fast
│   │   ├── transfer_engine_cancel_test.dart       # cancel from sender & receiver
│   │   ├── transfer_engine_integrity_test.dart    # corrupted chunk → integrityCheckFailed, no file
│   │   ├── transfer_engine_backpressure_test.dart # slow consumer
│   │   └── transfer_engine_collision_test.dart    # auto-rename
│   └── signaling/
│       └── loopback_signaling_channel_test.dart
└── helpers/
    └── temp_files.dart             # test fixtures (temp file builders, fake slow channel)
```

**Structure Decision**: Engine-only layer inside the existing Clean-Architecture `lib/core/` tree from #001 — `domain/transfer/` (entities, immutable), `services/signaling/` + `services/transport/` (behavior), `constants/` + `config/` (centralized tuning & ICE config), `failures/` (extended taxonomy). No `lib/features/` changes; the engine is consumed by Send (#004) and Receive (#005) later. Tests mirror the source tree under `test/core/` and drive everything through the loopback channel.

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
