# Security & Privacy Verification (US2)

Re-runnable audit confirming the core promise — **no intermediary server holds
the data** — still holds with TURN added (#014). Re-run before every release.

## Checks

| # | Check | How | Result |
|---|---|---|---|
| 1 | Signaling carries metadata only (no file bytes) | Capture ws traffic across a full lifecycle; confirm only SDP/ICE/control + `turn-credentials`. Unit: `server` "no file bytes ever cross signaling" + `turn-credentials carries no file/byte field`. | ✅ (unit) / ⬜ (device capture) |
| 2 | Data channel DTLS-encrypted end-to-end | DTLS is mandatory in `flutter_webrtc` and never disabled (Constitution II); confirm on device the channel is encrypted. | ⬜ (device) |
| 3 | TURN relays encrypted bytes only, persists nothing | coturn config has no media dump; relayed payload is DTLS; confirm coturn stores nothing post-session. | ⬜ (device) |
| 4 | No sensitive value in any log | `grep` app + server logs across success/failure/cancel/relay for: file bytes, paths, peer ids, pairing codes, device names, signaling/TURN endpoints, **TURN secret/credentials**. | ⬜ (device run) |
| 5 | TURN secret never in the client | The `static-auth-secret` lives only in the relay env; the client only ever receives ephemeral HMAC creds. Confirm the secret is absent from the built binary + source. | ✅ (by design — ephemeral creds; unit asserts the mint frame omits the secret) |
| 6 | Privacy explainer accurate | In-app how-it-works/privacy page describes STUN/TURN: relay forwards encrypted bytes, persists nothing. | ✅ (copy reviewed) |
| 7 | Works in airplane mode for on-disk files | In-app viewers (#013) render with no network (SC-008). | ⬜ (device) |

## Automated coverage (CI)

- `packages/safesend_signaling` — `turn-credentials` frame carries no
  file/byte field; backward-compatible unknown-type handling.
- `server` — `TurnCredentialService` mint is deterministic HMAC and the frame
  never contains the secret; existing "no file bytes ever cross signaling".
- App — relay detection + credential mapping unit tests; existing log-hygiene
  privacy tests.

## Manual log-grep (device)

```sh
# After a full transfer (success + a forced failure + a relayed run):
adb logcat | grep -iE '(/SafeSend/|turn:|static-auth|credential|[0-9]{6})'   # expect: nothing sensitive
# iOS: Console.app filtered to the app — same expectation.
```
