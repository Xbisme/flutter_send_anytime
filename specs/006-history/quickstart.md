# Quickstart: Lịch sử (History) — #006

**Date**: 2026-06-25 · **Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

How to build, run, and verify #006 locally. Assumes the #001–#005 toolchain is already set up.

---

## 1. Add dependencies

`pubspec.yaml` (versions verified pub.dev 2026-06-25 — see [research.md](research.md)):

```yaml
dependencies:
  drift: ^2.34.0
  drift_flutter: ^0.3.0        # bundles sqlite3 native libs + path_provider + isolate
  # path_provider already present (^2.1.6) — compatible with drift_flutter's ^2.1.5

dev_dependencies:
  drift_dev: ">=2.34.0 <2.34.1"  # codegen (2.34.1 needs analyzer ^13, conflicts with freezed 3.2.5)
```

```bash
flutter pub get
# commit pubspec.lock; on the next device build, expect ios/Podfile.lock churn
# (sqlite3_flutter_libs pod) — review per Constitution XV.
```

> Note: `flutter analyze` crashes on this detached-HEAD Flutter checkout — use **`dart analyze lib test`** (gate-equivalent), per the project toolchain note.

---

## 2. Generate drift + freezed code

The drift `AppDatabase`, tables, and the freezed history entities are code-generated:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This produces `lib/core/data/database/app_database.g.dart` and the `*.freezed.dart` for the history entities. Re-run after any schema/table/entity change. Exclude generated files from analysis is already handled by the project `analysis_options.yaml` (`**.g.dart`, `**.freezed.dart`).

---

## 3. Regenerate localizations

After adding the history ARB strings to `lib/l10n/arb/app_vi.arb` (primary) + `app_en.arb`:

```bash
flutter gen-l10n     # or it runs as part of build; new strings appear on context.l10n
```

---

## 4. Run

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

Manual happy path (after a real or test send/receive):
1. Complete a transfer via Gửi (or Nhận) → reach Complete.
2. Open the **Lịch sử** tab → the transfer appears under "Hôm nay", direction-colored.
3. Tap it → detail page lists every file with type + size.
4. From a **sent** record whose files still exist → **Gửi lại** opens Send pre-filled.
5. From a **received** record → **Mở** launches the file; **Chia sẻ** opens the share sheet.
6. Swipe/delete a record → it disappears; **Xoá tất cả** (with confirm) empties the list.
7. Reopen the app → records persist.
8. Open **Trang chủ** → the recent area shows the real transfer (no mock data).

---

## 5. Tests (no device needed)

```bash
very_good test --test-randomize-ordering-seed random
# or: flutter test
```

Coverage to expect green:
- **DAO round-trip** (`test/core/data/transfer_history_dao_test.dart`) — opens `AppDatabase` over `NativeDatabase.memory()`; insert (record + files in a tx) → `watchAll`/`watchRecent` → search/filter (direction, date, query) → `deleteById` (cascade) → `clearAll`.
- **Repository mapping** — row ↔ `TransferRecord`/`RecordedFile`, `Result` wrapping of failures, enum name (de)serialization incl. unknown-name fallback.
- **Recording** (`test/features/send/…`, `test/features/receive/…`) — driving a terminal `TransferView` records exactly one correctly-mapped record; completed / partial / cancelled / failed status mapping; pairing-stage failure records **nothing** (FR-001).
- **HistoryCubit** — list, search, direction/date filter, empty vs no-results states.
- **Widgets** — day grouping headers, empty state, clear-all confirmation dialog, detail render.

Pre-commit gate (Constitution Development Workflow):
```bash
dart format .
dart analyze lib test          # 0 issues
flutter test                   # all pass
dart run bloc_tools:bloc lint . # 0 violations (if available; tracked otherwise)
```

---

## 6. Verify against the spec

| Check | Spec ref |
|---|---|
| Only agreed-and-started transfers recorded (pairing failures excluded) | FR-001, Clarifications |
| Completed / partial / failed / cancelled all recorded with right status | FR-003, SC-002 |
| Records survive restart | FR-006, SC-003 |
| Day-grouped, newest-first, direction-colored | FR-009–FR-011, SC-001 |
| Search + direction + date filter; no-results vs empty | FR-016–FR-019, SC-004 |
| Re-send all-or-nothing; open; delete; clear-all (confirm) | FR-020–FR-024, SC-005/006 |
| Delete/clear never removes files on disk | FR-025, SC-006 |
| Home recent backfilled from the same store | FR-026–FR-028, SC-007 |
| Responsive at several hundred records | SC-008 |

---

## 7. Out of scope (do not build here)

Cloud/sync; deleting underlying files from history; editing records; retention limits/settings (#010); QR/link/nearby pairing-method capture beyond reserving the enum (#007–#009); real peer names (#010). No two-device smoke test — History is a local feature with no P2P surface.
