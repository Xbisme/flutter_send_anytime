# Implementation Plan: Receive Flow (Nhận)

**Branch**: `005-receive-flow` | **Date**: 2026-06-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/005-receive-flow/spec.md`

## Summary

Build the second half of the MVP loop: a receiver opens Nhận from Home, **enters a 6-digit code** on the shared Connect hub (receiver role), and — once the direct WebRTC channel opens — is shown an **incoming-transfer prompt** (sender label + manifest: count, total size, types) with **Accept / Reject**. On accept, files stream to disk with live progress, each integrity-verified per-file; on completion the receiver reaches a **Complete** summary listing the received files with per-file **Open** and a **Share-all** action. Like #004, this is the **UI + orchestration layer** over the existing #002 transport engine and #003 6-digit pairing — no new transport or pairing mechanics.

Three design surfaces realized:

1. **Code entry** (`features/pairing`) — add the **receiver branch** to the existing role-parameterized Connect hub's "Mã 6 số" tab: a `CodeInput` field + connect action that calls the existing `PairingCubit.joinWithCode`. The connecting / connected / failure states already exist; only the receiver entry UI is new. On `connected` the hub returns the open `DataTransport` (same `ConnectResult` handoff as #004).
2. **Incoming-transfer prompt** (`features/receive`) — the design's accept/reject dialog ("‹Người gửi› muốn gửi cho bạn · N tệp · TỔNG · loại"). The engine's existing `onManifest` hook drives it: the receive cubit surfaces an *awaiting-decision* view carrying the manifest summary and resolves the engine's `Future<bool>` on the user's Accept/Reject.
3. **Progress + Complete** (shared) — the **same** screens as Send, **lifted into `core/presentation/transfer/`** and role-parameterized (badge "ĐANG NHẬN", terminal actions Open/Share). Driven by the **#002 snapshot stream**; partial outcome (FR-013a) reported on the Complete screen.

**Two seam changes** (the only edits to merged engine code, both additive — mirroring #004):

- **`TransferEngine.startReceiveOnTransport({transport, destinationDir, onManifest})`** — a receiver entry point that adopts an **already-open** `DataTransport` and runs the existing receive body from `handshaking` onward (skips `_establish`). The current `startReceive` is refactored to `_establish` + a shared `_runReceive(transport, …)` body, so the existing loopback receive tests stay green. This realizes the pre-spec decision to **reuse the channel the pairing layer already opened** rather than performing a second WebRTC handshake.
- **`PairingRepository.takeTransport()`** — **already added in #004**; reused unchanged for the receiver handoff (no new edit).

**One refactor** (shared Progress/Complete): `SendTransferView` is generalized to `core/domain/transfer/transfer_view.dart` (`TransferView`), and the progress/complete widgets move to `core/presentation/transfer/`, parameterized by `TransferRole` (badge label + terminal-action set). `features/send` keeps its own `SendTransferCubit`; `features/receive` adds `ReceiveTransferCubit`; both bind the shared views. This lets Receive reuse the Send UI **without `features/receive` importing `features/send`** (Constitution XI).

Everything fallible returns `Result<T>`; cubits `.fold`; user copy comes from ARB (Vietnamese primary) via a receive-side `AppFailure` → message mapper; numeric values use mono/tabular tokens. Validated by widget + bloc tests and a **loopback round-trip of `startReceiveOnTransport`** (a real sender engine over a paired loopback transport drives a real receiver engine to disk); the two-physical-device smoke is the deferred manual task. After merge, the **MVP checkpoint** is reached.

## Technical Context

**Language/Version**: Dart (SDK `^3.11.0`) / Flutter (latest stable 3.x). App only — no server/shared-package changes this feature.

**Primary Dependencies** (latest stable verified on pub.dev 2026-06-25 — Constitution XV):

- **Already present**: `flutter_webrtc` 1.5.2, `crypto` 3.0.7, `uuid` 4.5.3, `flutter_bloc` 9.1.1, `go_router` 17.3.0, `get_it` 9.2.1, `injectable` 3.0.0, `web_socket_channel` 3.0.3, `file_picker` 11.0.2, `intl` 0.20.2, `lucide_icons_flutter` 3.1.14, `safesend_signaling` (path).
- **New**:
  - `path_provider` **2.1.6** — resolve the app-owned destination directory (iOS `getApplicationDocumentsDirectory()`, exposed to the Files app via `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`; Android app-specific documents dir). Flutter-verified publisher; iOS 13+/Android 24+; **no runtime permission**.
  - `share_plus` **13.1.0** — hand received files to the system share sheet (`SharePlus.instance.share(ShareParams(files: [XFile(path), …]))`). No runtime permission. **Build note**: 13.x wants Java 17 / Kotlin 2.2 / AGP ≥ 8.12.1 on Android — verified at plan time, folded into the (already-deferred) on-device build; if it forces churn we pin to the highest 13.x compatible with the current Gradle, documented in research.md.
  - `open_filex` **4.7.0** — open a received file in an appropriate system viewer (`OpenFilex.open(path)`). No runtime permission (the `REQUEST_INSTALL_PACKAGES` requirement was removed upstream); Android may need a `FileProvider` entry only if it conflicts with another plugin — checked at implementation.
- **Deliberately NOT added**: `permission_handler` — **still deferred**. The save target is app-owned storage (no storage/photos permission), the document export goes through the OS share sheet, and open uses the OS viewer — none trigger a runtime permission dialog. Public-Downloads / save-to-photo-library destinations (which *would* need it) are #010. (Constitution XIII YAGNI, XV no unjustified deps.)

**Storage**: Received files are streamed to a quarantine `.part` in the app destination dir, hash-verified, then atomically renamed into place (existing #002 receiver behavior). Non-destructive collision rename already implemented. Nothing else persisted (history is #006).

**Testing**: `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5. New coverage: `ReceiveTransferCubit` (snapshot→view mapping, awaiting-decision → accept/reject bridge, terminal transitions, partial outcome, cancel), the Connect receiver branch widget (code entry → joinWithCode, invalid/expired/full/unreachable failures → retry preserving code), the incoming-transfer prompt dialog, the shared progress/complete render in **receiver role** (incl. Open/Share actions and partial summary), the receive `AppFailure` mapper, and a **loopback round-trip of `startReceiveOnTransport`** (real sender engine over a loopback transport → real receiver engine writes verified files to a temp dir). Command: `very_good test --test-randomize-ordering-seed random` (gate-equivalent: `dart test` / `flutter test`).

