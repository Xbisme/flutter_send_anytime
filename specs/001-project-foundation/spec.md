# Feature Specification: Project Foundation & Navigation

**Feature Branch**: `001-project-foundation`
**Created**: 2026-06-24
**Status**: Draft
**Input**: User description: "Spec #001 — Project Foundation & Navigation cho Safe Send (app chia sẻ file P2P qua WebRTC, Flutter, iOS + Android). Foundation spec — no networking/WebRTC/persistence yet; build the app shell + design system + navigation so every later spec plugs in."

## Overview

Safe Send is a peer-to-peer file-sharing app (Send Anywhere-style). This first feature establishes the **application shell**: the brand-correct visual identity, a fixed light/dark design system, the three-tab navigation, and a fully laid-out Home screen (with placeholder data) including the two primary actions — **Gửi (Send)** and **Nhận (Receive)**. No real file transfer, discovery, persistence, or settings logic is delivered here; those arrive in later features and plug into this foundation without rework.

The value: the team can immediately open the app on iOS and Android, navigate it, see the real look-and-feel, and validate layout/branding/localization/accessibility — while every subsequent feature (transport, send, receive, history, settings) lands into an already-correct frame.

## Clarifications

### Session 2026-06-24

- Q: How should Home's hero summary, stat tiles, and "recent" sections render in #001 (no real data yet)? → A: Static sample/mock data matching the design mockup (populated hero stats + sample recent media grids); clearly non-functional, replaced by real values in #006.
- Q: Is a splash/launch screen in scope for #001, and what kind? → A: Minimal static branded splash (logomark on brand background) shown during startup, then Home; no animation, no logic.
- Q: What is the minimum supported OS baseline for the app? → A: iOS 13.0 and Android 8.0 (API 26) — WebRTC-ready modern baseline (~98% device coverage), clears API floors for later Local Network / nearby-Wi-Fi permissions.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate the app shell across three tabs (Priority: P1)

A user opens Safe Send and lands on the Home tab. A bottom navigation bar offers exactly three destinations — **Trang chủ (Home)**, **Lịch sử (History)**, **Cài đặt (Settings)**. The user moves between tabs and each retains its own scroll position and state.

**Why this priority**: The navigation frame is the spine every other feature attaches to. Without it there is no app to demonstrate, and it is the single most reusable artifact of this spec.

**Independent Test**: Launch the app, confirm Home is shown first, tap each of the three tabs, confirm the correct destination appears with its title/empty-state, scroll one tab and switch away and back to confirm state is preserved.

**Acceptance Scenarios**:

1. **Given** the app is freshly launched, **When** it finishes loading, **Then** the Home tab is shown with the bottom navigation bar displaying three tabs (Trang chủ, Lịch sử, Cài đặt) and Home marked active.
2. **Given** the user is on Home, **When** they tap the History tab, **Then** the History destination appears with its title and an empty-state placeholder, and the active-tab indicator moves to History.
3. **Given** the user scrolled the Home tab partway, **When** they switch to another tab and return to Home, **Then** Home is restored to its previous scroll position without rebuilding from scratch.
4. **Given** any tab is active, **When** the user views the bottom bar, **Then** exactly three tabs are present (no Send or Receive tab).

---

### User Story 2 - See the full Home layout and open the Send & Receive flows (Priority: P1)

On the Home tab the user sees the complete designed layout (with placeholder content): a header with the Safe Send logo/wordmark and a Settings shortcut, a search field, a hero summary card, three statistic tiles (Photos/Videos/Files), "recent" sections (Photos, Videos, Files, Transfers) in an empty/placeholder state, a quick-actions grid, and a tip card. The two primary actions **Gửi** and **Nhận** are present and tappable; each opens a full-screen flow that, in this foundation release, shows a branded "Coming soon" placeholder and can be dismissed back to Home.

**Why this priority**: Home is the product's front door and the entry to the two core jobs (send, receive). Proving the layout and the action entry points validates the design end-to-end and gives later specs a concrete surface to replace.

**Independent Test**: Open Home, visually confirm every designed section is present and laid out per the design, tap Gửi and confirm a full-screen placeholder opens with the bottom navigation hidden and a back affordance, dismiss it, repeat for Nhận.

