# Contract: iOS Live Activity `ContentState` (Dart ↔ Swift)

**Date**: 2026-06-27. The cross-boundary payload pushed from Dart (`live_activities`) into the native iOS Widget Extension's `ActivityAttributes.ContentState`. This is the one real serialization contract in #011. Keys MUST match exactly on both sides.

## State payload (App-Group dictionary)

| Key | Type | Example | Notes |
|---|---|---|---|
| `direction` | `String` | `"send"` / `"receive"` | selects accent + icon + verb in SwiftUI |
| `title` | `String` | `"Đang gửi · 18 tệp"` | localized in Dart (ARB) |
| `peerLine` | `String` | `"tới Minh's iPhone"` | localized in Dart |
| `percent` | `Int` | `64` | 0–100; drives ring + bar |
| `speedLabel` | `String` | `"2.4 MB/s"` | mono, formatted in Dart (intl) |
| `bytesLabel` | `String` | `"153 / 240 MB"` | mono, formatted in Dart |
| `etaLabel` | `String` | `"còn 0:48"` | mono, formatted in Dart |
| `phase` | `String` | `"transferring"` / `"done"` / `"failed"` / `"cancelled"` | final phases switch the widget to a settled look before dismissal |

> The Swift widget renders **only** what it is given (no business logic, no localization, no formatting in Swift) — Constitution XIV. All numbers arrive pre-formatted as mono strings except `percent` (needed numerically for the ring/bar geometry).

## SwiftUI surfaces to implement (Widget Extension target)

Per `ui-design-context.md` → "OS Surfaces — Background Transfer":

- **Dynamic Island compact**: leading = direction icon on brand chip; trailing = % ring.
- **Dynamic Island minimal**: % ring + direction arrow.
- **Dynamic Island expanded** (long-press): icon badge · title + peerLine · big % (mono) · progress bar · speedLabel ↔ bytesLabel·etaLabel row.
- **Lock Screen**: the expanded card layout on a translucent background.

No control buttons on the iOS surface (Cancel is Android-only — FR-007/FR-017). Tapping opens the app (deep link handled by the host app to the active progress route).

## Palette (mirrored literally into Swift — documented exception to Constitution VI)

The native widget cannot import Dart design tokens; these hexes come from the design token file and MUST stay in sync if tokens change:

| Token | Hex | Use |
|---|---|---|
| `green-400` | `#1ED66E` | send accent (%, ring), bar gradient start |
| `green-500` | `#00C853` | brand |
| `gradient-brand` | `#00E676 → #00C2A8` | send icon badge + bar |
| `gradient-brand-vivid` | `#1ED66E → #00B4D8` | receive icon badge + bar |
| receive accent | `#4FE6FF` | receive % / ring |
| island bg | `#000000` | Dynamic Island / card |
| icon-on-brand | `#053019` | arrow on send badge |

Fonts: **JetBrains Mono** for all numeric values (%, speed, bytes, ETA); **Sora** for title/peerLine. (Both already bundled in the app; the widget extension bundles the same TTFs.)
