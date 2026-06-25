# Contract — Receive Flow: Cubits, Use Cases, Services, Navigation

Public surfaces #005 adds, and how they compose. Features exchange only **core-typed** payloads; `features/receive` imports neither `features/send` nor `features/pairing` internals (Constitution XI).

---

## 1. `ReceivedFilesService` (core/services/file)

Abstracts the save destination + export. Returns `Result<T>` (Constitution V — no try/catch in cubits).

```dart
abstract class ReceivedFilesService {
  /// App-owned destination directory for received files (created if absent).
  /// iOS: <AppDocuments>/SafeSend ; Android: <AppDocuments>/SafeSend.
  /// Requires NO runtime permission.
  Future<Result<Directory>> destinationDirectory();

  /// Hand the given on-disk files to the system share sheet (Share-all).
  Future<Result<void>> share(List<String> paths);

  /// Open one received file in an appropriate system viewer.
  Future<Result<void>> open(String path);
}
```

- Impl (`received_files_service_impl.dart`): `path_provider.getApplicationDocumentsDirectory()` + `/SafeSend`; `SharePlus.instance.share(ShareParams(files: paths.map(XFile.new).toList()))`; `OpenFilex.open(path)` (maps a non-success result → `AppFailure.unknown`/a localized "can't open" message). `@LazySingleton(as: ReceivedFilesService)`.

## 2. `StartReceiveUseCase` (features/receive/domain/usecases)

Wraps the engine seam; injected into the cubit (Use Case, not repo).

```dart
@injectable
class StartReceiveUseCase {
  StartReceiveUseCase(this._engine, this._files);

  Stream<TransferSnapshot> get snapshots => _engine.snapshots;

  /// Receive over the already-open [transport]. [onManifest] is the cubit's
  /// accept/reject bridge. Resolves to the destination dir failure or the
  /// terminal transfer Result.
  Future<Result<void>> call({
    required DataTransport transport,
    required Future<bool> Function(TransferManifest) onManifest,
  });

  Future<void> cancel();
  Future<void> dispose();
}
```

- `call` first resolves `destinationDirectory()`; on failure returns it (cubit → error). Otherwise `engine.startReceiveOnTransport(transport: …, destinationDir: dir, onManifest: onManifest)`.
- `_engine` is the shared `TransferEngine` (`@lazySingleton`), same instance the snapshots stream comes from.

## 3. `ReceiveTransferCubit` (features/receive/presentation/cubit)

`AppCubit<TransferView>` — projects the engine stream + bridges the manifest decision. (`@injectable`, page-scoped.)

```dart
@injectable
class ReceiveTransferCubit extends AppCubit<TransferView> {
  ReceiveTransferCubit(this._startReceive);

  /// Begin receiving over the open [transport].
  Future<void> start(DataTransport transport);

  /// Resolve the pending incoming-transfer decision.
  void accept();   // completes the engine's onManifest future with true
  void reject();   // completes it with false → engine rejects & terminates

  /// Cancel an in-progress receive (after a confirm dialog).
  Future<void> cancel();
}
```

- Holds `Completer<bool>? _decision` + the shared `TransferProgressProjector` (speed/ETA). `onManifest` callback: store completer, build `IncomingOffer` from the manifest, emit `loaded(view.copyWith(awaitingDecision:true, incomingOffer:…))`, return `_decision!.future`.
- `_onSnapshot`: project to `TransferView(role: receiver, …)`; on `phase==failed && failure!=null` → `emitError(failure)`; else `emitLoaded(view)`.
- Distinguishes a user reject (drives Home) from a recoverable failure (drives code-entry) via a `_rejectedByUser` flag set in `reject()`.
- `close()`: cancel subscription, `dispose()` the use case (closes engine/transport).

## 4. Connect receiver branch (features/pairing/presentation/connect)

The hub is reused; only the receiver entry UI is added.

- `connect_page.dart` `_CodeTab`: when `request.role == TransferRole.receiver`, render `CodeInput` + a Connect `PrimaryButton` (enabled at 6 digits) → `context.read<PairingCubit>().joinWithCode(code)`. The existing `connecting`/`connected`/`failure` panels are reused; `_onConnected` already calls `takeTransport()` and pops `ConnectResult{transport}`.
- `widgets/code_input.dart` (NEW): 6-digit entry — mono, digit-only `TextInputType.number` + input formatters, exposes `onCompleted(String code)` / `onChanged`; reduce-motion safe; a11y label. Reusable by #007/#009.
- **Failure → retry preserving code** (FR-023): on an `AppError` the field keeps its text; the user re-submits or edits. (The cubit re-`join`s; no code is cleared by the hub.)

## 5. Navigation & handoff (core/router)

```
AppRoutes.connect          '/connect'          extra: ConnectRequest{role}      → pops ConnectResult{transport}
AppRoutes.receiveProgress  '/receive/progress' extra: DataTransport (core type) → ReceiveTransferCubit.start
```

- Home "Nhận" → the receive entry coordinator (`receive_entry_page.dart`) pushes `connect` with `ConnectRequest(role: receiver)`.
- On the popped `ConnectResult`, the coordinator pushes `receiveProgress` with the **core-typed** `DataTransport` as `extra` (same decoupling shape as #004's `SendProgressArgs`, but receive needs only the transport — destination dir is resolved inside the use case).
- Flow routes use the **root navigator key** to hide the bottom nav (Constitution X / VI IA).
- **Reject** → the receive page pops the entire flow to Home (FR-009). **Recoverable failure** → pop back to the Connect/code-entry step with the code preserved (FR-023). **Done** (Complete) → Home.
- `core/router` composes pairing + receive; neither feature imports the other.

## 6. Incoming-transfer dialog (features/receive/presentation/widgets)

`IncomingTransferDialog` — built from `IncomingOffer`; follows the **Dialogs & Toasts** spec (avatar badge, title "‹Người gửi› muốn gửi cho bạn", body "N tệp · TỔNG · loại", primary **Nhận** gradient, secondary **Từ chối**). Shown via `BlocListener` when `view.awaitingDecision`; returns nothing — it calls `cubit.accept()`/`cubit.reject()`. Cupertino/Material-appropriate. All copy via ARB; sizes via mono/tabular `intl`.

## 7. Shared Progress/Complete (core/presentation/transfer)

- `TransferProgressView(view)` — badge by `view.role`, %/bar/speed/ETA/current "tệp N / M", DangerButton **Huỷ** (→ cancel-confirm dialog).
- `TransferCompleteView(view, onOpen, onShare, onSendAgain, onDone)` — summary (count/size/peer/elapsed); for `receiver`, a FileRow list with per-file **Mở** (`onOpen(path)`) + a **Chia sẻ** Share-all (`onShare(paths)`); for `sender`, **Gửi lại**/**Xong**. A **partial** view (`view.isPartial`) shows "Đã nhận X / N tệp" and a non-celebratory header, same actions over the files that did arrive.
- Both consume the shared `TransferView`; the receive/send pages wire the role-appropriate callbacks. No cross-feature import.

## 8. ARB additions (VI primary + EN)

Receive/prompt copy (`receiveEnterCode`, `receivePrompt*`, `receiveConnecting`, `receiveProgressBadge`, `receiveCompleteTitle`, `receivePartialTitle(x,n)`, `receiveOpen`, `receiveShare`, `receiveCancelConfirm*`, `receiveDone`) + receive-failure messages (§ data-model R6). `@description` on each (Constitution XIV).
