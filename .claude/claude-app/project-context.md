# Safe Send — Project Context

> Last updated: 2026-06-24 (Project bootstrapped — Speckit scaffolding in place; no specs started. Roadmap drafted.)
> **Mục đích**: Snapshot tối thiểu để LLM/người đọc bắt đầu một session làm việc — context hiện tại, focus, links. Không chứa ship history hay alignment decisions.
>
> **Đọc file nào khi nào**:
> - Bắt đầu session mới hoặc onboarding → file này (snapshot) + [`CLAUDE.md`](../../CLAUDE.md) (day-to-day reference).
> - Chuẩn bị họp spec mới → file này (current focus) + [`sdd-roadmap.md`](sdd-roadmap.md) (planning + dependency cho spec sắp làm).
> - Làm phần **giao diện** của bất kỳ spec nào → [`ui-design-context.md`](ui-design-context.md) (screens, tokens, components, navigation IA) — pull bản gốc từ claude_design MCP.
> - Cần hiểu vì sao spec X ra đời với scope Y → [`decisions/`](decisions/) (alignment per spec).
> - Cần biết spec nào đã ship khi nào → [`changelog.md`](changelog.md).

## Snapshot

- **App name**: Safe Send.
- **Product**: Cross-platform (iOS + Android, Flutter) **peer-to-peer file-sharing** app — a "Send Anywhere"-style product. Any file type, **no size limit**, transferred **device-to-device over WebRTC** with **no intermediary server holding the data**.
- **Platforms**: iOS + Android (Flutter). Desktop/web are post-v1.0.
- **Core surfaces**: **Gửi (Send)** · **Nhận (Receive)** · **Lịch sử (History)**. **Navigation**: bottom nav = 3 tabs **Trang chủ (Home) / Lịch sử (History) / Cài đặt (Settings)**; **Gửi + Nhận are Home-screen actions** that push nav-less flows (not tabs). 8 designed screens — see [`ui-design-context.md`](ui-design-context.md).
- **Connection methods** (how two devices pair): **6-digit key** (core), **QR**, **nearby radar**, **share link** — all live as tabs/actions of one **Kết nối (Connect)** screen.
- **Theme**: fixed light & dark palette (no scheme picker — only light/dark/system mode). Brand green `#00C853` + teal; fonts **Sora** + **JetBrains Mono**. Tokens imported from claude_design.
- **Design source**: claude_design MCP project `SafeSend` (projectId `a8e27438-935f-4a14-a772-5b1ed908746c`). Full UI context in [`ui-design-context.md`](ui-design-context.md).
- **Communication**: Vietnamese (spoken between user + Claude) · English for code, comments, documentation. Primary in-app UI copy is Vietnamese (Gửi / Nhận / Lịch sử), with English l10n.

## How It Works (one-paragraph mental model)

Two devices agree on a **rendezvous identifier** (a 6-digit code, a QR, a link, or a radar tap). A **lightweight signaling relay** (WebSocket) swaps WebRTC SDP + ICE between them — it **never sees file bytes**. Once ICE completes, a direct DTLS-encrypted `RTCDataChannel` carries the chunked file(s) peer-to-peer. A **TURN** server may relay traffic *encrypted* only when NAT traversal fails (bytes pass through, never stored) — the single documented exception to pure-direct transfer. See the Architecture Primer in [`sdd-roadmap.md`](sdd-roadmap.md).

## Current Focus

