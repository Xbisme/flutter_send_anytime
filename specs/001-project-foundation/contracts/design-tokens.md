# Contract: Design Tokens

**Feature**: 001-project-foundation · **Source of truth**: `.claude/claude-app/ui-design-context.md` (rendered screens win over source CSS where they disagree, e.g. radii).

All visual properties MUST come from these tokens (Constitution VI / FR-015). No hardcoded hex / pixel values at call sites.

## Color — semantic aliases (resolved per brightness)

| Alias | Light | Dark |
|---|---|---|
| `bgBase` | `#FFFFFF` | `#070B09` |
| `bgSubtle` (screen bg) | `#F4F7F5` | `#0E1512` |
| `surfaceCard` | `#FFFFFF` | `#18211D` |
| `surfaceSunken` | `#E8EEEA` | `#0E1512` |
| `borderSubtle / Default / Strong` | `#E8EEEA / #D6E0DA / #B6C4BC` | `#18211D / #283330 / #3E4B45` |
| `textPrimary / Secondary / Muted` | `#0E1512 / #5B6B64 / #8A9A92` | `#F4F7F5 / #8A9A92 / #5B6B64` |
| `textOnAccent` | `#070B09` | `#070B09` |
| `accent / Hover / Press` | `#00C853 / #00A847 / #008539` | `#1ED66E / #4FE08F / #00C853` |
| `accentSubtle` | `#E6FBEF` | `rgba(0,200,83,.14)` |
| `accentBorder` | `#8DECB6` | `rgba(0,200,83,.35)` |
| `overlay` | `rgba(7,11,9,.45)` | `rgba(0,0,0,.6)` |

Base ramps (constant across themes): green 50–900 (`#E6FBEF`…`#0A4322`, core `#00C853`), teal 300–600 (`#4FE6D2`…`#009E8A`), neutral 0–950, status info `#2D9CF0` / success `#00C853` / warning `#F5A623` / danger `#FF4D4D`.

Gradients: `brand` = `linear(135°,#00E676,#00C2A8)`; `brandVivid` = `linear(135°,#1ED66E,#00B4D8)`; `radar` = `radial(rgba(0,200,83,.28)→transparent 70%)`.

## Typography

- Families: `Sora` (display/body), `JetBrainsMono` (mono — codes, sizes, rates, counts, timestamps).
- Scale (px): xs 12 · sm 14 · base 16 · md 18 · lg 22 · xl 28 · 2xl 36 · 3xl 48 · 4xl 60.
- Weights: 400/500/600/700/800. Tracking: tight `-0.02em` (display), code `0.12em`.
- **Numeric/technical values MUST use the mono style with tabular figures** (FR-016).

## Spacing / Radius / Shadow / Motion

- Spacing (4-base): 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80.
- Radius (rendered-screen values): card 16–18 · hero 20–22 · phone-frame n/a · chip/code 11–14 · pill 999 · full 50%.
- Shadow: `soft` = `0 6px 20px rgba(7,11,9,.07)` (light) / `0 6px 20px rgba(0,0,0,.4)` (dark); `accentGlow` = `0 8px 22px rgba(0,200,83,.32–.42)`.
- Motion: durations fast 120 / base 200 / slow 360 ms; ease-out `cubic-bezier(.16,1,.3,1)`. **Decorative motion freezes when Reduce Motion is on** (FR-019).

## Theme contract

- `AppTheme.light` / `AppTheme.dark` built entirely from the above; app uses `ThemeMode.system` (R-06).
- Tap target ≥ 44px. Min contrast on text passes in both themes (SC-003).
