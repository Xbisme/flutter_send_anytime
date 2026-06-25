# Research: Lịch sử (History) — #006

**Date**: 2026-06-25 · **Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

All `NEEDS CLARIFICATION` from Technical Context are resolved below. Versions were fetched from pub.dev on 2026-06-25 (Constitution XV).

---

## Decision 1 — Persistence: drift (SQLite) via drift_flutter

**Decision**: Use `drift` (SQLite ORM with codegen) as the persistence engine, with `drift_flutter` providing the database connection (it bundles the native sqlite3 libraries, resolves the on-device file path via `path_provider`, and runs the DB on a background isolate). Generated code via `drift_dev` + the existing `build_runner`.

**Versions** (pub.dev, 2026-06-25):
- `drift ^2.34.0` — runtime, sdk `>=3.10.0 <4.0.0` (our SDK is `^3.11.0` ✓)
- `drift_flutter ^0.3.0` — runtime; pulls `drift ^2.30.0`, `path_provider ^2.1.5` (we already pin `^2.1.6` ✓), `sqlite3`, `sqlite3_flutter_libs ^0.6.0+eol`, `sqlcipher_flutter_libs ^0.7.0+eol`
- `drift_dev` pinned to `2.34.0` (`>=2.34.0 <2.34.1`) — dev dep, sdk `>=3.10.0 <4.0.0` ✓

**Rationale**: The constitution **mandates drift (SQLite) for transfer history** (Technical Standards → "Local persistence: drift (SQLite) for transfer history only"; Principle IX names drift migrations explicitly). drift gives compile-time-checked schema, typed queries, reactive `Stream` queries (ideal for a live-updating list + Home recent), transactions (one record + its files inserted atomically), and a first-class migration framework (Constitution IX). `drift_flutter` removes the manual native-setup boilerplate (`sqlite3_flutter_libs`, app-documents path, isolate).

**Alternatives considered**:
- *Raw `sqflite`* — rejected: no typed schema/queries, no reactive streams, weaker migration story; more hand-written SQL to keep correct.
- *`shared_preferences` / JSON file* — rejected: no querying/filtering/indexing, poor at "several hundred records" (SC-008), no migration safety; violates the constitution's drift mandate.
- *Hand-wiring `drift` + `sqlite3_flutter_libs` + `path_provider` directly (no `drift_flutter`)* — viable but more boilerplate (isolate + path + native lib registration). `drift_flutter`'s `driftDatabase(name:)` is the maintainer-recommended path and keeps setup to one line; we accept the transitive `sqlcipher_flutter_libs` (unused — we don't enable encryption) for that simplicity.

**`+eol` note**: `sqlite3_flutter_libs 0.6.0+eol` and `sqlcipher_flutter_libs 0.7.0+eol` carry an `+eol` build tag marking the end of the `0.x` line; they remain the current published versions that `drift_flutter 0.3.0` depends on. We do **not** hand-pin them — they arrive transitively and `pubspec.lock` will capture the resolved versions (committed per Constitution XV). When drift_flutter publishes a successor major, revisit at that time.

**Native impact (verify at device build, Constitution XV)**: `sqlite3_flutter_libs` adds a CocoaPods pod (iOS) and a bundled `.so` (Android) → expect `ios/Podfile.lock` churn on the next `pod install`. SQLite has no runtime permissions and supports iOS 13 / Android 26 far below our floors. `sqlcipher_flutter_libs` is pulled transitively but unused (we open a plain, unencrypted DB); it adds binary size only.

---

## Decision 2 — Database location: `core/data/` (not inside a feature)

**Decision**: Put the drift `AppDatabase`, tables, DAO, and the `TransferHistoryRepositoryImpl` in `lib/core/data/`. The repository **interface** and the `TransferRecord` domain entity live in `lib/core/domain/history/`.

**Rationale**: Four features touch this store — **Send** and **Receive** write records, **History** and **Home** read them. Constitution XI forbids `lib/core/` importing features and forbids feature↔feature imports. If the DB lived in `features/history/`, then Send/Receive/Home would have to import it — a cross-feature import violation. The only legal shared home is `core/`. The constitution's repo map already anticipates this: `core/data/ # drift database + DAOs (history)`. Features depend on the **core** repository through DI (Constitution: "Cross-feature communication MUST go through core services or DI").

