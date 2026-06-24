# Implementation Plan: Send Flow (Gửi)

**Branch**: `004-send-flow` | **Date**: 2026-06-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-send-flow/spec.md`

## Summary

Build the first user-facing transfer experience: a sender picks files, gets a 6-digit code, and — once a peer joins — ships the files directly over the WebRTC channel already built in #002/#003, watching live progress to a success or a clearly-surfaced, retryable failure. This feature is the **UI + orchestration layer** over existing engines; it introduces no new transport or pairing mechanics.

Four visual screens from the design (02 Gửi file → 03 Kết nối → 05 Đang truyền → 06 Hoàn tất) realized as:

1. **File selection** (`features/send`) — `file_picker` (any type, multi-select) → a tray of `FileSource`s with per-file + total size; block continue when empty.
2. **Connect / pairing hub** (`features/pairing`) — the **production** Connect screen replacing the dev-only debug page: a functional "Mã 6 số" tab (radar visual, `CodeBox` row, live TTL countdown) plus visible-but-disabled QR / Gần đây tabs and a stubbed "Chia sẻ link mời". Generic and **role-parameterized** so #005 reuses it for the receiver. On a successful pairing it returns the open `DataTransport` to its caller.
3. **Progress + Complete** (`features/send`) — one route driven by the **#002 transfer state machine stream** (`TransferEngine.snapshots`): "ĐANG GỬI" badge, %/bar/speed/ETA/current-file while transferring; a celebratory summary on `done`; a typed, retryable error on failure; a confirm-gated Cancel.

**Two seam changes** (the only edits to merged engine code, both additive):

- **`TransferEngine.startSendOnTransport({transport, session})`** — a sender entry point that adopts an **already-open** `DataTransport` and runs the existing send body from `handshaking` onward (skips `_establish`). The current `startSend` is refactored to `_establish` + the shared body, so loopback tests stay green. This realizes the pre-spec decision to **reuse the channel the pairing layer already opened** rather than performing a second WebRTC handshake.
- **`PairingRepository.takeTransport()`** — transfers ownership of the connected `DataTransport` out of the pairing layer (the repo no longer closes it on dispose once taken). The Connect screen calls this on `connected` and hands the transport to the send Progress route.

Everything fallible returns `Result<T>`; cubits `.fold`; user copy comes from ARB (Vietnamese primary) via an `AppFailure` → message mapping; numeric values use the mono/tabular tokens. Validated by widget + bloc tests and a loopback round-trip of the new engine entry point; the two-physical-device smoke is the deferred manual task (T0xx).

## Technical Context

**Language/Version**: Dart (SDK `^3.11.0`) / Flutter (latest stable 3.x). App only — no server/shared-package changes this feature.

**Primary Dependencies** (latest stable verified on pub.dev 2026-06-24 — Constitution XV):

- **Already present**: `flutter_webrtc` 1.5.2, `crypto` 3.0.7, `uuid` 4.5.3, `flutter_bloc` 9.1.1, `go_router` 17.3.0, `get_it` 9.2.1, `injectable` 3.0.0, `web_socket_channel` 3.0.3, `intl` 0.20.2, `lucide_icons_flutter` 3.1.14, `safesend_signaling` (path).
- **New**: `file_picker` **11.0.2** — system document picker for any-type multi-select. Cross-platform; on iOS/Android it uses `UIDocumentPickerViewController` / Storage Access Framework, which **require no runtime storage permission** for arbitrary files. Picked files are exposed as readable on-disk paths (iOS copies into the app cache dir), so `DiskFileSource(path)` streams them without buffering whole files in memory.
- **Deliberately NOT added**: `permission_handler` (roadmap-listed for #004) is **deferred to #005**. The any-file document-picker path triggers no runtime permission dialog, so there is no "denied" branch to handle on the send side; saving / photo-library access on the receive side is where it is actually needed. (Constitution XIII YAGNI, XV no unjustified deps.)

**Storage**: None new. Files are read (streamed) from their picked paths; nothing is persisted (history is #006).

**Testing**: `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5. New coverage: `SendSelectionCubit` (add/remove/total/empty-guard), `SendTransferCubit` (snapshot→state mapping, terminal transitions, cancel), the production Connect screen widget (code display, countdown, failure→retry, connected→returns transport), the file-selection and progress widget renders, and a **loopback round-trip of `startSendOnTransport`** (two engines over a paired loopback `DataTransport`). Command: `very_good test --test-randomize-ordering-seed random` (local gate-equivalent: `dart test` / `flutter test`).

**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+ (unchanged). No new pods/entitlements (document picker needs none).

**Project Type**: Mobile app (Flutter). Feature work in `lib/features/{send,pairing}` + small additive seams in `lib/core/services/transport` and `lib/features/pairing/{domain,data}`.

**Performance Goals**: Selection → shareable code in < 30 s excluding file browsing (SC-001). Streamed I/O so memory does not scale with file size (SC-003); 16 KiB chunking + backpressure already enforced by the engine. Progress UI updates continuously from the snapshot stream (SC-005).

