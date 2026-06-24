# Phase 1 Data Model: Project Foundation & Navigation

**Feature**: 001-project-foundation · **Date**: 2026-06-24

> #001 has **no persistence**. These are presentation-layer / domain **view-models** and foundation primitives held in memory. All "data" on Home is static mock content (R-09). Models are immutable (`freezed`). The seams here are designed so later specs (#006 real data, #010 settings) replace the *data source*, not the models or UI.

---

## Foundation Primitives (core/domain)

### Result\<T\>
- Sealed union: `Success(T value)` | `Failure(AppFailure failure)`.
- `.fold(onSuccess, onFailure)`, `.when(...)`. Used by every repository/data-source.

### AppFailure (freezed sealed)
- Foundation variants needed in #001 (the full P2P set arrives with later specs):
  - `unexpected({String? message, Object? error})`
  - `notImplemented` — backing the "coming soon" placeholder flows.
- Later specs extend this union (signaling/transfer/file failures). UI maps each to a localized message — never raw exception text.

### AppCubit\<T\> (base)
- Abstract base emitting the mandatory 4-state freezed union:
  `initial → loading → loaded({required T data}) → error({required AppFailure failure})`.
- Helpers: `emitLoading()`, `emitLoaded(T)`, `emitError(AppFailure)`. All feature cubits extend this.

---

## Configuration & Theming

### AppFlavor (enum)
- `dev`, `prod`. Drives application id, display name, and (later) signaling endpoint.

### AppConfig
- Fields: `flavor: AppFlavor`, `appName: String`, `deepLinkScheme: String = 'safesend'`.
- Provided at bootstrap per entry point (`main_dev` / `main_prod`); registered as `@lazySingleton`.

### Design Token Sets (core/theme) — see contracts/design-tokens.md
- **AppColors**: semantic aliases resolved per brightness (light/dark): `bgBase, bgSubtle, surfaceCard, surfaceSunken, borderSubtle/Default/Strong, textPrimary/Secondary/Muted, textOnAccent, accent/Hover/Press, accentSubtle, accentBorder, overlay` + brand greens/teal + status (info/success/warning/danger) + gradients (brand, brandVivid, radar).
- **AppTypography**: `Sora` (display/body) + `JetBrainsMono` (mono) text styles for the scale (xs 12 → 4xl 60), weights 400–800.
- **AppSpacing** (4-base: 4…80), **AppRadii** (card 16/18, hero 20/22, chip 11–14, pill 999, full 50%), **AppShadow** (soft, accent-glow), **AppMotion** (durations 120/200/360, ease-out curve).
- **AppTheme**: builds light + dark `ThemeData` from the above; `ThemeMode.system`.

---

## Navigation

### NavTab (enum + descriptor)
- Values: `home`, `history`, `settings`.
- Each descriptor: `route: String` (from `AppRoutes`), `labelKey` (l10n), `icon: IconData` (Lucide: house / history / settings), `activeIcon`.
- Exactly three; **no** send/receive tab.

### AppRoutes (constants)
- `splash = '/'` (or initial), `home = '/home'`, `history = '/history'`, `settings = '/settings'`, `send = '/send'`, `receive = '/receive'`.
- `deepLinkScheme = 'safesend'` (reserved; no handlers in #001).

---

## Home Placeholder View-Models (features/home/domain) — static mock (R-09)

### HomeDashboard (aggregate returned by HomePlaceholderDataSource as Result<HomeDashboard>)
- `summary: TransferSummary`
- `stats: List<StatTileModel>` (exactly 3: photos, videos, files)
- `recentImages: List<MediaThumb>`
- `recentVideos: List<VideoThumb>`
- `recentFiles: List<FileItemModel>`
- `recentTransfers: List<TransferGroupModel>`
- `quickActions: List<QuickActionModel>`

### TransferSummary
- `sentBytes: int`, `receivedBytes: int`, `monthlyTransferCount: int`, `progressFraction: double` (0–1, for hero bar). Displayed via mono + size formatter.

### StatTileModel
- `kind: {photos, videos, files}`, `count: int`, `labelKey`, `icon`, `accentColorToken`.

### MediaThumb / VideoThumb
- `name: String`, `sizeLabel: String`, `gradient` (placeholder visual); VideoThumb adds `durationLabel`.

### FileItemModel
- `name: String`, `ext: String` (PDF/DOCX/…), `metaLabel: String` (size · date), derived `chipColorToken` from ext→color map.

### TransferGroupModel
- `direction: TransferDirection {sent, received}`, `peerName: String`, `metaLabel` (count · size), `timeLabel`, `thumbs: List<gradient>`, `moreCount: int`.

### QuickActionModel
- `kind: {scanQr, nearby, send, receive}`, `labelKey`, `subLabelKey`, `icon`, `gradientToken`. Tap targets: `send`→Send flow, `receive`→Receive flow; `scanQr`/`nearby`→Send/Receive placeholder (real targets in #007/#009).

> **Enum reuse note**: `TransferDirection` and the ext→color map live in `core/domain` (not the home feature) because History (#006) reuses them. This keeps the model shared without cross-feature imports.

---

## Settings Placeholder Models (features/settings) — visual only

### SettingsToggleRowModel (static, non-functional in #001)
- `labelKey`, `subLabelKey`, `icon`, `value: bool` (display only — no persistence; real behavior in #010).
- Rows shown: auto-receive, save-to-library, notifications, dark-mode (all static).

### DeviceProfileModel (static placeholder)
- `displayName: String` (e.g. "An's iPhone"), `avatarInitial: String`. Editable behavior deferred to #010.

---

## Localization (l10n)

### LocalizedString (ARB-backed, conceptual)
- Keyed entry with `vi` (primary) + `en` values + `@description`.
- Key groups this spec introduces: `nav.*` (3 tabs), `home.*` (header, search hint, hero labels, section titles, tip card, quick actions), `send.*`/`receive.*` (coming-soon copy), `history.*` (title + empty state), `settings.*` (title, profile, toggle labels, version), `common.*` (see-all, back).

---

## Relationships / Lifecycle

- `HomeCubit` (extends `AppCubit<HomeDashboard>`) → on init calls `HomePlaceholderDataSource.load()` → `Result<HomeDashboard>` → emits `loaded` (always succeeds in #001; `error` path wired for #006).
- No state transitions persist; no entity has an identity/uniqueness rule (no storage).
- App shell holds the active `NavTab`; `StatefulShellRoute` preserves each branch's navigator stack + scroll (FR-003).
- Send/Receive flows are leaf routes with no model — they render `ComingSoonView` (`AppFailure.notImplemented` semantics, but presented as a friendly branded placeholder, not an error state).