**Alternatives considered**:
- *DB in `features/history/`, exposed via a core interface* — rejected: the interface would still need a core home and the impl's drift types would leak; cleaner to keep the whole persistence layer in core.
- *A separate `core/services/` history service instead of `core/data/`* — rejected: persistence belongs in the `data/` layer per the repo map; `services/` is for transport/signaling/file engines.

---

## Decision 3 — Write path: one core `RecordTransferUseCase`, per-feature mappers

**Decision**: A single `RecordTransferUseCase` in `core/domain/history/usecases/` wraps `TransferHistoryRepository.record(...)`. Both `SendTransferCubit` and `ReceiveTransferCubit` inject it and call it once when they detect a terminal, **agreed-and-started** transfer. Each feature owns a small mapper that builds a `TransferRecord` from the data it has (Send: the `List<FileSource>` it started with → source paths for re-send; Receive: the `TransferView.items` `finalPath`s).

**Rationale**: Honors "inject Use Cases (not repos) into Cubits" (Constitution III) without duplicating the write logic across two features. The mapping genuinely differs by direction (sent files carry an originating disk path for re-send; received files carry a final on-device path for open), so the mappers are per-feature; the persistence call is shared. This is the **only edit to merged #004/#005 code** — additive (one injected use case + one call on the existing terminal branch), mirroring the additive `startSendOnTransport`/`startReceiveOnTransport` seams of #004/#005.

**Recording threshold (Clarifications 2026-06-25, FR-001)**: record **only** once a transfer is agreed-and-started (manifest exchanged + accepted). The cubits already distinguish this: a record is written when the phase reaches `done`/`failed`/`cancelled` *after* a manifest existed (Send: after `startSend`; Receive: only after the user accepted — `awaitingDecision` cleared and transfer began). Pairing-stage failures (invalid/expired code, room full, relay unreachable, reject-before-accept, drop-before-manifest) never reach that point, so they are naturally excluded.

**Status mapping** (`TransferView` → `TransferRecordStatus`):
- `phase == done` → `completed`
- terminal but `completedCount > 0 && < fileCount` (`isPartial`) → `partial`
- `phase == cancelled` → `cancelled`
- `phase == failed` (no/zero completed) → `failed`

**Alternatives considered**:
- *Record from the core `TransferEngine` directly* — rejected: the engine's generic `FileSource`/item view does not expose the sender's originating disk path (needed for re-send) or the peer label/pairing method; the feature layer has that context.
- *A per-feature `RecordTransferUseCase` in each of send/receive* — rejected: duplicates identical repo-forwarding logic; the write is one core capability.

---

## Decision 4 — Data model: two tables, path-reference per file

**Decision**: `transfer_records` (1) ──< `transfer_record_files` (N). Each file row stores `name`, `mimeType`, `size`, and a nullable `path` (sender: original source path for re-send availability; receiver: final on-device path for open). Full schema in [data-model.md](data-model.md).

**Rationale**: Re-send (FR-020/021) needs each sent file's original path to test existence (all-or-nothing per Clarifications); open (FR-022) needs each received file's final path. A normalized child table keeps per-file detail for the detail page (FR-014) and avoids JSON-blob querying. `totalBytes`, `fileCount`, `direction`, `status`, `pairingMethod`, `peerLabel`, `createdAt` live on the parent for fast list rendering without joining children.

