# Phase 0 Research: Nearby Radar (Gần đây)

**Feature**: #009 | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

All package data verified against pub.dev / official docs on **2026-06-26** (Constitution XV). The clarified
scope is **same local network (Wi-Fi/LAN) only — no BLE/Wi-Fi-Aware**, sender advertises / receiver browses,
and no known-device persistence (see spec Clarifications).

---

## D1. Discovery mechanism & package

**Decision**: Use **`nsd: ^5.0.1`** (Network Service Discovery) as the single discovery dependency —
mDNS/Bonjour service **register (advertise)** + **discovery (browse)** + **resolve** + **TXT records** on
both iOS and Android.

**Rationale**:
- `nsd` 5.0.1 (published 2026-04-04) declares `sdk: ^3.11.0`, `flutter: >=3.41.0` — **exactly the project
  floor**. Unlike `app_links` (whose 7.x needs Dart ^3.12), the **latest** `nsd` is compatible; no version
  pinning required.
- Supports all four capabilities we need through one cohesive `Future`-based API:
  - `register(Service)` → advertise (sender).
  - `startDiscovery(serviceType, autoResolve: true)` → browse + auto-resolve (receiver).
  - `Service.txt` is typed `Map<String, Uint8List?>?` ("DNS TXT records") → the 6-digit code rides in the
    TXT payload natively on both platforms.
- Native-backed (Android `NsdManager`, iOS `NetService`/Bonjour) — **no third-party native libraries**, so
  no surprise transitive pods. Platform mins iOS 13 / Android API 21 clear our iOS 13 / API 26 floor.
- Actively maintained; the plugin **acquires the Android `MulticastLock` internally** (we only declare the
  permission).

**Alternatives considered**:
- **`bonsoir` 7.1.4** — also advertise+browse+resolve+TXT, Dart `>=3.8.0` (compatible). Rejected as
  second choice only: federated multi-package, event-stream wiring is heavier than `nsd`'s flat API, and
  its Flutter floor (`>=3.0.0`) is looser than `nsd`'s exact `>=3.41.0` match. Kept as a drop-in fallback
  if `nsd` ever blocks.
- **`multicast_dns` 0.3.3+1** (Flutter team) — **browse/query ONLY, no advertise API**. Cannot satisfy the
  sender side; rejected.
- **`flutter_nsd`** — discovery-only; rejected.
- **BLE (`flutter_blue_plus`) / Wi-Fi Aware** — out of scope per Clarification (off-Wi-Fi deferred to v1.1).

**Sources**: pub.dev `nsd` (5.0.1), `bonsoir` (7.1.4), `multicast_dns` (0.3.3+1); `nsd` dartdoc `Service`/library.

---

## D2. Service type & TXT payload format

