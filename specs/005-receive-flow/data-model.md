# Phase 1 — Data Model: Receive Flow (Nhận)

Presentation/domain entities for #005. The transport-layer types (`TransferSnapshot`, `TransferManifest`, `FileTransferItem`, `TransferPhase`, `TransferRole`, `DataTransport`, `AppFailure`) come from #002 and are **reused unchanged**. New/changed types below.

---

## 1. `TransferView` (shared, lifted to `core/domain/transfer/transfer_view.dart`)

Generalization of #004's `SendTransferView` — the presentation projection of a `TransferSnapshot` that **both** the Send and Receive Progress/Complete screens bind to. Computed, never authoritative (the engine stream is the single source of truth, Constitution VIII). Speed/ETA are derived across snapshots by the shared `TransferProgressProjector` and passed in.

```
TransferView (freezed)
  phase            : TransferPhase          // from snapshot
  role             : TransferRole           // sender | receiver (drives badge + terminal actions)
  overallProgress  : double = 0             // 0..1
  bytesDone        : int = 0                // sent (sender) / received (receiver)
  bytesTotal       : int = 0
  speedBytesPerSec : double = 0             // from projector
  etaSeconds       : int?                   // from projector
  currentIndex     : int?
  currentFileName  : String?
  fileCount        : int = 0
  items            : List<FileTransferItem> = const []   // per-file status/paths
  elapsed          : Duration = Duration.zero
  // receive-only decision bridge (null/false for sender):
  awaitingDecision : bool = false           // true while the engine awaits accept/reject
  incomingOffer    : IncomingOffer?         // populated with the manifest summary at the prompt
  failure          : AppFailure?

  // derived
  isDone            => phase == done
  isTransferring    => phase == transferring
  isPreparing       => phase == connecting || phase == handshaking
  isPartial         => phase is terminal && completedCount < fileCount   // FR-013a
  completedCount    => items.where((i) => i.status == completed).length
```

- **Rename note**: `bytesSent` → `bytesDone` (role-neutral). `SendTransferView.fromSnapshot` logic carries over verbatim into `TransferView.fromSnapshot(snapshot, {role, speed, eta, elapsed, awaitingDecision, incomingOffer})`.
- `features/send` updates its imports/usages from `SendTransferView` → `TransferView` (role: sender). No behavioral change to Send.

## 2. `TransferRole` (existing #002 enum — reused)

`sender | receiver`. Already on `TransferSnapshot.role`. Used here to parameterize the shared widgets:

| role | progress badge | terminal actions (Complete) |
|---|---|---|
| sender | "ĐANG GỬI" | *Gửi lại* (new empty selection) · *Xong* (→ Home) |
| receiver | "ĐANG NHẬN" | per-file *Mở* (Open) + *Chia sẻ* (Share-all) · *Xong* (→ Home) |

## 3. `IncomingOffer` (new, `features/receive/domain` or `core/domain/transfer`)

The manifest summary shown at the accept/reject prompt (derived from `TransferManifest`, held only for the session).

```
IncomingOffer (freezed)
  senderLabel : String      // generic localized "Người gửi" until #010
  fileCount   : int
  totalBytes  : int
  typeSummary : List<String> // distinct extensions/type buckets for the "Ảnh, video & tài liệu"-style line
```

