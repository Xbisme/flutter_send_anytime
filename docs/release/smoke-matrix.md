# Two-Device Smoke Matrix (US5)

Clears the deferred on-device backlog from #002–#013. Run on **two physical
devices** (one iOS, one Android). CI loopback cannot validate real NAT
traversal, native pods, throughput, or platform background behavior. Mark each
cell ✅/❌ with notes.

> Status: ⬜ pending hardware (needs 2 devices + an Apple signing Team).

## Connection methods — full pair → send → receive → save

| Scenario | iOS→Android | Android→iOS | Notes |
|---|---|---|---|
| 6-digit code | ⬜ | ⬜ | |
| QR scan | ⬜ | ⬜ | |
| Share link (warm) | ⬜ | ⬜ | |
| Share link (cold start) | ⬜ | ⬜ | |
| Nearby radar (same Wi-Fi) | ⬜ | ⬜ | |

## Resilience & relay (US1 on real networks)

| Scenario | Result | Notes |
|---|---|---|
| Forced relay-only path completes (FR-001) | ⬜ | indicator shows "relayed · encrypted" |
| Direct path when reachable (relay not used, FR-004) | ⬜ | no relay indicator |
| Kill Wi-Fi mid-transfer → clear retry, partial kept | ⬜ | |
| Background past OS limit → clean fail/grace per platform | ⬜ | |
| TURN unreachable but direct works (FR-008) | ⬜ | |

## Background transfer (#011)

| Scenario | iOS | Android |
|---|---|---|
| Backgrounded send sustains/displays per platform | ⬜ | ⬜ |
| Cancel from the OS surface | ⬜ | ⬜ |

## In-app viewers (#013)

| Type | Result |
|---|---|
| Image (zoom/pan) | ⬜ |
| Video / audio (play/seek, stops on dismiss) | ⬜ |
| PDF (page/zoom) | ⬜ |
| Text/code (selectable, truncation notice) | ⬜ |
| Real video thumbnails in grids | ⬜ |

## Performance (US4)

| Scenario | Result | Notes |
|---|---|---|
| ≥4 GB single file — bounded memory, no freeze (SC-007) | ⬜ | profile peak memory |
| Many-file batch — bounded memory | ⬜ | |
| Cold start ≤ 3 s to interactive Home (FR-022) | ⬜ | measure |

## Native build

| Item | Result |
|---|---|
| iOS `pod install` (folds any pod churn) | ⬜ |
| Signing Team configured; prod build runs on device | ⬜ |
| Android release signingConfig; prod appbundle runs on device | ⬜ |
