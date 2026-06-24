# Safe Send — Signaling Relay

A lightweight, **stateless, self-hostable** WebSocket service that introduces two
Safe Send peers to each other and relays only the WebRTC handshake metadata
(SDP offer/answer + ICE candidates) plus a short-lived 6-digit pairing code.

> **It never sees file bytes.** File data flows peer-to-peer over the encrypted
> WebRTC `RTCDataChannel` once the two devices connect directly. This service is
> the "matchmaker" that steps out of the way after the handshake (#003).

## Run

```bash
cd server
dart pub get
dart run bin/server.dart --port 8080 --ttl 300
# → Safe Send signaling relay listening on ws://0.0.0.0:8080 (code TTL 300s)
```

Flags:

| Flag | Default | Meaning |
|------|---------|---------|
| `--port` | `8080` | TCP port to listen on |
| `--ttl`  | `300`   | Pairing-code time-to-live, in seconds |

Point the app at the relay via `AppConfig.signalingEndpoint` (set per flavor in
`lib/main_dev.dart` / `lib/main_prod.dart`). For two physical devices on the same
Wi-Fi, use your machine's LAN IP (e.g. `ws://192.168.1.20:8080`) in the dev
flavor (which permits cleartext `ws://`).

## Production (TLS / `wss://`)

Terminate TLS at a reverse proxy (nginx/Caddy/Fly/Cloud Run) and forward the
WebSocket upgrade to this service; point the prod flavor at `wss://your-host`.
The prod flavor is TLS-only — it does **not** allow cleartext.

## Privacy guarantees

- **No persistence.** Rooms live only in memory (a `Map`); there is no database
  or disk write. Nothing survives a restart, and nothing is retained after a
  session ends.
- **Metadata only.** The wire protocol (`packages/safesend_signaling`) has no
  frame field that can carry file bytes — this is enforced structurally.
- **Minimal logging.** The process logs only its listening line. It does **not**
  log pairing codes, IP addresses, peer identifiers, or SDP/ICE payloads.
- **Two peers per room.** A third device that submits a live code is rejected
  (`room-full`); the existing pair is undisturbed.
- **Abuse resistance.** Invalid join attempts are rate-limited per connection so
  the 6-digit code space cannot be feasibly enumerated.

## Wire protocol

Versioned JSON frames, defined once in
[`packages/safesend_signaling`](../packages/safesend_signaling) and shared by the
app and this service. See
[`specs/003-signaling-6digit/contracts/signaling-protocol.md`](../specs/003-signaling-6digit/contracts/signaling-protocol.md)
for the full message catalog and sequences.

## Test

```bash
cd server && dart test          # room lifecycle, TTL, rate limiting, full wire round-trip
```

## TURN (deferred)

A TURN relay (encrypted-only fallback for hard NATs) is **not** part of this
service. It is a documented, configurable hook on `AppConfig.iceServers` and is
stood up in #011. When used, TURN relays only end-to-end-encrypted traffic and
never persists it (Constitution I).
