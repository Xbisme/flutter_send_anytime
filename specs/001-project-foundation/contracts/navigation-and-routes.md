# Contract: Navigation & Routes

**Feature**: 001-project-foundation

## Route table (`AppRoutes`)

| Constant | Path | In shell? | Bottom nav visible | Notes |
|---|---|---|---|---|
| `splash` | `/` | no | no | Native static splash (flutter_native_splash); app then routes to `home` |
| `home` | `/home` | yes (branch 0) | yes | Initial tab |
| `history` | `/history` | yes (branch 1) | yes | Placeholder this spec |
| `settings` | `/settings` | yes (branch 2) | yes | Placeholder this spec |
| `send` | `/send` | **no** (top-level) | **no** | Nav-less flow; ComingSoonView |
| `receive` | `/receive` | **no** (top-level) | **no** | Nav-less flow; ComingSoonView |

- Deep-link scheme `safesend://` is **registered/reserved** at the router + native layers; **no** deep-link handlers are wired in #001 (FR-028).
- All navigation uses `context.go()` / `context.push()` / `context.pop()` (Constitution X). No direct `Navigator`.

## Shell structure

- `StatefulShellRoute.indexedStack` with **exactly 3 branches** → Home, History, Settings (FR-001).
- Each branch has its own `Navigator` + key → per-tab state/scroll preserved across tab switches (FR-003, SC-009).
- App opens on `home` after splash (FR-002).
- Bottom navigation = Material `NavigationBar` styled from design tokens; 3 destinations with Lucide icons (house / history / settings) + localized labels (`nav.home`, `nav.history`, `nav.settings`).

## Behavioral contract

| Given | When | Then |
|---|---|---|
| App launched | startup completes | Splash shown briefly → Home (branch 0) active, 3-tab bar visible |
| On Home | tap History tab | History branch shown; bar indicator moves; Home branch state retained |
| Home scrolled | switch away & back | Home restored to prior scroll (indexedStack) |
| On Home | tap **Gửi** | `push('/send')` → full-screen ComingSoonView, **bottom bar hidden**, back returns to Home |
| On Home | tap **Nhận** | `push('/receive')` → full-screen ComingSoonView, bottom bar hidden, back returns to Home |
| On Home | tap header Settings shortcut | navigate to Settings tab |
| In Send/Receive flow | system back gesture | return to Home, bottom bar restored |

## Acceptance mapping
- FR-001, FR-002, FR-002a, FR-003, FR-005, FR-010, FR-011, FR-028 · SC-001, SC-002, SC-009.