**Constraints**: No file bytes over signaling (reused engine guarantee); logs carry phase/error-type only (Constitution I/II); `lib/core/` MUST NOT import `lib/features/`; `features/send` and `features/pairing` MUST NOT import each other's internals — they are composed by `core/router` and exchange **core-typed** payloads (`List<FileSource>`, `DataTransport`) via `go_router` navigation `extra`/pop-value; inject Use Cases (not repos) into Cubits; all strings via ARB; reduce-motion disables the radar + spinner; bottom nav hidden on every flow screen.

**Scale/Scope**: Single peer per send; single active send at a time; multi-file sequential (engine). ~14–18 new/changed app files: `features/send/{domain/usecases,presentation/cubit,presentation/pages,presentation/widgets}`, the production `features/pairing/presentation/connect/*` (+ shared pairing widgets), `core/services/file/*` (file picker service), two additive engine/repository seam methods, `core/constants/app_routes.dart` additions, router wiring, and new ARB strings (send + connect copy, send-failure messages).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | How this feature complies |
|---|---|---|
| I. Privacy-First P2P | ✅ | Reuses the engine/relay unchanged; no bytes over signaling; codes stay single-use/TTL'd (#003). New code logs only phase/error-type — never file names, paths, peer ids, IPs, or SDP/ICE. |
| II. Direct Transfer & Data Minimization | ✅ | `DiskFileSource.openRead()` streams; engine chunks 16 KiB with backpressure — no whole-file buffering even for multi-GB. Nothing persisted. file_picker's temp copy is on-disk, bounded. |
| III. BLoC-Driven State (4-state) | ✅ | `SendSelectionCubit : AppCubit<SendSelection>`, `SendTransferCubit : AppCubit<SendTransferView>`, reused `PairingCubit`. Transfer progress is a **stream derived from the engine's state machine** (Principle VIII), not ad-hoc setState. Nav/dialogs/toasts via `BlocListener`. Cubits closed page-scoped. |
| IV. Code Quality & Dart Safety | ✅ | very_good_analysis 0 warnings; explicit types; freezed immutable states; self-documenting. |
| V. Result\<T\> Error Handling | ✅ | `PickFilesUseCase`, `StartSendUseCase`, file service return `Result<T>`; cubits `.fold` → loaded/error; no try/catch in cubits; user text from `AppFailure` mapping. |
| VI. Design System & Theming | ✅ | Reuses `core/presentation` shared widgets (CodeBox, FileRow/FileChip, SegmentedTabs, Primary/Secondary/DangerButton, AppToast, FlowAppBar); CTA = pill gradient, Cancel = DangerButton; tokens only (no hex); reduce-motion disables radar + spinner; flow hides bottom nav. New reusable bits (ProgressBar, radar pulse, file-type chip color map) land in `core/presentation` if not already present. |
| VII. Cross-Platform Native Integration | ✅ | file_picker works on both; no runtime permission needed for the document picker (graceful: a cancelled pick simply yields no change). Haptics on connect/complete/fail. Reduce-motion + screen-reader labels honored. |
| VIII. Transport & Signaling Architecture | ✅ | UI is driven by the **single** transfer state machine stream; no parallel progress notion. `startSendOnTransport` reuses the **established** transport (one channel, no second handshake); SignalingChannel seam and per-flavor config untouched. |
| IX. Transfer Reliability & Integrity | ✅ | "Complete" gated by the engine's per-file hash; interruptions (decline, connection-lost, file-read-fail) surface as typed, retryable `AppFailure`s; confirmed cancel tears down the connection and releases handles. |
| X. go_router Navigation | ✅ | New `AppRoutes.connect` + `AppRoutes.sendProgress` constants; `context.push/pop` only; flow routes use `parentNavigatorKey: rootKey` to hide the bottom nav; Connect returns a typed pop-value. No deep links here. |
| XI. Feature-First Modularity | ✅ | `core/` imports no features; `features/send` and `features/pairing` do **not** import each other — `core/router` composes them and they exchange core-typed payloads via navigation. Cubits depend on Use Cases, not repos; no repo→repo. |
| XII. Testing Discipline | ✅ | bloc_test for both new cubits; widget tests for selection, Connect, progress/complete; loopback round-trip for `startSendOnTransport`. Two-physical-device smoke tracked as deferred in tasks.md banner. |
| XIII. Simplicity & YAGNI | ✅ | Only `file_picker` added; permission_handler deferred; per-stage cubits (no mega flow-cubit); no resume/trusted-peer. |
| XIV. Internationalization | ✅ | All copy in ARB (VI primary, EN); `AppFailure` → localized message (extend the existing pairing mapper / add a send mapper); sizes/speed/ETA via locale-aware `intl` formatters with mono tabular figures. |
| XV. Dependency Hygiene | ✅ | file_picker 11.0.2 verified on pub.dev 2026-06-24; caret constraint; `pubspec.lock` committed; no native pods → no `Podfile.lock` churn. |

