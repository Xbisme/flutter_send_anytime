# Quickstart — #007 QR Connect

## Prerequisites

- Two physical devices (QR scanning + camera cannot be validated in CI / simulators reliably).
- The signaling relay reachable per flavor (`server/`, dev `ws://`).
- First on-device build after this spec runs `pod install` (mobile_scanner + permission_handler +
  screen_brightness pods) → `ios/Podfile.lock` will churn; commit it.

## CI gate (no devices)

```bash
dart format .
dart analyze lib test            # 0 issues (flutter analyze crashes on this checkout — see CLAUDE.md)
flutter test                     # all pass, incl. new #007 tests
# dart run bloc_tools:bloc lint . # still uninstalled, tracked since #001
```

## Two-device smoke (deferred manual task — track in tasks.md banner)

1. **Sender presents QR**: Device A → Home → Gửi → pick files → Connect hub → **QR tab**.
   - ✅ A QR renders; the readable 6-digit code shows beneath it; screen brightness boosts.
   - ✅ Switch A between **Mã 6 số** ↔ **QR** repeatedly → the code never changes, no reconnect.
   - ✅ Decoding A's QR with any reader yields `safesend://connect?v=1&code=<that code>`.
2. **Receiver scans**: Device B → Home → **Quét QR** (or Nhận → Quét mã QR).
   - ✅ First time: camera permission prompt shows the VI rationale; on grant the preview starts.
   - ✅ Point at A's QR → B joins automatically → incoming-transfer accept/reject prompt (no typing).
3. **Transfer + history**:
   - ✅ Accept → files transfer → complete; A's brightness restores on leaving the QR tab.
   - ✅ Both A and B show the transfer in Lịch sử tagged **QR** (detail → method = QR).
4. **Pick-from-photo**: screenshot A's QR to B's library → B → Quét mã QR → pick image → joins.
5. **Torch**: in a dim room, toggle the scanner torch → camera illuminates.
6. **Permission recovery**: deny camera on B → reopen scanner → ✅ "open Settings" + pick-from-photo
   offered (no dead preview); Open Settings deep-links to the app settings.
7. **Foreign / expired QR**:
   - ✅ Scan a non-Safe-Send QR → gentle "not a Safe Send code" toast, scanning continues.
   - ✅ Scan A's QR after its code expired → "expired code" with a retry path.
8. **Lifecycle**: background B while scanning → camera releases; return → preview resumes.

## Restore note

Brightness is restored on tab-leave / dismiss / background, with the plugin's lifecycle reset as a
backstop — verify the screen does not stay stuck bright after leaving the QR tab.
