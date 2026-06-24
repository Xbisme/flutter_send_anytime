# Contract: Shared Widget Library (core/presentation)

**Feature**: 001-project-foundation · Built once here, reused by all later specs (FR-017, SC-007). Lives in `core/presentation/` — MUST NOT import from `features/` (Constitution XI).

Each widget consumes design tokens only (no hardcoded values). Each ships a widget test and renders correctly in light + dark.

| Widget | Purpose | Key API (props) | Used by (this spec) |
|---|---|---|---|
| `PrimaryButton` | CTA pill, brand gradient, `textOnAccent`, height 52, optional leading/trailing icon, accent glow | `label`, `onPressed`, `icon?`, `expanded=true`, `enabled` | Home actions, ComingSoon |
| `SecondaryButton` | Pill, 2px border, transparent/surface | `label`, `onPressed`, `icon?` | ComingSoon, Settings |
| `DangerButton` | Pill, 2px danger border, danger text | `label`, `onPressed`, `icon?` | (reserved; used #004/#005) |
| `FileChip` | Rounded ext badge, color by file type | `ext` (→ color via core ext-map) | Home file rows |
| `FileRow` | Card row: chip + name(ellipsis) + mono meta + trailing slot | `name`, `meta`, `ext`, `trailing?` | Home "recent files" |
| `CodeBox` | Single mono digit/char cell, accent border, optional caret | `value?`, `focused=false` | (reserved; used #003/#005) |
| `SegmentedTabs` | Pill segmented control, active = surface + accent | `segments`, `selectedIndex`, `onChanged` | (reserved; used #003) |
| `ToggleRow` | Settings row: icon + label/sub + switch | `label`, `sub`, `icon`, `value`, `onChanged?` | Settings placeholder (static) |
| `StatTile` | Square stat tile: icon + mono count + label | `icon`, `count`, `label`, `accentToken` | Home stat tiles |
| `QuickActionCard` | Gradient action card: icon + label/sub | `label`, `sub`, `icon`, `gradientToken`, `onTap` | Home quick actions |
| `SearchPill` | Inert search field pill (presentational) | `hintText`, `onTap?` | Home search |
| `AppToast` | Centralized toast (toastification) | `AppToast.show(context, message, {type})` | global; never raw ScaffoldMessenger |
| `AppEmptyView` | Centered empty state (icon + title + optional CTA) | `icon`, `title`, `cta?` | History/Settings placeholders |
| `FlowAppBar` | Flow-screen app bar: 40px circular back/close + title | `title`, `leadingIcon` (arrow-left/x), `onLeading` | Send/Receive flows |
| `ComingSoonView` | Branded "Sắp ra mắt" placeholder body | `titleKey`, `subKey`, `icon` | Send/Receive flows |

## Contract rules
- Buttons: every button is one of `PrimaryButton/SecondaryButton/DangerButton` (no inline `styleFrom` at call sites — Constitution VI).
- All user-facing text comes in via localized strings from the caller (widgets take already-resolved strings or l10n keys; no hardcoded copy inside).
- Reduce Motion: any animated affordance added later checks `MediaQuery.disableAnimations`; #001 widgets are static.
- Accessibility: interactive widgets expose semantic labels/tooltips (FR-021).

## Acceptance mapping
- FR-017 (library exists + reused), SC-007 (each component referenced by ≥1 shell screen, not duplicated).
