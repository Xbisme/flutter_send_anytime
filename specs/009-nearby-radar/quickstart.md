# Quickstart & Verification: Nearby Radar (Gần đây)

**Feature**: #009 | **Date**: 2026-06-26 | **Plan**: [plan.md](plan.md)

## Prereqs

- `flutter pub get` after `nsd: ^5.0.1` is added to `pubspec.yaml`.
- Run codegen (freezed/injectable): `dart run build_runner build --delete-conflicting-outputs`.
- iOS: first `pod install` (adds the `nsd` pod — `Podfile.lock` will churn).

## Automated gate (CI-equivalent, no device needed)

```bash
dart analyze lib test          # 0 issues (flutter analyze crashes on this checkout — use dart analyze, per #001)
flutter test                   # all pass, incl. the new #009 tests over the in-process fake discovery service
dart format --output=none --set-exit-if-changed .
```

The in-process **fake `NearbyDiscoveryService`** proves the advertise → browse → tap → `joinWithCode` path
without real mDNS or a second device (research D8).

## Manual two-device smoke (REQUIRED, deferred — Constitution XII)

Two **physical** devices on the **same Wi-Fi** (radar is same-network only — Clarification).

1. **Permission (first run)**
   - iOS: on entering a nearby surface, see the rationale, then the OS **Local Network** prompt → Allow.
   - Android 13+: see the rationale, then the **Nearby devices** permission prompt → Allow.
   - Deny path: confirm a **permission-blocked** state with retry / Open Settings (Android); iOS shows the
     empty-state hint (no query API).

2. **Discover + connect (P1 / SC-001, SC-002)**
   - Device A (sender): pick files → Connect hub → **"Gần đây"** tab → radar shows "discoverable" + the live
     code/countdown + privacy note.
   - Device B (receiver): open **Nhận** (or Home → **Thiết bị gần**) → device A appears as a device row with
     name + avatar **within ~5 s**.
   - Tap A's row on B → lands straight on the **accept/reject** prompt (zero typing). Accept → transfer runs
     and saves; history on both shows **pairingMethod = nearby**.

3. **Lifecycle (FR-005, SC-003)**
   - On A, switch away from "Gần đây" (to QR / Mã 6 số) or background the app → A disappears from B's radar
     within ~10 s. Switching back re-advertises. Confirm switching tabs **never regenerates the code**
     (FR-009).

4. **Resilience / edge cases**
   - Let A's code expire (or stop advertising) then tap its stale row on B → graceful toast + the entry
     drops off; radar stays usable (FR-017).
   - Two senders advertising → both listed distinctly; tapping one connects only to it.
   - Put both devices on **different networks** → B's radar shows the empty same-Wi-Fi hint (not an error).
   - Reduce Motion on → radar wave animation static (FR-019).
   - Reject at the prompt → no transfer, no history record (FR-001).

## Done = 

- Automated gate green; all FR-001..019 exercised by tests or the smoke checklist; `pairingMethod=nearby`
  recorded; no edits to signaling/transport/protocol/history-schema (SC-004); two-device same-Wi-Fi smoke
  passed on real hardware (or explicitly tracked as deferred in `tasks.md`).
