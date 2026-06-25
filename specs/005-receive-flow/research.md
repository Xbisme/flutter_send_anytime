# Phase 0 — Research: Receive Flow (Nhận)

Decisions resolving the unknowns in the plan's Technical Context. Each entry: **Decision · Rationale · Alternatives rejected**.

---

## R1. Receiver engine reuse — adopt the pairing transport, no second handshake

**Decision**: Add an additive `TransferEngine.startReceiveOnTransport({required DataTransport transport, required Directory destinationDir, Future<bool> Function(TransferManifest) onManifest})` that adopts an **already-open** transport (via the existing private `_adoptTransport`) and runs the receive protocol from `handshaking` onward. Refactor the existing `startReceive` into `_establish(signaling)` + a shared `Future<Result<void>> _runReceive(transport, destinationDir, onManifest)` holding the current frame loop verbatim. This mirrors exactly what #004 did for the sender (`startSend` → `startSendOnTransport` + shared `_runSend`).

**Rationale**: The pairing layer (#003) already completed the WebRTC handshake and opened the `RTCDataChannel`; re-establishing would be wrong (two channels) and impossible (the code is single-use/TTL'd). The #004 sender seam proved the pattern: extract the body, add a transport-adopting entry, keep `startReceive` as `_establish` + body so the existing receive loopback tests pass unchanged. The receive frame loop (manifest→accept/reject→fileStart→chunks→fileComplete(hash)→sessionComplete, with `.part`→atomic-rename and collision handling) is untouched — only its entry differs.

**Alternatives rejected**:
- *Call the existing `startReceive` with the WebSocket `SignalingChannel`* — would trigger a second `_establish`/handshake on a channel that's already up; breaks the one-channel guarantee (Constitution VIII) and the single-use-code rule (I).
- *A new parallel receive engine* — duplicates the audited protocol/integrity code; violates Simplicity (XIII) and Testing (XII, the loopback path).

## R2. `PairingRepository.takeTransport()` — reuse #004 handoff unchanged

**Decision**: Reuse the existing `PairingRepository.takeTransport()` (added in #004) for the receiver handoff. The Connect hub already calls it on `connected` and returns a `ConnectResult{transport}`; the receive flow consumes that transport identically to the send flow.

**Rationale**: Ownership handoff is role-agnostic — the repo relinquishes the `DataTransport` (and stops closing it on dispose) once taken, and the receiving engine then owns teardown. No second seam is needed; #004 already generalized this.

**Alternatives rejected**: A receiver-specific handoff method — redundant; the transport is a core type with no role.

## R3. Save target & permissions — app-owned dir, no runtime permission, permission_handler still deferred

**Decision**: Save received files under an app-owned **"Safe Send" subfolder of the application documents directory** (`path_provider.getApplicationDocumentsDirectory()`), on both platforms. Expose them to the user via:
- **iOS**: mark the app's Documents folder browsable in the Files app with Info.plist `UIFileSharingEnabled = YES` and `LSSupportsOpeningDocumentsInPlace = YES` (folded into the deferred on-device build), plus the in-app **Share** (share sheet) and **Open** (system viewer) actions.
- **Android**: the app-specific documents dir; reached via the in-app **Share** (share sheet → save to Downloads / forward) and **Open** actions.

No storage or photo-library runtime permission is requested anywhere in the flow. `permission_handler` **stays deferred** (it was deferred in #004 too).

**Rationale**: Writing inside the app sandbox needs no permission on either platform; the share sheet and OS open-with cover "get it out of the app" without the app holding broad storage access — matching the spec's chosen strategy and the privacy posture (least privilege). Public-Downloads/MediaStore and save-to-photo-library (which *would* need permission) are explicitly #010.

**Alternatives rejected**:
- *Public Downloads via MediaStore/SAF (Android)* — better "Send Anywhere" feel but adds permission/scoped-storage complexity; deferred to #010 per the spec clarification.
- *Add permission_handler now* — no code path needs it (YAGNI, XIII; no unjustified deps, XV).

## R4. Accept/Reject prompt — bridging the engine's `onManifest` `Future<bool>` through a 4-state cubit

**Decision**: The engine calls `onManifest(manifest)` and awaits a `Future<bool>` before writing anything. `ReceiveTransferCubit` supplies that callback: on invocation it stores a `Completer<bool>` and emits a **loaded** `TransferView` with an `awaitingDecision` flag + an `IncomingOffer` summary (file count, total size, type set, sender label). The page's `BlocListener` shows the `IncomingTransferDialog`; the user's tap calls `cubit.accept()` / `cubit.reject()`, which completes the completer (`true`/`false`) and clears the flag. On reject the engine sends the reject frame and terminates; the cubit then drives the flow to Home.

**Rationale**: Keeps the engine as the single source of truth (it owns the protocol decision point) while the 4-state cubit stays clean — the prompt is a flag on the loaded view, not a fork in the state machine. The `Completer` is the standard Dart bridge between an imperative callback and user interaction. Constitution III is honored (extended info lives in the loaded data; side-effect dialog via `BlocListener`).

**Alternatives rejected**:
- *A dedicated `awaitingDecision` cubit state subclass* — heavier; the 4-state base already carries a typed `TransferView` and a boolean flag is sufficient and testable.
- *Auto-accept then let the user cancel* — violates the always-prompt consent rule (FR-007) and writes bytes before consent.

## R5. Partial outcome (FR-013a) — keep verified files, discard only the in-flight one

**Decision**: On a mid-transfer failure (integrity mismatch, connection lost, write error), keep every file already finalized (atomically renamed after its hash matched) and discard only the active `.part`. The terminal `TransferView` reports `received X / N`. This is **already the engine's behavior**: each file is renamed into place on `FileCompleteFrame` after the hash check, and only `_activePart` is deleted on failure/cancel — no rollback of finalized files exists or is added.

**Rationale**: Matches the user's Q1 clarification and the engine's per-file atomic-finalize design (Constitution IX). No engine change is required for the data behavior; the only new work is **presenting** the partial outcome (count received-vs-offered) on the Complete screen and not labeling it a clean success (FR-014). Already-finalized files are complete-and-verified, so keeping them never leaves corrupt/partial data (SC-002/SC-003 hold: the discarded `.part` is the only unverified artifact, and it is deleted).

**Alternatives rejected**:
- *All-or-nothing rollback* — would require tracking and deleting finalized files, contradicts the engine's atomic-finalize model, loses good data, and is more code (XIII).

## R6. Share & Open mechanics

**Decision**:
- **Share**: `SharePlus.instance.share(ShareParams(files: paths.map((p) => XFile(p)).toList()))` — supports multiple files in one share-sheet invocation (Complete's Share-all).
- **Open**: `OpenFilex.open(path)` for the per-file Open action; the platform resolves the viewer by MIME (Android) / UTI (iOS).
Both wrapped in `ReceivedFilesService` returning `Result<void>` so the cubit `.fold`s and surfaces a localized failure (e.g. "no app to open this type") via toast.

**Rationale**: These are the maintained, permission-free plugins for exactly these jobs (verified pub.dev 2026-06-25). Wrapping them keeps try/catch out of the cubit (V) and the call sites token/ARB-clean.

**Alternatives rejected**: `open_file` (less maintained than `open_filex`); raw platform channels (reinventing maintained plugins, XIII).

**Build notes (XV)**: `share_plus` was **pinned to 12.0.2** (not 13.1.0): 13.x depends on `win32 ^6`, which conflicts with `file_picker` 11's `win32 ^5.9` (a Windows-only transitive, irrelevant to iOS/Android but resolved by pub across all platforms). 12.0.2 exposes the identical `SharePlus.instance.share(ShareParams(files:[XFile]))` API, needs `win32 ^5.5.3` (compatible), and requires no runtime permission — verified pub.dev 2026-06-25. `open_filex` 4.7.0 dropped the `REQUEST_INSTALL_PACKAGES` requirement; a `FileProvider` manifest entry is added only if a conflict surfaces at build. `path_provider` 2.1.6 is Flutter-verified, no native config.

## R7. Shared Progress/Complete lift — reuse Send UI without cross-feature imports

**Decision**: Generalize `features/send`'s `SendTransferView` into `core/domain/transfer/transfer_view.dart` (`TransferView`) and move the progress/complete widgets into `core/presentation/transfer/`, parameterized by `TransferRole` (sender/receiver — already a core enum). The role selects the badge label ("ĐANG GỬI"/"ĐANG NHẬN") and the terminal-action set (sender: *Gửi lại* / *Xong*; receiver: per-file *Mở* + *Chia sẻ* / *Xong*). Each feature keeps its own cubit; the speed/ETA smoothing becomes a shared `TransferProgressProjector` helper in core used by both.

**Rationale**: The spec requires sharing these screens (Assumptions) and Constitution XI forbids `features/receive` importing `features/send`. Lifting the shared view + widgets to `core/` is the clean resolution; the role parameter is a tiny, justified branch (not a plugin framework, XIII). The projection math is identical across roles, so a shared helper avoids divergence while the cubits stay separate (different Use Cases).

**Alternatives rejected**:
- *Keep the UI in `features/send` and have receive import it* — direct Constitution XI violation.
- *Duplicate the progress/complete screens in `features/receive`* — divergence risk + double maintenance for pixel-identical UI; rejected.
- *One shared `TransferCubit` for both* — the Use Cases differ (StartSend vs StartReceive) and receive adds the manifest-decision bridge; a shared base would leak role concerns. Two cubits + shared view/widgets is simpler.

## R8. Connect receiver branch — code entry on the existing role-parameterized hub

**Decision**: Add the receiver branch to the Connect hub's `_CodeTab`: when `request.role == receiver`, render a new `CodeInput` (6 mono cells / single masked field, digit-only, enables Connect at 6 digits) that calls the existing `PairingCubit.joinWithCode(code)`. The hub's existing `connecting`/`connected`/`failure` handling is reused as-is; on `connected` it returns the same `ConnectResult{transport}`. A recoverable failure keeps the entered code in the field for retry (FR-023).

**Rationale**: #004 already built the hub "role-parameterized" but only wired the sender (host) branch; `PairingCubit.joinWithCode` + `takeTransport` already exist. The only gap is the receiver entry UI — a focused, single-purpose widget that belongs in the pairing feature and is reusable by #007/#009 later.

**Alternatives rejected**: A separate receive-only pairing screen — duplicates the hub, breaks the "one Connect screen" IA (VI), and forgoes the shared connected/failure handling.

---

## Resolved unknowns summary

| Unknown (from plan) | Resolution |
|---|---|
| Receiver reuse of the open channel | R1 — `startReceiveOnTransport` + `startReceive` refactor (mirror of #004) |
| Handoff ownership | R2 — reuse existing `takeTransport()` |
| Save location & permissions | R3 — app documents dir; no runtime permission; permission_handler deferred |
| Accept/Reject through a 4-state cubit | R4 — `onManifest` `Future<bool>` bridged by a `Completer` + `awaitingDecision` flag |
| Files kept on partial failure | R5 — engine already keeps finalized files; only present the partial count |
| Share / Open | R6 — share_plus / open_filex wrapped in `ReceivedFilesService` |
| Sharing Send's Progress/Complete | R7 — lift to `core/`, role-parameterized; no cross-feature import |
| Receiver code entry | R8 — receiver branch in the existing Connect hub + `CodeInput` |
| Generic peer label | Same as #004 — localized "Người gửi" until #010 |