**Result**: PASS — no violations. Complexity Tracking table omitted (nothing to justify).

## Project Structure

### Documentation (this feature)

```text
specs/004-send-flow/
├── plan.md              # This file
├── research.md          # Phase 0 — decisions (seam, picker, permissions, peer label, formatters)
├── data-model.md        # Phase 1 — selection / transfer-view / failure entities + state mapping
├── quickstart.md        # Phase 1 — how to run, test, and demo the send flow
├── contracts/
│   ├── send-flow-contract.md      # Cubits, use cases, navigation + handoff model
│   └── transfer-engine-seam.md    # startSendOnTransport + PairingRepository.takeTransport
├── checklists/
│   └── requirements.md  # (from /speckit.specify)
└── tasks.md             # Phase 2 — /speckit.tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_routes.dart                 # + connect, sendProgress
│   ├── services/
│   │   ├── file/
│   │   │   ├── file_picker_service.dart     # abstract: pickFiles() -> Result<List<FileSource>>
│   │   │   └── file_picker_service_impl.dart # file_picker 11 → DiskFileSource list
│   │   └── transport/
│   │       └── transfer_engine.dart         # + startSendOnTransport(...) (refactor startSend)
│   ├── presentation/
│   │   └── transfer/                         # reusable bits if not already present:
│   │       ├── progress_bar.dart             #   gradient ProgressBar
│   │       └── file_type_color.dart          #   ext → chip colors (design table)
│   └── router/app_router.dart               # wire connect + send flow routes
├── features/
│   ├── send/
│   │   ├── domain/
│   │   │   ├── models/send_selection.dart    # selected files + totals (freezed)
│   │   │   └── usecases/
│   │   │       ├── pick_files_usecase.dart    # → FilePickerService
│   │   │       └── start_send_usecase.dart    # build TransferSession + startSendOnTransport
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── send_selection_cubit.dart  # AppCubit<SendSelection>
│   │       │   └── send_transfer_cubit.dart   # AppCubit<SendTransferView> (snapshot stream)
│   │       ├── pages/
│   │       │   ├── send_selection_page.dart   # Screen 02 (replaces placeholder send_page.dart)
│   │       │   └── send_transfer_page.dart    # Screen 05 + 06 (progress / complete / failure)
│   │       └── widgets/                       # selection tray, progress header, complete summary
│   └── pairing/
│       └── presentation/
│           ├── connect/
│           │   ├── connect_page.dart          # Screen 03 production hub (role-parameterized)
│           │   ├── connect_request.dart       # { role } arg
│           │   ├── connect_result.dart        # { DataTransport transport } pop-value
│           │   └── widgets/                    # SegmentedTabs, radar pulse, code+countdown, stubs
│           └── debug/pairing_debug_page.dart  # unchanged (dev-only)
│   (pairing domain/data: + PairingRepository.takeTransport())

test/
├── features/send/        # selection cubit, transfer cubit, selection + progress widgets
├── features/pairing/     # connect page widget (code/countdown/failure/connected)
└── core/services/transport/  # startSendOnTransport loopback round-trip
```

**Structure Decision**: Feature-first per Constitution XI. The Connect screen lives in `features/pairing/` (it is the shared pairing hub, reused by #005) and is **composed into the send flow by `core/router`**, not imported by `features/send`. The two features never import each other; they exchange **core-typed** payloads (`List<FileSource>` / `DataTransport`) through `go_router` navigation. Per-stage page-scoped cubits (selection, transfer) plus the existing `PairingCubit` keep each screen independently testable; the selection page acts as the lightweight coordinator that sequences the pushes (pick → await Connect's transport → push transfer), which keeps the file selection alive in the back stack so a retry preserves it (FR-025a / Clarification Q2).

## Phase 0 — Research

See [research.md](research.md). Resolves: the engine-reuse seam vs second-handshake; document-picker permission reality (why permission_handler is deferred); the generic peer label until #010; speed/ETA derivation from the snapshot stream; transport ownership/teardown after handoff; and file_picker streamed-read behavior on iOS/Android.

## Phase 1 — Design & Contracts

- [data-model.md](data-model.md) — `SendSelection`, `SelectedFile`, `SendTransferView` (snapshot projection: %, speed, ETA, current file), failure mapping, and the selection→pairing→transfer state flow.
- [contracts/send-flow-contract.md](contracts/send-flow-contract.md) — cubit APIs, use cases, the Connect request/result contract, and the navigation/handoff sequence.
- [contracts/transfer-engine-seam.md](contracts/transfer-engine-seam.md) — exact signatures and ownership rules for `TransferEngine.startSendOnTransport` and `PairingRepository.takeTransport`, including teardown responsibilities.
- Agent context: `CLAUDE.md` SPECKIT block updated to point at this plan/spec.

**Post-Design Constitution Re-check**: PASS — the design adds no new violations; the only engine edits are additive and preserve existing loopback test paths.
