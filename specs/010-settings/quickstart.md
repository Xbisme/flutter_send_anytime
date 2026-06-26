# Quickstart / Manual Verification: Settings & Preferences (#010)

Run after implementation. CI-testable items are covered by unit/bloc/widget tests; items marked 📱 need two physical devices (deferred, tracked in tasks.md banner).

## Setup
```bash
flutter pub get          # pulls shared_preferences, package_info_plus, in_app_review, gal, flutter_local_notifications
dart run build_runner build --delete-conflicting-outputs   # injectable + freezed codegen
dart analyze lib test    # expect 0 issues
flutter test             # expect all pass (prior 230 + new)
```
> First iOS device build: `pod install` will churn `ios/Podfile.lock` (gal + flutter_local_notifications pods) — expected.

## US1 — Device profile (P1)
1. Open Cài đặt. Profile card shows the generated default name + initial avatar + "hiển thị với thiết bị gần đây".
2. Tap edit → change to "Minh's iPhone" → save. Card updates immediately.
3. Try saving empty / only spaces → rejected, previous name kept.
4. Try a 40-char name → rejected (≤30).
5. Force-quit + relaunch → custom name persists.
6. 📱 Pair via 6-digit/QR/share-link to a 2nd device → the receiver's **accept prompt shows "Minh's iPhone"** (via manifest `senderName`); History on the receiver shows it as `peerLabel`.
7. 📱 Open the "Gần đây" tab → the 2nd device sees "Minh's iPhone" in the nearby list (mDNS TXT).

## US2 — Incoming-file handling (P1)
1. Toggle Tự động nhận / Lưu vào Thư viện / Thông báo → each persists across restart.
2. **Auto-receive**: with it ON and the receive screen foregrounded, 📱 send from the 2nd device → transfer is accepted **without** the manual prompt. Turn OFF → the prompt returns.
3. **Save-to-library**: turn ON (grant photo permission when asked) → 📱 receive an image → it appears in the system photo library *and* still in the app save/share. Receive a non-media file → library untouched.
4. **Notifications**: turn ON (grant notif permission) → background the app → 📱 send → a local notification appears; tapping it opens the receive screen for that transfer.
5. **Permission denial**: deny the photo / notification permission → the toggle does not show active; an Open-Settings path is offered.

## US3 — Appearance & language (P2)
1. Theme → Tối: every screen switches to dark immediately; restart keeps it.
2. Theme → Theo hệ thống: flip OS dark/light → app follows.
3. Language → English: all copy switches immediately; restart keeps it. Theo hệ thống with an unsupported OS locale → Vietnamese.

## US4 — Advanced signaling (P3)
1. Enter `wss://my.relay:8443` → saves; the next pairing uses it.
2. Diagnostic → reports reachable / unreachable in plain language.
3. Enter `ws://x` in a **prod** build → rejected; in a **dev** build → accepted. Enter `http://x` → rejected, prior value kept.
4. Clear the field → reverts to the per-flavor default (diagnostic confirms).

## US5 — About (P3)
1. About shows the real build version + "Safe Send v1.0.0 · WebRTC P2P".
2. Open How-it-works → in-app explainer (no browser). Open Privacy → in-app page.
3. Rate app → native review sheet appears.

## Regression
- `dart analyze` 0 · `flutter test` green · `dart format` clean.
- Existing send/receive/history/pairing flows unaffected; manifest round-trip still passes loopback (now with optional `senderName`).
- No device name / endpoint / secret in logs (grep the AppLogger output).
