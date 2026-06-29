# Contract: Ephemeral TURN Credentials

Two contracts: (A) the additive **signaling frame** that carries credentials app↔server, and (B) the **coturn HMAC** scheme the `server/` relay and coturn agree on. Both are additive and backward-compatible.

## A. `turnCredentials` signaling frame (additive)

Lives in the shared pure-Dart protocol package `packages/safesend_signaling/` (one source of truth for app + server). Versioned JSON, same envelope as existing frames.

**Direction**: server → client. Sent once per peer right after the peer joins/creates a room, before SDP/ICE exchange.

```json
{
  "type": "turnCredentials",
  "v": 1,
  "urls": ["turn:turn.safesend.app:3478?transport=udp", "turns:turn.safesend.app:5349?transport=tcp"],
  "username": "1751212800",
  "credential": "rN3k...base64-hmac...==",
  "ttlSeconds": 600
}
```

**Rules**:
- **Backward compatible**: a client that doesn't understand the frame ignores it (existing demux skips unknown `type`); a server that never sends it leaves the client on its static per-flavor `iceServers`. No version bump breaks older peers.
- The frame carries **connection-setup metadata only** (ICE config) — permitted by Principle VIII; it MUST NOT carry any file/peer data.
- The client maps it into the session `iceServers` and discards at teardown. **Never logged** (no urls/username/credential in any log line — Principle I).
- Credentials are per-flavor (dev coturn vs prod coturn), matching the per-flavor signaling endpoint.

## B. coturn `use-auth-secret` HMAC contract

The `server/` relay and coturn share one secret per flavor (env/config, never in the client, never logged).

- coturn config: `use-auth-secret`, `static-auth-secret=<SECRET>`, realm + listening ports (3478 UDP/TCP, 5349 TLS), `no-cli`, denied loopback/multicast peers, fingerprint on.
- Credential generation (in `server/`, reuses `crypto`):
  - `username = <unix-expiry>` where expiry = now + ttl (e.g. now + 600s).
  - `credential = base64( HMAC_SHA1( static-auth-secret, username ) )`.
- coturn validates the HMAC itself; the relay never proxies media — it only mints the credential string.

**Verification (US2)**: confirm coturn relays only DTLS-encrypted bytes, persists nothing (no media dump, logs at error-only without payloads), and that the shared secret never appears in the client binary, app logs, or VCS.

## Test expectations

- Loopback/unit: server mints a credential for a known secret+timestamp and the bytes match the expected HMAC (deterministic with injected `now`).
- Client: on receiving the frame, the session `iceServers` include the TURN entry with the given username/credential; on absence, the static config is used.
- Privacy: a log-capture test asserts no urls/username/credential/secret string is emitted across mint → send → connect.
