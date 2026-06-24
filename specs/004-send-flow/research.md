# Research: Send Flow (Gửi)

Phase 0 decisions for #004. Each entry: **Decision · Rationale · Alternatives considered**. Anchored to the merged #002/#003 code and the pre-spec alignment (2026-06-24).

## R1 — Reuse the pairing-established channel vs a second WebRTC handshake

**Decision**: Add `TransferEngine.startSendOnTransport({required DataTransport transport, required TransferSession session})` that **adopts the already-open transport** produced by the pairing layer and runs the existing send body from the `handshaking` phase onward (skipping `_establish`/`PeerConnector.connect`). Refactor the current `startSend` to `_establish` + the same shared body so the loopback tests are unchanged. Ownership of the transport transfers to the engine (it wires the `closed` watcher and closes it on terminal/dispose).

**Rationale**: Today **both** [`PairingRepositoryImpl._establish`](../../lib/features/pairing/data/pairing_repository_impl.dart) **and** [`TransferEngine._establish`](../../lib/core/services/transport/transfer_engine.dart) call `PeerConnector.connect(...)`. Pairing already opens a `DataTransport` and reaches `PairingConnected` before transfer begins. If the Send flow waited for `connected` and then called `startSend`, it would negotiate ICE **twice** (or conflict on the single peer connection) and waste the channel pairing just opened. Reusing the open transport keeps to the "one channel" intent and Constitution VIII (single transport path).

**Alternatives considered**:
- *Pairing stops at `peerPresent` and hands back the `SignalingChannel`; the engine handshakes.* Cleaner against #002's original design, but requires refactoring merged #003 code + its tests (pairing no longer reaching `connected`), and re-opens the question of who drives ICE. Rejected as more invasive for no functional gain. (This was option B in the pre-spec discussion.)
- *Leave both connects in place (double handshake).* Wastes a negotiation and risks conflicting peer connections. Rejected.

## R2 — Transport ownership & teardown after handoff

**Decision**: Add `DataTransport? takeTransport()` to `PairingRepository`. It returns the connected transport **and clears the repo's internal reference** so `PairingRepository.dispose()` no longer closes it. The Connect screen calls `takeTransport()` on `connected`, returns it to the caller as `ConnectResult`, and the send Progress route owns it via the engine. The signaling `WebSocketSignalingChannel` / socket may be torn down after the data channel is open: for a **data-channel-only** transfer there is no renegotiation, so closing signaling post-connect does not affect the live transport.

**Rationale**: Prevents a double-close (pairing dispose vs engine dispose) and a use-after-free of the channel. Makes the handoff explicit and one-directional. Aligns with Constitution IX (cancellation/teardown release handles exactly once).

**Alternatives considered**: Carry the transport inside `PairingState.connected(DataTransport)`. Workable (core→core), but puts a service-layer object inside a domain state and complicates equality/freezed; a repository getter/`takeTransport()` is leaner. Rejected.

## R3 — file_picker permissions: why permission_handler is deferred to #005

**Decision**: Add only `file_picker` **11.0.2** for #004. Do **not** add `permission_handler` yet.