**Acceptance Scenarios**:

1. **Given** the Home tab is shown, **When** the user views it, **Then** the header (logo + "Safe Send" + Settings shortcut), search field, hero summary card, three stat tiles, recent sections, quick-actions grid, and tip card are all visible in the designed order.
2. **Given** the Home tab is shown, **When** the user taps **Gửi**, **Then** a full-screen Send placeholder screen opens, the bottom navigation bar is hidden, and a back/close affordance returns the user to Home.
3. **Given** the Home tab is shown, **When** the user taps **Nhận**, **Then** a full-screen Receive placeholder screen opens, the bottom navigation bar is hidden, and a back/close affordance returns the user to Home.
4. **Given** the "recent" sections have no real data in this release, **When** Home is shown, **Then** those sections render their empty/placeholder state without errors or broken layout.
5. **Given** the Settings shortcut in the header, **When** the user taps it, **Then** the app navigates to the Settings destination.

---

### User Story 3 - Consistent appearance in light & dark, localized, and accessible (Priority: P2)

The user's device theme and language drive the app. In system light mode the app uses the light palette; in dark mode it uses the dark palette — both from the fixed Safe Send design system (no in-app color-scheme picker). All visible text is localized, with **Vietnamese as the primary language** and English as a fallback. The shell respects Reduce Motion (decorative animations freeze), Dynamic Type / font scaling, and screen readers, and it lays out correctly on devices with notches/Dynamic Island and display cutouts without content entering unsafe areas.

**Why this priority**: Getting theming, localization, and accessibility right at the foundation prevents pervasive rework later; every later screen inherits these behaviors. It is P2 only because the app is already demonstrable (P1) before these are fully proven.

**Independent Test**: Toggle the device between light and dark and confirm the whole shell flips palette; switch device language between Vietnamese and English and confirm tab labels and titles change; enable Reduce Motion and confirm decorative animation stops; increase font size and confirm layouts adapt; view on a notched device and a cutout device and confirm no clipping into unsafe areas.

**Acceptance Scenarios**:

1. **Given** the device is in dark mode, **When** the app is shown, **Then** every shell surface, text, and control uses the dark palette from the design system with legible contrast.
2. **Given** the device language is Vietnamese, **When** the app is shown, **Then** the tab labels read "Trang chủ", "Lịch sử", "Cài đặt" and all visible copy is in Vietnamese.
3. **Given** the device language is English, **When** the app is shown, **Then** all visible copy switches to English with no hardcoded Vietnamese remaining.
4. **Given** Reduce Motion is enabled, **When** a screen with a decorative animation is shown, **Then** the animation is presented in a static state.
5. **Given** a larger system font size, **When** any shell screen is shown, **Then** text scales and the layout adapts without truncation that hides essential meaning or overlapping controls.
6. **Given** a device with a notch/Dynamic Island or a display cutout, **When** any shell screen is shown, **Then** interactive and textual content stays within the safe area.

---

### Edge Cases

- **Tap a not-yet-built destination**: Tapping Gửi or Nhận (or any "Xem tất cả"/quick action that targets future functionality) must lead to a clear branded placeholder, never a crash, dead-end, or blank screen.
- **Very small / very large screens**: The Home layout must remain usable on the smallest supported phone and on large phones/tablets without overflow errors or clipped controls.
- **Unsupported device language**: If the device language is neither Vietnamese nor English, the app falls back to a defined default language (see Assumptions) rather than showing untranslated keys.
- **Rapid tab switching**: Quickly switching tabs repeatedly must not lose per-tab state or cause flicker/rebuild storms.
- **Settings toggles (visual only)**: Any toggle shown on the Settings destination in this release is non-functional UI; interacting with it must not imply a real preference change or persist anything.
- **Back gesture from a placeholder flow**: Using the system back gesture/button from a Send/Receive placeholder returns to Home and restores the bottom navigation.

## Requirements *(mandatory)*

### Functional Requirements

