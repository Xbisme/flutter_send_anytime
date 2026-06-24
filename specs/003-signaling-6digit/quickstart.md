# Quickstart: Signaling Server & 6-Digit Pairing (#003)

How to run the relay, run the tests, and perform the (deferred) two-device smoke. Assumes #001/#002 are in place.

## Layout recap

```
packages/safesend_signaling/   # shared wire protocol (pure Dart)
server/                        # shelf signaling relay (pure Dart)
lib/core/services/signaling/   # SignalingClient + WebSocketSignalingChannel
lib/features/pairing/          # repo + use cases + PairingCubit + dev debug page
```

## 1. Install dependencies

```bash
# app (adds web_socket_channel + dev path-dep on server)
flutter pub get

# shared package
cd packages/safesend_signaling && dart pub get && cd -

# relay
cd server && dart pub get && cd -
```

## 2. Run the signaling relay (dev)

```bash
cd server
dart run bin/server.dart --port 8080            # add --ttl 300 to override code TTL (seconds)
# → "Safe Send signaling relay listening on ws://0.0.0.0:8080"
```

- Logs are phase/error-type only — no codes, IPs, peer ids, or SDP/ICE (FR-022). Verify by watching the output during a pairing.
- Self-hosting notes (flags, TLS/`wss://` behind a reverse proxy, privacy guarantees) live in [`server/README.md`](../../server/README.md).

## 3. Point the app at the relay

`AppConfig.signalingEndpoint` is set per flavor in the entrypoints:

- **dev** (`lib/main_dev.dart`): `ws://<your-machine-LAN-ip>:8080` for two devices on the same Wi-Fi (use `ws://localhost:8080` only for a simulator + host pairing). Dev flavor allows cleartext (Android `usesCleartextTraffic`, iOS ATS) — dev manifests only.
- **prod** (`lib/main_prod.dart`): `wss://<placeholder-host>` (real host filled when deployment lands — #011).

STUN is Google public (`stun:stun.l.google.com:19302`) in both flavors; TURN is an empty documented hook (R-07).

## 4. Run the tests (the real validation for #003)

```bash
# app: client demux, channel adapter, PairingCubit, and the headline integration test
very_good test --test-randomize-ordering-seed random        # or: flutter test

# shared protocol codec
cd packages/safesend_signaling && dart test && cd -

# relay unit tests (room lifecycle, TTL, collision, room-full, rate limiter)
cd server && dart test && cd -
```

The integration test (`test/integration/pairing_handshake_test.dart`) starts the **real `shelf` relay in-process** on an ephemeral port and drives **two real WebSocket clients** through: host → code → join → `peer-joined` → SDP/ICE relay → (loopback engine) DataChannel open — asserting **no bytes cross signaling** (SC-002) and a short injected TTL for expiry cases (no real 5-min waits). No physical devices needed.

## 5. Pre-commit gates (Constitution / dev-workflow)

```bash
dart format .
dart analyze lib test                 # 0 issues (note: `flutter analyze` crashes on this Flutter checkout — use dart analyze)
cd server && dart analyze && dart format --output=none --set-exit-if-changed . && cd -
cd packages/safesend_signaling && dart analyze && cd -
flutter test
dart run bloc_tools:bloc lint .        # if available; else note deferred (as in #001)
```

## 6. Two-physical-device smoke — DEFERRED (manual, tracked in tasks.md banner)

CI cannot prove real NAT traversal or throughput (Constitution XII). When ready:

1. Deploy/forward the relay so both devices can reach it (LAN IP, or a public host with `wss://`).
2. Set the dev endpoint to that address; build the **dev** flavor on two phones.
3. Open the **dev-only debug screen** (FR-021a): Phone A "Host (get code)"; Phone B "Join (enter code)".
4. Confirm: `peer-joined` on both → connection state reaches `connected` (RTCDataChannel open). Try across different networks (cellular vs Wi-Fi) to exercise STUN.
5. Failure checks: let a code expire (5 min) → `code-expired`; enter a wrong code → `invalid-code`; a third device → `room-full`; kill one app mid-handshake → the other shows `peer-left`.

> Actual file transfer over the open channel is exercised by #004/#005; #003 stops at "channel open".
