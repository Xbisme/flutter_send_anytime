# Contracts: Share Link

UI/integration feature — the "contracts" are (1) the OS deep-link registration, (2) the core service
interfaces, and (3) the additive core-typed seams. No network/API contracts (signaling/transport
unchanged).

## C1 — Invite link format (reused from #007, authoritative)

```
safesend://connect?v=1&code=NNNNNN
  scheme = safesend     (AppRoutes.deepLinkScheme)
  host   = connect      (target)
  v      = 1            (payload version; reject unknown)
  code   = 6 digits     (SignalingProtocol.isValidCode)
```
- Build: `ConnectLink.build(code) → String`.
- Parse: `ConnectLink.parse(raw) → Result<String>` (success = code; failure = `AppFailure.invalidCode`).
- Acceptance matrix already covered by #007 tests; #008 adds no new payload rules.

## C2 — iOS URL scheme registration (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>app.safesend</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>safesend</string>
    </array>
  </dict>
</array>
```
Contract: a tap on a `safesend://…` URL in another iOS app launches/foregrounds Safe Send and
delivers the URL to `app_links`. Shared by dev + prod (single Info.plist).

## C3 — Android intent-filter (`android/app/src/main/AndroidManifest.xml`, inside `.MainActivity`)

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="safesend" android:host="connect" />
</intent-filter>
```
Contract: an `ACTION_VIEW` for `safesend://connect…` resolves to `.MainActivity` and is delivered to
`app_links`. `autoVerify` is intentionally absent (custom scheme, not an App Link). Shared by dev +
prod (single main manifest).

## C4 — `DeepLinkService` (core service interface)

```dart
abstract interface class DeepLinkService {
  /// The link that cold-started the app, or null. Call once after the app is ready.
  Future<Uri?> getInitialLink();

  /// Links delivered while the app is running (warm start).
  Stream<Uri> get links;
}
```
- Impl `@LazySingleton`, wraps `AppLinks()` (`getInitialLink()` + `uriLinkStream`).
- MUST NOT import any `features/…`. MUST NOT log URL contents (Constitution I).
- Test double: an in-memory fake emitting controlled `Uri`s (cold via a settable initial, warm via a
  `StreamController`).

## C5 — `ActiveHostingRegistry` (core service interface)

```dart
abstract interface class ActiveHostingRegistry {
  String? get activeHostingCode;       // null when not hosting
  void setHosting(String code);        // pairing layer, on host-start / code rotation
  void clear();                        // pairing layer, on dispose / session end
}
```
- Impl `@LazySingleton`. Single nullable field. Written by `PairingRepositoryImpl`; read by the
  deep-link coordinator. Never logged.

## C6 — Deep-link coordinator behavior (composition layer)

Given a delivered `Uri`, the coordinator MUST:
1. `ConnectLink.parse(uri.toString())`.
   - failure → `AppToast` `shareLinkInvalid` + `go(AppRoutes.home)`. (FR-013)
2. on success(code):
   - if `code == ActiveHostingRegistry.activeHostingCode` → `AppToast` `shareLinkOwn`, stop. (FR-015)
   - if current router location ∈ {`sendProgress`, `receiveProgress`} → confirm dialog
     `shareLinkLeaveTransfer`; cancel → stop, confirm → continue. (FR-014)
   - `go(AppRoutes.receive, extra: ReceiveEntryRequest(autoJoinCode: code))`. (FR-012)
3. Serialize handling; only the most recent link is acted upon. (FR-016)

Cold start: process `getInitialLink()` once in a post-first-frame callback (router + DI ready) (FR-011).

## C7 — Additive core seams

```dart
// core/domain/pairing/connect_handoff.dart — ConnectRequest gains:
final String? autoJoinCode;   // receiver-only; default null

// new core type for the receive route extra:
class ReceiveEntryRequest {
  const ReceiveEntryRequest({this.openScanner = false, this.autoJoinCode});
  final bool openScanner;
  final String? autoJoinCode;
}
```
- `AppRoutes.receive` builder: `extra as ReceiveEntryRequest?` (was `bool?`).
- Receiver Connect panel: if `request.autoJoinCode != null` → `joinWithCode(code)` and set
  `ConnectResult.method = PairingMethod.shareLink`.

## C8 — Localization keys (new; VI primary + EN, with `@description`)

| Key | Purpose |
|---|---|
| `connectShareLinkMessage` | Invite text prepended to the link in the share sheet (FR-005). |
| `shareLinkInvalid` | Toast: malformed / not-a-Safe-Send invite (FR-013). |
| `shareLinkExpired` | Toast: valid-but-expired/consumed code (FR-013). |
| `shareLinkOwn` | Toast: tapped your own invite link (FR-015). |
| `shareLinkLeaveTransferTitle` / `shareLinkLeaveTransferBody` / confirm + cancel labels | Confirm dialog when interrupting a transfer (FR-014). |

(`connectShareLink` button label + `historyMethodShareLink` already exist.)

## Test contracts (Constitution XII)

- **Unit**: `ConnectLink.parse` (already #007); deep-link coordinator decision table (valid→receive,
  invalid→toast+home, own→toast, expired→toast+home) with a fake `DeepLinkService` + fake
  `ActiveHostingRegistry` + test router; `ActiveHostingRegistry` set/clear.
- **Bloc/widget**: receiver auto-join via `ConnectRequest.autoJoinCode` reaches the accept/reject
  prompt and records `shareLink`; "Chia sẻ link mời" action builds the right link + invokes share;
  confirm dialog appears on the progress route and not elsewhere.
- **Deferred (manual, two-device)**: cold-start (app closed) and warm-start (app open) tap of a real
  shared link from a chat app → accept/reject prompt; self-invite + expired-link toasts on device.