**Decision**:
- Service type: **`_safesend._tcp`** (constant in `core/constants/nearby_constants.dart`).
- TXT keys (centralized constants, Principle VIII bullet 6):
  - `c` → the 6-digit rendezvous code (the #003 identifier).
  - `v` → payload version `1` (forward-compat, mirrors `ConnectLink` `v=1`).
- The advertised **service instance name** is the device display name (D5); a per-advertisement random
  instance suffix guarantees uniqueness when names collide (edge case: two devices, same name).

**Rationale**: Keeping the code in a TXT record (not the instance name) keeps the human-readable instance
name = device name, and lets the receiver `resolve` to read the code. Reusing `v=1` aligns with the
existing `ConnectLink`/protocol versioning. The code is validated with the existing
`SignalingProtocol.isValidCode` before any join (Constitution X / I).

**Privacy note**: the TXT carries only `c`+`v`; the code is already short-lived & single-use (#003), and
advertising only runs while the sender is foreground on the "Gần đây" tab (FR-005). No bytes, paths, or
identities are ever broadcast (Constitution I/II). Logs never include the code or device name (FR-018).

---

## D3. iOS native configuration

**Decision** — add to `ios/Runner/Info.plist` (single plist, both flavors):

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>{localized rationale: tìm thiết bị gần trên cùng Wi-Fi để chia sẻ tệp}</string>
<key>NSBonjourServices</key>
<array>
  <string>_safesend._tcp</string>
</array>
```

**Rationale / behavior**:
- iOS 14+ shows the **Local Network permission prompt automatically** the first time the app advertises or
  browses mDNS. There is **no public API to pre-request or query** this status, and **`permission_handler`
  does not cover iOS Local Network** (no `Permission.localNetwork`).
- Therefore the iOS flow: show our **rationale UI first** (FR-011), then start discovery/advertise (which
  triggers the OS prompt). If the user denies, mDNS simply yields nothing → we show the empty-state hint
  (FR-016). We cannot distinguish "denied" from "nobody nearby" on iOS — acceptable; the hint copy covers
  both ("đảm bảo cùng Wi-Fi / cho phép mạng cục bộ trong Cài đặt").
- `NSBonjourServices` MUST list the exact service type we register **and** browse, or iOS blocks it.
- Test on a **real device** — the iOS Simulator mishandles the Local Network prompt.
- First `pod install` will add the `nsd` pod and churn `ios/Podfile.lock` — deferred to the device build
  (consistent with prior native-plugin specs).

---

## D4. Android native configuration & permission

**Decision** — `android/app/src/main/AndroidManifest.xml` (both flavors):

```xml
<uses-permission android:name="android.permission.INTERNET" />               <!-- already present -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission
    android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
```

**Rationale / behavior**:
- `INTERNET` + `CHANGE_WIFI_MULTICAST_STATE` are required by `NsdManager`/mDNS (the `nsd` README lists
  them); the plugin acquires the `MulticastLock` itself.
- On **API 33+**, framework local-network classes (incl. `NsdManager`) require **`NEARBY_WIFI_DEVICES`**, a
  **runtime** permission. Declared with `usesPermissionFlags="neverForLocation"` so we do **not** pull in
  location. Requested at runtime via the existing **`permission_handler` (`Permission.nearbyWifiDevices`)**
  before advertise/browse on Android 13+ — this is the seam that lets us show a distinct
  **permission-blocked** state (FR-012) vs the empty state (FR-016).
- **`ACCESS_FINE_LOCATION` is NOT required** for NSD/mDNS — do not add it.
- On API 26–32 the permission is effectively granted (no runtime gate); `NearbyPermissionService` returns
  granted there.

---

## D5. Device display name source (until Settings #010)

**Decision**: For #009 the broadcast display name uses a **generated default** —
`"{localized base} {short stable suffix}"` (e.g. `Safe Send · 7F3A`) where the suffix derives from the
per-advertisement id — with the avatar derived from the name's leading characters. **No `device_info_plus`.**

**Rationale**:
- Modern iOS restricts the real device name (returns a generic "iPhone" without a special entitlement), so
  `device_info_plus` would not give "Minh's iPhone" anyway, while adding a dep + transitive native code.
- The **editable device profile name** is owned by Spec #010 (per spec Assumptions / Dependencies). When
  #010 lands, the user-set profile name replaces the generated default with **no schema/seam change**
  (the display name is just sourced from the profile).
- The generated suffix + the stable per-advertisement id keep two same-named devices distinguishable
  (edge case), satisfying FR-002's "human-recognizable" intent without a new dependency (Constitution
  XIII YAGNI).

**Alternatives rejected**: `device_info_plus` (iOS name restricted, extra dep), `network_info_plus`
(needs location to read SSID), `connectivity_plus` (the empty-state always shows the same-Wi-Fi hint, so
Wi-Fi detection adds no required value — rejected for YAGNI; reconsider in #011 if the hint needs to
distinguish "no Wi-Fi" from "nobody nearby").

---

## D6. Advertise / browse lifecycle

**Decision**:
- **Sender** advertises only while the Connect hub "Gần đây" tab is selected **and** the app is foreground,
  reusing the **live #003 hosting code** (no new code/socket — FR-009). Switching away from the tab,
  leaving the Connect flow, or backgrounding the app → `stopAdvertise()` promptly (FR-005). When a receiver
  connects (room handshake), advertising stops and the sender transitions to the shared progress screen.
- **Receiver** browses only while on the nearby browse surface + foreground; `stopDiscover()` on leave/
  background. The discovery stream emits a self-updating `List<NearbyDevice>` — entries appear on resolve,
  refresh on re-seen, and are removed on the service-lost callback or a freshness timeout (SC-003), with
  **self-suppression** (a device never lists its own advertisement — FR-004) by matching the local
  advertisement instance id / code.
- Lifecycle is driven by Flutter `WidgetsBindingObserver` (app lifecycle) + route/tab visibility inside the
  two screen-scoped cubits.

**Rationale**: Matches the clarified "tab presence = discoverability control" (FR-014) and keeps broadcast
exposure minimal (Principle I). No background/persistent advertising (deferred to #010).

---

## D7. Pairing handoff & history method threading

**Decision**: Tapping a discovered device calls the **existing** `PairingRepository.joinWithCode(code)` with
the resolved TXT code, then `takeTransport()` — identical to the 6-digit/QR/share-link receiver path — and
lands on the existing #005 `IncomingTransferDialog`. The transfer records `pairingMethod = nearby`
(enum value already reserved in #006) by threading the method through `ConnectResult.method` →
the receive/send transfer cubits → the existing #006 mappers (the same pattern #007/#008 used; the only
edits to merged code are additive method-threading + the Home action + native config).

**Rationale**: Full reuse of the #003 rendezvous + #002 transport (FR-006/007); zero protocol, signaling,
transport, or DB-schema change (SC-004). `nearby` is an existing enum value → **no migration**.

---

## D8. Testing strategy (no real mDNS / second device in CI)

**Decision**: Define `NearbyDiscoveryService` as an interface with an in-process **fake** that lets a test
"advertise" from one fake instance and "discover" it from another (or feed a scripted device list), so the
advertise → browse → tap → `joinWithCode` path is exercised in CI without real mDNS or a second device.
The real `nsd`-backed impl is validated only by the **deferred two-device same-Wi-Fi smoke** (Constitution
XII), tracked in `tasks.md`.

**Coverage**: NearbyDevice TXT build/parse + `isValidCode` gate (unit); self-suppression + stale-removal
(unit/bloc); advertise start-on-tab / stop-on-leave/background (bloc); discovery list add/refresh/remove +
tap→emit-code (bloc); permission-granted/denied/blocked branches (bloc); "Gần đây" tab radar/empty/blocked
render + DeviceRow tap + Home action (widget); receive nearby→`pairingMethod=nearby` mapper (unit).

---

## Summary of decisions

| # | Decision |
|---|---|
| D1 | `nsd: ^5.0.1` — single discovery dep; advertise+browse+resolve+TXT; latest matches Dart 3.11 exactly |
| D2 | Service `_safesend._tcp`; TXT `c`=code, `v`=1; instance name = display name (+random suffix) |
| D3 | iOS: `NSLocalNetworkUsageDescription` + `NSBonjourServices`; OS auto-prompt, no pre-request, not in permission_handler |
| D4 | Android: `NEARBY_WIFI_DEVICES`(neverForLocation, runtime via permission_handler) + multicast/network-state; no FINE_LOCATION; MulticastLock handled by nsd |
| D5 | Display name = generated default (+suffix) until #010; no `device_info_plus` |
| D6 | Advertise/browse tied to foreground + tab/surface presence; self-suppression; freshness timeout |
| D7 | Tap → existing `joinWithCode`/`takeTransport`; `pairingMethod=nearby` (reserved enum, no migration) |
| D8 | In-process fake discovery service for CI; two-device same-Wi-Fi smoke deferred |

**All NEEDS CLARIFICATION resolved. Ready for Phase 1.**
