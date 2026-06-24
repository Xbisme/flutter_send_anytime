# Contract: Send Flow — cubits, use cases, navigation

UI/orchestration contracts for #004. Dart-flavored signatures (illustrative; final types follow the codebase). All fallible calls return `Result<T>`; cubits `.fold` to `AppLoaded`/`AppError`.

## Routes (added to `AppRoutes`)

```dart
static const connect = '/connect';        // shared pairing hub (send + receive)
static const sendProgress = '/send/progress';
// existing: send = '/send'
```

All three render outside the `StatefulShellRoute` (via `parentNavigatorKey: rootKey`) so the bottom nav is hidden (Constitution X / VI).

## Connect sub-flow contract (features/pairing)

The Connect screen is **file-agnostic** and **role-parameterized**, reused by #005.

```dart
class ConnectRequest {            // passed as go_router `extra`
  const ConnectRequest({required this.role}); // sender (send) | receiver (receive #005)
  final TransferRole role;
}

class ConnectResult {            // returned via context.pop(result)
  const ConnectResult({required this.transport});
  final DataTransport transport; // ownership transferred to the caller
}
```

Behavior:
- On open: `PairingCubit.host()` (sender) — shows `PairingHosting.code` + `remaining` countdown.
- On `PairingConnected`: call `PairingRepository.takeTransport()` (via the cubit), then `context.pop(ConnectResult(transport))`.
- On user cancel / back (FR-018): `context.pop(null)` and dispose the pairing session (no lingering code).
- On `PairingFailed(failure)`: render the localized message inline with **Retry** (re-`host()` → fresh code, FR-011) and **Back** (`pop(null)`).
- QR / Gần đây tabs + "Chia sẻ link mời": visible, disabled, "coming soon" (FR-009).

## `SendSelectionCubit` (features/send)

```dart
@injectable
class SendSelectionCubit extends AppCubit<SendSelection> {
  SendSelectionCubit(this._pickFiles);
  final PickFilesUseCase _pickFiles;

  // starts at AppLoaded(SendSelection.empty()) so the (empty) tray renders immediately
  Future<void> addFiles();           // pick → merge into selection; AppError on failure
  void removeAt(int index);          // remove one; recompute totals
  void clear();                      // reset to empty (for "Gửi tiếp")
}
```

- `addFiles()` calls `_pickFiles()` → `Result<List<FileSource>>`; success merges into the current `SendSelection`; a cancelled pick yields an empty list → no change (R3).
- Continue is enabled only when `state.data.isEmpty == false` (FR-005); enforced in the page.

## `SendTransferCubit` (features/send)

```dart
@injectable
class SendTransferCubit extends AppCubit<SendTransferView> {
  SendTransferCubit(this._startSend);
  final StartSendUseCase _startSend;

  Future<void> start(List<FileSource> sources, DataTransport transport);
  Future<void> cancel();             // engine.cancel(); honored on both ends
}
```

- `start(...)` subscribes to `TransferEngine.snapshots`, projects each to `SendTransferView` (R5), and `emitLoaded`. A terminal `failed` → `emitError(failure)`; `done`/`cancelled` stay `loaded` with the terminal phase so the view can branch.
- Page side effects (success haptic, navigation, confirm-cancel dialog) fire from a `BlocListener` (Constitution III), never `BlocBuilder`.
- The cubit is closed page-scoped; closing disposes the engine subscription and (if non-terminal) cancels the transfer.

## Use cases (features/send/domain)

```dart
@injectable
class PickFilesUseCase {            // wraps the core FilePickerService
  Future<Result<List<FileSource>>> call();
}

@injectable
class StartSendUseCase {            // builds the session + drives the engine seam
  Future<Result<void>> call({
    required List<FileSource> sources,
    required DataTransport transport,
  });
  // internally: TransferSession.fromSources(sources) → engine.startSendOnTransport(...)
  // exposes engine.snapshots to the cubit (via the engine instance from DI)
}
```

> Cubits inject **use cases**, not repositories/services (Constitution XI). `StartSendUseCase` and the `SendTransferCubit` share the same `TransferEngine` instance (one per transfer, `@injectable`); the use case starts it and the cubit reads its `snapshots`. (Impl detail: the use case may return the engine handle, or the engine is injected into both — finalized at tasks time; either keeps the engine as the single progress authority.)

## Core file service (core/services/file)

```dart
abstract interface class FilePickerService {
  Future<Result<List<FileSource>>> pickFiles(); // any type, multi-select
}

@Injectable(as: FilePickerService)
class FilePickerServiceImpl implements FilePickerService { /* file_picker 11 */ }
```

- Uses `FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any, withData: false, withReadStream: false)` → maps each `PlatformFile.path` to `DiskFileSource(path, mimeType: ...)`.
- Returns `Result.success(<>)` on a cancelled pick (no files), `Result.failure(AppFailure.unexpected(...))` on a picker error. Never logs paths (Constitution I).

## Navigation / coordination sequence

```dart
// SendSelectionPage "Tiếp tục":
final result = await context.push<ConnectResult>(
  AppRoutes.connect,
  extra: const ConnectRequest(role: TransferRole.sender),
);
if (result == null || !context.mounted) return;          // cancelled pairing
await context.push(
  AppRoutes.sendProgress,
  extra: SendProgressArgs(sources: selection.toSources(), transport: result.transport),
);

// SendTransferPage on done: stay on route, render Complete view.
//   "Gửi tiếp" → context.pop() back to selection + selectionCubit.clear() (or pop to /send).
//   "Xong"     → context.go(AppRoutes.home).
// SendTransferPage on failed: render Failure view.
//   "Thử lại" → context.pop() back to selection (selection intact) → user re-continues. (FR-025a)
// Cancel (transferring): confirm dialog → cubit.cancel() → context.go(home) / pop out. (FR-019)
```

`SendProgressArgs { List<FileSource> sources; DataTransport transport; }` is a plain carrier passed as `extra`.
