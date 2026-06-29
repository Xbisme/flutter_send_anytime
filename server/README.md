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

## TURN relay (#014)

The encrypted-only fallback for hard NATs is now **stood up** (it replaces the
old documented-empty hook). It runs as a self-hosted **coturn** daemon next to
this signaling relay; relayed traffic stays DTLS-encrypted end-to-end and is
**never persisted or logged** (Constitution I). TURN is used only when a direct
P2P path fails.

### Credentials are ephemeral (no secret in the client)

coturn runs with `use-auth-secret`. This relay shares the same secret and, on
each pairing, mints a short-lived credential —
`username = <unix-expiry>`, `credential = base64(HMAC-SHA1(secret, username))` —
and delivers it to both peers over the signaling channel as a
`turn-credentials` frame. The secret lives only in the relay's environment and
**never reaches the client or any log**.

### Run it

1. Edit [`turnserver.conf`](turnserver.conf): set `external-ip`, a long random
   `static-auth-secret`, and (for `turns:`) TLS `cert`/`pkey`.
2. Start coturn: `turnserver -c turnserver.conf`.
3. Start this relay with the matching env so it issues credentials:
   ```sh
   TURN_URLS="turn:<host>:3478?transport=udp,turns:<host>:5349?transport=tcp" \
   TURN_SECRET="<same as static-auth-secret>" \
   TURN_TTL_SECONDS=600 \
   dart run bin/server.dart --port 8080
   ```
   When `TURN_URLS`/`TURN_SECRET` are unset, the relay stays STUN-only and
   clients fall back to their static per-flavor ICE config (backward compatible).

> **Managed alternative**: a hosted TURN (Cloudflare/Metered/Twilio) is a
> drop-in — point the client's per-flavor `iceServers` at it instead. The client
> is provider-agnostic; only the credential source changes.
