# Research: Signaling Server & 6-Digit Key Pairing (#003)

Phase 0 output. Each decision resolves a candidate unknown from the plan's Technical Context. Format: Decision · Rationale · Alternatives considered.

---

## R-01 — Where do room/code semantics live vs. the 1:1 `SignalingChannel`?

**Decision**: Introduce a `SignalingClient` in `core/services/signaling/` that owns the WebSocket and implements the **pairing/room protocol** (host → code, join → room, peer-present, room-full, expired, peer-left). Once paired, it **produces** a `WebSocketSignalingChannel implements SignalingChannel` that exposes only the 1:1 SDP/ICE/bye relay the #002 engine consumes. The engine still depends solely on the seam.

**Rationale**: The existing `SignalingChannel` (from #002) is deliberately a *peer-to-peer metadata pipe* — `offer`/`answer`/`iceCandidate`/`bye`, no notion of codes or rooms. Pairing is a higher concern. Splitting them keeps the engine untouched (Constitution VIII: reuse the seam), keeps room logic out of the transport, and lets the same `WebSocketSignalingChannel` later serve QR/link/radar pairing (#007–009) which produce the *same* rendezvous via different `SignalingClient` entry methods.

**Alternatives considered**:
- *Widen `SignalingChannel` to carry room/code messages* — rejected: pollutes the engine's seam with pairing concerns, breaks the #002 contract, and couples transport to one pairing method.
- *Two separate sockets (one control, one relay)* — rejected: doubles connection/NAT cost for no benefit; one socket multiplexes fine (R-02).

---

## R-02 — Wire protocol shape & framing

**Decision**: **Versioned JSON text frames** over a single WebSocket: `{"v":1,"type":"<name>", ...fields}`. One frame catalog (host, code-issued, join, peer-joined, room-full, code-expired, invalid-code, relay, peer-left, bye, rate-limited) defined once in the shared package with encode/decode + validation. Relay frames wrap the SDP/ICE payload: `{"v":1,"type":"relay","kind":"offer|answer|ice", ...}`.

**Rationale**: JSON is human-readable (debuggable during the manual two-device smoke), needs no codegen on the server, and the frames are tiny. A `v` field makes the protocol explicitly versioned (Constitution VIII) so #007+ can extend it compatibly. Multiplexing control + relay on one connection keeps NAT/connection cost minimal (Constitution XIII).

**Alternatives considered**:
- *Binary/opcode framing (like the #002 transfer protocol)* — rejected here: the transfer protocol is binary because it carries file chunks at volume; signaling carries a handful of small text messages where readability wins.
- *Reuse #002's opcode codec* — rejected: different layer, different payloads; coupling them helps nothing.

---

## R-03 — Avoiding protocol drift across two programs (the shared package)

**Decision**: A **pure-Dart shared package** `packages/safesend_signaling/` holds the frame types, JSON codec, protocol version, and message-type/constant names. Both the app (`lib/`) and the relay (`server/`) depend on it via **path dependency**. The app's `dev_dependencies` also path-depend on `server/` so the integration test runs the real relay with the same codec.

**Rationale**: Constitution VIII mandates protocol message types live in **one place, never duplicated as string literals**. The protocol genuinely spans two separately-run programs; the only way to honor "one place" is a shared compilation unit. Silent drift (server renames a type, client doesn't) would break pairing with no compile error — exactly the failure a shared package prevents. The package is pure Dart (no Flutter) so the headless server can import it.

**Alternatives considered**:
- *Duplicate the constant strings in app and server* — rejected: violates Constitution VIII; drift is invisible until runtime.
- *Generate from a schema (protobuf/JSON-schema)* — rejected: heavyweight for ~10 message types (Constitution XIII YAGNI); adds a codegen toolchain.
- *Put protocol in `server/` and have the app depend on the server package* — rejected: the app would transitively pull `shelf` (a server-only dep) into the mobile build; a thin shared package keeps the app's dependency surface clean.

---

## R-04 — 6-digit code generation, uniqueness, leading zeros

**Decision**: Generate with `Random.secure().nextInt(1000000)`, format as a **zero-padded 6-char string** (`toString().padLeft(6, '0')`), covering the full `000000`–`999999` space. On collision with an active code, regenerate (bounded retry). The code is always handled as a string end-to-end (generation, room key, display, entry validation = `^\d{6}$`).

**Rationale**: Matches FR-002 (full range, leading zeros preserved). `Random.secure()` (not `Random()`) avoids predictable codes, complementing the join rate limit (R-06) against guessing (Constitution I: rendezvous secrets short-lived + not predictable). String-everywhere removes the int-vs-padded-string ambiguity that causes display/validation bugs.

**Alternatives considered**:
- *Non-secure `Random`* — rejected: predictable sequence weakens a small secret space.
- *First-digit-non-zero range* — rejected by clarification (Q3 → full range).
- *Alphanumeric codes* — rejected: the design (Screen 03 mono `CodeBox`es) and Send-Anywhere mental model are numeric; #007 QR covers the high-entropy path.

---

## R-05 — Enforcing the 5-minute TTL testably

**Decision**: Each room holds an expiry `Timer` (or compares against an injected clock) sized by a **configurable `Duration`** (default 5 min). On fire: remove the room, notify the host with `code-expired`, close. Tests inject a **short TTL** (e.g. tens of ms) or a fake clock — never a real 5-minute wait.

**Rationale**: FR-004/FR-013 require expiry + cleanup; Constitution XII requires deterministic, non-flaky tests. A configurable duration makes the same code path provable in milliseconds.

**Alternatives considered**:
- *Lazy expiry (check-on-access only)* — rejected alone: a never-accessed room would leak until process exit; an active timer guarantees cleanup (Constitution II ephemerality). (Lazy check on `join` is kept as a cheap belt-and-suspenders.)
- *Real-time test waits* — rejected: flaky + slow (Constitution XII).

---

## R-06 — Join-attempt rate limiting (FR-011a)

**Decision**: Per **connection**, track invalid-`join` attempts; after a small threshold (e.g. 5) within a window, respond `rate-limited` (with a `retryAfter`) and throttle; on continued abuse, close the socket. Valid joins reset the counter. Applied at the relay (the only enumerable surface).

**Rationale**: A 1,000,000-code space with a 5-min TTL is still enumerable by a fast attacker; a per-connection cap makes brute force impractical without auth (clarification Q1 → option A). Keeping it per-connection (plus optional per-source coalescing) is simple and stateless-friendly.

**Alternatives considered**:
- *No limit* (clarification option B) — rejected by the user.
- *Global rate limit* — rejected: punishes legitimate users during any abuse; per-connection is fairer and simpler.
- *Auth/API key* (clarification option C) — rejected by the user for v1; revisit at #011 if abuse is observed.

---

## R-07 — STUN / TURN configuration

**Decision**: Populate `AppConfig.iceServers` with **Google public STUN** (`stun:stun.l.google.com:19302` + one or two alternates) for both flavors, set in the flavor entrypoints. TURN stays a **documented, empty, configurable hook** — `iceServers` accepts `turn:` entries with credentials, but none is shipped (no relay stood up). Where TURN appears in docs it is noted as encrypted-relay-only, never persisted (Constitution I).

**Rationale**: STUN is free and sufficient for the common NAT case; standing up TURN is out of scope (#011). The `RtcIceServer` model (already on `AppConfig`) supports `username`/`credential`, so the hook needs no new types.

**Alternatives considered**:
- *Ship a TURN server now* — rejected: out of scope, infra cost, deferred to #011.
- *No STUN (host candidates only)* — rejected: would fail across most real NATs, defeating the two-device goal.

---

## R-08 — Per-flavor signaling endpoint & cleartext

**Decision**: Add `AppConfig.signalingEndpoint` (`Uri`). **dev** → `ws://<localhost-or-LAN-ip>:8080` (cleartext, for on-network testing); **prod** → `wss://<placeholder-host>` (TLS; real host filled when deployment lands). The dev cleartext exception (Android `usesCleartextTraffic`, iOS ATS) is scoped to the **dev flavor manifests/Info.plist only**; prod stays TLS-only.

**Rationale**: FR-020 requires per-flavor config; Constitution VIII requires endpoints centralized in `AppConfig`, never hardcoded. Localhost/LAN dev testing needs `ws://`; restricting the cleartext allowance to the dev flavor keeps prod secure (Constitution VII).

**Alternatives considered**:
- *TLS even in dev (self-signed)* — rejected: cert management friction for LAN testing; dev-scoped cleartext is the pragmatic norm.
- *Single endpoint for both flavors* — rejected: violates per-flavor config and the dev/prod separation already established in #001.

---

## R-09 — Reconnect / ICE-restart / resume

**Decision**: **Out of scope.** A peer disconnect tears the room down and notifies the survivor (`peer-left` → `connectionLost`/`roomExpired`). No automatic reconnect, ICE-restart, or session resume.

**Rationale**: Constitution XIII (YAGNI) and the spec's Out-of-Scope/Assumptions explicitly defer resume to post-v1.0. Clean teardown is simpler and matches the single-use rendezvous promise (Constitution I).

**Alternatives considered**:
- *Reconnect window / ICE restart* — rejected for v1: significant complexity (session resumption, stale-room handling) for an edge case; post-v1.0 roadmap item.

---

## R-10 — `AppFailure` gaps

**Decision**: Extend the `AppFailure` sealed class with the signaling/pairing variants the constitution enumerates but #002 didn't add: `signalingUnreachable`, `signalingTimeout`, `roomExpired`, `roomFull`, `invalidCode`, and `rateLimited`. Each maps to a localized VI/EN string (FR-022/023).

**Rationale**: Constitution V lists these exact failure modes; they are the named outcomes for SC-003 (every pairing failure is distinct and actionable). `rateLimited` is added beyond the constitution's list to surface FR-011a cleanly to the user.

**Alternatives considered**:
- *Reuse `networkError`/`unexpected` for all* — rejected: collapses distinct, user-actionable cases into opaque errors, failing SC-003 and Constitution V.

---

## Dependency verification (Constitution XV — pub.dev, 2026-06-24)

| Package | Version | Where | Notes |
|---|---|---|---|
| `web_socket_channel` | **3.0.3** | app + server (transitive) | Pure Dart WebSocket client; no native code → no pods/permissions. |
| `shelf` | **1.4.2** | server | HTTP pipeline + `shelf_io`. Pure Dart. |
| `shelf_web_socket` | **3.0.0** | server | WebSocket upgrade for shelf; depends `web_socket_channel >=2.0.0 <4.0.0` → **compatible** with 3.0.3 (one transport lib across client/server/tests). |

All pure Dart — no `pod install` / Gradle native verification needed (unlike #002's `flutter_webrtc`). Caret constraints; `server/pubspec.lock` and `packages/safesend_signaling/pubspec.lock` committed. No fictional packages.
