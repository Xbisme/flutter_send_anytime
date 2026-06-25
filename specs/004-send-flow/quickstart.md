# Quickstart: Send Flow (Gửi)

How to build, test, and demo #004. Assumes #001–#003 are merged.

## Prerequisites

- Flutter + Dart toolchain (the repo's pinned SDK).
- The signaling relay running for any real (non-loopback) pairing:
  ```bash
  cd server && dart run bin/server.dart      # listens on ws://localhost:8080 (dev)
  ```
- Dev flavor uses `AppConfig.signalingEndpoint = ws://localhost:8080` + Google STUN.

## Add the dependency (Constitution XV — verified pub.dev 2026-06-24)

```yaml
# pubspec.yaml → dependencies
file_picker: ^11.0.2
```

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed + injectable
```

No new pods/entitlements (the document picker needs none). `permission_handler` is **not** added in #004 (see research.md R3).

## Run

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

Home → **Gửi** → pick files → **Tiếp tục** → a 6-digit code appears with a countdown → have a receiver join (the #005 flow, or the dev pairing-debug page on a second device joining the code, or a test harness) → watch progress → **Hoàn tất**.

> Until #005 lands, end-to-end on real devices uses the **dev pairing-debug** page on the receiver side, or the deferred two-device smoke. The send UI itself is fully testable via the loopback + widget tests below.

## Test

```bash
very_good test --test-randomize-ordering-seed random
# or: flutter test
```

Expected new coverage:
- **`SendSelectionCubit`** — add merges + recomputes count/total; remove updates; empty-guard; clear resets.
- **`SendTransferCubit`** — snapshot→`SendTransferView` projection (%, speed, ETA, current file); `done`/`failed`/`cancelled` transitions; `cancel()` calls the engine.
- **`startSendOnTransport` loopback round-trip** — sender engine over a paired `LoopbackDataTransport` → receiver engine; assert files arrive, integrity matches, terminal `done`.
- **Connect page widget** — renders the code + countdown, disabled QR/Gần đây tabs, failure→retry, and pops `ConnectResult` on connected.
- **Send selection + progress widgets** — tray with per-file/total size, empty-state CTA disabled; progress header (%/speed/ETA/current file) and complete summary render with mono tabular figures.

## Gate (pre-commit, Constitution Development Workflow)

```bash
dart format .
dart analyze            # 0 issues (flutter analyze crashes on this checkout — use dart analyze)
flutter test            # all pass
dart run bloc_tools:bloc lint .   # 0 violations (if available)
```

## Demo checklist (maps to acceptance scenarios)

- [ ] Empty selection → "Tiếp tục" disabled (FR-005).
- [ ] Multi-select any types → per-file + total size shown (FR-002/003).
- [ ] Remove a file → totals update (FR-004).
- [ ] Code + countdown shown; QR/Gần đây disabled (FR-007/008/009).
- [ ] Receiver joins → auto-advances to progress (FR-010).
- [ ] Progress shows %/speed/ETA/current file in mono (FR-015/017); peer shows generic label (FR-015, Q1).
- [ ] Cancel mid-transfer → confirm → aborts + peer informed (FR-019/020).
- [ ] Success → completion summary + Xong / Gửi tiếp (FR-022/023).
- [ ] Receiver declines → "đã từ chối" + retry keeps selection (FR-024, FR-025a).
- [ ] Connection drop mid-transfer → "mất kết nối" + retry, no crash (FR-025).
- [ ] Reduce-Motion on → radar + spinner static, info still textual (FR-029).

## Deferred (manual)

- **Two-physical-device send smoke** — real NAT + multi-GB throughput. Tracked in tasks.md banner.
