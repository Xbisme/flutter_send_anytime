# Research: Polish & v1.0 Release (#014)

Phase 0 — resolves the plan-time-deferred decisions and supporting unknowns. Format per item: **Decision / Rationale / Alternatives**.

## 1. TURN provider — self-host vs managed

**Decision**: Self-host **coturn** alongside the existing `server/` signaling relay (documented `turnserver.conf` + self-host README). Document a managed provider (e.g. Cloudflare TURN / Metered / Twilio) as a config-only drop-in alternative, since both are just ICE-server entries to the client.

**Rationale**: The product's identity is self-hostable, privacy-respecting infrastructure (`server/` already ships a self-hostable signaling relay; the constitution calls the relay "a self-hostable component"). coturn is the de-facto open-source TURN server, runs next to the relay, and keeps the whole rendezvous stack one-box deployable. The client stays provider-agnostic — switching to a managed TURN is a per-flavor `iceServers` change, no code.

**Alternatives**: Managed TURN (zero-ops, pay-per-GB) — rejected as the *default* because it adds a third-party dependency and recurring cost to a product whose pitch is "no server holds your data," but kept as a documented option. Google's public STUN-only (status quo) — rejected: it cannot relay, which is exactly the gap US1 closes.

## 2. TURN credential model — static vs ephemeral

**Decision**: **Ephemeral, server-issued** time-limited credentials. coturn runs with `use-auth-secret`; the `server/` relay shares the secret and, when a room is created, issues a short-lived credential pair (`username = <expiry-unix-ts>`, `credential = base64(HMAC-SHA1(secret, username))`, TTL ~10 min) delivered to each client over the existing signaling channel as an additive `turnCredentials` frame. The client feeds them into `AppConfig.iceServers` for that session only.

**Rationale**: #014 includes an explicit **security pass (US2)**. Baking a long-term TURN username/password into the shipped client makes it trivially extractable — anyone could abuse the relay's bandwidth, and a static secret in the binary contradicts Principle I ("no rendezvous secrets in… debug output" + the spirit of not shipping extractable secrets). Ephemeral HMAC credentials are coturn's documented best practice, expire quickly, and reuse `crypto` (already a dependency) on the server. ICE/credential config travels as connection-setup metadata, which is exactly what signaling is permitted to carry (Principle VIII) — no file bytes.

**Alternatives**: Static per-flavor credentials in `AppConfig` (simplest, YAGNI) — rejected: extractable, abusable, weakens the very promise US2 audits. A dedicated REST credential endpoint (TURN REST API over HTTPS) — rejected for v1.0: the signaling channel is already open at the moment creds are needed, so a separate HTTP round-trip is redundant complexity (Principle XIII); the HMAC scheme is identical, just delivered over the existing socket.

## 3. Relay-in-use detection (for the FR-004a indicator)

**Decision**: After the data channel opens, call `RTCPeerConnection.getStats()` once and inspect the **nominated/selected candidate pair**; if the local or remote selected candidate `candidateType == 'relay'`, set `TransferSnapshot.relayInUse = true`. Surface it through the existing snapshot stream → progress UI.

**Rationale**: `getStats()` is the standard WebRTC way to know whether ICE selected a relayed path; `flutter_webrtc` exposes it. Reading once on connect (not polling) is cheap and matches the single-source-of-truth snapshot model (Principle VIII) — no parallel progress/state. Works identically for send and receive.

**Alternatives**: Inferring relay from `iceConnectionState` — rejected: state doesn't distinguish relay vs direct. Forcing `iceTransportPolicy: 'relay'` to test — used only as a *test harness* toggle (quickstart), never in production (production must prefer direct, FR-004).

## 4. Resilience failure surfacing

**Decision**: Reuse the existing `AppFailure` taxonomy — `peerUnreachable`/`iceFailed` → "couldn't connect" (FR-007), `connectionLost`/`dataChannelClosed` → mid-transfer drop (FR-005/006), `signalingUnreachable`/`signalingTimeout` → signaling loss. Add **one** new variant `AppFailure.relayUnavailable()` only for the distinct "TURN misconfigured/unreachable while direct also failed" case (FR-008), if it isn't adequately covered by `peerUnreachable`. Each maps to localized copy + the existing retry affordance; the bounded connect timeout already exists (`TransferConstants.kConnectTimeout`).

