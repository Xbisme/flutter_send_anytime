# Quickstart: Share Link (#008)

How to exercise the feature once implemented. CI covers parse/route/auto-join via fakes; the
cold/warm + two-device paths are manual (Constitution XII).

## Prerequisites

- `flutter pub get` (adds `app_links` 6.4.1) → then **`pod install`** in `ios/` (first run churns
  `ios/Podfile.lock` — commit it).
- Dev signaling relay running (`server/`) and reachable per `AppConfig.signalingEndpoint` (dev).
- Two physical devices for the full loop (or one device + a simulator for warm/cold link plumbing).

## A. Share + open on one device (plumbing smoke, no second device)

1. Launch the app (dev flavor). Tap **Gửi** → pick a file → land on the **Kết nối** hub (sender,
   hosting; a live 6-digit code shows).
2. Tap **Chia sẻ link mời** → the system share sheet opens carrying the invite text + a
   `safesend://connect?v=1&code=NNNNNN` link. Send it to yourself (Notes / Messages to self).
3. **Self-invite (FR-015)**: while still hosting, tap that link → expect a toast "this is your own
   invite link"; you stay on the Connect hub, no join attempt.

## B. Warm start — receiver app already open (FR-010)

1. On the receiver device, open the app and leave it on Home.
2. From a chat app, tap a valid invite link shared by the sender (sender hosting a live code).
3. Expect: app foregrounds → Receive flow → **accept/reject prompt** with the sender's manifest, no
   digits typed. Accept → transfer → complete (per #005).
4. History (both devices): the receiver's record shows method = **Chia sẻ link** (FR-017).

## C. Cold start — receiver app fully closed (FR-011)

1. Force-quit the receiver app.
2. Tap a valid invite link from a chat app.
3. Expect: app launches, finishes startup, and lands on the **accept/reject prompt** (the invite is
   not lost during launch). Accept → transfer completes.

## D. Interrupt during a transfer (FR-014)

1. Start a transfer on the receiver (be on the progress screen).
2. Tap a new invite link.
3. Expect a **confirm dialog**: *cancel* keeps the current transfer running; *confirm* leaves it and
   joins the new invite. The running transfer is never silently dropped.

## E. Invalid / expired link (FR-013)

1. Tap a malformed link (e.g. `safesend://connect?v=1&code=12` or `safesend://nope`) → toast
   "invalid invite", land on **Home** (cold and warm).
2. Tap a link whose code expired (wait out the 5-min TTL, or use a stale shared link) → toast
   "expired code", land on **Home**.

## Acceptance check (maps to Success Criteria)

| Step | Criterion |
|---|---|
| B / C reach prompt < 10 s, zero digits | SC-001 |
| Every sender-shared live link pairs | SC-002 |
| Mã 6 số ↔ QR ↔ link never regenerate the code | SC-003 |
| D never silently drops a transfer | SC-005 |
| All E cases land safely on Home with a clear toast | SC-004 |
| B/C records tagged "share link" in History | SC-006 |

## Gate before PR (Constitution Dev Workflow)

```bash
dart format .
dart analyze lib test      # 0 issues (flutter analyze crashes on this checkout — dart analyze is gate-equivalent)
flutter test               # all pass (199 prior + #008 new)
```

## Deferred (tracked in tasks.md banner)

- Two-physical-device cold + warm smoke (B/C/D/E on real hardware over real NAT).
- First `pod install` / `Podfile.lock` commit (folds into the next on-device build).
