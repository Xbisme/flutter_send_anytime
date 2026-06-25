# Data Model: Lịch sử (History) — #006

**Date**: 2026-06-25 · **Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

Two layers: (a) the **drift schema** (persisted SQLite tables, in `core/data/`) and (b) the **domain entities** (`core/domain/history/`) the app works with. The repository maps between them.

---

## Domain entities (`lib/core/domain/history/`)

### Enums (`transfer_history_enums.dart`)

```dart
enum TransferDirection { sent, received }

/// Terminal outcome of an agreed-and-started transfer (FR-003).
enum TransferRecordStatus { completed, partial, failed, cancelled }

/// How the two devices paired. Only sixDigitCode exists today (#003);
/// the rest are reserved so #007–#009 add values without a schema change (FR-007).
enum PairingMethod { sixDigitCode, qr, shareLink, nearby }
```

Persisted as their **name string** (drift `TextColumn`) — name-based storage tolerates enum reordering and makes the DB self-describing; unknown future names degrade to a safe default on read.

### `TransferRecord` (`transfer_record.dart`, freezed)

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | UUID (existing `uuid` dep); stable key for delete/detail/extra. |
| `direction` | `TransferDirection` | sent / received. |
| `peerLabel` | `String` | Generic localized label today; real name fills it in #010 (FR-008). |
| `status` | `TransferRecordStatus` | completed / partial / failed / cancelled. |
| `pairingMethod` | `PairingMethod` | `sixDigitCode` for the MVP (FR-007). |
| `fileCount` | `int` | Number of files **offered** in the transfer. |
| `totalBytes` | `int` | Sum of offered file sizes. |
| `createdAt` | `DateTime` | Terminal-state timestamp (UTC stored; local for day grouping, FR-010). |
| `files` | `List<RecordedFile>` | Per-file detail (detail page, re-send, open). |

Derived (no storage): `receivedCount`/`completedCount` for the "nhận X / N tệp" partial label is computed from `files` where `path != null && status completed` — but since we only persist files that were part of the transfer, partial detail is captured via each `RecordedFile.included` flag (below) rather than recomputing.

### `RecordedFile` (`transfer_record.dart`, freezed)

| Field | Type | Notes |
|---|---|---|
| `name` | `String` | Basename only (no directory). |
| `mimeType` | `String?` | Best-effort type (drives icon + type summary). |
| `size` | `int` | Bytes. |
| `path` | `String?` | Sender: original source path (re-send existence check). Receiver: final on-device path (open). Null when not applicable/unknown. |
| `included` | `bool` | Whether this file actually completed+verified in the transfer (true for all files of a `completed` record; mixed for `partial`). Lets the detail page show which files of a partial transfer landed. |

### `HistoryFilter` (`history_filter.dart`, freezed)

| Field | Type | Notes |
|---|---|---|
| `direction` | `TransferDirection?` | null = both. |
| `from` / `to` | `DateTime?` | Inclusive local-day range; null = unbounded. |
| `query` | `String?` | Trimmed text; matches `peerLabel` or any `RecordedFile.name` (case-insensitive). |

`HistoryFilter.none` = all-null (the default, full list). `isActive` = any field set (drives "no results" vs "empty" state, FR-019).

---

## drift schema (`lib/core/data/database/`)

**`schemaVersion = 1`** (initial). `MigrationStrategy(onCreate: m.createAll())`; no `onUpgrade` yet — future bumps add `from-N` steps + tests (Constitution IX).

### Table `transfer_records` (`tables/transfer_records_table.dart`)

| Column | drift type | Constraints |
|---|---|---|
| `id` | `text()` | **PRIMARY KEY** (UUID). |
| `direction` | `text()` | enum name (`sent`/`received`). |
| `peer_label` | `text()` | not null. |
| `status` | `text()` | enum name. |
| `pairing_method` | `text()` | enum name. |
| `file_count` | `integer()` | not null. |
| `total_bytes` | `integer()` | not null (64-bit). |
| `created_at` | `dateTime()` | not null; **indexed** for newest-first ordering + date filter. |

### Table `transfer_record_files` (`tables/transfer_record_files_table.dart`)

