# Accessibility Audit (US3)

Per-screen checklist for VoiceOver (iOS) + TalkBack (Android), Dynamic Type, and
Reduced Motion (FR-014–FR-017). Best verified with a screen reader on device.

> Code-level: the shared widget library carries `Semantics` labels; the relay
> indicator (#014) is `Semantics`-labeled; Reduced Motion is gated via
> `MediaQuery.disableAnimations` on the radar + transfer spinner (existing since
> #004). The per-screen walkthrough below needs device verification.

| Screen | Controls announced | Code/state/progress not color-only | Largest text scale OK | Reduced Motion honored |
|---|---|---|---|---|
| Home | ⬜ | ⬜ | ⬜ | n/a |
| Send (selection) | ⬜ | ⬜ | ⬜ | n/a |
| Connect (6-digit/QR/nearby) | ⬜ | ⬜ (code read aloud) | ⬜ (code grid) | ⬜ (radar) |
| Receive (prompt) | ⬜ | ⬜ | ⬜ | n/a |
| Progress | ⬜ | ⬜ (%, relay badge) | ⬜ | ⬜ (spinner) |
| Complete | ⬜ | ⬜ | ⬜ | n/a |
| History (+detail) | ⬜ | ⬜ | ⬜ (rows) | n/a |
| Settings | ⬜ | ⬜ | ⬜ | n/a |
| Viewers (#013) | ⬜ (player controls) | ⬜ | ⬜ | n/a |

Exempt: dev-only debug screen.
