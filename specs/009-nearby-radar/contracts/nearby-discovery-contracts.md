# Phase 1 Contracts: Nearby Radar (Gần đây)

**Feature**: #009 | **Date**: 2026-06-26 | **Plan**: [plan.md](plan.md)

Internal contracts (this is a mobile app — "contracts" = the core service seams + native config the
feature exposes/consumes). All seams are **core-pure** (import only `nsd` / `permission_handler` / core
types — no features), consumed by the pairing (sender) and receive (receiver) features via DI.

---

## C1. `NearbyDiscoveryService` (core/services/nearby/nearby_discovery_service.dart)

```dart
/// Pure-core mDNS discovery seam. Wraps `nsd`; imports no features.
abstract interface class NearbyDiscoveryService {
  /// Advertise this device on the local network carrying [code] in the TXT record.
  /// [displayName] becomes the service instance name (generated default until #010).
  /// Returns Result.failure(networkError) if mDNS registration fails.
  Future<Result<void>> advertise({
    required String code,
    required String displayName,
  });

  /// Stop advertising (idempotent; safe if not advertising).
  Future<void> stopAdvertise();

  /// Browse + resolve nearby Safe Send advertisements as a live, self-updating list.
  /// The stream applies self-suppression (never lists our own advertisement) and
  /// stale removal (entries un-refreshed past [kNearbyStaleTimeout] drop off).
  /// Emits [] when nobody is nearby.
  Stream<List<NearbyDevice>> discover();

  /// Stop browsing (idempotent). Closing the consuming cubit calls this.
  Future<void> stopDiscover();
}
```

- **Impl** `@LazySingleton(as: NearbyDiscoveryService)` `NearbyDiscoveryServiceImpl` wrapping `nsd`:
  `register(Service(type: kNearbyServiceType, name: displayName, txt: {...}))` for advertise;
  `startDiscovery(kNearbyServiceType, autoResolve: true)` for browse; maps `Service.txt` → `NearbyDevice`
  via `NearbyDevice.codeFromTxt` (skipping entries that fail `v==1` / `isValidCode`).
- **Self-suppression**: track the locally-registered service id/code; filter it out of the discovery list.
- **Errors**: platform/registration failures → `Result.failure(AppFailure.networkError)`; never throws into
  cubits (Constitution V). Logs carry no code/name/address (FR-018).

## C2. `NearbyPermissionService` (core/services/nearby/nearby_permission_service.dart)

```dart
/// Pure-core nearby/local-network permission seam.
abstract interface class NearbyPermissionService {
  /// Ensure the platform permission needed to advertise/browse on the LAN.
  /// Android 13+ : requests `Permission.nearbyWifiDevices` via permission_handler.
  /// Android <13 : effectively granted (no runtime gate).
  /// iOS        : returns granted — the OS Local Network prompt fires automatically
  ///              on first mDNS use (no pre-request/query API exists).
  Future<NearbyPermissionStatus> ensure();

  /// Open the OS app settings (for the permanently-denied recovery path).
  Future<void> openSettings();
}

enum NearbyPermissionStatus { granted, denied, permanentlyDenied }
```

- **Impl** `@LazySingleton(as: NearbyPermissionService)` over `permission_handler` (existing #007 dep).
- Maps to `AppFailure.permissionDenied` for the blocked state (FR-012). iOS path returns `granted`
  (handled by the OS prompt + empty-state fallback — research D3).

## C3. mDNS wire contract (TXT)

| Item | Value |
|---|---|
| Service type | `_safesend._tcp` (`kNearbyServiceType`) |
| Instance name | device display name (+ random suffix for uniqueness) |
| TXT `v` | `'1'` (`kNearbyTxtVersion`) — payload version |
| TXT `c` | the 6-digit #003 code (validated with `SignalingProtocol.isValidCode`) |

Contract: a receiver MUST validate `v==1` and `isValidCode(c)` before surfacing a device as tappable;
malformed/foreign advertisements are silently skipped (Constitution I input-validation at the boundary).

## C4. Tap-to-join handoff (reused, unchanged)

Tapping a `NearbyDevice` calls the **existing** `PairingRepository.joinWithCode(device.code)` →
`takeTransport()` → existing #005 `IncomingTransferDialog`. No new signaling/transport path. The resulting
transfer threads `pairingMethod = nearby` via the existing `ConnectResult.method` → transfer cubits →
#006 mappers.

## C5. Routing contract (reuse existing receive route — no new route)

The nearby device-row section lives on the existing **Receive entry surface** (`AppRoutes.receive`,
ui-design §Screen 04), alongside code entry / Quét QR. Home "Thiết bị gần" navigates there with the
additive extra:

```dart
class ReceiveEntryRequest {           // existing (#008) — add openNearby
  final bool openScanner;             // #007/#008
  final String? autoJoinCode;         // #008
  final bool openNearby;              // #009 — default false; true ⇒ emphasize/scroll-to nearby section
}
```

- Navigated via `context.push(AppRoutes.receive, extra: ReceiveEntryRequest(openNearby: true))`; the
  discovered code is validated (`isValidCode`) before the join (Principle X). No new `AppRoutes` constant.

## C6. Native configuration contract

**iOS** (`ios/Runner/Info.plist`, both flavors):
```xml
<key>NSLocalNetworkUsageDescription</key><string>{localized}</string>
<key>NSBonjourServices</key><array><string>_safesend._tcp</string></array>
```
**Android** (`android/app/src/main/AndroidManifest.xml`, both flavors):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"
    android:usesPermissionFlags="neverForLocation" />
```
First `pod install` (nsd pod) churns `ios/Podfile.lock` — deferred to the device build.

---

## Contract test obligations (Constitution XII)

| Contract | Test |
|---|---|
| C1 discover | fake service: advertise from instance A → appears in B's list; stop → removed within stale window; self not listed |
| C1 advertise | advertise(code) → Result.success; registration failure → Result.failure(networkError) |
| C2 permission | granted → proceeds; denied → error(permissionDenied) blocked state; iOS → granted |
| C3 TXT | toTxt/codeFromTxt round-trip; reject `v!=1`, reject invalid code |
| C4 handoff | tap → joinWithCode(code) called with resolved code; method threads `nearby` to mapper |
| C5 routing | Home "Thiết bị gần" → receive route w/ `ReceiveEntryRequest(openNearby:true)`; tap → existing prompt |
