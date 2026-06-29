# Dark-Mode Sweep (US4 / T034)

Confirm every screen renders correctly in both light and dark with **tokens
only** (no hardcoded hex) and adequate contrast (FR-019). The palette is fixed
(Principle VI); this is a verification + fix pass, best done on device.

> Code-level guard: `grep` for hardcoded colors at call sites should find none
> outside the token layer. Run:
> `grep -rnE "Color\(0x|Colors\.[a-z]" lib --include="*.dart" | grep -v core/theme`
> (expected: empty, or only token definitions).

| Screen | Light OK | Dark OK | Notes |
|---|---|---|---|
| Home | ⬜ | ⬜ | |
| Send (selection) | ⬜ | ⬜ | |
| Connect (all tabs) | ⬜ | ⬜ | |
| Receive (prompt) | ⬜ | ⬜ | |
| Progress (+ relay badge #014) | ⬜ | ⬜ | |
| Complete | ⬜ | ⬜ | |
| History (+detail) | ⬜ | ⬜ | |
| Settings (+ how-it-works/privacy) | ⬜ | ⬜ | |
| Viewers (#013) | ⬜ | ⬜ | |
| Toasts / dialogs | ⬜ | ⬜ | |