- **Latest**: **Spec #004 Send Flow (Gửi)** ✅ **IMPLEMENTED** on branch `004-send-flow` (2026-06-24). First user-facing transfer: pick files (any type, multi-select via `file_picker` 11.0.2 — no runtime permission; `permission_handler` deferred to #005) → production **Connect hub** (6-digit tab functional, radar + countdown; QR/Gần đây stubbed; role-parameterized for #005) → **progress** (%/speed/ETA, driven by the #002 snapshot stream) → **complete** / typed retryable **failure**. Engine reused via two additive seams — `TransferEngine.startSendOnTransport` (no second handshake) + `PairingRepository.takeTransport` (ownership handoff). `features/send` + `features/pairing` exchange core-typed payloads via `core/router` + `go_router` extra (never import each other, Constitution XI). Peer = generic label until #010; retry preserves selection (FR-025a). **`dart analyze lib test` = 0 · `flutter test` = 107 passed · `dart format` clean.** Deferred (device-only): two-device send smoke (T041). See [changelog.md](changelog.md) + [specs/004-send-flow/](../../specs/004-send-flow/). **Next spec: #005 Receive Flow ⭐ MVP.**
- **Prior**: **Spec #003 Signaling Server & 6-Digit Key Pairing** ✅ **IMPLEMENTED** on branch `003-signaling-6digit` (2026-06-24). The rendezvous layer: sender-generated 6-digit code (full `000000`–`999999`, 5-min TTL) → two devices join one room on a self-hostable `shelf` WebSocket relay (`server/`, in-memory, relays SDP/ICE only, never file bytes, per-connection join rate limiting) → `WebSocketSignalingChannel implements SignalingChannel` (the #002 seam, reused unchanged) opens the direct WebRTC channel. New pure-Dart shared protocol pkg `packages/safesend_signaling/` (versioned JSON frames, single source of truth for app+server); `features/pairing/` repo + use cases + 4-state `PairingCubit` + **dev-flavor-only debug screen** (FR-021a). `AppConfig.signalingEndpoint` per flavor + Google STUN; TURN = documented empty hook (#011). **`dart analyze` = 0 across all 3 packages · 133 tests pass (app 84 / shared 28 / server 21) · `dart format` clean.** Deferred (device-only): two-physical-device smoke (T055) + iOS ATS in the on-device build. See [changelog.md](changelog.md) + [specs/003-signaling-6digit/](../../specs/003-signaling-6digit/). **Next spec: #004 Send Flow.**
- **Prior**: **Spec #002 WebRTC Transport & Transfer Protocol Core** ✅ **IMPLEMENTED** on branch `002-webrtc-transport-core` (2026-06-24). Engine-only (no UI): direct P2P transfer over encrypted WebRTC `RTCDataChannel`, versioned opcode-framed protocol, single transfer state machine as a broadcast stream, sequential multi-file + fail-fast, per-file streamed SHA-256, quarantine→atomic-rename (non-overwriting), sender backpressure (bounded memory), manifest path-traversal rejection. Abstract `SignalingChannel`/`PeerConnector`/`DataTransport` + in-process **loopback** make it fully testable in CI; real `WebRtcPeerConnector` (flutter_webrtc 1.5.2) wired, validated only by the deferred two-device smoke. **`dart analyze lib test` = 0 · `flutter test` = 63 passed · `dart format` clean.** Deferred (device-only): iOS pod install / Android release config (T002 tail) + two-device smoke (T050). See [changelog.md](changelog.md) + [specs/002-webrtc-transport-core/](../../specs/002-webrtc-transport-core/). **Next spec: #003.**
- **Prior**: **Spec #001 Project Foundation & Navigation** ✅ **IMPLEMENTED** on branch `001-project-foundation` (2026-06-24). Flutter app shell built: 3-tab nav (Trang chủ/Lịch sử/Cài đặt) via `go_router` StatefulShellRoute; Gửi/Nhận as Home actions → nav-less placeholder flows; fixed light/dark design-token system (Sora + JetBrains Mono bundled, `AppColors` ThemeExtension); shared widget library in `core/presentation/`; `Result`/`AppFailure`/4-state `AppCubit`; DI (get_it+injectable); `HomeCubit` + static mock dashboard (swap seam for #006); l10n VI-primary + EN + VI fallback; branded splash. **`dart analyze lib test` = 0 issues · `flutter test` = 27 passed · `dart format` clean.** dev/prod flavors fully wired on both platforms (Android `productFlavors`; iOS build configs + `dev`/`prod` schemes via `ios/setup_flavors.rb`, verified with `xcodebuild -list`). Deferred (device-only): on-device build (T067), quickstart smoke (T068), bloc_tools CLI (T005). See [changelog.md](changelog.md) + [specs/001-project-foundation/](../../specs/001-project-foundation/).
- **Latest**: **Spec #005 Receive Flow (Nhận)** ✅ **IMPLEMENTED** on branch `005-receive-flow` (2026-06-25). ⭐ MVP loop closed in code: enter 6-digit code (Connect hub receiver branch + `CodeInput`) → incoming-transfer accept/reject prompt → stream to app sandbox → live Progress/Complete (shared, role-parameterized, lifted to `core/`) with per-file Open + Share-all; partial outcome on mid-transfer drop (FR-013a). Additive seam `TransferEngine.startReceiveOnTransport`; `permission_handler` still deferred (app-sandbox save). **`dart analyze lib test` = 0 · `flutter test` = 128 passed · `dart format` clean.** Deferred: two-device receive smoke (T034). See [changelog.md](changelog.md) + [specs/005-receive-flow/](../../specs/005-receive-flow/). **Next spec: #006 History.**
- **Latest**: **Spec #006 Lịch sử (History)** ✅ **IMPLEMENTED** on branch `006-history` (2026-06-25). drift (SQLite) persistence in `core/data/` + `TransferHistoryRepository` (core, shared by Send/Receive/History/Home); one additive `RecordTransferUseCase` writes a record on each agreed-and-started terminal transfer (pairing-stage failures excluded, FR-001). Lịch sử tab = day-grouped list + search/direction/date filter + detail; actions re-send (all-or-nothing) / open / share / delete / clear-all (record-only, never deletes files). Home recent backfilled from the same store (FR-008 seam). **`dart analyze lib test` = 0 · `flutter test` = 167 passed · `dart format` clean.** Packages: `drift` 2.34.0 + `drift_flutter` 0.3.0 + `drift_dev` pinned 2.34.0 (2.34.1 needs analyzer ^13, conflicts with freezed 3.2.5). Deferred (device-only): on-device quickstart + first `pod install`. See [changelog.md](changelog.md) + [specs/006-history/](../../specs/006-history/). **Next spec: #007 QR Connect.**
- **Next spec**: **#007 QR Connect** — render a QR encoding the rendezvous id (Connect "QR" tab) + a Receive scan entry → auto-join the room. Reuses the #003 signaling rendezvous.
- **Toolchain note**: `flutter analyze` crashes on this detached-HEAD Flutter checkout (AOT analysis-server snapshot) — use **`dart analyze`** (gate-equivalent, same engine + `analysis_options.yaml`).
- **Active blockers**: none. (Decisions to confirm at #003 planning: signaling-server language — Dart `shelf` vs Node — and hosting target for dev/prod. Bundle ids `app.safesend` / `app.safesend.dev` proposed, user-confirmable before store setup.)

## Spec Status

| # | Name | Status | Branch / merge |
|---|---|---|---|
| 001 | Project Foundation & Navigation | ✅ Implemented (code) · native/device deferred | `001-project-foundation` |
| 002 | WebRTC Transport & Transfer Protocol Core | ✅ Implemented (code) · 2-device smoke deferred | `002-webrtc-transport-core` |
| 003 | Signaling Server + 6-Digit Key Pairing | ✅ Implemented (code) · 2-device smoke deferred | `003-signaling-6digit` |
| 004 | Send Flow (Gửi) | ✅ Implemented (code) · 2-device smoke deferred | `004-send-flow` |
| 005 | Receive Flow (Nhận) ⭐ MVP | ✅ Implemented · **device-validated on 2 iPhones** | `005-receive-flow` |
| 006 | Lịch sử (History) | ✅ Implemented (code) · device quickstart deferred | `006-history` |
| 007 | QR Connect | ⬜ Not started | `007-qr-connect` |
| 008 | Share Link | ⬜ Not started | `008-share-link` |
| 009 | Nearby Radar | ⬜ Not started | `009-nearby-radar` |
| 010 | Settings & Preferences | ⬜ Not started | `010-settings` |
| 011 | Polish & v1.0 Release | ⬜ Not started | `011-polish-v1-release` |

For per-spec scope + dependency see [`sdd-roadmap.md`](sdd-roadmap.md). For ship history see [`changelog.md`](changelog.md).

## Tech Stack (planned, concise)

- **Flutter** (latest stable) / **Dart** (latest stable).
- **WebRTC**: `flutter_webrtc` (RTCPeerConnection + RTCDataChannel). `crypto` for chunk/file integrity hashing.
- **Signaling**: `web_socket_channel` client → a lightweight self-hostable relay (Dart `shelf` or Node, lives in `server/`). STUN config + optional TURN fallback (encrypted relay only).
- **State**: `flutter_bloc` (+ `bloc_test`, `bloc_lint`) — BLoC/Cubit, 4-state via freezed sealed classes.
- **DI**: `get_it` + `injectable` + `injectable_generator`.
- **Router**: `go_router` with deep-link skeleton (`safesend://`, activated in #008).
- **Local persistence**: `drift` (SQLite) for transfer history (#006).
- **Connection methods**: `qr_flutter` (render) + `mobile_scanner` (scan) for QR; `app_links` for share-link deep links; `nsd`/`multicast_dns` + `network_info_plus` (and possibly `flutter_blue_plus`) for nearby radar.
- **Files**: `file_picker` (select any type), `receive_sharing_intent` (inbound share), `path_provider` + `share_plus` + `open_filex` (save/open), `permission_handler`.
- **Theme / design system**: bespoke fixed `AppColors` light + dark + semantic token layer ported from claude_design (NO scheme picker). Fonts **Sora** (display/body) + **JetBrains Mono** (codes/values) via `google_fonts`. Icons via `lucide_icons` (Lucide set used in design). `flutter_svg` for brand marks. Theme mode light/dark/system in #010.
- **Codegen**: `freezed` + `json_serializable` + `build_runner`.
- **Utils**: `shared_preferences`, `package_info_plus`, `in_app_review`, `toastification`, `intl`, `uuid`.
- **Linting**: `very_good_analysis` · `bloc_lint`.
- **Testing**: `flutter_test`, `bloc_test`, `mocktail`.
- **Flavors**: `dev` + `prod` (per-flavor signaling endpoint + bundle id).
- **i18n**: Flutter ARB (`lib/l10n/arb/`) — Vietnamese + English.
- **Architecture**: Clean Architecture + MVVM, feature-first folders.

## Architecture Decisions (anchors)

- **Three shared layers** — Pairing/Discovery → Signaling → WebRTC DataChannel transport. All four connection methods converge on the same signaling rendezvous; never fork the transport per method.
- **Signaling carries metadata only** — never file bytes. TURN is the only (encrypted, non-persisted) data-relay fallback and must be documented wherever it appears.
- **Streamed I/O** — files stream from/to disk in chunks; never load a whole file into memory (must survive multi-GB transfers).
- **Transfer state machine is the single source of truth** — `idle → connecting → handshaking → transferring → done/failed/cancelled` (#002), exposed as a stream that drives Send/Receive UI identically.
- **`lib/core/` MUST NOT import `lib/features/`** (use marker interfaces / lifecycle hooks for cross-cutting concerns).
- **BLoC pattern**: Events = plain sealed class, States = freezed; inject Use Cases (not Repos) into Cubits; BlocProvider page-scoped.
- **AppToast** for all user-facing messages; **AppLogger** for all logging — never `print`/`debugPrint`.

## Repo Map (target after #001)

```
lib/
├── app/                      # App root widget + theme wiring (fixed light/dark palette)
├── bootstrap.dart            # Pre-runApp setup (DI, config)
├── main_dev.dart / main_prod.dart
├── core/                     # Shared infra (NO imports from features/)
│   ├── config/               # AppConfig, flavors, signaling endpoint
│   ├── constants/            # Routes, channel keys, asset keys
│   ├── data/                 # drift database + DAOs (history, #006)
│   ├── di/                   # injectable graph
│   ├── domain/               # Result<T>, AppFailure, AppCubit base, transfer entities/enums
│   ├── presentation/         # Shared widget library (PrimaryButton, FileRow, CodeBox, SegmentedTabs, ToggleRow, AppToast…)
│   ├── router/               # go_router shell + deep links
│   ├── services/             # WebRtcService, SignalingClient, TransferEngine, FileService
│   ├── theme/                # AppColors (light+dark) + design tokens (typography/spacing/radius/motion)
│   └── utils/                # AppLogger, formatters
├── features/
│   ├── home/                 # Trang chủ tab — entry + Gửi/Nhận actions (Spec #001 shell)
│   ├── send/                 # Gửi flow → Connect → Progress → Complete (Spec #004)
│   ├── receive/              # Nhận flow → Progress → Complete (Spec #005)
│   ├── history/              # Lịch sử tab (Spec #006)
│   ├── pairing/              # Connect hub: 6-digit / QR / radar / link (#003/#007/#008/#009)
│   └── settings/             # Cài đặt tab (#010)
└── l10n/arb/                 # Vietnamese + English

assets/brand/                 # logomark.svg, logo-wordmark.svg (from claude_design)
server/                       # Lightweight signaling relay (#003) — self-hostable
specs/                        # SDD spec folders (each self-contained)
.claude/claude-app/           # Project meta (this file lives here)
├── project-context.md        # ← you are here
├── sdd-roadmap.md            # spec planning (dependency graph, scope per spec)
├── ui-design-context.md      # UI source of truth (screens, tokens, components, IA)
├── dev-workflow.md           # Speckit workflow conventions
├── changelog.md              # spec ship history (append-only) — create on first merge
└── decisions/                # alignment decisions per spec
```

## References

- **claude_design MCP project `SafeSend`** — the UI/UX source of truth (projectId `a8e27438-935f-4a14-a772-5b1ed908746c`, connector `https://api.anthropic.com/v1/design/mcp`). 8 screens + design-system tokens. Distilled into [`ui-design-context.md`](ui-design-context.md); pull originals via `DesignSync` (auth: `/design-login`).
- **flutter_formly (Authenticator Portal / Secrypt)** (`/Users/ase/Documents/flutter_formly`) — SDD methodology source: `.claude/` structure, Speckit per-spec workflow, Clean Architecture + BLoC conventions, design-token discipline. **Follow the methodology + technical patterns, NOT the product or UI/UX.**

## Key Documents

| File | Vai trò |
|---|---|
| [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) | **Constitution v1.0.0** — 15 non-negotiable principles (authoritative; conflicts → constitution wins) |
| [`CLAUDE.md`](../../CLAUDE.md) | Quick-reference for codebase day-to-day (created/expanded during #001) |
| [`sdd-roadmap.md`](sdd-roadmap.md) | Spec planning (dependency graph, scope per spec, timeline, architecture primer) |
| [`ui-design-context.md`](ui-design-context.md) | **UI source of truth** — screens, design tokens, components, navigation IA |
| [`dev-workflow.md`](dev-workflow.md) | Speckit workflow conventions + per-spec hygiene + commit style |
| [`changelog.md`](changelog.md) | Spec ship history (append-only) — created at first merge |
| [`decisions/`](decisions/) | Alignment decisions per spec |