**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+ (unchanged). iOS adds two Info.plist keys (`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`) so received files appear in the Files app — folded into the deferred on-device build. No new pods beyond the three pure/standard plugins.

**Project Type**: Mobile app (Flutter). Feature work in `lib/features/{receive,pairing}` + a shared lift into `lib/core/{presentation/transfer,domain/transfer}` + one additive engine seam in `lib/core/services/transport` + a new `lib/core/services/file` receive-storage service.

**Performance Goals**: Open Nhận → incoming prompt against a hosting sender in < 30 s on a typical LAN (SC-001). Streamed I/O so memory does not scale with file size (Constitution II); 16 KiB chunking + backpressure already enforced by the engine. Progress UI updates continuously from the snapshot stream.

**Constraints**: No file bytes over signaling (reused engine guarantee); logs carry phase/error-type only (Constitution I/II) — never file names, paths, peer ids, IPs, SDP/ICE; received-file writes stay inside the app destination dir (manifest path-traversal already rejected by #002); `lib/core/` MUST NOT import `lib/features/`; `features/receive` and `features/send` MUST NOT import each other — the shared Progress/Complete live in `core/presentation/transfer/` and both features compose them; `features/receive` and `features/pairing` exchange only **core-typed** payloads (`DataTransport`) via `go_router` navigation; inject Use Cases (not repos) into Cubits; all strings via ARB; reduce-motion disables spinner; bottom nav hidden on every flow screen.

**Scale/Scope**: Single peer per receive; single active receive at a time; multi-file sequential (engine). ~16–20 new/changed app files: `features/receive/{domain/usecases,presentation/cubit,presentation/pages,presentation/widgets,presentation/receive_failure_l10n.dart}`, the Connect receiver branch + a `CodeInput` widget in `features/pairing/presentation/connect/`, the shared `core/presentation/transfer/*` (lifted progress/complete + role config) and `core/domain/transfer/transfer_view.dart`, `core/services/file/received_files_service.dart` (+impl), the additive `TransferEngine.startReceiveOnTransport` (refactor `startReceive`), `core/constants/app_routes.dart` (+ `receiveProgress`), router wiring, and new ARB strings (receive + prompt copy, receive-failure messages).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | How this feature complies |
|---|---|---|
| I. Privacy-First P2P | ✅ | Reuses engine/relay unchanged; no bytes over signaling; received writes confined to the app dir (manifest path-traversal already rejected by #002). New code logs only phase/error-type — never file names, paths, peer ids, IPs, SDP/ICE. |
| II. Direct Transfer & Data Minimization | ✅ | Receiver streams chunks to a `.part` then atomic-renames on hash match (existing #002); never buffers a whole file. Nothing persisted beyond the user's save location; no content telemetry. |
| III. BLoC-Driven State (4-state) | ✅ | `ReceiveTransferCubit : AppCubit<TransferView>` projects the engine's **state-machine stream** (Principle VIII), not ad-hoc setState; the awaiting-decision moment is a loaded-view flag bridged to the engine's `onManifest` `Future<bool>` via a `Completer`. Reused `PairingCubit`. Nav/dialogs/toasts via `BlocListener`; cubits closed page-scoped. |
| IV. Code Quality & Dart Safety | ✅ | very_good_analysis 0 warnings; explicit types; freezed immutable `TransferView`; self-documenting. |
| V. Result\<T\> Error Handling | ✅ | `StartReceiveUseCase`, `ReceivedFilesService` return `Result<T>`; cubit `.fold`s; no try/catch in cubits; user text from a receive `AppFailure` mapper. |
| VI. Design System & Theming | ✅ | Reuses `core/presentation` shared widgets; the accept/reject prompt, cancel-confirm, and Complete actions follow the distilled **Dialogs & Toasts** spec (gradient primary, danger cancel, FileRow list); tokens only (no hex); reduce-motion disables spinner; flow hides bottom nav. New reusable `CodeInput` + the shared transfer Progress/Complete land in `core/presentation/`. |
| VII. Cross-Platform Native Integration | ✅ | path_provider/share_plus/open_filex work on both; **no runtime permission** in the receive path (save = app dir; export = OS share sheet; open = OS viewer). Cupertino/Material-appropriate dialogs. Haptics on connect/complete/fail. Reduce-motion + screen-reader labels honored. iOS Files visibility via Info.plist keys (deferred device build). |
| VIII. Transport & Signaling Architecture | ✅ | UI driven by the **single** transfer state-machine stream; no parallel progress notion. `startReceiveOnTransport` reuses the **established** transport (one channel, no second handshake); SignalingChannel seam + per-flavor config untouched; protocol/state-machine unchanged. |
| IX. Transfer Reliability & Integrity | ✅ | "Complete" gated by per-file hash; `.part` quarantine → atomic rename already enforced; mismatch/disconnect/write-fail surface as typed retryable `AppFailure`; partial outcome keeps only verified files (FR-013a); confirmed cancel tears down the connection and discards the in-flight `.part`. |
| X. go_router Navigation | ✅ | New `AppRoutes.receiveProgress`; reuses `AppRoutes.connect`; `context.push/pop` only; flow routes use the root navigator key to hide bottom nav; Connect returns a typed pop-value; Reject → Home, recoverable failure → code-entry. No deep links here. |
| XI. Feature-First Modularity | ✅ | `core/` imports no features; `features/receive` and `features/send` do **not** import each other — the shared Progress/Complete live in `core/presentation/transfer/` and the view model in `core/domain/transfer/`; `features/receive` ↔ `features/pairing` exchange only the core-typed `DataTransport` via navigation. Cubits depend on Use Cases, not repos. |
| XII. Testing Discipline | ✅ | bloc_test for `ReceiveTransferCubit` (incl. accept/reject bridge + partial); widget tests for the Connect receiver branch, the accept/reject prompt, and the receiver-role progress/complete; **loopback round-trip** for `startReceiveOnTransport`. Two-physical-device receive smoke tracked as deferred in tasks.md banner. |
| XIII. Simplicity & YAGNI | ✅ | Only the three save/share/open packages added (each a concrete need); permission_handler still deferred; auto-receive/save-location prefs left to #010; per-stage cubits (no mega flow-cubit); shared Progress/Complete via a small role parameter, not a framework. |
| XIV. Internationalization | ✅ | All copy in ARB (VI primary, EN); receive `AppFailure` → localized message (new mapper mirroring the send/pairing ones); sizes/speed/ETA via locale-aware `intl` with mono tabular figures. |
| XV. Dependency Hygiene | ✅ | path_provider 2.1.6 / share_plus 13.1.0 / open_filex 4.7.0 verified on pub.dev 2026-06-25; caret constraints; `pubspec.lock` committed; share_plus 13.x Android toolchain (Java 17 / AGP 8.12.1) noted and folded into the deferred device build; no unexpected pod churn for the document path. |

**Result**: PASS — no violations. Complexity Tracking table omitted (nothing to justify).

## Project Structure

### Documentation (this feature)

```text
specs/005-receive-flow/
├── plan.md              # This file
├── research.md          # Phase 0 — decisions (receive seam, save target & permissions, prompt bridge, share/open, partial outcome, shared-UI lift)
├── data-model.md        # Phase 1 — TransferView (shared) + receive cubit states, IncomingOffer, ReceivedFile, failure mapping, receive state flow
├── quickstart.md        # Phase 1 — how to run, test, and demo the receive flow (incl. two-engine loopback)
├── contracts/
│   ├── receive-flow-contract.md     # Cubits, use cases, Connect receiver branch, prompt bridge, navigation/handoff, save/share/open service
│   └── transfer-engine-seam.md      # startReceiveOnTransport signature, ownership/teardown, startReceive refactor
├── checklists/
│   └── requirements.md  # (from /speckit.specify)
└── tasks.md             # Phase 2 — /speckit.tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_routes.dart                     # + receiveProgress (reuses connect)
│   ├── domain/transfer/
│   │   ├── transfer_view.dart                  # NEW: TransferView (lifted from SendTransferView) — shared projection
│   │   └── incoming_offer.dart                 # NEW: IncomingOffer (manifest summary for the accept/reject prompt)
│   ├── services/
│   │   ├── file/
│   │   │   ├── received_files_service.dart      # abstract: destinationDirectory(), share(paths), open(path) -> Result
│   │   │   └── received_files_service_impl.dart # path_provider + share_plus + open_filex
│   │   └── transport/
│   │       └── transfer_engine.dart            # + startReceiveOnTransport(...) (refactor startReceive → _establish + _runReceive)
│   ├── presentation/
│   │   └── transfer/                            # shared Progress/Complete (lifted from features/send), role-parameterized:
│   │       ├── transfer_progress_view.dart      #   %/bar/speed/ETA/current-file + badge(role)
│   │       ├── transfer_complete_view.dart       #   summary + terminal actions(role): send-again/done | open/share/done
│   │       └── transfer_progress_projector.dart  #   shared speed/ETA smoothing helper (used by both cubits)
│   └── router/app_router.dart                  # wire receive flow routes (Home Nhận → connect(receiver) → receiveProgress)
├── features/
│   ├── receive/
│   │   ├── domain/usecases/
│   │   │   └── start_receive_usecase.dart       # destinationDir + startReceiveOnTransport; exposes snapshots + accept/reject + cancel
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── receive_transfer_cubit.dart   # AppCubit<TransferView> (snapshot stream + manifest-decision bridge)
│   │       ├── pages/
│   │       │   ├── receive_entry_page.dart        # Home "Nhận" entry → pushes Connect(receiver), then receiveProgress
│   │       │   └── receive_transfer_page.dart     # binds ReceiveTransferCubit → shared progress/complete (receiver role)
│   │       ├── widgets/
│   │       │   └── incoming_transfer_dialog.dart  # accept/reject prompt (Dialogs & Toasts spec)
│   │       └── receive_failure_l10n.dart          # AppFailure → receive message mapper
│   └── pairing/
│       └── presentation/connect/
│           ├── connect_page.dart                # + receiver branch in _CodeTab (CodeInput + connect → joinWithCode)
│           └── widgets/
│               └── code_input.dart              # NEW: 6-digit entry field (mono, validates, enables connect)
│   (pairing domain/data: PairingRepository.takeTransport() — reused from #004, no change)

test/
├── features/receive/        # receive transfer cubit (incl. accept/reject + partial), incoming dialog, receiver-role progress/complete
├── features/pairing/        # connect receiver branch (code entry → join; failure→retry preserves code)
└── core/services/transport/ # startReceiveOnTransport loopback round-trip (sender engine → receiver engine → verified files)
```

**Structure Decision**: Feature-first per Constitution XI. The Progress/Complete UI is **lifted to `core/presentation/transfer/`** (and its view model to `core/domain/transfer/`) so both Send and Receive reuse it without importing each other; each feature keeps its own cubit (different use cases) and supplies a `TransferRole` config (badge + terminal actions). The Connect hub stays in `features/pairing/` and is **composed into the receive flow by `core/router`**; `features/receive` receives the open `DataTransport` as a core-typed navigation payload (same handoff shape as #004). The receive entry page is the lightweight coordinator that sequences the pushes (push Connect(receiver) → await transport → push receiveProgress), keeping the code-entry alive in the back stack so a recoverable-failure retry preserves the entered code (FR-023); Reject pops the whole flow to Home (FR-009).

## Phase 0 — Research

See [research.md](research.md). Resolves: the receiver engine-reuse seam vs second-handshake (+ how `startReceive` refactors safely); the save target and why no runtime permission is needed (and why permission_handler stays deferred); how the accept/reject prompt bridges the engine's `onManifest` `Future<bool>` through a 4-state cubit; share/open mechanics and the iOS Files-visibility Info.plist keys; the partial-outcome behavior (FR-013a) given the engine's per-file atomic finalize; and the shared-UI lift that keeps `features/send` and `features/receive` decoupled.

## Phase 1 — Design & Contracts

- [data-model.md](data-model.md) — `TransferView` (shared projection), `ReceiveTransferCubit` states incl. the awaiting-decision flag, `IncomingOffer` (manifest summary), `ReceivedFile`, the receive `AppFailure` mapping, and the receive state flow (code → connect → prompt → transfer → complete/partial/failure, with Reject→Home).
- [contracts/receive-flow-contract.md](contracts/receive-flow-contract.md) — cubit APIs, `StartReceiveUseCase`, the `ReceivedFilesService` contract (destination/share/open), the Connect receiver-branch contract, the manifest-decision bridge, and the navigation/handoff sequence.
- [contracts/transfer-engine-seam.md](contracts/transfer-engine-seam.md) — exact signature and ownership/teardown rules for `TransferEngine.startReceiveOnTransport`, plus how `startReceive` is refactored to `_establish` + shared `_runReceive` with existing loopback tests preserved.
- Agent context: `CLAUDE.md` active-feature pointer updated to #005 plan/spec.

**Post-Design Constitution Re-check**: PASS — the design adds no new violations; the only engine edit is additive (`startReceiveOnTransport` + a body-extracting refactor) and preserves existing loopback receive tests; the shared-UI lift is a move within `core/` that strengthens (not weakens) the feature-decoupling rule.