**Reserved-for-future fields** (no schema change later, FR-007/FR-008): `pairingMethod` is an enum stored as text/int that already reserves `qr`/`shareLink`/`nearby` (#007–#009); `peerLabel` is a plain string that a real device name (#010) can fill — neither needs migration.

**Alternatives considered**:
- *Single table with a JSON files column* — rejected: can't query/aggregate per-file, weaker typing, awkward detail rendering.
- *Storing file bytes/thumbnails* — rejected outright by Constitution II (no content retention).

---

## Decision 5 — Querying, grouping, search/filter

**Decision**: The repository exposes `Stream<List<TransferRecord>> watch(HistoryFilter)` and `Stream<List<TransferRecord>> watchRecent(int limit)`. `HistoryFilter` carries `direction?`, `dateRange?`, and `query?`. Direction + date range are applied in SQL (`WHERE`); the text `query` matches peer label and file names (SQL `LIKE` over a joined/`EXISTS` subquery). **Day grouping is computed in the cubit/presentation** from each record's local-day bucket — not in SQL — using `intl` for "Hôm nay/Hôm qua"/date headers.

**Rationale**: Reactive drift streams make the list and Home recent auto-refresh when a new record lands while browsing (edge case: concurrent write). Pushing direction/date into SQL keeps result sets small; grouping by local day is a presentation concern (timezone-dependent, FR-010) best done in Dart. At the expected scale (hundreds of records, SC-008) this is comfortably fast; lazy slivers render only visible sections.

**Alternatives considered**:
- *Full-text search (FTS5)* — rejected as premature (Constitution XIII) at this scale; simple `LIKE` suffices and avoids an FTS virtual table + its migration weight.
- *Grouping in SQL (`GROUP BY date`)* — rejected: harder to localize headers and to keep "Hôm nay/Hôm qua" relative; Dart grouping is clearer.

---

## Decision 6 — Home recent backfill via the existing FR-008 seam

**Decision**: `features/home` gains a real data source that reads `watchRecent(limit)` from the core repository and maps records → the existing `TransferGroupModel` recent-transfers section of `HomeDashboard`, keeping the `HomeDashboard` contract and `HomeCubit`/UI unchanged (the #001 FR-008 seam). The other dashboard sections (media gallery, stat tiles) remain placeholder — they are out of #006 scope and owned by later media/stats work.

**Rationale**: #001 deliberately left `HomePlaceholderDataSource` as a swap seam ("#006 replaces this with a real (drift-backed) source without changing the HomeDashboard contract or the cubit/UI"). Honoring that keeps the change minimal and avoids touching Home's UI. Empty state (FR-027) falls out of an empty recent list.

**Alternatives considered**:
- *New Home cubit/contract* — rejected: unnecessary churn; the seam exists precisely to avoid it.

---

## Decision 7 — Detail navigation + actions

**Decision**: New route `AppRoutes.historyDetail`; the list and Home recent both `context.push` it with the core-typed `TransferRecord` as go_router `extra` (no DB round-trip, mirrors the established core-typed-extra handoff from #004/#005). Actions: **re-send** routes into the existing Send flow with reconstructed `FileSource`s (all-or-nothing existence check first, FR-020/021); **open** uses `open_filex`; **delete/clear** call the repo then drift streams refresh the list; **clear-all** uses a platform confirm dialog + `DangerButton`.

**Rationale**: Reuses every existing mechanism (core-typed extra, `open_filex`, `share_plus`, shared widgets) — no new transport, no new pairing. Re-send re-enters Send cleanly (new code/pairing); it does not reconnect to the original peer (Assumptions).

**Alternatives considered**:
- *Pass only a record id and re-query in detail* — rejected as unnecessary at this scale; passing the already-loaded record is simpler and matches the project's core-typed-extra pattern. (A future deep-link into detail, if ever needed, would re-query by id — noted, not built.)

---

## Decision 8 — Testing without devices

**Decision**: DAO/repository tests open `AppDatabase` over drift's in-memory `NativeDatabase.memory()` (from `package:drift/native.dart`), exercising insert→watch→search→delete→clearAll and the row↔domain mapping. Cubit tests mock `TransferHistoryRepository` (mocktail) and feed record streams. Recording is tested by driving a terminal `TransferView` through the send/receive mapper + `RecordTransferUseCase` and asserting one correctly-shaped `record()` call. Widget tests cover day-grouping, empty vs no-results states, detail, and the clear-all confirmation.

**Rationale**: `NativeDatabase.memory()` resolves the host's libsqlite3 (present on macOS/Linux CI/dev), so the full persistence path runs in `flutter test` with no device or native plugin — matching Constitution XII's "testable without a device" bar. History is a local feature with no P2P surface, so **no two-device smoke test is required** (unlike #002–#005).

**Migrations (Constitution IX)**: schema starts at version 1 with a `MigrationStrategy(onCreate: ...)`. There is no prior version to migrate from, so no migration test is needed yet; the plan reserves the structure so any future schema bump adds a `from-N` migration + its test, satisfying "cover every prior schema version."
