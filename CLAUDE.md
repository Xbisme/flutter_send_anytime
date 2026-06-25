<!-- SPECKIT START -->
# Safe Send — Agent Context

Active feature: **#005 Receive Flow (Nhận)** ✅ IMPLEMENTED ⭐ MVP (branch `005-receive-flow`). #001 ✅ · #002 ✅ · #003 ✅ merged · #004 ✅ · #005 ✅ implemented. **Next: #006 History.**
Current plan: [specs/005-receive-flow/plan.md](specs/005-receive-flow/plan.md)
Spec: [specs/005-receive-flow/spec.md](specs/005-receive-flow/spec.md)

## Project meta (read these first)
- Constitution (authoritative, 15 principles): [.specify/memory/constitution.md](.specify/memory/constitution.md)
- Roadmap: [.claude/claude-app/sdd-roadmap.md](.claude/claude-app/sdd-roadmap.md)
- Project context: [.claude/claude-app/project-context.md](.claude/claude-app/project-context.md)
- UI design source of truth: [.claude/claude-app/ui-design-context.md](.claude/claude-app/ui-design-context.md)
- Dev workflow: [.claude/claude-app/dev-workflow.md](.claude/claude-app/dev-workflow.md)

## What Safe Send is
Cross-platform (iOS + Android, Flutter) P2P file-sharing app over WebRTC — **no intermediary server holds the data**. Surfaces: Gửi (Send) / Nhận (Receive) / Lịch sử (History). Pairing: 6-digit / QR / nearby radar / share link. Fixed light & dark palette.

## Stack (current — #001)
- Flutter (latest stable) / Dart 3.5+; Clean Architecture + feature-first; BLoC (`flutter_bloc` 9.1.1, 4-state freezed); DI `get_it` 9.2.1 + `injectable` 3.0.0; router `go_router` 17.3.0 (StatefulShellRoute, scheme `safesend://`).
- UI: fixed design tokens (Sora + JetBrains Mono bundled fonts), `lucide_icons_flutter` 3.1.14+2, `flutter_svg` 2.3.0, `toastification` 3.2.0, splash via `flutter_native_splash` 2.4.8.
- Codegen: `freezed` 3.2.5 / `json_serializable` 6.14.0 / `build_runner` 2.15.0. i18n: ARB + `intl` 0.20.2 (VI primary, EN; VI fallback). Lint: `very_good_analysis` 10.3.0 + `bloc_lint`. Test: `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5.
- Target: iOS 13.0+ / Android 8.0 (API 26)+. Flavors: dev (`app.safesend.dev`) / prod (`app.safesend`). No networking/persistence in #001.
- **#002 engine (merged)**: `flutter_webrtc` 1.5.2 (RTCPeerConnection + RTCDataChannel, data-channel-only → no camera/mic), `crypto` 3.0.7 (streamed SHA-256), `uuid` 4.5.3. Engine lives in `core/{domain/transfer,services/signaling,services/transport,constants}`; abstract `SignalingChannel` (offer/answer/ice/bye, 1:1 seam) + in-process loopback for tests; versioned opcode-framed protocol (16 KiB chunks, backpressure via `bufferedAmount`); quarantine→atomic-rename, per-file hash gates completion; single transfer state machine `idle→connecting→handshaking→transferring→done|failed|cancelled`. Signaling carries metadata only.
- **#003 signaling/pairing (merged)**: `web_socket_channel` 3.0.3 (app); `server/` relay (Dart `shelf` 1.4.2 + `shelf_web_socket` 3.0.0); pure-Dart shared protocol pkg `packages/safesend_signaling/` (versioned JSON frames, one source of truth for app+server). App side: `SignalingClient` (owns ws, drives 6-digit pairing, demuxes frames) **produces** `WebSocketSignalingChannel implements SignalingChannel` (#002 seam reused unchanged); `features/pairing/` repo+use-cases+4-state `PairingCubit` + **dev-flavor-only** debug page. Code = full `000000`–`999999`, 5-min TTL, sender-generated, per-connection join rate-limit. STUN = Google public per flavor; TURN = documented empty hook (#011). `AppConfig.signalingEndpoint` per flavor (dev `ws://`, prod `wss://`). Relay in-memory only, no bytes, logs phase/error-type only. `AppFailure` variants: signalingUnreachable/signalingTimeout/roomExpired/roomFull/invalidCode/rateLimited. 2-device smoke deferred.
- **#004 send flow (implemented)**: new `file_picker` 11.0.2 (any-type multi-select; document picker → **no runtime permission**; `permission_handler` deferred to #005). UI/wiring only over #002/#003. `features/send/` (selection + transfer cubits, pages 02/05/06, use cases) + production **Connect screen** in `features/pairing/presentation/connect/` (Mã 6 số tab functional; QR/Gần đây stubbed; role-parameterized, reused by #005). **Two additive engine seams**: `TransferEngine.startSendOnTransport({transport, session})` (reuse the pairing-opened channel — no second handshake; `startSend` refactored to share `_runSend`) + `PairingRepository.takeTransport()` (ownership handoff, no double-close). Cross-feature handoff via `core/router` composition + `go_router` `extra` of core types (`List<FileSource>`/`DataTransport`) — features never import each other. Peer shown as **generic label** until #010. New routes `AppRoutes.connect` + `sendProgress`. New ARB: send/connect copy + transferRejected/connectionLost/fileReadFailed messages. 2-device send smoke deferred.

## Key rules (see constitution for full list)
- `lib/core/` MUST NOT import `lib/features/`. Shared widget library lives in `core/presentation/`.
- BLoC 4-state freezed; inject Use Cases (not repos) into Cubits; page-scoped providers.
- All visual props from design tokens (semantic aliases) — never hardcode hex. Numeric/technical text uses mono + tabular figures.
- `AppToast` for messages (never raw ScaffoldMessenger); `AppLogger` for logs (never print). `AppRoutes` constants; `context.go/push/pop` only.
- All UI strings via ARB (VI primary). Pre-commit: `dart format` · `flutter analyze` (0) · `flutter test` · `bloc lint` (0). Package versions: fetch from pub.dev, never guess (Constitution XV).
<!-- SPECKIT END -->