- Built from `TransferManifest` (names → extensions → buckets; sizes → total). No new transport field; purely a presentation projection.
- Lives in `core/domain/transfer/` (so the shared dialog/widget can type against it without a feature import) — or `features/receive/domain` if only the receive feature uses it. **Decision: `core/domain/transfer/incoming_offer.dart`** (the incoming-transfer dialog is receive-only today but the type is core-shaped and #010 will extend it with a real peer).

## 4. `ReceivedFile` (conceptual — realized via existing `FileTransferItem`)

A single arrived file. The engine already tracks this on `FileTransferItem` (name, size, status, `finalPath`, `sha256`). No new type needed; the Complete screen reads `view.items.where(completed)` for the file list + per-file Open (`item.finalPath`) and Share-all (all `finalPath`s).

## 5. `ReceiveTransferCubit` states (4-state, `AppCubit<TransferView>`)

| State | When | `TransferView` content |
|---|---|---|
| `initial` | before start | — |
| `loading` | after `start()`, before first snapshot | — |
| `loaded(data)` | every snapshot projection | `TransferView` for the current phase |
| `loaded(data)` · `awaitingDecision=true` | engine called `onManifest` | view carries `incomingOffer`; page shows the dialog |
| `loaded(data)` · terminal `done`/partial | `sessionComplete` (all or some files) | Complete screen (full or partial summary) |
| `error(failure)` | snapshot `phase==failed` (non-reject) | mapped receive `AppFailure` → retry preserving code |

- **Decision bridge**: cubit holds `Completer<bool>? _decision`. `onManifest(manifest)` → set `_decision`, emit loaded(view with `awaitingDecision:true, incomingOffer:…`), return `_decision!.future`. `accept()` → `_decision!.complete(true)` + clear flag; `reject()` → `_decision!.complete(false)` + clear flag (engine then sends reject & terminates → cubit drives Home).
- **Reject vs failure routing** (page-level `BlocListener`): a `transferRejected` terminal that originated from the **user's own reject** → pop to Home (FR-009); a recoverable `AppFailure` (invalid/expired/full/unreachable/connectionLost/fileWriteFailed) → surface on the code-entry/pairing step with the code preserved (FR-023).

## 6. Receive `AppFailure` mapping (new `receive_failure_l10n.dart`)

Mirror of the send/pairing mappers — extension on `AppFailure` → localized message via `context.l10n`. Reuses existing variants (no new `AppFailure` variants needed):

| `AppFailure` | Receive copy (VI primary) |
|---|---|
| `invalidCode` / `roomExpired` | "Mã không đúng hoặc đã hết hạn" |
| `roomFull` | "Phòng đã đủ hai thiết bị" |
| `signalingUnreachable` / `signalingTimeout` | "Không kết nối được máy chủ ghép nối — thử lại" |
| `connectionLost` / `dataChannelClosed` | "Mất kết nối khi đang nhận" |
| `transferCancelled` | "Lượt nhận đã bị huỷ" |
| `integrityCheckFailed` | "Tệp bị lỗi khi kiểm tra — nhận lại" |
| `fileWriteFailed` / `storageFull` | "Không lưu được tệp vào thiết bị" |
| `transferRejected` | (user-initiated reject → no error UI; routes to Home) |

## 7. Receive state flow

```
Home "Nhận"
   │ push Connect(role: receiver)
   ▼
Connect hub · _CodeTab (receiver branch)
   │  CodeInput (6 digits) → PairingCubit.joinWithCode(code)
   │   ├─ connecting … (spinner; reduce-motion → static)
   │   ├─ failure (invalid/expired/full/unreachable) → message, code preserved, retry  ──┐
   │   └─ connected → takeTransport() → pop ConnectResult{transport}                     │
   ▼                                                                                     │
receive entry coordinator: push receiveProgress(transport)                               │
   ▼                                                                                     │
ReceiveTransferCubit.start(transport, destinationDir)                                     │
   │ engine.startReceiveOnTransport(...) (handshaking)                                    │
   │ onManifest → awaitingDecision + IncomingOffer                                        │
   ▼                                                                                      │
IncomingTransferDialog (Nhận / Từ chối)                                                   │
   ├─ Từ chối → reject() → engine sends reject → terminate → pop flow to Home (FR-009)    │
   └─ Nhận → accept() → transferring                                                      │
        │  snapshots → TransferProgressView (%/bar/speed/ETA/current N of M)             │
        │  per-file: .part → hash → atomic rename (kept on later failure, FR-013a)        │
        ├─ done (all files)      → TransferCompleteView (full): list + Open/Share, Xong   │
        ├─ partial (some files)  → TransferCompleteView (partial: "nhận X/N"): same actions│
        └─ failed (recoverable)  → error → back to code-entry, code preserved  ───────────┘
   (cancel mid-transfer → confirm dialog → engine.cancel → discard .part → end state)
```

## 8. Validation & invariants

- Code: digit-only, exactly 6, full `000000`–`999999`; Connect disabled until complete (FR-002/FR-003).
- No file write before `accept()` resolves `true` (FR-006/FR-007).
- Every file labeled "received" has `status==completed` (hash-passed) — partial outcomes never include the discarded `.part` (SC-002/SC-003).
- Writes confined to `destinationDir`; collision → non-overwriting rename (existing #002; FR-017).
- No storage/photos runtime permission requested at any point (FR-020/SC-004).
- All copy via ARB; numeric values mono/tabular; reduce-motion disables the spinner (FR-026/FR-027).