**Rationale**: The failure model already enumerates nearly every resilience case (Principle V). Partial-retained-on-drop is already implemented (#005 FR-013a). The work is mostly *verifying* each path surfaces correctly + adding localized copy, not new mechanics. Minimizing new variants keeps the mapping testable.

**Alternatives**: A fresh resilience-specific failure enum — rejected (duplicates `AppFailure`, violates Principle V centralization).

## 5. Haptics

**Decision**: Flutter built-in `HapticFeedback` (`mediumImpact` on connect, `heavyImpact`/success pattern on complete, `vibrate`/error pattern on fail), wrapped in a tiny core util that no-ops gracefully where unsupported.

**Rationale**: Principle XIII — built-in covers connect/complete/fail without a package. A wrapper centralizes the mapping and the graceful-degradation guard (devices without a taptic engine / haptics disabled).

**Alternatives**: `gaimon`/`vibration` packages (richer patterns) — rejected (YAGNI; no requirement beyond three distinct cues).

## 6. Accessibility strategy

**Decision**: Per-screen audit against a fixed checklist — wrap interactive widgets in `Semantics` with localized labels/roles; convey pairing code, connection state, and progress via semantics (not color/animation alone, FR-015); test layouts at the largest standard `MediaQuery.textScaler`; gate motion-heavy widgets (radar, progress spinner) on `MediaQuery.disableAnimations` (Reduce Motion already a Principle-VI requirement — verify coverage). The dev-only debug screen is exempt.

**Rationale**: Flutter's `Semantics` + `MediaQuery` are the native a11y surface for VoiceOver/TalkBack/Dynamic Type/Reduce Motion; no package needed. A checklist makes "every screen" verifiable.

**Alternatives**: Automated a11y scanners — useful but not a substitute for screen-reader walkthroughs; used as a supplement, not the gate.

## 7. Bounded-memory performance validation

**Decision**: Validate on device with a ≥4 GB single file (crosses the 4 GB / 32-bit-offset boundary, per clarify) and a many-file batch, observing peak memory via the platform profiler (Xcode Instruments / Android Studio Profiler). Pass = peak memory does not grow with file size (attributable to the fixed chunk/backpressure buffers from #002, not file size) and no sustained frame drops. Confirm streamed I/O paths have no accidental full-file reads introduced since #002.

**Rationale**: Streamed I/O is mandated since #002; this story *proves* it under the worst realistic case. The 4 GB boundary catches any 32-bit offset/length bug that smaller files miss.

**Alternatives**: Synthetic memory unit tests — can't observe native/OS memory; device profiling is the real gate.

## 8. Release readiness (build + store prep)

**Decision**: Production builds with Dart obfuscation (`--obfuscate --split-debug-info`) + platform release signing/provisioning; stage store assets under `docs/release/` — metadata (VI + EN), screenshots per required device sizes, a privacy policy, and the Apple privacy-nutrition + Google data-safety answers stating **no data collected/held by a server** (consistent with the verified US2 behavior, including the encrypted-non-persisted TURN relay). Do **not** submit (FR-029).

**Rationale**: Obfuscation + split debug info is the standard Flutter release hardening; staging assets in-repo makes them reviewable and keeps the privacy answers honest against actual behavior. Submission is intentionally the maintainer's manual step with their own accounts.

**Alternatives**: CI-driven fastlane submission — out of scope (no submission this spec); can be a post-v1.0 ops task.

## Open items deferred to implementation

- Exact TURN credential TTL and coturn hardening flags (`turnserver.conf`) — tuned during US1 implementation.
- Concrete cold-start number against a measured baseline device (target ≤ 3 s).
- Whether `AppFailure.relayUnavailable` is actually needed or `peerUnreachable` suffices — decided when wiring FR-008.