**Rationale**: For any-type selection, `file_picker` uses `UIDocumentPickerViewController` (iOS) and the Storage Access Framework / `ACTION_GET_CONTENT` (Android). These grant per-file access **without a runtime permission dialog** — there is no storage/photo permission to request or be "denied" on the send side. The genuine permission needs (save to Downloads/Files, photo-library access) live on the **receive** side (#005), which is where `permission_handler` will be justified. Adding it now would be an unused dependency (Constitution XIII/XV). FR-006's "graceful denied state" therefore reduces, on the send path, to handling a **cancelled pick** (no change to the selection) — already covered by FR-005's empty-selection guard.

**Spec reconciliation**: FR-006 stays valid but is satisfied trivially (no runtime prompt in the document-picker path). research.md records this so tasks/impl don't wire a permission flow the platform doesn't require.

**Alternatives considered**: Add `permission_handler` 12.0.3 now "to be safe". Rejected — no code path needs it in #004; it pulls iOS Info.plist usage-description requirements and a Podfile post_install block for permissions that #004 never requests.

## R4 — Generic destination-peer label until #010 (Clarification Q1)

**Decision**: Show a **generic localized label** ("Thiết bị nhận" / "the receiver") on Progress (FR-015) and Complete (FR-022). Do **not** exchange device names; do **not** expand the #002/#003 wire contract.

**Rationale**: #003 signaling carries metadata only and no device name; the device profile is owned by #010 (Settings). A generic label keeps #004 a pure UI/wiring layer and avoids a premature contract change (Constitution XIII). When #010 lands a device profile, the same UI slot can show the real name with no flow-contract change.

**Alternatives considered**: (B) exchange a lightweight name at handshake now — expands the manifest/handshake and needs a name source before Settings exists; (C) omit the peer reference entirely — diverges from the design's "tới <thiết bị>" copy. Both rejected per the clarification.

## R5 — Deriving %, speed, and ETA from the snapshot stream

**Decision**: The progress view computes display values **purely from `TransferSnapshot`** (the engine's single source of truth): percentage = `overallBytesTransferred / overallTotalBytes`; instantaneous **speed** = delta-bytes / delta-time across consecutive snapshots (smoothed with a short moving window); **ETA** = remaining bytes / smoothed speed. The `SendTransferCubit` keeps the last sample (bytes, timestamp) to compute the rate; the view never tracks progress independently (Constitution VIII).

**Rationale**: Keeps the transfer state machine the only progress authority. A small moving-average avoids a jittery speed/ETA readout. All values render with the mono + tabular-figures tokens via locale-aware `intl` formatters (sizes in MB/GB, speed in MB/s, ETA as `m:ss`).

**Alternatives considered**: Add speed/ETA fields to the engine. Rejected — derivation is a presentation concern; keeping the engine lean (Constitution XIII) and the projection in the cubit is cleaner and unit-testable.

## R6 — Navigation & cross-feature handoff without feature→feature imports

**Decision**: `core/router` composes the flow: `/send` (selection, `features/send`) → `/connect` (pairing hub, `features/pairing`, returns `ConnectResult{transport}`) → `/send/progress` (transfer, `features/send`). The selection page coordinates by `await context.push<ConnectResult>(AppRoutes.connect, extra: ConnectRequest(role: sender))`, then `context.push(AppRoutes.sendProgress, extra: SendProgressArgs(sources, transport))`. Payloads are **core types** (`List<FileSource>`, `DataTransport`); neither feature imports the other.

**Rationale**: Satisfies Constitution XI (features don't import each other's internals; cross-feature via core composition + DI). Keeps the Connect screen file-agnostic and reusable by #005. Pushing (not replacing) keeps the selection page in the back stack so a retry returns to it with the selection intact (FR-025a / Q2).

**Alternatives considered**: A single flow-scoped mega-cubit provided by a `ShellRoute`. More moving parts and would couple selection + pairing + transfer into one `AppCubit<T>` (awkward with the 4-state single-`T` pattern). Rejected for YAGNI; per-stage cubits are simpler and independently testable.

## R7 — Production Connect screen replaces the dev debug page

**Decision**: Build `features/pairing/presentation/connect/connect_page.dart` per design Screen 03: `SegmentedTabs` (Mã 6 số / QR / Gần đây), functional "Mã 6 số" tab (radar pulse, `CodeBox` row, "Hết hạn sau mm:ss" countdown, share instruction), disabled QR/Gần đây tabs + stubbed "Chia sẻ link mời" (coming-soon placeholders for #007/#008/#009). It drives the existing `PairingCubit` and is **role-parameterized** (`ConnectRequest.role`) so #005 reuses it. The dev-only `pairing_debug_page.dart` stays for the deferred manual smoke.

**Rationale**: The design treats Connect as one shared hub; building it now (vs inline-in-send) matches the IA and is reused by #005 (Clarification chose "Mã 6 số thật + QR/Gần đây stub"). The countdown reads `PairingCode.remaining`; on reaching zero with no peer, surface "code expired" + a "lấy mã mới" action (re-host).

**Alternatives considered**: Inline the code display in the Send screen (no separate Connect route). Rejected — diverges from the design hub and would not be reusable by #005.

## R8 — Package version verification (Constitution XV)

**Verified on pub.dev, 2026-06-24**:
- `file_picker` **11.0.2** — latest stable; multi-platform; document-picker path needs no runtime permission for any-type files; exposes on-disk paths (iOS copies to cache dir). **Added** with caret `^11.0.2`.
- `permission_handler` **12.0.3** — latest stable; **not added** (deferred to #005, see R3).

No native pods are introduced (file_picker's iOS/Android pieces are part of the plugin and need no extra Info.plist keys for the document picker), so no `Podfile.lock` churn is expected; `pubspec.lock` will update for `file_picker` + its transitive deps and must be committed and reviewed.

## Deferred / out of scope (carried)

- Two-physical-device send smoke (real NAT + >1 GB throughput) — manual, tracked in tasks.md banner.
- `permission_handler` + save-side permissions — #005.
- Real device name on the peer label — #010.
- Inbound share-sheet, QR/link/radar pairing, history record on completion — #006/#007/#008/#009.
