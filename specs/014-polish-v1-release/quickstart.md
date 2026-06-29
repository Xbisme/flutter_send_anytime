# Quickstart: Polish & v1.0 Release (#014)

How to run and verify each user story. Loopback unit/widget tests stay CI-runnable; the resilience + device stories need real hardware.

## Prereqs
- Flutter 3.41.7 / Dart 3.11.5 (project floor), `flutter pub get`.
- `server/` signaling relay running; **coturn** running with `use-auth-secret` (see `server/` self-host docs).
- Two physical devices (one iOS, one Android) for US1/US4/US5; an Apple signing Team for the iOS prod build.

## US1 — TURN fallback + resilience
1. Start coturn + the relay locally; point the dev flavor `iceServers`/secret at them.
2. **Force relay**: set the connector's `iceTransportPolicy: 'relay'` behind a test-only flag (or block direct paths with a firewall rule) → confirm a transfer still completes and `TransferSnapshot.relayInUse == true`.
3. Confirm the progress screen shows the localized "relayed · encrypted" indicator (and a screen reader announces it); a direct transfer shows none.
4. Force each disruption mid-transfer (kill Wi-Fi, background past the limit, drop the peer, stop the relay) → each surfaces a clear localized failure + retry, partial files retained, no hang.
5. Unit: relay-decision from a stubbed `getStats()`; ephemeral-credential HMAC matches for a fixed secret+`now`; `AppFailure`→copy mapping.

## US2 — Security/privacy verification
1. Capture signaling traffic across a full lifecycle → assert no file bytes (metadata only).
2. Run a relayed transfer → confirm payloads are DTLS-encrypted and coturn persists nothing.
3. `grep` all app + server logs across success/failure/cancel/relay → zero file bytes, paths, peer ids, codes, device names, endpoints, or the TURN secret.
4. Read the in-app how-it-works/privacy page → it accurately describes STUN/TURN (encrypted, non-persisted relay).
5. Record results in a short security-verification note (re-runnable for future releases).

## US3 — Accessibility
1. Enable VoiceOver (iOS) / TalkBack (Android) → traverse all 8 screens, complete send + receive end-to-end; every control announced with a localized label/role; code/state/progress conveyed.
2. Set the largest standard text size → no clipped/unreachable critical content on any screen (esp. Connect code grid, progress, history rows).
3. Enable Reduced Motion → radar + progress animations reduce/still.

## US4 — Polish & performance
1. Transfer a **≥4 GB** single file device→device; profile with Instruments / Android Profiler → peak memory does not scale with file size, UI stays responsive.
2. Transfer a many-file batch → all complete (or clean partial), bounded memory.
3. Confirm distinct haptics on connect / complete / fail (and graceful no-op where haptics unavailable).
4. Toggle dark mode → walk every screen; all colors from tokens, adequate contrast.
5. Measure cold start → interactive Home ≤ ~3 s.

## US5 — Two-device validation backlog
Run the smoke matrix (see data-model.md) on both devices: each of the 4 connection methods → full pair→send→receive→save; background transfer per platform; open each in-app viewer; iOS `pod install` + signed build installs/runs. Record pass/fail per cell.

## US6 — Release readiness (no submission)
1. Build obfuscated + signed prod for each platform (`flutter build … --obfuscate --split-debug-info=…`); confirm it installs/runs on a device.
2. Review staged `docs/release/` assets: metadata (VI+EN), screenshots, privacy policy, Apple privacy-nutrition + Google data-safety answers — complete and matching real behavior.
3. Confirm nothing is submitted to either store.

## Gate (whole feature)
`dart format` clean · `dart analyze lib test` = 0 · `flutter test` green (incl. new relay/credential/failure tests) · no dead code / unused deps · all new copy in ARB (VI primary + EN).
