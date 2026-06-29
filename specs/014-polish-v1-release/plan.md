# Implementation Plan: Polish & v1.0 Release

**Branch**: `014-polish-v1-release` | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/014-polish-v1-release/spec.md`

## Summary

The final v1.0 hardening sweep. No new user feature — instead: (1) a **real TURN relay fallback** so transfers survive restrictive NATs, wired into the *existing* per-flavor `iceServers` config with **ephemeral, server-issued credentials** (no static secret in the client) and a subtle "relayed · encrypted" progress indicator; (2) a **security/privacy verification pass** re-confirming signaling-metadata-only + DTLS + relay-not-persisted/logged now that TURN is in the path; (3) **accessibility** (VoiceOver/TalkBack labels, Dynamic Type, Reduced Motion) and **UX polish** (haptics on connect/complete/fail, dark-mode sweep) across every screen; (4) validated **bounded-memory** performance for a ≥4 GB file + many-file batch; (5) the full **two-device device-validation backlog** from #002–#013 run on real hardware; (6) **release-ready** obfuscated/signed prod builds + staged store assets (not submitted).

Technical approach: maximize reuse of existing seams. TURN needs no engine redesign — it extends `AppConfig.iceServers` (already maps `username`/`credential`) plus one additive signaling frame carrying short-lived TURN credentials issued by the `server/` relay (coturn `use-auth-secret` HMAC). Relay-in-use is detected via `RTCPeerConnection.getStats()` selected-candidate-pair type and surfaced through the existing `TransferSnapshot` stream (no parallel progress model — Principle VIII). Haptics use Flutter's built-in `HapticFeedback` (no new package — Principle XIII). Accessibility, dark-mode, and resilience-copy work is additive over existing widgets + ARB.

## Technical Context

**Language/Version**: Dart 3.11.5 / Flutter 3.41.7 (project floor — unchanged)
**Primary Dependencies**: `flutter_webrtc` 1.5.2 (existing — TURN + `getStats`), `web_socket_channel` 3.0.3 (existing — carries the additive TURN-cred frame), `crypto` 3.0.7 (existing — HMAC for ephemeral TURN creds), Flutter built-in `HapticFeedback` / `MediaQuery` (Reduced Motion, text scale). **Server**: `coturn` (TURN daemon, self-hosted alongside the `server/` Dart `shelf` relay).
**Storage**: drift (existing) — **no schema change**.
**Testing**: `flutter_test` + `bloc_test` 10 + `mocktail`; in-process loopback `SignalingChannel` for engine logic; new unit tests for relay-decision/credential/failure mapping; **two-physical-device manual smoke matrix** (the device backlog itself).
**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+ (unchanged).
**Project Type**: Mobile app (Flutter, `lib/`) + self-hostable servers (`server/` signaling relay + coturn TURN).
**Performance Goals**: cold start to interactive Home ≤ 3 s on a typical supported device; ≥4 GB single-file transfer completes with peak memory bounded (not scaling with file size); throughput network-bound, no UI jank.
**Constraints**: NO new Flutter/Dart client package if avoidable (Principle XIII/XV); additive only — no engine/transport/DB-schema redesign; the only protocol touch is one **additive, backward-compatible** signaling frame for ephemeral TURN credentials (ICE config = connection metadata, Principle VIII-compliant); TURN never persists/logs bytes (Principle I).
**Scale/Scope**: 8 screens swept for a11y + dark mode; 4 connection methods × 2 platforms device-validated; 6 user stories.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

This spec is unusually constitution-aligned — it largely *operationalizes* principles the constitution already mandates (TURN as encrypted/non-persisted fallback, resilience, a11y, haptics, streamed I/O, dark mode).

| Principle | Status | Notes |
|---|---|---|
| I. Privacy-First P2P | ✅ Reinforces | TURN is the permitted encrypted, non-persisted fallback; US2 *verifies* it. Ephemeral creds avoid baking secrets into the client (no secret in logs/VCS). |
| II. Direct Transfer & Data Min. | ✅ Reinforces | US4 *proves* the streamed-I/O bound on a ≥4 GB file; DTLS never weakened on the relay path. |
| III. BLoC 4-state | ✅ | Relay indicator + failure states ride the existing transfer snapshot → cubits; no new ad-hoc state. |
| V. Result/AppFailure | ✅ | Resilience copy maps existing `AppFailure` variants (peerUnreachable/iceFailed/connectionLost/…); add at most a `relayUnavailable` variant if needed. |
| VI. Design System | ✅ | Dark-mode sweep enforces tokens-only; relay badge + indicators use existing tokens; Reduce Motion already a principle. |
| VII. Cross-Platform Native | ✅ Reinforces | A11y (VoiceOver/TalkBack, Dynamic Type, Reduce Motion) + haptics are explicit Principle-VII items. |
| VIII. Transport & Signaling | ✅ | TURN config stays per-flavor + centralized; one additive versioned signaling frame; one shared pipeline preserved. |
| IX. Reliability & Integrity | ✅ Reinforces | US1 is the resilience clause made real (clear retryable errors, no hang, partial retained). |
| XII. Testing | ✅ | New loopback-able unit tests for relay-decision/credential/failure logic; the two-device matrix is the spec's own US5. |
| XIII. Simplicity/YAGNI | ✅ | No new client package (built-in haptics); reuse existing ICE/snapshot/ARB seams; no relay usage cap. |
| XIV. i18n | ✅ | All new copy via ARB (VI primary + EN). |
| XV. Dependency Hygiene | ✅ | No new pub package planned; coturn is server infra (documented + versioned in `server/`). If any client package proves necessary, verify on pub.dev first. |

**Gate result: PASS** — no violations; Complexity Tracking not required.

## Project Structure

### Documentation (this feature)

```text
specs/014-polish-v1-release/
├── plan.md              # This file
├── research.md          # Phase 0 — TURN provider/cred model, relay detection, a11y/perf strategy
├── data-model.md        # Phase 1 — TURN config, ephemeral cred, relay state, failure states, smoke matrix
├── quickstart.md        # Phase 1 — how to run/verify each story (incl. coturn setup + device matrix)
├── contracts/           # Phase 1 — additive signaling TURN-cred frame + coturn REST contract
└── tasks.md             # Phase 2 (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── config/                 # AppConfig.iceServers extended with TURN; ephemeral-cred holder
│   ├── services/
│   │   ├── transport/          # webrtc_peer_connector: relay-detection via getStats; iceTransportPolicy
│   │   ├── signaling/          # consume additive turnCredentials frame → ICE config
│   │   └── security/           # (new, optional) log-hygiene audit helper / verification notes
│   ├── domain/transfer/        # TransferSnapshot gains a `relayInUse` flag (additive)
│   ├── domain/failures/        # AppFailure: add `relayUnavailable` if required
│   ├── presentation/
│   │   ├── transfer/           # progress page: "relayed · encrypted" indicator (tokens + a11y)
│   │   └── a11y/               # shared Semantics helpers / haptics util wrapper
│   └── utils/                  # HapticFeedback wrapper (graceful degradation)
├── features/                   # a11y labels + dark-mode audit per screen (home/send/receive/history/pairing/settings/viewers)
└── l10n/arb/                   # relay indicator + resilience failure copy (VI primary + EN)

