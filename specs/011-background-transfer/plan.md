# Implementation Plan: Background Transfer

**Branch**: `011-background-transfer` | **Date**: 2026-06-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-background-transfer/spec.md`

## Summary

Keep an already-started transfer running and visible while the app is backgrounded or the device is locked, on both platforms, by **rendering the existing #002 transfer-snapshot stream onto OS surfaces** — an iOS Live Activity (Lock Screen + Dynamic Island) and an Android foreground-service notification — with **no parallel progress model** (Constitution VIII). Orchestration lives in a **core-pure `BackgroundTransferCoordinator`** that observes app lifecycle + the active transfer's snapshots and drives two thin platform controllers; Send/Receive cubits publish the active transfer to it through one **additive seam** (mirroring #006/#008), so `core/` imports no features. Android is the **sustained-background** path (foreground service keeps the process alive → transfer completes backgrounded); iOS is **display + brief OS grace**, with long backgrounded transfers cleanly failing into the existing partial-outcome + retry path (data-channel-only means no audio keep-alive — Principle I). Cancel from the Android notification is immediate and reuses the in-app cancel path. No engine/signaling/transport/protocol/DB-schema changes.

## Technical Context

**Language/Version**: Dart `^3.11.0` (Flutter `>=3.41.0`) — the verified project floor.
**Primary Dependencies (new)**: `live_activities ^2.4.9` (iOS Live Activity bridge; sdk `^3.11.0` / flutter `>=3.41.0` — exact floor, no pin) · `flutter_foreground_task ^9.2.2` (Android foreground service; Dart 3.4+/Flutter 3.22+, minSdk 21, iOS 12+). Reuses `permission_handler`, `flutter_local_notifications`/notification permission (#010), `flutter_webrtc`/transfer engine (#002).
**Storage**: None new (no drift table, no `shared_preferences` key, no manifest/protocol field).
**Testing**: `flutter_test` + `bloc_test` + `mocktail`; coordinator/controllers tested with fakes (no plugins/devices) via the loopback-style discipline; two-device on-device smoke deferred.
**Target Platform**: iOS 13.0+ (rich Live Activity only on **16.1+**, Dynamic Island on 14 Pro+); Android `minSdk 26`.
**Project Type**: Mobile app (Flutter, iOS + Android) — feature-first Clean Architecture.
**Performance Goals**: Surface updates throttled to ≈0.5–1 s or ≥1% delta; no measurable added memory (surfaces hold a small view model; transfer streaming is untouched, Principle II).
**Constraints**: Single source of truth = the #002 snapshot stream (no parallel progress); `core/` MUST NOT import `features/`; metadata-only surfaces, no byte/identifier logging; Vietnamese-first ARB; native package versions verified at plan time (done — see research.md).
**Scale/Scope**: Single active transfer; 3 OS surface forms (iOS compact/minimal/expanded + lock screen, Android notification); ~1 core service + 2 platform controllers + 1 additive feature seam + 1 iOS Widget Extension target.

## Constitution Check

*GATE: evaluated before Phase 0 and re-checked after Phase 1 design. Result: **PASS** (no violations; Complexity Tracking empty).*

| Principle | Assessment |
|---|---|
| **I. Privacy-First P2P** | Surfaces display metadata only (peer name, file count, sizes, %); no file bytes. Coordinator/controllers log phase + error-type only — never peerName/bytes/paths (FR-014). No signaling/TURN/transport touch. ✅ |
| **II. Direct Transfer & Data Min.** | Streamed I/O untouched (transfer engine unchanged); no new persistence; no content telemetry. ✅ |
| **III. BLoC State Mgmt** | Long-running progress stays derived from the transfer state machine stream (not setState). Orchestration is a **core service**, not a cubit — precedented by #008 `DeepLinkCoordinator` / #010 services (OS-surface plumbing, not in-app UI state). `onCancel` is a callback, not a cubit-to-cubit ref. ✅ |
| **IV. Code Quality** | very_good_analysis 0; explicit types; immutable view models. ✅ |
| **V. Result\<T\>** | Platform controller calls return `Result<void>`; failures degrade (no surface) rather than throw; OS-suspend reuses existing transfer-failure mapping (connectionLost / cancelled). ✅ |
| **VI. Design System** | iOS Live Activity = custom SwiftUI matching tokens; **documented exception**: token hexes mirrored literally in Swift (native widget can't import Dart tokens) — recorded in contracts. Android notification is system-styled (content + accent + Cancel), noted in ui-design-context. ✅ |
| **VII. Cross-Platform Native** | The feature's substance; permissions degrade gracefully (FR-019); Dynamic Island/cutout aware; honors both platforms' surface conventions. ✅ |
| **VIII. Transport & Signaling** | **Single source of truth honored** — surfaces derive from the #002 snapshot stream; NO parallel progress model (FR-005). No protocol/signaling/config change. ✅ (key gate) |
| **IX. Transfer Reliability** | OS-suspend → clean fail + retain verified partial (#005) + retry (FR-011..013); cancel tears down both ends; no half-written files presented as whole (unchanged engine). ✅ |
| **X. go_router** | Surface tap → `AppRoutes.sendProgress`/`receiveProgress` (centralized constants); no `Navigator` direct. ✅ |
| **XI. Feature-First Modularity** | Coordinator + controllers in `core/services/background/`; core imports no features; features publish via additive seam (like #006 `RecordTransferUseCase` / #008 `ActiveHostingRegistry`). `@lazySingleton` coordinator, no eager singletons. ✅ |
| **XII. Testing Discipline** | Projection + lifecycle + cancel-routing + degraded-path + log-hygiene unit/bloc tests with fakes; two-device background smoke explicitly deferred in tasks banner. ✅ |
| **XIII. Simplicity & YAGNI** | No pause/resume; no custom Android RemoteViews; two packages each justified by concrete native capability; no config/flags. ✅ |
| **XIV. i18n** | All surface strings composed in Dart from ARB (native widget renders given strings); intl formatters for numbers. ✅ |
| **XV. Dependency Hygiene** | Both packages verified on pub.dev 2026-06-27 with exact constraints + min-OS + permissions + transitive notes (research.md); caret constraints; lock files to be committed. ✅ |

**Initial gate (pre-Phase 0)**: PASS. **Post-design gate (post-Phase 1)**: PASS — design introduced no new violations; the only noted deviation (Swift literal hexes) is an inherent native-boundary exception, documented, not a workaround.

## Project Structure

### Documentation (this feature)

```text
specs/011-background-transfer/
├── plan.md              # This file
├── spec.md              # Feature spec (+ Clarifications)
├── research.md          # Phase 0 — package + platform decisions (verified pub.dev)
├── data-model.md        # Phase 1 — in-memory view models + surface lifecycle
├── quickstart.md        # Phase 1 — validation + deferred device smoke
├── contracts/
│   ├── services.md      # Core service interfaces + additive feature seam
│   └── live_activity_state.md  # Dart↔Swift ContentState payload + palette
└── tasks.md             # Phase 2 — /speckit.tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/core/services/background/         # NEW — core-pure orchestration (no feature imports)
├── background_transfer_coordinator.dart   # observes lifecycle + snapshots, drives controllers
├── active_transfer_handle.dart            # published by Send/Receive cubits
├── background_transfer_state.dart         # snapshot → surface view model (+ BackgroundPhase)
├── live_activity_controller.dart          # wraps live_activities (iOS); no-op when unsupported
└── foreground_service_controller.dart     # wraps flutter_foreground_task (Android)

