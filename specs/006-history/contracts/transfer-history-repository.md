# Contract: Transfer History Repository + Write Hook — #006

**Date**: 2026-06-25 · **Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

This is the internal contract (Flutter app has no external API — Phase 1 "interface contract" = the core seam every feature depends on). It defines the **one core boundary** shared by Send, Receive, History, and Home. Stable shape so the four features integrate without importing each other.

---

## Core interface: `TransferHistoryRepository`

Location: `lib/core/domain/history/transfer_history_repository.dart` (interface) · impl `@LazySingleton(as: TransferHistoryRepository)` in `lib/core/data/transfer_history_repository_impl.dart`.

```dart
abstract interface class TransferHistoryRepository {
  /// WRITE — persist one finished transfer (Send/Receive, on terminal state).
  /// Exactly one record per agreed-and-started terminal transfer (FR-001/FR-004).
  Future<Result<void>> record(TransferRecord record);

  /// READ — reactive, day-orderable list for the History tab.
  /// Direction + date filtered in SQL; text query matches peer label / file names.
  Stream<List<TransferRecord>> watch(HistoryFilter filter);

  /// READ — newest-first capped list for the Home recent area (FR-026).
  Stream<List<TransferRecord>> watchRecent(int limit);

  /// READ — single record (detail fallback / deep navigation).
  Future<Result<TransferRecord?>> getById(String id);

  /// DELETE — remove one record (record-only; never touches files, FR-025).
  Future<Result<void>> deleteById(String id);

  /// DELETE — remove all records (record-only; confirmation is a UI concern).
  Future<Result<void>> clearAll();
}
```

**Contract guarantees**
- `record` is idempotent at the call-site level only by id uniqueness; callers MUST generate a fresh `id` per terminal transfer and call exactly once (FR-004).
- `watch`/`watchRecent` emit a fresh list whenever the underlying table changes (drift reactive streams) — a record written while the History tab or Home is open appears without manual refresh (spec edge case).
- Write/read failures are surfaced as `Result.failure(AppFailure …)` — never thrown across the boundary (Constitution V). Streams do not carry `Result`; a stream error maps to the cubit's `error` state.
- The repository **never writes, moves, or deletes a file on disk** — it persists metadata + path strings only (Constitution I/II; FR-025).

---

## Write hook: `RecordTransferUseCase`

Location: `lib/core/domain/history/usecases/record_transfer_usecase.dart` (`@injectable`). The write half, injected into `SendTransferCubit` and `ReceiveTransferCubit` (the only additive edit to merged #004/#005 code).

```dart
@injectable
class RecordTransferUseCase {
  const RecordTransferUseCase(this._repository);
  final TransferHistoryRepository _repository;
  Future<Result<void>> call(TransferRecord record) => _repository.record(record);
}
```

**Calling contract (Send & Receive cubits)**
- Call **once**, when the snapshot stream reaches a terminal phase (`done`/`failed`/`cancelled`) for an **agreed-and-started** transfer (Send: a `startSend` was issued; Receive: the user accepted — `awaitingDecision` was cleared and transfer began). Pairing-stage failures MUST NOT call it (FR-001).
- Build the `TransferRecord` via the feature's mapper (Send uses its started `List<FileSource>`; Receive uses `TransferView.items` final paths) per [data-model.md](../data-model.md) → *Mapping rules*.
- A `Result.failure` from `record(...)` MUST NOT alter the user-visible transfer outcome — recording is best-effort side persistence; on failure, log a non-sensitive note (`AppLogger`) and continue (the Complete/partial screen still shows). History being momentarily un-written is recoverable; failing the transfer over it is not acceptable.

---

## Read use cases (`features/history/domain/usecases/`)

Thin wrappers injected into `HistoryCubit` / detail (Constitution III — cubits inject use cases):

| Use case | Wraps | Used by |
|---|---|---|
| `WatchHistoryUseCase` | `repo.watch(filter)` | `HistoryCubit` (list + search/filter) |
| `WatchRecentTransfersUseCase` | `repo.watchRecent(limit)` | `features/home` data source (FR-026) |
| `GetHistoryDetailUseCase` | `repo.getById(id)` | detail fallback (extra is primary) |
| `DeleteRecordUseCase` | `repo.deleteById(id)` | row/detail delete (FR-023) |
| `ClearHistoryUseCase` | `repo.clearAll()` | clear-all (FR-024) |

---

## Navigation contract

- New route constant `AppRoutes.historyDetail` (e.g. `/history/detail`), pushed via `context.push(AppRoutes.historyDetail, extra: record)` with a **core-typed** `TransferRecord` (mirrors #004/#005 core-typed `extra` — features pass core types, never feature types).
- Re-send routes into the existing Send flow: reconstruct `List<FileSource>` (`DiskFileSource` from each `RecordedFile.path`) **only if every path exists** (FR-020/021), then hand off through the established Send entry (`AppRoutes.connect`/send selection) using the existing core-typed handoff — History does not import `features/send` internals.

---

## DI registration summary

| Symbol | Annotation | Layer |
|---|---|---|
| `AppDatabase` | `@lazySingleton` (+ dispose) | core/data |
| `TransferHistoryDao` | constructed from `AppDatabase` (drift) / `@lazySingleton` | core/data |
| `TransferHistoryRepository` ← `…Impl` | `@LazySingleton(as: …)` | core/data |
| `RecordTransferUseCase` | `@injectable` | core/domain |
| History read use cases | `@injectable` | features/history/domain |
| `HistoryCubit` | `@injectable` | features/history |

`@lazySingleton` for the DB/repo (single shared connection across features — Constitution XI: shared services are singletons; eager `@singleton` is forbidden). The DB connection opens lazily on first use and is closed on DI reset (tests) / app teardown.