#### Navigation & Shell
- **FR-001**: The app MUST present a bottom navigation bar with exactly three destinations — Home, History, Settings — and no Send or Receive tab.
- **FR-002**: The app MUST open to the Home destination on launch.
- **FR-002a**: The app MUST show a minimal static branded launch/splash screen (logomark on the brand background, no animation, no logic) during startup, then transition to the Home destination.
- **FR-003**: Each tab MUST preserve its own navigation/scroll state when the user switches away and returns.
- **FR-004**: The History and Settings destinations MUST render a branded title and an empty-state/placeholder consistent with the design system in this release.
- **FR-005**: The app MUST expose a Settings shortcut from the Home header that navigates to the Settings destination.

#### Home Screen
- **FR-006**: The Home screen MUST display, in the designed order: header (logo + "Safe Send" wordmark + Settings shortcut), a search field, a hero summary card, three statistic tiles (Photos/Videos/Files), recent sections (Photos, Videos, Files, Transfers), a quick-actions grid, and a tip card.
- **FR-007**: The Home screen MUST present **Gửi (Send)** and **Nhận (Receive)** as tappable primary actions.
- **FR-008**: Recent sections and summary figures MUST render with **static sample/mock content matching the design mockup** in this release (no real transfer data) without layout errors. This content MUST be clearly non-functional placeholder data, replaced by real values in #006.
- **FR-009**: The search field MUST be displayed as a visual (presentational) element; it does not perform search in this release. It MUST be **inert** (a no-op affordance that does not open a keyboard or a broken/blank search surface). Real search is out of scope (deferred).

#### Send / Receive Flow Entry (placeholder)
- **FR-010**: Tapping **Gửi** MUST open a full-screen flow that hides the bottom navigation bar and provides a back/close affordance returning to Home.
- **FR-011**: Tapping **Nhận** MUST open a full-screen flow that hides the bottom navigation bar and provides a back/close affordance returning to Home.
- **FR-012**: The Send and Receive flows in this release MUST present a clear, branded "coming soon" placeholder rather than any real transfer functionality.

#### Design System & Theming
- **FR-013**: The app MUST apply a single fixed design system with a light and a dark palette sourced from the Safe Send design tokens; there MUST be no in-app color-scheme picker.
- **FR-014**: The app MUST follow the device theme (light / dark / follow-system) for choosing between the light and dark palettes.
- **FR-015**: All shell screens MUST use design-system tokens (color, typography, spacing, radius, shadow) for visual properties; the design system MUST be the single source of these values.
- **FR-016**: Numeric and technical values (sizes, counts, codes, rates, timestamps) MUST be presented using the design system's monospaced type treatment.
- **FR-017**: The app MUST provide a reusable component set: primary/secondary/danger buttons, file chip and file row, code box, segmented tabs, toggle row, statistic tile / quick-action card, search pill, toast/notification, empty view, and a flow-screen app bar. Components not yet exercised by a #001 screen (code box, segmented tabs, danger button) are built as **reserved** shared components for later features (#003/#004/#005), per SC-007.
- **FR-018**: The app MUST display the Safe Send logomark and wordmark from the official brand assets.

#### Accessibility & Platform
- **FR-019**: Decorative animations MUST present in a static state when the device's Reduce Motion setting is enabled.
- **FR-020**: All shell text MUST scale with the device's Dynamic Type / font-scaling setting, and layouts MUST adapt without hiding essential meaning.
- **FR-021**: Shell screens MUST expose meaningful labels to screen readers (VoiceOver/TalkBack) for navigation items, the Settings shortcut, and the primary actions.
- **FR-022**: Shell content MUST remain within the device safe area on phones with notches/Dynamic Island and display cutouts, on both iOS and Android.

#### Internationalization
- **FR-023**: All user-facing strings MUST be localized through the app's localization system with no hardcoded display strings.
- **FR-024**: The app MUST provide Vietnamese (primary) and English (secondary) translations for every user-facing string introduced in this release.
- **FR-025**: Date, time, number, and size formatting (where shown as placeholders) MUST use locale-aware formatting.

#### Foundation Quality (structural, user-invisible but verifiable)
- **FR-026**: The app MUST build and run on both iOS and Android, supporting a minimum baseline of **iOS 13.0** and **Android 8.0 (API level 26)**.
- **FR-027**: The app MUST provide two build configurations (a development and a production flavor) that are each launchable.
- **FR-028**: The app MUST reserve a deep-link scheme (`safesend://`) at the navigation layer for later features, without exposing user-facing deep-link behavior in this release.