lib/core/domain/transfer/             # reuse TransferSnapshot / TransferView / TransferProgressProjector (unchanged)
lib/core/constants/                   # add background channel/notification-id + ARB keys wiring
lib/core/di/                          # register coordinator (@lazySingleton) + controllers

lib/features/send/presentation/       # additive seam: attach/detach on transferring/terminal
lib/features/receive/presentation/    # additive seam: attach/detach on transferring/terminal

lib/l10n/arb/                         # new surface + interrupted-transfer strings (VI primary + EN)

ios/                                  # NEW Widget Extension target (Swift/SwiftUI Live Activity)
├── <WidgetExtension>/                # ActivityAttributes + ContentState + SwiftUI views
├── Runner/Info.plist                 # NSSupportsLiveActivities = YES
└── (App Group entitlement for Runner + extension)

android/app/src/main/AndroidManifest.xml   # <service> dataSync + FOREGROUND_SERVICE(+_DATA_SYNC)

test/core/services/background/        # coordinator/projection/controller-fake/log-hygiene tests
test/features/{send,receive}/         # seam tests (attach on transferring, detach on terminal, onCancel)
```

**Structure Decision**: Feature-first Clean Architecture (Constitution XI). New cross-cutting orchestration lives in `core/services/background/` because it is consumed by both Send and Receive and must not import features; Send/Receive depend on it via DI and publish the active transfer through an additive seam. The iOS Widget Extension is a native target under `ios/`; the Android service is configured via manifest + the plugin. This mirrors the additive-seam pattern proven in #006/#008/#010.

## Complexity Tracking

> No Constitution violations — section intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Phase 2 (next): `/speckit.tasks`

Tasks will be organized by the three user stories (P1 surface+keep-alive → P2 interact → P3 graceful fail), with setup tasks first: add + verify packages, Android manifest/permissions, iOS Widget Extension + App Group + Info.plist, then the core coordinator/controllers (test-first with fakes), the Send/Receive additive seam, ARB strings, and the deferred two-device background smoke in the banner.
