# Implementation Plan: Nearby Radar (Gần đây)

**Branch**: `009-nearby-radar` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/009-nearby-radar/spec.md`

## Summary

Add the fourth and final connection method — **nearby radar discovery on the same local Wi-Fi/LAN**.
The sender (who already holds a live #003 hosting code) **advertises** an mDNS service whose TXT record
carries that 6-digit code; the receiver **browses + resolves** nearby Safe Send advertisements, sees
each as a tappable device row, and a single tap **auto-joins** the advertised code straight into the
existing #005 accept/reject prompt. The feature **reuses the #003 6-digit rendezvous and #002 transport
unchanged** — mDNS is only a new way to carry the rendezvous identifier (exactly like QR #007 and share
link #008). It adds one new package (`nsd`), a **core-pure discovery service seam**, two screen-scoped
4-state cubits (advertise / browse), the Connect-hub "Gần đây" tab + Receive device-rows surface, and
`pairingMethod = nearby` threading. No engine/signaling/transport/protocol/DB-schema changes.

## Technical Context

**Language/Version**: Dart 3.11.x (`environment: sdk: ^3.11.0`) / Flutter ~3.41 (project floor) — same toolchain as #001–#008
**Primary Dependencies**: `nsd` **5.0.1** (NEW — mDNS register + discover + resolve + TXT, both platforms); `permission_handler` 12.0.3 (existing #007 — Android `nearbyWifiDevices` runtime permission); reuses #003 `PairingRepository`/`SignalingClient`/`joinWithCode`/`takeTransport` + `SignalingProtocol.isValidCode` (existing)
**Storage**: None new. History reuses the existing `transfer_records` schema; `PairingMethod.nearby` already reserved (#006) — **no migration**
**Testing**: `flutter_test` + `bloc_test` + `mocktail` (unit/bloc/widget); an in-process fake `NearbyDiscoveryService` exercises advertise↔browse↔tap→join without real mDNS or a second device; two-physical-device same-Wi-Fi smoke deferred (Constitution XII)
**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+ — `nsd` 5.0.1 floor (iOS 13, Android API 21) clears the project floor
**Project Type**: Mobile (Flutter, iOS + Android), Clean Architecture + feature-first
**Performance Goals**: Sender appears on a browsing receiver within 5 s (SC-001); stops appearing within 10 s of advertising ending (SC-003); tap → accept/reject prompt effortless (SC-006)
**Constraints**: Same-network (Wi-Fi/LAN) **only** — no BLE/Wi-Fi-Aware (Clarification); TXT payload carries only the already-short-lived code + version (no bytes/identity — Constitution I/II); advertising tied to foreground + "Gần đây" tab presence (FR-005/014); logs carry no device name/address/code (FR-018); discovered identifiers validated via `SignalingProtocol.isValidCode` before join (Constitution X)
**Scale/Scope**: One new core discovery service seam + one core `NearbyDevice` model + service-type constant + 2 screen-scoped cubits + Connect "Gần đây" tab + Receive nearby browse surface + Home quick-action wiring + `pairingMethod=nearby` threading + native config (iOS Info.plist 2 keys, Android manifest 4 permissions). 2 designed surfaces touched (Connect tab, Receive device-rows) + Home action.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Privacy-First P2P | ✅ | mDNS TXT carries only the version + the already short-lived/single-use #003 code (Principle I bullet 4 preserved). No bytes ever traverse mDNS. Discovered codes validated (`isValidCode`) before join. Advertising is foreground + tab-scoped (FR-005), reducing broadcast exposure; privacy note surfaced (FR-013). |
| II. Direct Transfer & Data Min. | ✅ | No change to transport/integrity/streamed-I/O. Discovery state is ephemeral runtime only — nothing persisted (Clarification: no known-device list). |
| III. BLoC 4-state | ✅ | New `NearbyAdvertiseCubit` + `NearbyDiscoveryCubit` are 4-state freezed (`loadedDiscovering`/`loadedAdvertising` variants prefix the base). Discovery is a service stream → cubit (Principle VIII stream-derived). Side effects (toast, navigate to prompt) via `BlocListener`. |
| IV. Code Quality & Dart Safety | ✅ | `very_good_analysis` 0; explicit types; immutable freezed models/states. |
| V. Result\<T\> | ✅ | Discovery service start/advertise return `Result<void>`; permission + mDNS platform errors mapped to `AppFailure` (`permissionDenied`, `networkError`). Tap-to-join reuses existing `joinWithCode` Result path. No try/catch in cubits. |
| VI. Design System & Theming | ✅ | "Gần đây" tab reuses `SegmentedTabs`; device rows reuse the designed `DeviceRow` (avatar gradient + name + "Nhận" pill); radar uses the `ssRadar` token animation; numeric code stays mono. No hardcoded hex. |
| VII. Cross-Platform Native | ✅ | iOS Local Network (`NSLocalNetworkUsageDescription` + `NSBonjourServices`) + Android `NEARBY_WIFI_DEVICES`(33+)/multicast permissions, both flavors; contextual request with rationale + graceful denial (FR-011/012); Reduce-Motion degrades radar (FR-019); haptic on connect reuses existing. Discovery is the explicitly-scoped radar integration (Principle VII bullet 3). |
| VIII. Transport & Signaling | ✅ | Radar is a 4th *pairing front door* onto the **same** rendezvous + signaling + transport; mDNS only obtains the identifier. No new signaling/transport path, no protocol frames touched. Service-type + TXT-key constants centralized (Principle VIII bullet 6). |
| IX. Transfer Reliability | ✅ | Stale/expired/unreachable tap fails gracefully + self-heals the list (FR-017); no finalize/integrity change. Existing room-full/busy failures reused. |
| X. go_router Navigation | ✅ | Reuses the existing `AppRoutes.receive` route (no new route) — the nearby device-row section lives on the Receive entry surface (ui-design §Screen 04); Home "Thiết bị gần" navigates there via `context.push` + the additive `ReceiveEntryRequest.openNearby` extra. Discovered code validated (`isValidCode`) before the join (Principle X bullet 5). |
| XI. Feature-First Modularity | ✅ | `NearbyDiscoveryService` (+ `NearbyDevice`, `NearbyPermissionService`) are **core-pure** (`core/services/nearby/`, `core/domain/pairing/`) wrapping only `nsd`/`permission_handler` + core types — import no features. Sender (pairing feature) and receiver (receive feature) consume via DI; no feature↔feature import. Tap-to-join reuses the existing core-typed `joinWithCode`/`takeTransport` handoff. |
| XII. Testing Discipline | ✅ | Unit (NearbyDevice TXT codec, service-type constant, self-suppression, isValidCode gate), bloc (advertise lifecycle start/stop on tab/background; discovery list add/remove/stale; tap→join), widget ("Gần đây" tab radar/empty/permission-blocked, DeviceRow tap, Home action). In-process fake service replaces real mDNS in CI. Two-device same-Wi-Fi smoke tracked + deferred. |
| XIII. Simplicity & YAGNI | ✅ | One dep only (`nsd`). `connectivity_plus`/`network_info_plus`/`device_info_plus` evaluated and **rejected** (empty-state always shows the same-Wi-Fi hint; display name uses a generated default until #010). No saved-peer/known-device persistence (deferred v1.1). No BLE. |
| XIV. i18n by Default | ✅ | New ARB keys (tab label, discoverable/radar copy, privacy note, empty-state hint, permission rationale + blocked, stale/unreachable toast) VI primary + EN with `@description`. |
| XV. Dependency Hygiene | ✅ | `nsd` verified on pub.dev 2026-06-26: latest **5.0.1** targets `sdk ^3.11.0` / `flutter >=3.41.0` — **exactly the project floor** (no pinning needed, unlike `app_links`), supports advertise+browse+resolve+TXT, iOS 13 / Android API 21, native-backed (NsdManager / NetService, no third-party native libs). Caret `^5.0.1`. Native config verified at plan time (iOS Local Network keys; Android `NEARBY_WIFI_DEVICES`+multicast; MulticastLock handled by the plugin). See [research.md](research.md). |

**Gate result: PASS** — no violations, no Complexity Tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/009-nearby-radar/
├── plan.md              # This file
├── spec.md              # Feature spec (+ Clarifications)
├── research.md          # Phase 0 — package + native-config + architecture decisions
├── data-model.md        # Phase 1 — entities / seams / state shapes (no DB schema change)
├── quickstart.md        # Phase 1 — manual same-Wi-Fi two-device + permission verification
├── contracts/
│   └── nearby-discovery-contracts.md   # NearbyDiscoveryService/Permission API + TXT format + native config + additive core seams
├── checklists/
│   └── requirements.md  # Spec quality checklist (from /speckit.specify)
└── tasks.md             # Phase 2 (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── nearby_constants.dart            # NEW — '_safesend._tcp' service type + TXT keys ('c'=code,'v'=version)
│   ├── domain/pairing/
│   │   ├── nearby_device.dart               # NEW — NearbyDevice model (id, displayName, code, lastSeen) + TXT build/parse
│   │   ├── receive_entry_request.dart       # (existing #008) ADD additive `bool openNearby = false`
│   │   └── connect_handoff.dart             # (existing) ConnectResult.method — add PairingMethod.nearby threading
│   ├── services/nearby/                     # NEW — pure-core discovery seam (imports nsd + core types only)
│   │   ├── nearby_discovery_service.dart    #   interface: advertise()/stopAdvertise(); Stream<List<NearbyDevice>> discover()/stopDiscover()
│   │   ├── nearby_discovery_service_impl.dart  # @LazySingleton wrapping nsd register/startDiscovery/resolve + self-suppress
│   │   ├── nearby_permission_service.dart   #   interface: ensureNearbyPermission() (Android nearbyWifiDevices; iOS no-op→granted)
│   │   └── nearby_permission_service_impl.dart  # @LazySingleton over permission_handler
│   └── di/                                   # (existing) injectable picks up @LazySingleton impls
├── features/
│   ├── pairing/presentation/connect/
│   │   ├── connect_page.dart                # mount the "Gần đây" tab (sender role only, like QR)
│   │   ├── nearby_advertise_cubit.dart      # NEW — 4-state; advertise(live code) on tab-enter, stop on leave/background
│   │   └── widgets/nearby_advertise_panel.dart  # NEW — ssRadar discoverable state + live code/countdown + privacy note
│   ├── receive/presentation/
│   │   ├── pages/receive_entry_page.dart    # (existing #005/#008) ADD the nearby device-row section (radar + list / empty / blocked); show/scroll-to when openNearby
│   │   ├── nearby_discovery_cubit.dart      # NEW — 4-state; browse stream → device list; tap → emit code to join
│   │   └── widgets/nearby_device_row.dart   # NEW — reuses core DeviceRow; tap → joinWithCode → existing prompt
│   └── home/presentation/home_page.dart     # wire "Thiết bị gần" quick action → receive route + ReceiveEntryRequest(openNearby:true)
├── core/router/app_router.dart              # (existing) receive route extra already ReceiveEntryRequest — no new route
ios/Runner/Info.plist                        # ADD NSLocalNetworkUsageDescription + NSBonjourServices(_safesend._tcp)
android/app/src/main/AndroidManifest.xml     # ADD INTERNET (exists) + CHANGE_WIFI_MULTICAST_STATE + ACCESS_NETWORK_STATE + NEARBY_WIFI_DEVICES(neverForLocation)
lib/l10n/arb/app_*.arb                        # NEW nearby tab/radar/privacy/empty/permission/stale strings (VI primary + EN)
```

**Structure Decision**: Mobile feature-first (existing). Discovery is a **core-pure service seam**
(`NearbyDiscoveryService` + `NearbyPermissionService` + `NearbyDevice`), depending only on `nsd` /
`permission_handler` / core types — it imports no features, mirroring the #007 `CameraPermissionService`
and #008 `DeepLinkService` seams. The **sender** half lives in the existing `features/pairing` Connect
hub (new "Gần đây" tab + advertise cubit) and the **receiver** half is the **nearby device-row section
embedded in the existing Receive entry surface** (ui-design §Screen 04 — alongside code entry / Quét QR)
+ a discovery cubit, reached from Home "Thiết bị gần" via the additive `ReceiveEntryRequest.openNearby`
extra (no new route). Each side consumes the core seam via DI and reuses the existing
`joinWithCode`/`takeTransport` rendezvous handoff — so the two features never import each other
(Constitution XI). The radar only transports a #003 code; signaling/transport are untouched.

## Complexity Tracking

> No Constitution Check violations — section intentionally empty.
