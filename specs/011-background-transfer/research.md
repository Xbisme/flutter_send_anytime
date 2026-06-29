# Research: Background Transfer (#011)

**Date**: 2026-06-27 · **Branch**: `011-background-transfer`
**SDK floor (verified from pubspec.yaml)**: Dart `^3.11.0` · Flutter `>=3.41.0` · iOS `13.0` · Android `minSdk 26`.

This document resolves the plan's NEEDS CLARIFICATION items and records package + platform decisions. Package versions were verified on pub.dev on 2026-06-27 (Constitution XV).

---

## Decision 1 — iOS Live Activity bridge: `live_activities` 2.4.9

- **Decision**: Use `live_activities` `^2.4.9` to bridge Dart → ActivityKit, and hand-write a native **iOS Widget Extension** (Swift/SwiftUI) implementing the Live Activity / Dynamic Island UI from the design.
- **Verified (pub.dev 2026-06-27)**: latest `2.4.9`; pubspec `environment: { sdk: ^3.11.0, flutter: >=3.41.0 }` — **exactly the project floor, no pinning needed** (unlike app_links #008). Published ~2 months ago. License MIT, verified publisher.
- **Platform**: iOS 16.1+ for Live Activities (the package itself states "iOS 16.1+ or Android API 24+"; we use it iOS-only). Android beta path (RemoteViews) is **not** used — Android uses `flutter_foreground_task` instead.
- **What it does / does not do**: it provides the Dart↔ActivityKit channel (start/update/end an Activity + push an App-Group state dictionary). It does **not** provide the UI — the developer MUST implement a Widget Extension target in Swift/SwiftUI with an `ActivityAttributes` + a `ContentState` matching our pushed fields. This is the main native lift of the spec.
- **Update mechanism**: `updateActivity()` works **only while the app has execution time** (foreground or within iOS's short background-task grace). Remote updates to a fully-suspended app require **APNs push** — out of scope (Principle I: no server pushing to us). Consequence: on iOS, a long transfer that the OS suspends will stop updating and then be interrupted → handled by the clean-fail path (US3 / FR-011..013).
- **Rationale**: the Live Activity UI must be custom SwiftUI either way (the compact/minimal/expanded + lock-screen layouts in the design); the package removes the tedious ActivityKit↔Flutter bridge boilerplate and App-Group plumbing. Writing the bridge fully by hand (raw MethodChannel + Swift) is strictly more code for the same result.
- **Alternatives considered**:
  - *Fully-native ActivityKit via a custom MethodChannel (no package)* — rejected: more boilerplate, we'd reinvent the App-Group state push the package already does; no capability gain.
  - *`live_activities` Android RemoteViews path* — rejected for Android: `flutter_foreground_task` is the idiomatic foreground-service solution and is what actually keeps the process alive; RemoteViews would not solve background execution.

## Decision 2 — Android foreground service: `flutter_foreground_task` 9.2.2

- **Decision**: Use `flutter_foreground_task` `^9.2.2` to run an Android **foreground service** (type `dataSync`) that keeps the app process alive during a backgrounded transfer and renders the ongoing progress notification with a single "Huỷ" (Cancel) action.
- **Verified (pub.dev 2026-06-27)**: latest `9.2.2`; constraints Flutter `>=3.22.0`, Dart `>=3.4.0` (both **below** the project floor → compatible). Android `minSdk 21` (project is 26 ✓), iOS `12.0+`. Supports **0–3 notification action buttons** and a **progress bar**; supports two-way comms with the main isolate. License MIT.
- **Android manifest / permissions**: requires `FOREGROUND_SERVICE` + the service-type permission `FOREGROUND_SERVICE_DATA_SYNC`, and the `<service>` declared with `android:foregroundServiceType="dataSync"`. `POST_NOTIFICATIONS` is **already present** (added in #010). No new Gradle/AGP churn expected (AGP 8.11.1 / compileSdk 35 already in place).
- **Keep-alive model (important)**: the transfer runs on the **main isolate** (the existing #002 engine + WebRTC sockets). We do **not** move the transfer into the plugin's background isolate. The foreground service's job is simply to keep the **process** alive so the main-isolate transfer keeps running; progress notification updates are pushed from the main isolate via the plugin's update API on each transfer snapshot. (The plugin's separate `TaskHandler` isolate is used minimally/not for transfer work.)
- **Android 14+ note**: `dataSync` foreground services have a ~6-hour/day cumulative cap on Android 14+. Acceptable for file transfers (well under the cap); documented, not worked around.
- **Rationale**: a foreground service is the only sanctioned way to keep a long network operation alive in the background on Android; `flutter_foreground_task` handles the service lifecycle, Android-14 service types, notification, and action buttons — non-trivial to hand-roll (Constitution XIII: package justified by concrete capability).
- **Alternatives considered**:
  - *Hand-written native foreground Service + MethodChannel* — rejected: significantly more native code for the same behavior; the plugin is well-maintained and current.
  - *WorkManager / background job* — rejected: WorkManager is for deferrable jobs, not a live, user-visible, immediately-running transfer with a persistent notification.

## Decision 3 — iOS background-execution strategy (honest scope)

- **Decision**: iOS gets the **Live Activity for display** plus best-effort continuation within iOS's default background grace (a short `beginBackgroundTask` assertion). iOS does **not** promise sustained background transfer for long files.
- **Rationale**: Safe Send is **data-channel-only** (Principle I/II — no camera/mic/audio). The audio/VoIP keep-alive tricks other apps use to stay alive are **forbidden** here. iOS gives a foreground app only a brief window (~seconds to ~30s) after backgrounding before suspending non-exempt work. A multi-minute WebRTC file transfer will therefore be suspended by iOS once that window elapses.
- **Consequence (already in the spec)**: `SC-001` scopes the "runs to completion while backgrounded" guarantee to the **Android** path. On iOS, short transfers may finish within the grace window; longer ones are suspended → **clean fail + retain partial + retry** (US3, FR-011..013). The Live Activity reflects last-known state and is then ended on the failure.
- **Alternatives considered**:
  - *Audio/VoIP background mode keep-alive* — rejected (violates Principle I/II; also App-Store-risky for a non-audio app).
  - *BGProcessingTask / BGTaskScheduler* — rejected: these are for deferred maintenance work, not a live socket transfer; they don't extend an in-progress transfer.

## Decision 4 — Orchestration architecture (single source of truth)

- **Decision**: A **core-pure `BackgroundTransferCoordinator`** (`lib/core/services/background/`) observes (a) the existing transfer **snapshot stream** (the #002 single source of truth) for the active transfer and (b) **app lifecycle** (foreground/background). It drives two thin platform controllers — `LiveActivityController` (wraps `live_activities`) and `ForegroundServiceController` (wraps `flutter_foreground_task`) — mapping each `TransferSnapshot` to the surface state. **No parallel progress model** is introduced (Constitution VIII / FR-005).
- **How the active transfer reaches core** (Constitution XI — core MUST NOT import features): the Send/Receive cubits **publish** the active transfer to the coordinator on start — its snapshot stream, static metadata (direction, peer name, file count), and a `cancel()` callback — and clear it on terminal state. This is an **additive seam** mirroring the #006 `RecordTransferUseCase` injection and the #008 `ActiveHostingRegistry`: features depend on a core service; core depends on no feature.
- **Surface tap → app**: tapping a surface brings the app to the foreground on the in-app progress route (`AppRoutes.sendProgress` / `receiveProgress`), which is already mounted (the flow was never popped — it was only backgrounded). Android uses the plugin's launch intent; iOS opens the app from the Live Activity. A light core hook (à la #008 `DeepLinkCoordinator`) ensures the right route is shown; no feature pages are imported by core.
- **Android Cancel action → transfer**: the notification "Huỷ" button event is delivered to Dart (main isolate) and invokes the published `cancel()` callback — the **same** path as in-app Cancel (FR-007), **immediately, no confirm** (Clarification 2026-06-27).
- **Rationale**: keeping orchestration in a core service (not a feature cubit) matches the #008 `DeepLinkCoordinator` / #010 services precedent, keeps `core/` free of feature imports, and guarantees the surfaces and the in-app progress screen render from the **same** snapshots.

## Decision 5 — Surface fidelity vs. design mock

- **iOS Live Activity**: implemented as **custom SwiftUI** → can closely match the design (compact/minimal/expanded Dynamic Island + lock-screen card, gradient-brand send / gradient-brand-vivid receive). Palette hexes are mirrored from the design tokens **literally in Swift** (the native widget cannot import Dart tokens; this is the documented exception to "no hardcoded hex", which targets Dart call sites — Constitution VI). The token values are recorded in the contract.
- **Android notification**: rendered by `flutter_foreground_task` using the **standard Android notification template** (small icon + accent color + title + text + progress bar + Cancel action). It **cannot** be the custom rounded gradient card the mock depicts — Android system-styles ongoing notifications. We match **content + small icon + accent tint + Cancel**, not the pixel-exact card. This divergence is expected and noted in `ui-design-context.md`.
- **Decision**: accept system styling on Android; full custom fidelity on iOS. No attempt to draw a custom Android notification layout (custom RemoteViews) for v1.0 — YAGNI / fragile across OEMs.

## Decision 6 — Localization of surface text

- **Decision**: All surface strings (titles like "Đang gửi · N tệp", "tới <peer>", meta, "Huỷ") are **composed in Dart from ARB** and passed into the surface state (both iOS Activity state and Android notification config). The native iOS widget renders the strings it is given — it does **not** hold its own copy. Numeric values keep mono/tabular formatting via existing `intl` formatters. This keeps Constitution XIV satisfied without duplicating strings in Swift.

## Resolved unknowns summary

| Unknown | Resolution |
|---|---|
| iOS Live Activity package + version | `live_activities` ^2.4.9 (sdk ^3.11.0 / flutter >=3.41.0 — exact floor) |
| Android FG-service package + version | `flutter_foreground_task` ^9.2.2 (Dart 3.4+/Flutter 3.22+; minSdk 21; iOS 12+) |
| Min iOS for rich surface | 16.1+ (Live Activities); below 16.1 → no rich surface, transfer still best-effort + existing notification |
| iOS sustained background transfer? | No (data-channel-only; no audio keep-alive). Android is the sustained path. iOS = display + grace → clean fail |
| Android FGS type + perms | `dataSync`; FOREGROUND_SERVICE + FOREGROUND_SERVICE_DATA_SYNC; POST_NOTIFICATIONS already present (#010) |
| Parallel progress model? | None — surfaces derive from the #002 snapshot stream (Constitution VIII / FR-005) |
| Where orchestration lives | core-pure `BackgroundTransferCoordinator` + 2 platform controllers; features publish active transfer via additive seam |
| Android Cancel semantics | Immediate, no confirm; same cancel path as in-app (Clarification) |
| Native protocol/engine changes | None — no signaling/transport/protocol/DB-schema edits |
