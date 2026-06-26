# Implementation Plan: Share Link

**Branch**: `008-share-link` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/008-share-link/spec.md`

## Summary

Add the third connection method — a shareable `safesend://connect?v=1&code=NNNNNN` invite link.
The sender shares the link for the **live hosting session** from the Connect hub (system share
sheet); the receiver taps it (warm or cold start) and is routed straight into the Receive flow with
the room auto-joined, landing on the existing accept/reject prompt. The feature **reuses the #007
`ConnectLink` codec verbatim** and the #003 6-digit rendezvous unchanged — it adds only (a) OS-level
deep-link registration + delivery, (b) the share action wiring on the Connect hub, and (c)
`pairingMethod = shareLink` threading. No engine/signaling/transport/protocol/DB-schema changes.

## Technical Context

**Language/Version**: Dart 3.11.x (project `environment: sdk: ^3.11.0`) / Flutter (project floor) — same toolchain as #001–#007
**Primary Dependencies**: `app_links` **6.4.1** (NEW — OS deep-link delivery, cold + warm); `share_plus` 12.0.2 (existing — system share sheet); `go_router` 17.3.0 (existing — routing); reuses `ConnectLink` codec + `SignalingProtocol.isValidCode` (existing)
**Storage**: None new. History reuses the existing `transfer_records` schema; `PairingMethod.shareLink` already reserved (#006) — **no migration**
**Testing**: `flutter_test` + `bloc_test` + `mocktail` (unit/bloc/widget); in-process fakes for the deep-link service; two-physical-device cold/warm smoke deferred (Constitution XII)
**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+ — `app_links` 6.4.1 platform floor (`flutter >=3.24.0`) is well below the project floor
**Project Type**: Mobile (Flutter, iOS + Android), Clean Architecture + feature-first
**Performance Goals**: Tap-to-prompt < 10 s on warm and cold start (SC-001); cold-start invite never dropped (FR-011)
**Constraints**: Privacy — link carries only code + version, no bytes/identity (FR-008, Constitution I/II); custom-scheme only (no domain/AASA/assetlinks, no web fallback — out of scope); links validated at the boundary before routing (Constitution X)
**Scale/Scope**: One new core service + one composition-layer coordinator + 2 additive core seam fields + native scheme registration (iOS Info.plist + Android manifest) + Connect-hub share action; ~1 designed surface touched (Connect hub action) + Receive entry path

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Privacy-First P2P | ✅ | Link payload = code + version only (FR-008). Rendezvous codes already short-lived/single-use (#003). Deep links validated at the boundary before routing (FR-007, FR-013). |
| II. Direct Transfer & Data Min. | ✅ | No change to transport/integrity/streamed-I/O. No new persistence. |
| III. BLoC 4-state | ✅ | Any new presentation state uses 4-state freezed Cubit; deep-link delivery is a core service (no UI state), coordination uses existing cubits + `BlocListener` for side effects. |
| IV. Code Quality & Dart Safety | ✅ | `very_good_analysis` 0; explicit types; immutable seams. |
| V. Result\<T\> | ✅ | `ConnectLink.parse` already returns `Result<String>`; deep-link service maps platform errors to `Result`/typed outcomes; `AppFailure.invalidCode` reused. |
| VI. Design System & Theming | ✅ | Share action reuses existing `SecondaryButton` + `LucideIcons.share2` stub already in place; no new tokens; invite copy via ARB; numeric code uses mono tokens. |
| VII. Cross-Platform Native | ✅ | Registers `safesend://` on iOS (CFBundleURLTypes) + Android (intent-filter) for both flavors; graceful handling of malformed/own/expired links (FR-013/014/015); deep-link is an explicitly-scoped inbound OS integration (Principle VII bullet 4). |
| VIII. Transport & Signaling | ✅ | Share link is a 4th *pairing-method front door* onto the **same** rendezvous; no new signaling/transport path; no protocol frames touched. |
| IX. Transfer Reliability | ✅ | FR-014 forbids silently abandoning an active transfer (confirm dialog). No finalize/integrity change. |
| X. go_router Navigation | ✅ | Routes via `AppRoutes` constants + `context.go`; **deep links validated before routing** (scheme + version + code) per Principle X bullet 5; `safesend://` is the reserved scheme now activated. |
| XI. Feature-First Modularity | ✅ | Deep-link *delivery* (`DeepLinkService`) and *coordination* (`deep_link_coordinator.dart`) are both core-pure — they navigate by `AppRoutes` + core-typed `ReceiveEntryRequest` and import **no** feature pages. Cross-feature handoff stays core-typed (`ConnectRequest`/`ConnectResult`). The existing `core/router` composition root remains the only place importing feature pages. |
| XII. Testing Discipline | ✅ | Unit (ConnectLink already covered; deep-link parse→route mapping), bloc (auto-join path), widget (share action, confirm dialog, invalid-link toast). Two-device cold/warm smoke tracked + deferred. |
| XIII. Simplicity & YAGNI | ✅ | No universal links, no web fallback, no new abstraction beyond a thin `DeepLinkService` seam + a small `ActiveHostingRegistry` for self-invite detection. Reuses `ConnectLink`, share_plus, existing receiver auto-join shape. |
| XIV. i18n by Default | ✅ | New ARB keys (invite share text, own-link / invalid-invite / expired toasts) VI primary + EN with `@description`. |
| XV. Dependency Hygiene | ✅ | `app_links` verified on pub.dev (2026-06-26): latest 7.2.0 requires Dart `^3.12.0` — **incompatible** with this project's Dart 3.11; pinned to **6.4.1** (`sdk ^3.5.0`, `flutter >=3.24.0`), the newest guaranteed-compatible release. Caret constraint `^6.4.1`. Native config (Info.plist / manifest) verified at plan time (this doc). See [research.md](research.md). |

**Gate result: PASS** — no violations, no Complexity Tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/008-share-link/
├── plan.md              # This file
├── spec.md              # Feature spec (+ Clarifications)
├── research.md          # Phase 0 — package + native-config + architecture decisions
├── data-model.md        # Phase 1 — entities / seams (no DB schema change)
├── quickstart.md        # Phase 1 — manual cold/warm + two-device verification
├── contracts/
│   └── deep-link-contracts.md   # DeepLinkService API + native config + additive core seams
├── checklists/
│   └── requirements.md  # Spec quality checklist (from /speckit.specify)
└── tasks.md             # Phase 2 (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_routes.dart                 # (existing) deepLinkScheme='safesend', receive/connect/home routes
│   ├── domain/pairing/
│   │   ├── connect_link.dart               # (existing, #007) build/parse safesend://connect — REUSED verbatim
│   │   └── connect_handoff.dart            # ConnectRequest (+ autoJoinCode), ConnectResult.method — additive
│   ├── services/deeplink/                  # NEW — pure-core deep-link delivery (no feature imports)
│   │   ├── deep_link_service.dart          #   interface: getInitialLink() + Stream<Uri> links
│   │   └── deep_link_service_impl.dart     #   @LazySingleton wrapping app_links AppLinks()
│   ├── services/pairing/                   # NEW — tiny cross-cutting registry
│   │   └── active_hosting_registry.dart    #   @LazySingleton holds current hosting code (self-invite, FR-015)
│   └── router/
│       ├── app_router.dart                 # (existing composition root) receive route extra → ReceiveEntryRequest
│       └── deep_link_coordinator.dart      # NEW — listens to DeepLinkService, parses, routes/guards (FR-010..016)
├── app/
│   └── app.dart                            # (existing) mount the deep-link coordinator under the router
├── bootstrap.dart                          # (existing) instantiate AppLinks early; kick cold-start handling
├── features/
│   ├── pairing/
│   │   ├── data/pairing_repository_impl.dart   # write active hosting code into ActiveHostingRegistry
│   │   └── presentation/connect/connect_page.dart  # implement "Chia sẻ link mời" action; receiver auto-join
│   ├── receive/presentation/pages/receive_entry_page.dart  # accept initialCode → ConnectRequest.autoJoinCode
│   ├── send/ ...                           # (unchanged — method already threads via ConnectResult→SendProgressArgs)
│   └── home/presentation/home_page.dart    # (existing Nhận / Quét QR actions → ReceiveEntryRequest)
ios/Runner/Info.plist                       # ADD CFBundleURLTypes (safesend scheme)
android/app/src/main/AndroidManifest.xml    # ADD VIEW intent-filter (safesend scheme) to MainActivity
lib/l10n/arb/app_*.arb                       # NEW invite/share + toast strings (VI primary + EN)
```

**Structure Decision**: Mobile feature-first (existing). The feature splits into a **core-pure delivery
seam** (`DeepLinkService` + `ActiveHostingRegistry`, depending only on `app_links` / core types) and a
**core-pure coordinator** (`deep_link_coordinator.dart` next to `app_router.dart`). The coordinator
navigates purely by `AppRoutes` constants + the core-typed `ReceiveEntryRequest` extra, so it imports
**no feature pages** — it does not need to, even though `app_router.dart` (the established composition
root) does. This keeps the entire deep-link path free of feature coupling (Constitution XI) while
routing the validated invite into the existing Receive flow via the established
`ConnectRequest`/`ConnectResult` core-typed handoff.

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.
