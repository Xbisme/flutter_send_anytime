# Safe Send v1.0 — Spec Roadmap (SDD Roadmap)

> Goal v1.0: Ship a cross-platform (iOS + Android, Flutter) peer-to-peer file-sharing app — a "Send Anywhere"-style product. Any file type, no size limit, transferred device-to-device over WebRTC with **no intermediary server holding the data**. Three core surfaces — **Gửi (Send)**, **Nhận (Receive)**, **Lịch sử (History)** — plus four ways to connect two devices: **6-digit key**, **QR**, **nearby radar**, and **share link**. Fixed light & dark palette.
>
> **Vai trò file này**: pure planning — dependency graph, scope per spec, timeline, optimal order. Current status của các spec sống ở [`project-context.md`](project-context.md). Ship history sống ở [`changelog.md`](changelog.md). Alignment decisions sống ở [`decisions/`](decisions/). **Giao diện** (screens, tokens, components, navigation IA) sống ở [`ui-design-context.md`](ui-design-context.md) — đọc trước mọi phần UI/UX của spec.
>
> Last updated: 2026-06-29 (Specs #001–#013 merged via PRs #1–#13; **#013 In-App Viewers merged**. **All v1.0 feature specs done** — only the **#014 Polish & Release** sweep remains. Next: #014 Polish & v1.0 Release.)

---

## SDD Workflow For Each Spec

```
/speckit.specify → /speckit.clarify → /speckit.plan → /speckit.tasks → /speckit.analyze → /speckit.implement
```

Each spec creates: branch `NNN-feature-name`, folder `specs/NNN-feature-name/`. See [`dev-workflow.md`](dev-workflow.md) for the full per-spec flow.

---

## Architecture Primer (read before #002)

Safe Send is built on three layers that every connection method shares:

1. **Pairing / Discovery** — two devices agree on a *rendezvous identifier*. The four methods (6-digit key, QR, share link, nearby radar) are just different ways to exchange that identifier. They all converge onto the same signaling channel.
2. **Signaling** — a lightweight relay (WebSocket) that swaps WebRTC SDP offer/answer + ICE candidates between the two peers. **It never sees file bytes.** It can be self-hosted and is stateless/ephemeral.
3. **WebRTC DataChannel transport** — once ICE completes, a direct encrypted (DTLS-SRTP) `RTCDataChannel` carries the file. Files are chunked, streamed with backpressure/flow-control, and reassembled on the receiver.

> **"No intermediary server holding the data" nuance**: file bytes flow peer-to-peer. A **TURN** server may relay traffic as an *encrypted* fallback when NAT traversal fails — bytes pass through but are end-to-end encrypted and never persisted. This is the only path where data leaves the direct P2P link, and it is documented + optional. The **signaling** server only ever carries connection metadata.

This is why **#002 (transport core)** and **#003 (signaling + 6-digit pairing)** are the blocking foundation: every later feature is a new *entry* into the same pipeline.

> **Navigation IA (per [`ui-design-context.md`](ui-design-context.md))**: bottom nav = **3 tabs — Trang chủ (Home) / Lịch sử (History) / Cài đặt (Settings)**. **Gửi (Send)** and **Nhận (Receive)** are **primary actions on the Home screen**, not tabs — they push full-screen flows (Send → Connect → Progress → Complete; Receive → Progress → Complete) that **hide the bottom nav**. The four connection methods live as **tabs of one "Kết nối" (Connect) screen** (Mã 6 số / QR / Gần đây) + a "Chia sẻ link mời" action. There are **8 designed screens**: home · send · connect · receive · progress · complete · history · settings.

---

## Dependency Graph

```
Spec #001: Project Foundation & Navigation            ← FOUNDATION (blocking)
   (3 tabs Trang chủ/Lịch sử/Cài đặt, Home shell with
    Gửi+Nhận actions, fixed light/dark palette + design
    tokens, shared widgets, Result/AppFailure/AppCubit,
    DI, router, l10n)
    │
    ▼
Spec #002: WebRTC Transport & Transfer Protocol Core   ← ENGINE (blocking)
   (RTCPeerConnection lifecycle, DataChannel, file
    chunking + reassembly, transfer state machine,
    abstract SignalingChannel + in-process loopback
    for tests)
    │
    ▼
Spec #003: Signaling Server + 6-Digit Key Pairing      ← RENDEZVOUS (blocking)
   (WebSocket signaling client, lightweight relay,
    generate/enter 6-digit code → SDP/ICE exchange)
    │
    ├───────────────────────────────┐
    ▼                               ▼
Spec #004                       Spec #005
Send Flow (UI)                  Receive Flow (UI)
(send screen → Connect          (receive screen: enter
 hub tab "Mã 6 số" →             code / nearby device →
 Progress → Complete;            Progress → Complete;
 pick any-type files,            accept/reject, save to
 multi-select, cancel)           Files/Downloads)
    │                            progress)
    └───────────────┬───────────────┘
                    ▼
            ⭐ MVP CHECKPOINT (after #005)
            Full E2E: pair via 6-digit → send → receive
            (Home/Send/Connect/Progress/Complete/Receive)
                    │
                    ▼
            Spec #006: Lịch sử (History tab)
            (drift persistence, by-day list, direction
             color/icon, detail, re-send, clear, search)
                    │
                    ▼
            Spec #007: QR Connect
            (Connect-hub "QR" tab generate + Receive
             "Quét mã QR" scan — encodes rendezvous id)
                    │
                    ▼
            Spec #008: Share Link
            ("Chia sẻ link mời" on Connect; universal /
             deep link to pair; web fallback optional)
                    │
                    ▼
            Spec #009: Nearby Radar
            (Connect-hub "Gần đây" tab + Receive nearby
             DeviceRow; mDNS / UDP multicast / BLE;
             ssRadar animated UI; tap-to-connect)
                    │
                    ▼
            Spec #010: Settings & Preferences (Settings tab)
            (device profile, auto-receive, save-to-library,
             notifications, theme light/dark/system,
             signaling endpoint, auto-accept rules)
                    │
                    ▼
            Spec #011: Background Transfer
            (keep transfers running when backgrounded —
             iOS Live Activity + Android foreground Service;
             both platforms)
                    │
                    ▼
            Spec #012: Home Screen Completion
            (replace hardcoded Home content with real data;
             build the "Xem tất cả / See all" screens)
                    │
                    ▼
            Spec #013: In-App File Viewers
            (open known types in-app — image / video / audio /
             basic documents — from History, Complete, Home)
                    │
                    ▼
            Spec #014: Polish & v1.0 Release
```

---

## Spec Details

### Spec #001: Project Foundation & Navigation

- **Status**: ✅ **Implemented (code)** — branch `001-project-foundation` (2026-06-24). `dart analyze lib test` 0 issues · `flutter test` 27 passed. Native flavor split (iOS xcconfig / Android productFlavors) + on-device build deferred. See [`changelog.md`](changelog.md).
- **Branch**: `001-project-foundation`
- **Design**: see [`ui-design-context.md`](ui-design-context.md) — Navigation IA + Design Tokens + Shared Components sections are the build spec for this spec.
- **Scope**:
  - Clean Architecture folder structure (`core/` + `features/`), feature-first.
  - 2 build flavors (dev / prod), per-flavor entry points (`main_dev.dart` / `main_prod.dart`).
  - Bottom navigation with **3 tabs: Trang chủ (Home), Lịch sử (History), Cài đặt (Settings)**. **Gửi + Nhận are Home-screen actions, NOT tabs** (they push nav-less flows — wired in #004/#005). Flow screens hide the bottom nav.
  - **Home screen shell** — header + search pill + hero/stat/quick-action scaffolding (recent-media data wired by #006; Send/Receive actions wired by #004/#005).
  - **Fixed light & dark palette** — bespoke `AppColors` + full **design-token layer** (semantic aliases `accent`/`surface-card`/`text-secondary`…, Sora + JetBrains Mono typography, spacing/radius/shadow/motion) ported from the claude_design tokens. NO scheme picker; only light/dark/system mode.
  - **Shared widget library** (built once here, reused everywhere): `PrimaryButton`(pill gradient CTA), `SecondaryButton`, `DangerButton`, `FileChip`/`FileRow`, `CodeBox`, `SegmentedTabs`, `ToggleRow`, `StatTile`/`QuickActionCard`, `AppToast`, flow `AppBar`. Icon set mapped to **lucide_icons** (confirm at plan).
  - Foundation primitives: `Result<T>`, `AppFailure` (`@freezed`), `AppCubit<T>` base (4-state freezed sealed), `AppLogger`, `AppToast`.
  - Brand assets (`logomark.svg`, `logo-wordmark.svg`) pulled from the claude_design project into `assets/brand/`.
  - DI: `get_it` + `injectable`. Router: `go_router` with deep-link skeleton (`safesend://`) reserved for #008.
  - l10n (ARB): Vietnamese (primary UI copy) + English.
- **New packages**: `flutter_bloc`, `get_it`, `injectable`, `go_router`, `freezed`, `json_serializable`, `build_runner`, `toastification`, `lucide_icons` (or `flutter_lucide`), `flutter_svg`, `google_fonts`, `intl`, `very_good_analysis`.
- **Out of scope**: any networking, WebRTC, persistence.

### Spec #002: WebRTC Transport & Transfer Protocol Core

- **Status**: ✅ **Implemented (code)** — branch `002-webrtc-transport-core` (2026-06-24). `dart analyze lib test` 0 issues · `flutter test` 63 passed. Engine + abstract `SignalingChannel`/`PeerConnector`/`DataTransport` + in-process loopback; real `WebRtcPeerConnector` (flutter_webrtc 1.5.2) wired; two-device smoke + iOS pod/Android release config deferred. See [`changelog.md`](changelog.md).
- **Branch**: `002-webrtc-transport-core`
- **Depends on**: #001
- **Blocking**: all transfer features
- **Scope**:
  - `RTCPeerConnection` lifecycle wrapper (create, set local/remote SDP, add/collect ICE candidates, connection-state stream, teardown + resource zeroing).
  - `RTCDataChannel` setup (ordered, reliable) with **backpressure / flow-control** (`bufferedAmountLowThreshold`).
  - **Transfer protocol** (pure Dart, framing over the data channel): file manifest message (name, size, mime, count), chunk frames (sequence + payload), progress/ack, completion + integrity check (per-file hash), cancel/abort. Multi-file batched as a session.
  - **Chunking + reassembly** with a tuned chunk size; streamed from disk (no full-file-in-memory) on send, streamed to disk on receive.
  - **Transfer state machine** (`idle → connecting → handshaking → transferring → done/failed/cancelled`) exposed as a stream → drives every UI later.
  - **Abstract `SignalingChannel` interface** + an **in-process loopback impl** so the whole engine is unit/integration testable without a server. Real WebSocket impl lands in #003.
- **New packages**: `flutter_webrtc`, `crypto` (chunk/file hashing), `uuid`.
- **Out of scope**: real signaling transport (#003), any UI, pairing codes.

### Spec #003: Signaling Server + 6-Digit Key Pairing

- **Status**: ✅ **Implemented (code)** — branch `003-signaling-6digit` (2026-06-24). `shelf` WebSocket relay in `server/` + pure-Dart shared protocol pkg `packages/safesend_signaling/` + `WebSocketSignalingChannel implements SignalingChannel` (the #002 seam); 6-digit code (full range, 5-min TTL, sender-generated) → room → SDP/ICE relay; per-connection join rate limiting; `features/pairing/` cubit + dev-only debug screen. `dart analyze` 0 across 3 packages · 133 tests pass · two-device smoke deferred. See [`changelog.md`](changelog.md).
- **Branch**: `003-signaling-6digit`
- **Depends on**: #002
- **Design**: Screen 03 **Kết nối (connect)** — the pairing hub. This spec builds the **"Mã 6 số" tab** (radar-ringed phone, 4–6 mono CodeBoxes, expiry countdown) + the **Nhận "Nhập mã"** entry on Screen 04. QR/Gần đây tabs are stubbed for #007/#009. See [`ui-design-context.md`](ui-design-context.md) §Screen 03/04.
- **Scope**:
  - **Lightweight signaling relay** (separate tiny service — Dart `shelf` WebSocket or Node; lives in `server/`): rooms keyed by a rendezvous id, relays SDP/ICE between exactly two peers, ephemeral, no persistence, no file bytes. Documented for self-hosting; endpoint configurable per flavor.
  - **WebSocket signaling client** implementing the `SignalingChannel` interface from #002.
  - **6-digit key pairing**: sender generates a short-lived 6-digit code mapped to a rendezvous room; receiver enters the code → both join the same room → SDP/ICE exchange → DataChannel opens. Code TTL + collision handling + expiry UX.
  - Optional **STUN** config + documented **TURN** fallback hook (encrypted relay only, see Architecture Primer).
  - Connection-pairing UI primitives shared by #004/#005 (code display, code entry field).
- **New packages**: `web_socket_channel`.
- **Out of scope**: file-selection UI (#004), receive UI (#005), QR/link/radar pairing.

### Spec #004: Send Flow (Gửi)

- **Status**: ✅ **Implemented (code)** — branch `004-send-flow` (2026-06-24). File selection (`file_picker` 11.0.2, any-type multi-select, no runtime permission) → production Connect hub (6-digit functional; QR/Gần đây stubbed; role-parameterized for #005) → progress (#002 snapshot stream) → complete / typed retryable failure. Engine reused via additive seams `TransferEngine.startSendOnTransport` + `PairingRepository.takeTransport`; features decoupled via `core/router` + go_router extra. `dart analyze` 0 · `flutter test` 107 passed · two-device send smoke deferred. See [`changelog.md`](changelog.md).
- **Branch**: `004-send-flow`
- **Depends on**: #002, #003
- **Design**: Screens 02 **Gửi file (send)** → 03 **Kết nối** → 05 **Đang truyền (progress)** → 06 **Hoàn tất (complete)**, launched from the Home "Gửi" action. See [`ui-design-context.md`](ui-design-context.md) §Screen 02/05/06.
- **Scope**:
  - File selection — **any file type, multi-select** (and share-sheet "Send with Safe Send" inbound intent on both platforms). Selected-items tray with per-file size + total.
  - Send screen: shows the 6-digit code (+ placeholder slots for QR/link/radar to be filled by #007/#008/#009), waiting-for-peer state, then live per-file + overall **progress** (speed, ETA, %), pause-not-required but **cancel** supported.
  - Permissions (storage/photos as needed) via `permission_handler`.
  - Wires the #002 transfer state machine → Send UI.
- **New packages**: `file_picker`, `permission_handler`, `receive_sharing_intent` (inbound share), `qr_flutter` (code/QR render — QR pairing itself is #007).
- **Out of scope**: receiving, history persistence.

### Spec #005: Receive Flow (Nhận)

- **Status**: ✅ **Merged** (PR #5) — ⭐ **MVP CHECKPOINT reached · device-validated on 2 iPhones**
- **Branch**: `005-receive-flow`
- **Depends on**: #002, #003, #004
- **Design**: Screen 04 **Nhận file (receive)** → 05 **Đang truyền** → 06 **Hoàn tất**, launched from the Home "Nhận" action. Reuses Progress/Complete from #004. See [`ui-design-context.md`](ui-design-context.md) §Screen 04.
- **Scope**:
  - Receive screen: enter 6-digit code (or land here from QR/link/radar later), connect.
  - **Incoming-transfer prompt**: sender name + file manifest (names, types, total size) → **Accept / Reject**.
  - On accept: stream chunks to disk, live progress, then **save to platform location** (iOS Files/share-sheet, Android Downloads/SAF), open-file / reveal action.
  - Integrity verification per file (hash from #002) + failure/retry surfacing.
  - Wires the #002 transfer state machine → Receive UI.
  - **MVP**: after this spec the full loop works — pair via 6-digit, send any files, receive + save. Start dogfooding two physical devices.
- **New packages**: `path_provider`, `share_plus`, `open_filex` (or `open_file`); Android SAF via `saf` if needed.
- **Out of scope**: history list, QR/link/radar entry points.

### Spec #006: Lịch sử (History)

- **Status**: ✅ **Merged** (PR #6)
- **Branch**: `006-history`
- **Depends on**: #004, #005
- **Design**: Screen 07 **Lịch sử (history)** tab — by-day sections, direction-colored avatars (gửi=accent / nhận=info). Also backfills the Home screen's "recent" lists. See [`ui-design-context.md`](ui-design-context.md) §Screen 07/01.
- **Scope**:
  - **drift (SQLite)** persistence of transfer records: direction (sent/received), peer name, file names/types/sizes/count, total bytes, timestamp, status (completed/failed/cancelled), pairing method used.
  - History tab: grouped list (by day), search/filter (direction, date), detail page.
  - Quick actions: re-send (sender side → repopulate Send tray when files still exist), open received file, delete record, clear all.
  - Hooks `core/` lifecycle so #004/#005 write a record on terminal transfer state.
- **New packages**: `drift`, `drift_flutter`, `drift_dev`.
- **Out of scope**: cloud history, cross-device sync.

### Spec #007: QR Connect

- **Status**: ✅ **Merged** (PR #7) — branch `007-qr-connect` (2026-06-25). Sender QR tab (same hosting session + brightness boost) + receiver full-screen scanner (camera + torch + pick-from-photo + camera-permission recovery), reusing the #003 rendezvous unchanged; core `ConnectLink` codec (`safesend://connect?v=1&code=…`, deep-link-ready for #008); `pairingMethod=qr` recorded. `dart analyze` 0 · `flutter test` 199 passed. Two-device QR smoke + first `pod install` deferred to device build. See [`changelog.md`](changelog.md).
- **Branch**: `007-qr-connect`
- **Depends on**: #003, #004, #005
- **Design**: fills the **"QR" tab** of Screen 03 (Kết nối) + the **"Quét mã QR"** button on Screen 04 (Nhận). See [`ui-design-context.md`](ui-design-context.md) §Screen 03/04.
- **Scope**:
  - Sender renders a **QR** encoding the rendezvous identifier (6-digit code / room token / `safesend://` payload).
  - Receiver **scans** (camera + pick-from-photo) → auto-joins the room → straight into the receive prompt. No typing.
  - Slots the QR into the Send screen's pairing options + a dedicated scan entry on Receive.
- **New packages**: `mobile_scanner` (scan); reuses `qr_flutter` (render) from #004.
- **Out of scope**: link + radar pairing.

### Spec #008: Share Link

- **Status**: ✅ **Merged** (PR #8) — branch `008-share-link` (2026-06-26). Sender share action (`safesend://` invite reusing #007 `ConnectLink`) + receiver cold/warm deep-link auto-join into Receive; core-pure `DeepLinkService`/`ActiveHostingRegistry`/`DeepLinkCoordinator`; guards for invalid/expired/self-invite/in-transfer/latest-wins; `pairingMethod=shareLink`. Custom-scheme only (no universal links/web fallback — deferred). `dart analyze` 0 · `flutter test` 211 passed. Two-device cold/warm smoke + first `pod install` deferred. See [`changelog.md`](changelog.md).
- **Branch**: `008-share-link`
- **Depends on**: #003, #004, #005, #007
- **Design**: wires the **"Chia sẻ link mời"** secondary action on Screen 03 (Kết nối) + deep-link entry into Screen 04 (Nhận). See [`ui-design-context.md`](ui-design-context.md) §Screen 03.
- **Scope**:
  - Generate a **share link** (universal link / app link + `safesend://` deep link) encoding the rendezvous identifier; shareable via any app (Messages, etc.).
  - Cold/warm deep-link handling → routes straight into Receive + room join.
  - Optional lightweight **web landing fallback** (if app not installed → store + instructions). Decide scope at clarify.
  - iOS Associated Domains + Android App Links setup.
- **New packages**: `app_links` (or `uni_links`).
- **Out of scope**: radar.

### Spec #009: Nearby Radar

- **Status**: ✅ **Merged** (PR #9) — branch `009-nearby-radar` (2026-06-26) · **device-validated on 2 devices**. Fourth connection method: sender advertises the live #003 code via mDNS TXT on the Connect "Gần đây" tab; receiver browses + taps a nearby device → auto-join → existing accept/reject; reuses #003 rendezvous + #002 transport unchanged; same-Wi-Fi only (BLE deferred); core-pure `NearbyDiscoveryService`/`NearbyPermissionService` (`nsd` 5.0.1) + `NearbyDevice`; `pairingMethod=nearby`. `dart analyze lib test` 0 · `flutter test` 230 passed (19 new). **Two-device same-Wi-Fi smoke PASSED on 2 devices**; first `pod install` deferred. See [`changelog.md`](changelog.md).
- **Branch**: `009-nearby-radar`
- **Depends on**: #003, #004, #005
- **Design**: fills the **"Gần đây" tab** of Screen 03 (Kết nối, `ssRadar` animation) + the nearby **DeviceRow** ("đang chờ ở gần bạn" + "Nhận") on Screen 04 + the Home "Thiết bị gần" quick-action. See [`ui-design-context.md`](ui-design-context.md) §Screen 03/04.
- **Scope**:
  - **Local discovery** of nearby Safe Send devices on the same network — mDNS/Bonjour and/or UDP multicast (evaluate BLE for off-Wi-Fi at clarify; cross-platform constraints documented in research.md).
  - Animated **radar UI**: nearby devices appear as blips (device name + avatar); tap a device → initiates pairing automatically (local signaling rendezvous, no code needed).
  - Advertise/browse lifecycle tied to app foreground + a "discoverable" toggle; privacy note on broadcast device name.
  - Permissions (Local Network on iOS 14+, nearby-wifi/BLE on Android 12+).
- **New packages**: `nsd` or `multicast_dns` + `network_info_plus` (and `flutter_blue_plus` if BLE chosen).
- **Out of scope**: internet-wide discovery.

### Spec #010: Settings & Preferences

- **Status**: ✅ **Merged** (PR #10) — branch `010-settings` (2026-06-26) · **device-validated on 2 devices + first `pod install` OK**. Single `shared_preferences`-backed `SettingsRepository` + app-wide `SettingsCubit` driving runtime theme/language; device profile (+ additive manifest `senderName` to peers), auto-receive (foreground skip-tap) / save-to-library (`gal`) / notifications (`flutter_local_notifications`) with permission gating, signaling-endpoint override + diagnostic, About (version + in-app how-it-works/privacy + rate). `dart analyze lib test` 0 · `flutter test` 264 passed. **Two-device smoke PASSED on 2 devices + first `pod install` ran (build OK)**; only bloc-lint CLI remains deferred. See [`changelog.md`](changelog.md).
- **Branch**: `010-settings`
- **Depends on**: most prior specs
- **Design**: Screen 08 **Cài đặt (settings)** tab — device-profile card + ToggleRow group (Tự động nhận / Lưu vào Thư viện / Thông báo / Giao diện tối) + version footer. See [`ui-design-context.md`](ui-design-context.md) §Screen 08.
- **Scope**:
  - **Device profile** — device name + avatar (shown to peers in radar/receive prompt), editable.
  - **Tự động nhận (auto-receive)** from trusted devices · **Lưu vào Thư viện (save to photo library)** for received images/videos · **Thông báo (notifications)** on new file.
  - **Default download location** + "ask each time" toggle.
  - **Giao diện tối / Theme**: light / dark / follow-system (palette is fixed — no scheme picker).
  - **Signaling endpoint** override (advanced / self-host) + connection diagnostics.
  - **Auto-accept** rules (e.g. from known/saved peers) — decide at clarify.
  - **About**: version ("Safe Send v1.0.0 · WebRTC P2P"), privacy policy, how-it-works (the no-server-holds-data explainer), rate app.
  - Language picker EN/VI/Follow-system.
- **New packages**: `shared_preferences`, `package_info_plus`, `in_app_review`.
- **Out of scope**: accounts, cloud.

### Spec #011: Background Transfer

- **Status**: ✅ **Merged** (PR #11) — branch `011-background-transfer` (2026-06-27, merged 2026-06-29). OS background surfaces driven from the #002 snapshot stream: iOS Live Activity + Android `dataSync` foreground-service notification (immediate Huỷ); core-pure coordinator + per-platform controllers (`live_activities` 2.4.9 / `flutter_foreground_task` 9.2.2) via an additive binder seam; no engine/protocol edits. iOS Widget Extension + per-flavor App Group + `pod install` validated (build OK); iOS `beginBackgroundTask` grace landed (T032). `dart analyze lib test` 0 · `flutter test` 285 passed (18 new). Deferred (non-blocking): two-device on-device smoke (T040). See [`changelog.md`](changelog.md).
- **Was**: ⬜ Not started
- **Branch**: `011-background-transfer`
- **Depends on**: #002 (engine), #004/#005 (send/receive flows)
- **Design**: progress surfaces while the app is backgrounded — **iOS Live Activity** (Dynamic Island + lock-screen) and an **Android foreground-service notification**. Pull the latest screens from the **claude_design `SafeSend`** project (updated 2026-06-26) via `DesignSync` and distil into [`ui-design-context.md`](ui-design-context.md) before building.
- **Scope**:
  - Keep an in-flight transfer **running when the app is backgrounded** on both platforms (the WebRTC data channel + file streaming must survive backgrounding within OS limits).
  - **iOS**: a **Live Activity** showing live progress (%, speed/ETA, file) on the lock screen + Dynamic Island; background execution strategy for the transfer (background tasks / audio-free keep-alive — evaluate at research; document the OS time limits).
  - **Android**: a **foreground Service** with an ongoing progress notification so the OS won't kill the transfer; notification actions (cancel) wired to the transfer state machine.
  - Drive both from the existing #002 transfer-state-machine stream (no parallel progress model, Constitution VIII); update on the same snapshots.
  - Resume/handle return-to-foreground cleanly; surface a clear failure if the OS suspends the transfer.
- **New packages**: iOS Live Activity needs a native widget extension (ActivityKit) + a bridge (e.g. `live_activities`); Android foreground service (e.g. `flutter_foreground_task`) — **verify on pub.dev at plan time** (Constitution XV).
- **Out of scope**: push-initiated background wake (no server); transfers that survive full app termination.

### Spec #012: Home Screen Completion

- **Status**: ✅ **Merged** (PR #12, merge commit `f899caf`) — branch `012-home-completion` (2026-06-29). Home placeholder replaced with real data from the #006 history store **only** (no media library / new permission — FR-016): reactive `HomeCubit` + pure `HomeDashboardBuilder` drive the hero/stats/recent-media; real `Image.file` photo thumbnails (icon fallback), video tiles (frame → #013); new parametrized `AppRoutes.homeSeeAll` See-all screen; item tap → History detail (#006). Additive + feature-local; no new packages / engine / schema edits. `dart analyze lib test` 0 · `flutter test` 318 passed (33 new). Deferred: on-device UI pass (no two-device smoke — local feature). See [`changelog.md`](changelog.md).
- **Branch**: `012-home-completion`
- **Depends on**: #006 (history data), #001 (Home shell), #013 may follow (viewers open from Home)
- **Design**: Screen 01 **Trang chủ (home)** — hero stat card, 3 StatTiles (Ảnh/Video/File), Recent photos / videos / files grids, "Xem tất cả (See all)" per section. Pull the **updated** Home + See-all screens from claude_design via `DesignSync`.
- **Scope**:
  - Replace the remaining **hardcoded/mock Home content** (placeholder images, stat numbers) with **real data** from the transfer history + on-device media (define the data source at clarify — history records vs. a media index).
  - Build the **"Xem tất cả / See all"** destination screens for each section (Recent photos, Recent videos, Recent files) — full lists with their own routes.
  - Wire the hero stat card (Đã gửi / Đã nhận totals, "N transfers this month") to real aggregates.
  - Empty states for a fresh install (no history yet).
- **New packages**: possibly a media/thumbnail package if reading the device library — verify at plan.
- **Out of scope**: editing/deleting media on the device.

### Spec #013: In-App File Viewers

- **Status**: ✅ **Merged** (PR #13, merge commit `e452bc4`) — branch `013-in-app-viewers` (2026-06-29). Tapping a **received** known-type file (History detail, Receive-complete list, Home recent / See-all grids) opens an in-app viewer; a core viewer-kind resolver splits the #012 `FileCategory` `files` bucket into audio/PDF/text/code → routes image→`InteractiveViewer`, video/audio→one shared media player, PDF→PDFium doc viewer, text/code→`SelectableText` (≈1 MB cap, truncated-with-notice). Unsupported types + **sent** files fall back to existing `open_filex`/`share_plus` (no dead end). Real video thumbnails replace the #012 placeholder in Home/See-all media grids (on-disk LRU cache, path+mtime key, lazy, bounded memory). All on-device (works in airplane mode), reuses on-disk paths (no re-copy), additive — **no engine/signaling/transport/protocol/DB-schema edits**. `dart analyze lib test` 0 · `flutter test` **357 passed** (39 new). Native: first `pod install` since #007 (`pdfrx`/`video_player`/thumbnail pods); 2 device-run DI fixes folded in. Deferred (device): on-device viewer pass on 2 devices. See [`changelog.md`](changelog.md).
- **Branch**: `013-in-app-viewers`
- **Depends on**: #005/#006 (received files + history), #012 (open from Home), #003-#005 file paths
- **Design**: tapping a known-type item (Home recent, History detail, Receive complete) opens an **in-app viewer** instead of (or before) the OS share/open sheet. Pull the viewer screens from claude_design.
- **Scope**:
  - **In-app preview** for fixed/known types: **image**, **video**, **audio**, and **basic documents** (PDF + text/code; Office docx/xlsx/pptx out of scope → OS open/share — confirmed at clarify).
  - Reached from History detail, the Receive-complete file list, and Home recent grids; falls back to the existing `open_filex`/share for unsupported types.
  - Streamed/efficient loading (don't load huge media fully into memory); respect the streamed-I/O principle.
- **New packages**: `video_player` ^2.11.1 (shared video+audio player), `pdfrx` ^2.4.4 (PDFium PDF viewer; flutter `>=3.41.0` exact floor), `video_thumbnail_plus` ^0.0.2 (first-frame thumbnails — fork of the abandoned `video_thumbnail`). Image + text viewers use Flutter built-ins (no package).
- **Out of scope**: editing files; thumbnail generation for arbitrary formats; in-app Office rendering; streaming remote/URL media.

### Spec #014: Polish & v1.0 Release

- **Status**: 🟡 **Next**
- **Branch**: `014-polish-v1-release`
- **Depends on**: All
- **Scope**:
  - **Resilience sweep**: dropped connection / mid-transfer disconnect / app-backgrounded mid-transfer / NAT-traversal failure → TURN fallback path, all surfaced with clear copy + retry.
  - **Accessibility**: VoiceOver/TalkBack, Dynamic Type, Reduced Motion (radar animation).
  - **Haptics** on connect/complete/fail; **dark-mode sweep** of every screen.
  - **Performance**: large-file (multi-GB) + many-file throughput, memory ceiling (streamed I/O verified), cold start.
  - **Security pass**: confirm signaling carries no bytes, DataChannel DTLS verified, no plaintext leaks in logs, TURN-only-as-encrypted-relay documented.
  - **Code quality**: `flutter analyze` = 0, dead code, unused deps.
  - **Build config**: obfuscation, signing, provisioning; **App Store + Play** metadata, screenshots, privacy policy / data-safety form.
- **New packages**: none expected.

---

## Timeline (1 Developer)

| Spec | Name | Estimate | Cumulative |
|---|---|---|---|
| #001 | Project Foundation & Navigation | 1 week | Week 1 |
| #002 | WebRTC Transport & Transfer Protocol Core | 2 weeks | Week 2-3 |
| #003 | Signaling Server + 6-Digit Key Pairing | 1.5 weeks | Week 4-5 |
| #004 | Send Flow | 1 week | Week 5-6 |
| #005 | Receive Flow | 1 week | Week 6-7 |
| #006 | History | 1 week | Week 7-8 |
| #007 | QR Connect | 0.5 weeks | Week 8 |
| #008 | Share Link | 1 week | Week 8-9 |
| #009 | Nearby Radar | 1.5 weeks | Week 9-11 |
| #010 | Settings & Preferences | 1 week | Week 11-12 |
| #011 | Background Transfer (Live Activity / FG Service) | 1.5 weeks | Week 12-14 |
| #012 | Home Screen Completion (real data + See-all) | 1 week | Week 14-15 |
| #013 | In-App File Viewers | 1 week | Week 15-16 |
| #014 | Polish & v1.0 Release | 2 weeks | Week 16-18 |
| | **Total** | **~18 weeks** | |

### ⭐ MVP Checkpoint: After Spec #005

App can: pair two devices via a 6-digit key, send any-type files (no size limit) directly over WebRTC, receive + save them, with live progress. → Start dogfooding on two physical devices.

---

## Optimal Order (1 Developer)

#001 → #002 → #003 → #004 + #005 (#005 follows #004 closely; share the pairing primitives) → ⭐ MVP → #006 → #007 → #008 → #009 → #010 → #011 → #012 → #013 → #014

The four connection methods are deliberately sequenced **6-digit (core) → QR → link → radar** by increasing platform-integration cost; each reuses the same signaling rendezvous from #003.

The three v1.0 feature-completion specs (**#011 Background Transfer · #012 Home Completion · #013 In-App Viewers**) land **before** the **#014 Polish & Release** sweep. They are largely independent, but #012 (Home) and #013 (Viewers) pair naturally (Home recent grids open into the viewers), and #011 (Background) is the heaviest native lift — sequence it first while energy is high, or last if device-testing background behavior is gating.

---

## Post-v1.0 Features (v1.1+)

- Resume interrupted transfers.
- Saved / favorite peers + trusted auto-accept.
- Transfer encryption passphrase (extra app-layer key on top of DTLS).
- Folder transfer (preserve directory structure).
- Clipboard / text snippet send.
- Desktop (macOS / Windows) targets.
- Web receiver (browser WebRTC, no install).
- Self-hosting bundle (one-click signaling + TURN docker).
