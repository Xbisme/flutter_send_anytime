# Phase 0 Research: Share Link

All findings verified at plan time (2026-06-26). Package facts fetched from pub.dev / the package
repository (Constitution XV). Codebase seams confirmed by reading the live source on branch
`008-share-link`.

## D1 — Deep-link package selection (`app_links`)

**Decision**: Add `app_links: ^6.4.1`.

**Rationale**:
- The Constitution's stack already names `app_links` for deep links (Principle "Pairing").
- Latest on pub.dev is **7.2.0** (and 7.1.x), but all 7.1.1+ require `environment: sdk: ^3.12.0`,
  `flutter: >=3.44.0`. This project runs **Dart 3.11** (`pubspec.yaml` → `sdk: ^3.11.0`; the #001
  changelog records the forced Dart 3.11.5 toolchain), so 7.1.1/7.1.2/7.2.0 are **incompatible**.
- Compatible candidates and their constraints:

  | Version | `sdk` | `flutter` | Compatible with Dart 3.11? |
  |---|---|---|---|
  | 7.2.0 / 7.1.2 / 7.1.1 | `^3.12.0` | `>=3.44.0` | ❌ |
  | 7.0.0 | `^3.10.0` | `>=3.38.1` | ⚠️ borderline (needs Flutter ≥3.38.1) |
  | **6.4.1** | `^3.5.0` | `>=3.24.0` | ✅ comfortably |
  | 6.4.0 | `^3.3.0` | `>=3.19.0` | ✅ |

