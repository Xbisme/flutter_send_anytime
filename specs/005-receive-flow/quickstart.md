# Quickstart — Receive Flow (Nhận) #005

How to run, test, and demo the receive flow. Closes the MVP loop with #004.

## Prerequisites

- Flutter (latest stable 3.x), Dart `^3.11.0`; `flutter pub get` after the new deps land.
- New packages (verified pub.dev 2026-06-25): `path_provider ^2.1.6`, `share_plus ^13.1.0`, `open_filex ^4.7.0`.
- The signaling relay running for any real (non-loopback) pairing: `dart run server/bin/server.dart` (dev → `ws://localhost:8080`, per `AppConfig.signalingEndpoint`).
- iOS device build (deferred) needs Info.plist: `UIFileSharingEnabled=YES`, `LSSupportsOpeningDocumentsInPlace=YES` (received files visible in Files). Android: app-specific docs dir — nothing extra; `share_plus` 13.x wants Java 17 / AGP ≥ 8.12.1.

## Run the flow (dev flavor)

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

1. Home → **Nhận**.
2. Enter the 6-digit code a sender (#004 Gửi, or a test host) is currently showing → **Kết nối**.
3. On connect, the **incoming-transfer prompt** appears → **Nhận** (or **Từ chối**).
4. Watch progress (%/speed/ETA/tệp N/M) → **Hoàn tất**: tap **Mở** on a file or **Chia sẻ** all; **Xong** → Home.

### Demo without a second device (CI-style)
Use the loopback round-trip test (below) — it drives a real sender engine → real receiver engine to disk, no server/device.

## Test

```bash
very_good test --test-randomize-ordering-seed random
# or: flutter test   /   dart test
```

Gate (Constitution XII / Pre-Commit):
```bash
dart format .
dart analyze lib test          # gate-equivalent (flutter analyze crashes on this checkout)
flutter test
dart run bloc_tools:bloc lint .  # if available; else bloc_lint
```

### Key new tests
- `core/services/transport/` — **`startReceiveOnTransport` loopback round-trip**: sender (`startSendOnTransport`) ↔ receiver (`startReceiveOnTransport`) over a paired loopback `DataTransport`; assert single + multi-file arrive, hashes match, files exist at the temp destination, and a forced mid-transfer drop yields a **partial** (earlier files kept, `.part` removed). Existing `startReceive` loopback tests still green.
- `features/receive/` — `ReceiveTransferCubit`: snapshot→`TransferView` mapping; `onManifest` → `awaitingDecision`+`IncomingOffer`; `accept()`/`reject()` resolve the completer; terminal `done` / **partial** / `error`; reject routes Home vs failure routes code-entry; `cancel()`.
- `features/receive/` widgets — `IncomingTransferDialog` (offer summary + Nhận/Từ chối), receiver-role `TransferProgressView`/`TransferCompleteView` (Open/Share + partial summary).
- `features/pairing/` — Connect **receiver branch**: `CodeInput` enables Connect at 6 digits → `joinWithCode`; invalid/expired/full/unreachable failure → message + retry preserves the code.

## Demo with two physical devices (deferred manual smoke — tracked in tasks.md)

1. Run the relay reachable by both (or a hosted dev endpoint).
2. Device A: Gửi → pick files → read the code. Device B: Nhận → enter code → accept.
3. Verify: files arrive intact (hash), land in the app folder (iOS Files / Android app dir), Open + Share work, and a forced disconnect mid-transfer yields a clean partial/failure with the `.part` gone. This is the **MVP checkpoint** dogfood.

## What to look for (acceptance)

- No storage/photos permission prompt anywhere (SC-004).
- Nothing written before **Nhận** is tapped (FR-006/007); **Từ chối** writes nothing and returns to Home (FR-009).
- Every file shown as received passed its hash (SC-002); a partial outcome keeps only verified files, `.part` discarded (SC-003).
- Logs carry only phase/error-type — no file names/paths/peer/IP/SDP (Constitution I).
- Reduce-Motion: connecting spinner static.
