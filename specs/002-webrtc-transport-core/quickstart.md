# Quickstart: WebRTC Transport & Transfer Protocol Core

**Feature**: `002-webrtc-transport-core`

This engine has **no UI**. You exercise it through the **in-process loopback** signaling channel — the same path CI uses. This doc shows the canonical round-trip and how to verify the feature.

## Prerequisites

- Branch `002-webrtc-transport-core`.
- `pubspec.yaml` has `flutter_webrtc: ^1.5.2`, `crypto: ^3.0.7`, `uuid: ^4.5.3` (added during implementation).
- `flutter pub get` (and `pod install` in `ios/` after the first add for the WebRTC framework).

## Canonical in-process round-trip (the shape every test follows)

```dart
// 1. Connected loopback signaling pair (no server, no second device).
final (senderSig, receiverSig) = LoopbackSignalingChannel.pair();

// 2. Two engine instances (each transfer gets its own engine).
final sender = getIt<TransferEngine>();
final receiver = getIt<TransferEngine>();

// 3. Build a session from disk-backed sources (tests use temp files).
final session = TransferSession.fromSources([
  DiskFileSource(tmpFile('a.bin', 1 << 20)), // 1 MiB
  DiskFileSource(tmpFile('b.txt',  4096)),
]);

// 4. Receiver listens first (auto-accepts by default).
final recvFut = receiver.startReceive(
  signaling: receiverSig,
  destinationDir: tmpDir,            // Directory.systemTemp subdir in tests
  // onManifest: (m) async => true,  // default
);

// 5. Sender starts; both drive the same state machine to `done`.
final sendFut = sender.startSend(session: session, signaling: senderSig);

final results = await Future.wait([sendFut, recvFut]);

// 6. Assert success + byte-identical files + integrity.
expect(results.every((r) => r is Success), isTrue);
expect(receiver.current.phase, TransferPhase.done);
// files at tmpDir are byte-identical to the sources (hash match)
```

Observe progress by listening to `sender.snapshots` / `receiver.snapshots`.

## Verifying the feature (maps to Success Criteria)

Run the suite:

```bash
flutter pub get
dart format --set-exit-if-changed .
dart analyze lib test            # 0 issues (flutter analyze crashes on this Flutter checkout — see project-context)
flutter test                     # all green, deterministic
# or: very_good test --test-randomize-ordering-seed random
```

Required automated coverage (SC-009) — each is a test under `test/core/services/transport/`:

| Test | Asserts | SC |
|---|---|---|
| single-file round-trip | byte-identical + hash match + `done` | SC-001/002 |
| multi-file round-trip | sequential order, overall progress, `done` after last verify | SC-002 |
| manifest accept / reject | `onManifest=false` → `transferRejected`, no files | FR-014A |
| multi-file fail-fast | one file corrupt → whole session `failed`, no partial files | FR-013A / SC-003 |
| collision auto-rename | second `a.txt` → `a (1).txt`, original intact | FR-021 |
| cancel from sender / receiver | both `cancelled`, no `.part`, handles released | SC-006 |
| corrupted-chunk integrity | `integrityCheckFailed`, nothing at destination | SC-003 |
| malformed manifest | named failure, no crash | FR-015 |
| backpressure (slow consumer) | sender pauses > `kHighWaterMark`, completes intact | FR-011 |
| bounded memory (large/simulated) | peak buffered ≤ `kHighWaterMark + kChunkSize` | SC-004 |
| signaling carries no bytes | `SignalingMessage` has no byte variant; inspect traffic | SC-007 |
| clean teardown | no leaked controllers/handles after terminal | SC-006 |

## Privacy spot-check (Constitution I)

- `grep` engine logs in a test run: no file names, paths, IPs, SDP/ICE, or payload bytes appear (SC-008).
- `SignalingMessage` variants are SDP/ICE/bye only — there is structurally no way to put bytes on signaling.

## Two-device smoke test (REQUIRED, DEFERRED — manual)

CI cannot prove real NAT traversal or throughput. Tracked in `tasks.md` banner:
1. Wire a temporary throwaway signaling (or hardcode an exchanged SDP) on two physical devices on the same network.
2. Send a multi-file batch incl. one large (>1 GB) file; confirm integrity, bounded memory, and a real-link transfer completes.
3. (Deferred to #003 for the real signaling-driven version.)

## Notes

- A `TransferEngine` is single-use: after `done`/`failed`/`cancelled`, create a new one.
- `destinationDir` is injected; #005 supplies real platform save locations via `path_provider`. This feature uses caller-provided dirs only.
