---
description: "Task list for #009 Nearby Radar"
---

# Tasks: Nearby Radar (Gần đây)

**Input**: Design documents from `/specs/009-nearby-radar/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/nearby-discovery-contracts.md](contracts/nearby-discovery-contracts.md), [quickstart.md](quickstart.md)

**Tests**: INCLUDED — Constitution XII mandates unit tests for logic, `bloc_test` for all Cubits, and widget tests for transfer-critical flows.

**Organization**: Tasks are grouped by user story. **US1** (receiver discovers + taps to connect) is the **P1 MVP**; **US2** (sender advertises + radar) is the **P2** counterpart; **US3** (Home entry + consent/privacy) is **P3** polish. Radar reuses the #003 rendezvous + #002 transport unchanged — discovery is a new core-pure seam (`nsd`), no engine/signaling/protocol/DB change.

---

## ⚠️ Deferred / device-only tasks (track here per Constitution XII)

- **T0DEV-1** Two-physical-device **same-Wi-Fi** smoke — advertise on device A's "Gần đây" tab, discover + tap on device B, accept → transfer + `pairingMethod=nearby`; plus stale-removal, two-senders, different-network empty-state, and the iOS Local Network / Android Nearby-devices permission prompts. Cannot run in CI; see [quickstart.md](quickstart.md) §"Manual two-device smoke".
- **First `pod install`** after T001 adds the `nsd` pod and churns `ios/Podfile.lock` — commit the lock; folds into the next on-device build.
- **bloc-lint CLI** still uninstalled (tracked since #001) — gate step skipped, not failed.

> Quality gate per task group: `dart format .` · `dart analyze lib test` (0 issues — `flutter analyze` crashes on this checkout, per #001) · `flutter test`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the single discovery dependency and natively register the mDNS service + permissions (Constitution XV — `nsd` 5.0.1 verified pub.dev 2026-06-26 in [research.md](research.md); latest matches Dart 3.11, no pinning).

- [X] T001 Add `nsd: ^5.0.1` to [pubspec.yaml](../../pubspec.yaml), run `flutter pub get`, commit `pubspec.lock`.
- [X] T002 [P] iOS: add `NSLocalNetworkUsageDescription` + `NSBonjourServices` (`_safesend._tcp`) per [contracts/nearby-discovery-contracts.md](contracts/nearby-discovery-contracts.md) §C6 to [ios/Runner/Info.plist](../../ios/Runner/Info.plist).
- [X] T003 [P] Android: add `ACCESS_NETWORK_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, and `NEARBY_WIFI_DEVICES` (`usesPermissionFlags="neverForLocation"`) per §C6 to [android/app/src/main/AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml) (confirm `INTERNET` already present; both flavors merge cleanly; do NOT add `ACCESS_FINE_LOCATION`).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The core-pure discovery + permission seams, the `NearbyDevice` model + TXT codec + constants, the in-process fake (for CI), ARB copy, route, and DI graph that every story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Create `nearby_constants.dart` (`kNearbyServiceType='_safesend._tcp'`, TXT keys `kNearbyTxtCodeKey='c'`/`kNearbyTxtVersionKey='v'`, `kNearbyTxtVersion='1'`, `kNearbyStaleTimeout`) in [lib/core/constants/nearby_constants.dart](../../lib/core/constants/nearby_constants.dart) per [data-model.md](data-model.md).
- [X] T005 [P] Create the `NearbyDevice` `@freezed` model (`id`, `displayName`, `code`, `lastSeen`; equality by `id`) + static TXT helpers `toTxt({code})` / `codeFromTxt(txt)` (validate `v==1` + `SignalingProtocol.isValidCode`, return null on mismatch) in [lib/core/domain/pairing/nearby_device.dart](../../lib/core/domain/pairing/nearby_device.dart).
- [X] T006 [P] Create the `NearbyDiscoveryService` interface (`Future<Result<void>> advertise({code, displayName})`, `Future<void> stopAdvertise()`, `Stream<List<NearbyDevice>> discover()`, `Future<void> stopDiscover()`) in [lib/core/services/nearby/nearby_discovery_service.dart](../../lib/core/services/nearby/nearby_discovery_service.dart) per [contracts/nearby-discovery-contracts.md](contracts/nearby-discovery-contracts.md) §C1.
- [X] T007 Implement `NearbyDiscoveryServiceImpl` (`@LazySingleton(as: NearbyDiscoveryService)`, wraps `nsd` `register`/`startDiscovery(autoResolve:true)`/`Service.txt`; maps to `NearbyDevice` via `codeFromTxt`; self-suppression by local instance id/code; stale removal on service-lost + `kNearbyStaleTimeout`; platform errors → `Result.failure(networkError)`; logs no code/name/address — FR-018) in [lib/core/services/nearby/nearby_discovery_service_impl.dart](../../lib/core/services/nearby/nearby_discovery_service_impl.dart).
- [X] T008 [P] Create the `NearbyPermissionService` interface + `NearbyPermissionStatus` enum and `@LazySingleton` impl over `permission_handler` (Android 13+ → `Permission.nearbyWifiDevices`; Android <13 + iOS → `granted`; `openSettings()`) in [lib/core/services/nearby/nearby_permission_service.dart](../../lib/core/services/nearby/nearby_permission_service.dart) per §C2.
- [X] T009 [P] Create the in-process **fake** `NearbyDiscoveryService` (advertise from one instance → surfaces in another's `discover()` stream; scriptable device list; honors self-suppression + stop) in [test/core/services/nearby/fake_nearby_discovery_service.dart](../../test/core/services/nearby/fake_nearby_discovery_service.dart) per [research.md](research.md) D8.
- [X] T010 [P] Add the additive `bool openNearby = false` field to the existing `ReceiveEntryRequest` (#008) in [lib/core/domain/pairing/receive_entry_request.dart](../../lib/core/domain/pairing/receive_entry_request.dart) — the nearby section lives on the existing `AppRoutes.receive` surface (ui-design §Screen 04), so **no new route** is added.
- [X] T011 [P] Add #009 ARB strings (VI primary + EN, each `@description`, key parity) to [lib/l10n/arb/app_vi.arb](../../lib/l10n/arb/app_vi.arb) + [lib/l10n/arb/app_en.arb](../../lib/l10n/arb/app_en.arb): `connectNearbyTab`, `nearbyDiscoverableTitle`, `nearbyPrivacyNote`, `nearbyEmptyTitle`, `nearbyEmptyHint`, `nearbyPermissionRationale`, `nearbyPermissionBlocked`, `nearbyOpenSettings`, `nearbyStaleToast`, `nearbySectionTitle`.
- [X] T012 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate freezed (`NearbyDevice`, cubit states added later) + injectable DI (new `@LazySingleton`s) + l10n; then `dart analyze lib test` = 0.

**Checkpoint**: Discovery + permission seams + model + fake + route + copy ready — stories can proceed.

---

## Phase 3: User Story 1 — Receiver discovers a nearby sender and taps to connect (Priority: P1) 🎯 MVP

**Goal**: A receiver opens the nearby surface, sees live-advertising senders as device rows, and a single tap auto-joins the advertised code straight into the existing accept/reject prompt — zero typing.

**Independent Test**: With the fake service advertising one instance (or a real sender on the same Wi-Fi), the receiver surface lists exactly that device; tapping it calls `joinWithCode` with the resolved code → the existing incoming-transfer prompt; accepting records `pairingMethod=nearby`.

### Tests for User Story 1 ⚠️

- [X] T013 [P] [US1] Unit test `NearbyDevice` TXT round-trip + rejects `v!=1` / invalid code in [test/core/domain/pairing/nearby_device_test.dart](../../test/core/domain/pairing/nearby_device_test.dart).
- [X] T014 [P] [US1] `bloc_test` `NearbyDiscoveryCubit`: permission granted → `loadedDiscovering`; list add/refresh/remove (stale) + self-suppression; `tap` forwards `device.code` to join; permission denied → `error(permissionDenied)` in [test/features/receive/nearby_discovery_cubit_test.dart](../../test/features/receive/nearby_discovery_cubit_test.dart).
- [X] T015 [P] [US1] Widget test the nearby section on the Receive entry surface: discovering list renders `DeviceRow`s; empty → same-Wi-Fi empty-state; `error(permissionDenied)` → blocked state; tap → join invoked in [test/features/receive/nearby_section_test.dart](../../test/features/receive/nearby_section_test.dart).
- [X] T016 [P] [US1] Unit test: nearby receive path maps to `pairingMethod=nearby` in the #006 record mapper in [test/features/receive/receive_nearby_method_test.dart](../../test/features/receive/receive_nearby_method_test.dart).

### Implementation for User Story 1

- [X] T017 [US1] Create `NearbyDiscoveryCubit` + `NearbyDiscoveryState` (4-state: `initial`/`loading`/`loadedDiscovering(devices)`/`error`; `@injectable`; subscribes to `discover()`, applies stale/self-suppression, `WidgetsBindingObserver` stop on background; `ensure()` permission first) in [lib/features/receive/presentation/nearby_discovery_cubit.dart](../../lib/features/receive/presentation/nearby_discovery_cubit.dart) per [data-model.md](data-model.md).
- [X] T018 [P] [US1] Create `NearbyDeviceRow` widget (reuses the core `DeviceRow`: gradient avatar + name + "Nhận" pill; tap callback) in [lib/features/receive/presentation/widgets/nearby_device_row.dart](../../lib/features/receive/presentation/widgets/nearby_device_row.dart).
- [X] T019 [US1] Integrate the nearby device-row section into the existing `ReceiveEntryPage` (ui-design §Screen 04 — alongside code entry / Quét QR; provide the `NearbyDiscoveryCubit` page-scoped; `ssRadar` browse animation w/ Reduce-Motion fallback FR-019; list / empty-state FR-016 / permission-blocked FR-012 with Open-Settings; scroll-to/emphasize when `openNearby`; `BlocListener` → on tap `joinWithCode(device.code)` then `takeTransport()` → existing `IncomingTransferDialog`; stale/unreachable join → `nearbyStaleToast` + entry removed FR-017) in [lib/features/receive/presentation/pages/receive_entry_page.dart](../../lib/features/receive/presentation/pages/receive_entry_page.dart).
- [X] T020 [US1] Thread `pairingMethod=nearby` on the nearby receive join into the existing `ConnectResult.method` → receive transfer cubit → #006 mapper (additive; mirrors #007/#008) in [lib/features/receive/presentation/nearby_discovery_cubit.dart](../../lib/features/receive/presentation/nearby_discovery_cubit.dart) + the receive transfer wiring.
- [X] T021 [US1] `dart run build_runner build --delete-conflicting-outputs` (cubit freezed state), `dart format .`, `dart analyze lib test` = 0, `flutter test` green for US1.

**Checkpoint**: Receiver can discover + tap → prompt → transfer recorded as nearby, validated via the fake service.

---

## Phase 4: User Story 2 — Sender becomes discoverable and sees connection happen (Priority: P2)

**Goal**: The sender's Connect-hub "Gần đây" tab advertises the **live** #003 hosting code over mDNS while shown (foreground), shows a radar "discoverable" state + the live code/countdown, and stops on leave/background/connect.

**Independent Test**: Open the "Gần đây" tab with a live hosting session → `advertise(liveCode)` called once; switching tabs does NOT regenerate the code (FR-009); leaving/backgrounding → `stopAdvertise()`; a fake browser sees then loses the advertisement.

### Tests for User Story 2 ⚠️

- [X] T022 [P] [US2] `bloc_test` `NearbyAdvertiseCubit`: `start(liveCode)` (after permission) → `loadedAdvertising(code)` calling `advertise` once; `stop()` → `stopAdvertise`; permission denied → `error(permissionDenied)` in [test/features/pairing/nearby_advertise_cubit_test.dart](../../test/features/pairing/nearby_advertise_cubit_test.dart).
- [X] T023 [P] [US2] Widget test: the "Gần đây" tab renders the radar discoverable state + live code/countdown + privacy note; sender-only (receiver role hides it); switching to/from the tab triggers start/stop without code regeneration in [test/features/pairing/nearby_advertise_panel_test.dart](../../test/features/pairing/nearby_advertise_panel_test.dart).
- [X] T024 [P] [US2] Unit test: nearby send path maps to `pairingMethod=nearby` (last-action-wins) in the #006 record mapper in [test/features/send/send_nearby_method_test.dart](../../test/features/send/send_nearby_method_test.dart).

### Implementation for User Story 2

- [X] T025 [US2] Create `NearbyAdvertiseCubit` + `NearbyAdvertiseState` (4-state: `initial`/`loading`/`loadedAdvertising(code)`/`error`; `@injectable`; `start(liveHostingCode)` after `ensure()`, `stop()`; reuses the live code — never generates; `WidgetsBindingObserver` stop on background) in [lib/features/pairing/presentation/connect/nearby_advertise_cubit.dart](../../lib/features/pairing/presentation/connect/nearby_advertise_cubit.dart) per [data-model.md](data-model.md).
- [X] T026 [P] [US2] Create `NearbyAdvertisePanel` widget (`ssRadar` discoverable animation + Reduce-Motion fallback; live 6-digit code (mono) + TTL countdown; `nearbyPrivacyNote`) in [lib/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart](../../lib/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart).
- [X] T027 [US2] Wire the "Gần đây" segment into the Connect hub `SegmentedTabs` (sender role only — receiver hides it, like QR §#007); on tab-select start advertising the live hosting code, on tab-deselect/leave stop; tab-switch does not regenerate the code (FR-009) in [lib/features/pairing/presentation/connect/connect_page.dart](../../lib/features/pairing/presentation/connect/connect_page.dart).
- [X] T028 [US2] Thread `pairingMethod=nearby` (sender last-action-wins) into the existing `ConnectResult.method` → send transfer cubit → #006 mapper in the Connect/send wiring touched by T027.
- [X] T029 [US2] `dart run build_runner build --delete-conflicting-outputs`, `dart format .`, `dart analyze lib test` = 0, `flutter test` green for US1+US2.

**Checkpoint**: Sender advertises the live code from the "Gần đây" tab and a browser (fake/real) sees + loses it correctly; both stories work together.

---

## Phase 5: User Story 3 — Nearby entry points and discoverability/consent (Priority: P3)

**Goal**: A Home "Thiết bị gần" quick action reaches the receiver nearby surface; the permission rationale is shown before any broadcast/browse; the privacy note about broadcasting the device name is surfaced.

**Independent Test**: Tapping Home "Thiết bị gần" → receive route with `ReceiveEntryRequest(openNearby: true)` (nearby section emphasized); first use shows the rationale before discovery starts; denied → recoverable blocked state; the discoverable/browse surfaces show the privacy note.

### Tests for User Story 3 ⚠️

- [X] T030 [P] [US3] Widget test: Home "Thiết bị gần" quick action navigates to the receive route with `ReceiveEntryRequest(openNearby: true)` in [test/features/home/home_nearby_action_test.dart](../../test/features/home/home_nearby_action_test.dart).
- [X] T031 [P] [US3] Widget/bloc test: permission rationale is shown before discovery/advertise starts; deny → blocked state with Open-Settings; iOS path proceeds (OS prompt) in [test/features/receive/nearby_permission_flow_test.dart](../../test/features/receive/nearby_permission_flow_test.dart).

### Implementation for User Story 3

- [X] T032 [US3] Wire the Home "Thiết bị gần" quick action → `context.push(AppRoutes.receive, extra: ReceiveEntryRequest(openNearby: true))` in [lib/features/home/presentation/home_page.dart](../../lib/features/home/presentation/home_page.dart).
- [X] T033 [US3] Add the permission-rationale presentation (before broadcast/browse, FR-011) + ensure the privacy note (`nearbyPrivacyNote`, FR-013) renders on both the advertise panel and the browse surface, reusing the cubit `ensure()` flow in [lib/features/receive/presentation/pages/receive_entry_page.dart](../../lib/features/receive/presentation/pages/receive_entry_page.dart) + [lib/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart](../../lib/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart).
- [X] T034 [US3] `dart format .`, `dart analyze lib test` = 0, `flutter test` green for all stories.

**Checkpoint**: All three stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T035 [P] Verify FR-018 log hygiene across the discovery service + cubits (no code/name/address in `AppLogger`) and confirm SC-004 (no edits to signaling/transport/protocol/history-schema modules) via a diff review.
- [X] T036 [P] Final gate: `dart format .` · `dart analyze lib test` (0) · `flutter test` (all pass, target ~223+ with the ~11 new #009 tests) and update the test count in [changelog.md](../../.claude/claude-app/changelog.md) on merge.
- [X] T037 Run [quickstart.md](quickstart.md) automated gate; mark **T0DEV-1** (two-device same-Wi-Fi smoke) tracked as deferred and confirm the `pod install`/`Podfile.lock` note.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no deps — start immediately (T001 before T012 codegen).
- **Foundational (Phase 2)**: depends on Setup — **BLOCKS all stories**. T012 (codegen) depends on T004–T011.
- **US1 (Phase 3, P1)**: depends on Foundational. The MVP — stop & validate here.
- **US2 (Phase 4, P2)**: depends on Foundational; independent of US1 (uses the same core seam). Real two-device test pairs US1+US2.
- **US3 (Phase 5, P3)**: depends on Foundational; light wiring over US1's surface.
- **Polish (Phase 6)**: after the desired stories.

### Within Each User Story

- Tests (T013–T016 / T022–T024 / T030–T031) written first and FAIL before implementation.
- Models/constants → service → cubit → page; method-threading after the page wiring.

### Parallel Opportunities

- Setup: T002, T003 in parallel (after T001).
- Foundational: T004, T005, T006, T008, T009, T010, T011 in parallel; T007 after T006; T012 last.
- US1 tests T013–T016 in parallel; US2 tests T022–T024 in parallel; US3 tests T030–T031 in parallel.
- US1 and US2 can be built in parallel by two developers once Foundational is done.

---

## Parallel Example: Foundational

```bash
# After T001 (nsd added) + native config T002/T003:
Task: "T004 nearby_constants.dart"
Task: "T005 NearbyDevice model + TXT codec"
Task: "T006 NearbyDiscoveryService interface"
Task: "T008 NearbyPermissionService + impl"
Task: "T009 fake NearbyDiscoveryService (test)"
Task: "T010 ReceiveEntryRequest.openNearby (reuse receive route, no new route)"
Task: "T011 ARB strings (vi + en)"
# Then: T007 (ConnectResult threading prep) → T012 (build_runner + analyze)
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 Setup → Phase 2 Foundational → Phase 3 US1.
2. **STOP & VALIDATE**: receiver discovers (fake/real) + taps → prompt → `pairingMethod=nearby`.

### Incremental Delivery

1. Setup + Foundational → seam ready.
2. US1 (receiver discover+tap) → MVP.
3. US2 (sender advertise) → full two-device loop on same Wi-Fi.
4. US3 (Home entry + consent/privacy) → polish.
5. Phase 6 gate + deferred two-device smoke.

---

## Notes

- [P] = different files, no dependency on an incomplete task.
- Discovery is a new core-pure seam (`nsd`) — **no** engine/signaling/transport/protocol/DB change (SC-004).
- `pairingMethod=nearby` reuses the reserved #006 enum value — **no drift migration**.
- iOS Local Network permission has no pre-request/query API — handled via rationale + OS prompt + empty-state (research D3); only Android exposes a runtime gate (`nearbyWifiDevices`).
- Commit after each task or logical group; run the quality gate per group.