| Column | drift type | Constraints |
|---|---|---|
| `id` | `integer()` | **PRIMARY KEY AUTOINCREMENT**. |
| `record_id` | `text()` | **FK → transfer_records.id**, `onDelete: KeyAction.cascade`; **indexed**. |
| `name` | `text()` | basename. |
| `mime_type` | `text().nullable()` | |
| `size` | `integer()` | not null. |
| `path` | `text().nullable()` | source path (sent) / final path (received). |
| `included` | `boolean()` | not null, default `true`. |
| `position` | `integer()` | not null — preserves manifest order in the detail list. |

`PRAGMA foreign_keys = ON` is enabled on open so the cascade fires (a deleted record removes its file rows; clear-all truncates both — **never touches the files on disk**, FR-025).

---

## DAO (`lib/core/data/daos/transfer_history_dao.dart`)

| Method | Returns | Behavior |
|---|---|---|
| `insertRecord(TransferRecord)` | `Future<void>` | **Transaction**: insert parent + all child file rows atomically. |
| `watchAll(HistoryFilter)` | `Stream<List<_RecordWithFiles>>` | Reactive; `WHERE` direction + `created_at` range; text `query` via `LIKE` on `peer_label` or an `EXISTS` over child `name`; `ORDER BY created_at DESC`. |
| `watchRecent(int limit)` | `Stream<List<_RecordWithFiles>>` | `ORDER BY created_at DESC LIMIT n` (Home). |
| `getById(String id)` | `Future<_RecordWithFiles?>` | Single record + files. |
| `deleteById(String id)` | `Future<void>` | Cascade removes file rows. |
| `clearAll()` | `Future<void>` | Delete all from both tables. |

`_RecordWithFiles` is an internal join holder; the **repository** maps it to/from the `TransferRecord` domain entity and wraps every public call in `Result<T>` (try/catch → `AppFailure.fileWriteFailed`/`fileReadFailed`/`unknown`, Constitution V — DAO throws, repository catches).

---

## Mapping rules (feature mappers → `TransferRecord`)

**Send** (`features/send`, after terminal `TransferView`, with the started `List<FileSource>`):
- `direction = sent`; `peerLabel` = generic label; `pairingMethod = sixDigitCode`.
- `files`: one `RecordedFile` per source — `name`/`size`/`mimeType` from the `FileSource`; `path` = the `DiskFileSource.path` (for re-send existence); `included` = whether that file completed.
- `status` from the phase mapping (Decision 3): done→completed, partial→partial, cancelled→cancelled, failed→failed.

**Receive** (`features/receive`, after terminal `TransferView`):
- `direction = received`; `peerLabel` = generic label; `pairingMethod = sixDigitCode`.
- `files`: one `RecordedFile` per `TransferView.items` entry — `name`/`size`/`mimeType` from the item; `path` = `finalPath` (for open) when completed, else null; `included` = `status == completed`.
- `fileCount`/`totalBytes` = the **offered** manifest totals (so a partial reads "nhận X / N tệp" against the original N).

---

## Validation rules

- `id` non-empty and unique (UUID); insert of a duplicate id is a programmer error (the cubit generates a fresh id per terminal transfer — FR-004, one record per transfer).
- `fileCount >= files.length` is **not** required (offered count may exceed landed files in a partial); `fileCount` reflects the manifest, `files` reflects what was recorded.
- `name` is a basename only (no separators) — reuses the #002 manifest safe-name guarantee; the repository does not re-derive paths from it.
- `path` is stored verbatim but **never trusted for writing** — open/re-send only ever *read* it and first check `File(path).existsSync()` (Constitution I: no write outside app-sanctioned locations; History never writes files at all).
- Enum columns store names; an unrecognized name on read maps to a safe default (`PairingMethod.sixDigitCode` / `TransferRecordStatus.failed`) and is logged at debug as a non-sensitive schema note.

---

## State & lifecycle

A `TransferRecord` is **immutable once written** — there is no edit/update path in #006 (no annotations, no status changes). The only lifecycle operations are **create** (on terminal transfer) and **delete** (single or clear-all). Files on disk follow an independent lifecycle (FR-025): deleting a record never deletes a file; deleting a file (via the OS Files app) only makes a later `open` surface "file no longer available" (FR-022) and a `re-send` unavailable (FR-021).