- **6.4.1** is the newest release that is *guaranteed* compatible without depending on the exact
  Flutter minor (7.0.0's `>=3.38.1` is the same minor that first shipped Dart 3.11, so it is a
  coin-flip we don't need to take). The relevant API (`getInitialLink()`, `uriLinkStream`) is
  identical across 6.x and 7.x, so nothing is lost. This mirrors the disciplined pin in #006
  (`drift_dev` held back to dodge an analyzer conflict).

**Alternatives considered**:
- `uni_links` — unmaintained (last release years ago), no cold/warm parity story; rejected.
- `app_links 7.x` — rejected on the Dart 3.12 floor.
- A bespoke platform channel (`MethodChannel` for `openURL` / `onNewIntent`) — rejected per
  Constitution XIII (YAGNI); `app_links` already abstracts both platforms + cold/warm.

**API surface used** (verified from the 6.x/7.x `AppLinks` class):
- `Future<Uri?> getInitialLink()` — the link that cold-started the app (call once at startup).
- `Stream<Uri> get uriLinkStream` — subsequent (warm) links while running.
- (We do **not** rely on `uriLinkStream` replaying the initial link; cold start is handled
  explicitly via `getInitialLink()` to avoid a race — see D3.)

## D2 — Native scheme registration (custom scheme, both flavors)

**Decision**: Register `safesend://` via the standard custom-URL-scheme config on each platform; no
`AppDelegate`/`MainActivity` Dart-bridge code is required (the `app_links` plugin auto-registers the
platform handlers).

**iOS** — add to `ios/Runner/Info.plist` (single Info.plist shared by both flavors):
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

**Android** — add a `VIEW` intent-filter to the existing `.MainActivity` in
`android/app/src/main/AndroidManifest.xml` (shared by both flavors; `autoVerify` is **not** needed
for a custom scheme):
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="safesend" android:host="connect" />
</intent-filter>
```

**Flavor coexistence note**: dev (`app.safesend.dev`) and prod (`app.safesend`) both register the
same `safesend://` scheme. If both are installed on one device, iOS resolves to one arbitrarily and
Android shows a disambiguation chooser. This is an accepted dev-only edge (the two flavors are rarely
co-installed); documenting it here rather than diverging the scheme per flavor (which would break a
prod link opened on a dev build during testing). No per-flavor Info.plist/manifest split is
introduced.

**Rationale**: custom scheme needs only the registration above; `app_links` consumes the delivered
URL. This is the minimum that satisfies FR-009 for both platforms and both flavors.

## D3 — Cold-start vs warm-start delivery (FR-010, FR-011)

**Decision**: Instantiate `AppLinks` **early** (in `bootstrap()` before `runApp`, so the plugin is
listening for the launching intent), then:
- **Cold start**: after the app/router is ready, `await getInitialLink()` once and act on it.
- **Warm start**: subscribe to `uriLinkStream` for the app's lifetime.

The coordinator is mounted under the router so navigation targets exist when a link is handled; the
cold-start link is processed in a post-first-frame callback to guarantee the router + DI are ready
(FR-011 — the invite is never lost to startup ordering).

**Rationale**: `getInitialLink()` is the documented way to retrieve the launch URL deterministically;
splitting cold (one-shot) from warm (stream) avoids double-handling and the "initial link replayed on
the stream" ambiguity across plugin versions.

## D4 — Where the deep-link logic lives (Constitution XI)

**Decision**: Two layers.
1. **Core-pure delivery** — `DeepLinkService` (`lib/core/services/deeplink/`), `@LazySingleton`,
   wraps `AppLinks`. Depends only on `app_links` + core types; imports **no** features. Exposes
   `Future<Uri?> getInitialLink()` and `Stream<Uri> get links`.
2. **Composition-layer coordination** — `deep_link_coordinator.dart` next to `app_router.dart`.
   It parses each incoming `Uri` via `ConnectLink.parse`, applies the guards (D5/D6), and routes via
   `AppRoutes` + `context.go`. This layer is *allowed* to reference feature routes because
   `lib/core/router/app_router.dart` **already imports feature pages** (lines 11–24) — the router is
   the project's established composition root since #001.

**Rationale**: keeps the testable core engine free of feature coupling while reusing the existing
"core/router + go_router extra of core types" cross-feature handoff (the #004/#005/#007 pattern).
`DeepLinkService` is independently unit-testable with a fake; the coordinator is widget-testable with
an injected fake service + a test router.

**Alternatives considered**: putting the listener inside a feature (e.g. `features/pairing`) — rejected
because a feature can't own app-global launch routing and other features (Receive/Home) would need to
import it. Putting feature routing in `core/domain` — rejected (would import features → XI violation).

## D5 — Receiver auto-join seam (FR-012)

**Decision**: Route a valid invite to the **existing Receive entry coordinator** with the parsed code,
and auto-join there — do not bypass `ReceiveEntryPage` (it owns the receive transfer cubit + the
accept/reject → progress flow).

Additive core-typed seams (mirroring #007's `openScanner` and #004's `initialSources`):
- `ConnectRequest.autoJoinCode: String?` (receiver-only) — when set, the receiver Connect panel
  immediately `joinWithCode(autoJoinCode)` and records `method = PairingMethod.shareLink`.
- The receive route's `extra` is widened from a bare `bool openScanner` to a small core
  `ReceiveEntryRequest { bool openScanner = false; String? autoJoinCode; }`, threaded
  `ReceiveEntryPage → ConnectRequest.autoJoinCode`. The two existing call sites (Home "Nhận", Home
  "Quét QR") are updated to the struct — the same "additive edit to merged code" shape used by
  #006's `RecordTransferUseCase` injection.

**Rationale**: reuses the receiver's whole pipeline (page-scoped pairing cubit/repo, accept/reject,
progress) instead of duplicating it; the auto-join is the link-driven analog of typing a code or
scanning a QR. Setting `method = shareLink` on the existing `ConnectResult.method` field threads to
the #006 history mappers with no further change (verified: `SendProgressArgs.method` /
`ReceiveProgressArgs.method` → `*HistoryMapper.toRecord(pairingMethod:)`).

## D6 — Guard rails: self-invite, in-transfer, invalid (FR-013/014/015/016)

- **FR-015 self-invite**: a `@LazySingleton` core `ActiveHostingRegistry` holds the device's current
  hosting code. `PairingRepositoryImpl` writes the code on host-start and clears it on dispose
  (feature → core import is allowed). The coordinator compares the parsed code; on match it shows a
  localized "this is your own invite link" toast and does **not** join.
- **FR-014 in-transfer**: the coordinator inspects the router's current location; if it is
  `AppRoutes.sendProgress` or `AppRoutes.receiveProgress`, a transfer is active → show a confirm
  dialog (leave & join vs stay & discard). No new transfer-state registry is needed — the router is
  already the source of "what screen am I on". From any non-transfer screen, proceed without a prompt.
- **FR-013 invalid/expired**: `ConnectLink.parse` failure (wrong scheme/target/version/malformed) →
  `AppToast` "invalid invite" + `context.go(AppRoutes.home)`. A syntactically valid but expired/
  consumed code parses, then the existing join path surfaces `roomExpired/invalidCode`, mapped to the
  expired toast + Home (same destination for warm and cold per the clarify decision).
- **FR-016 rapid succession**: the coordinator serializes handling and acts only on the most recent
  link (latest-wins; a single in-flight join attempt).

**Rationale**: leverages signals that already exist (router location, `ConnectLink` Result, the join
path's typed failures) and adds the smallest possible new state (one nullable hosting code) to satisfy
self-invite detection.

## D7 — Share action (FR-001, FR-005)

**Decision**: Implement the already-stubbed `_HostingPanel` "Chia sẻ link mời" `SecondaryButton`
(`onPressed: null` today) to build `ConnectLink.build(activeCode)` and call
`SharePlus.instance.share(ShareParams(text: '<invite text>\n<link>'))` — reusing the `share_plus`
12.0.2 API already used by received-file sharing. The active code is read from the sender
`PairingCubit`'s current `PairingState.hosting(code)`. Invite text is a new ARB string (VI primary +
EN), e.g. "Mình muốn gửi bạn vài tệp qua Safe Send — chạm để nhận:".

**Rationale**: no new dependency; the stub, button component, and icon (`LucideIcons.share2`) are
already present. Sharing is a third presentation of the one hosting session — it neither generates a
code nor opens a socket (FR-003), because it only reads the already-active code.

## Open items deferred to implementation / later

- Exact invite share-text wording (ARB string — drafted at implementation, VI primary + EN).
- First `pod install` after adding `app_links` will churn `ios/Podfile.lock` (commit it — Constitution
  XV); folds into the next on-device build.
- Two-physical-device cold + warm smoke (tap a real shared link from a chat app, app-closed and
  app-open) — deferred manual task tracked in `tasks.md` (Constitution XII).