### Key Entities

- **Navigation Destination**: One of the three top-level tabs (Home, History, Settings); has a label, an icon, an active/inactive state, and preserves its own state.
- **Home Section**: A titled block on the Home screen (hero summary, stat tiles, a recent group, quick actions, tip); has a title, optional "see all" affordance, and an empty/placeholder state.
- **Primary Action**: A Home entry point (Send or Receive) that launches a full-screen, nav-less flow.
- **Design Token Set**: The fixed collection of color (light + dark semantic aliases), typography (display + monospace), spacing, radius, shadow, and motion values that all screens consume.
- **Shared Component**: A reusable UI building block (button, file chip/row, code box, segmented tabs, toggle row, stat/quick-action tile, toast, flow app bar) defined once and reused across features.
- **Localized String**: A user-facing text entry with Vietnamese and English values, referenced by key.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can open the app and reach any of the three tabs in a single tap, with Home shown first on 100% of launches.
- **SC-002**: From Home, a user can open the Send flow and the Receive flow and return to Home — both round-trips completing without dead-ends or crashes.
- **SC-003**: 100% of shell screens render correctly in both light and dark mode with no hardcoded colors and no contrast failures on text.
- **SC-004**: 100% of user-facing strings in this release display correctly in both Vietnamese and English, with zero untranslated keys visible in either language.
- **SC-005**: With Reduce Motion enabled, 100% of decorative animations in the shell present in a static state.
- **SC-006**: The Home layout and all shell screens display without overflow or clipped controls on the smallest and largest supported phone sizes, and content stays within the safe area on notch/Dynamic Island and cutout devices.
- **SC-007**: Every reusable component listed in FR-017 is built once as a shared component and is either **used by at least one shell screen** or **built as a reserved shared component available for reuse by later features** (e.g. CodeBox / SegmentedTabs / DangerButton, first used in #003/#004/#005). No reusable component is duplicated per screen.
- **SC-008**: The app builds and launches successfully in both the development and production configurations on iOS and Android.
- **SC-009**: Switching tabs preserves each tab's scroll/state in 100% of attempts (no reset on return).

## Assumptions

- **Default language fallback**: When the device language is neither Vietnamese nor English, the app falls back to **Vietnamese** (the primary product language). This can be revisited in the Settings feature (#010) where an explicit language picker is added.
- **Placeholder data**: Home "recent" sections, statistic tiles, and the hero summary show non-functional **static sample/mock content matching the design mockup** in this release; real values are wired by the History feature (#006).
- **Settings toggles are visual-only**: Any controls shown on the Settings destination are static UI; their real behavior (auto-receive, save-to-library, notifications, theme mode) is delivered by the Settings feature (#010).
- **Search is non-functional**: The Home search field is presentational in this release; real search is out of scope for the foundation.
- **No persistence**: No local database/history storage is introduced here; persistence arrives with the History feature (#006).
- **No networking**: No signaling, WebRTC, discovery, or transfer logic is introduced here; these arrive in features #002/#003 and later.
- **Brand assets available**: The Safe Send logomark and wordmark are available from the prepared design project and can be bundled.
- **Design source of truth**: Screen layouts, tokens, components, and the navigation information architecture follow the prepared Safe Send design (the project's UI design context); where the source token file and the rendered screens disagree (e.g. corner radii), the rendered screens govern.
- **Supported devices**: Minimum baseline is iOS 13.0 and Android 8.0 (API 26); modern iOS and Android phones are the target. Tablets are expected to adapt responsively but are not separately optimized in this release.

## Out of Scope (this feature)

- Any real file transfer, WebRTC, signaling, or device discovery.
- Real file selection, sending, or receiving.
- Real pairing methods (6-digit code, QR, nearby radar, share link) — only placeholder entry points exist.
- Local persistence / transfer history storage.
- Functional Settings (real toggles, language picker, device profile) — delivered in #010.
- Real Home "recent" data and summary statistics — delivered in #006.
- Functional search.

## Dependencies

- The prepared Safe Send design (UI design context: screens, design tokens, shared components, navigation IA) and the project constitution (design-system, cross-platform, navigation, modularity, and i18n principles).
- Safe Send brand assets (logomark, wordmark).