packages/safesend_signaling/    # additive `turnCredentials` frame (shared app+server source of truth)
server/                         # shelf relay issues ephemeral coturn creds (HMAC) on room create
                                # + coturn config + self-host docs (turnserver.conf, README)

docs/release/                   # staged store assets: metadata, screenshots, privacy policy, data-safety answers
ios/ , android/                 # release signing/obfuscation config; first pod install; signing Team
```

**Structure Decision**: Mobile-app + self-hostable servers (matches the existing repo: `lib/` app, `packages/safesend_signaling/` shared protocol, `server/` relay). TURN is additive across the existing transport/config/signaling seams; coturn joins `server/` as documented self-host infra. A new `docs/release/` holds release-readiness artifacts (US6). No feature folders are restructured.

## Phase 0 — Research (see research.md)

Resolves the two pre-spec-deferred decisions + supporting unknowns:
1. **TURN provider** → self-hosted **coturn** (fits the self-hostable ethos; `server/` already self-hosted) with a managed provider documented as a drop-in alternative.
2. **TURN credential model** → **ephemeral, server-issued** time-limited credentials (coturn `use-auth-secret` HMAC) delivered over the existing signaling channel — chosen over static client-baked creds because US2 is an explicit security pass and extractable static secrets would undermine it.
3. **Relay-in-use detection** → `RTCPeerConnection.getStats()` selected-candidate-pair `relay` type, read once on connect → `TransferSnapshot.relayInUse`.
4. **Haptics** → Flutter built-in `HapticFeedback` (no package).
5. **A11y / Dynamic Type / Reduced Motion** → Flutter `Semantics` + `MediaQuery.textScaler`/`disableAnimations`; per-screen audit checklist.
6. **Bounded-memory validation** → method for proving the ≥4 GB streamed bound on device.
7. **Release**: obfuscation/signing flags, store-asset + privacy-form checklist.

## Phase 1 — Design & Contracts (see data-model.md, contracts/, quickstart.md)

- **data-model.md**: `RtcIceServer` (TURN already supported); `TurnCredentials` (ephemeral: urls, username, credential, ttl); `TransferSnapshot.relayInUse` (additive bool); resilience `AppFailure` mapping; the device-validation smoke-matrix shape; store-listing package shape.
- **contracts/**: the additive `turnCredentials` signaling frame (versioned JSON, backward-compatible) + the coturn REST/HMAC credential contract the `server/` relay implements.
- **quickstart.md**: run/verify each story — stand up coturn locally, force relay-only to test fallback, run the two-device smoke matrix, produce signed builds, review staged store assets.
- **Agent context**: update the plan reference in `CLAUDE.md` between the SPECKIT markers to point at this plan.

## Complexity Tracking

No constitution violations — section intentionally empty.
