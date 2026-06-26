# Feature Specification: Settings & Preferences (Cài đặt)

**Feature Branch**: `010-settings`
**Created**: 2026-06-26
**Status**: Draft
**Input**: User description: "Settings & Preferences (Cài đặt) — Spec #010. Build out the Settings tab (Screen 08), currently a placeholder from #001. Device profile (editable name + avatar shown to peers), preference toggles (auto-receive / save-to-library / notifications / dark theme), default download location, signaling endpoint override + diagnostics, auto-accept rules, About section (version, privacy, how-it-works, rate app), language picker EN/VI/system. Persist locally; expose a settings repository other features read from."

## Overview

Safe Send's bottom navigation has three tabs — Trang chủ (Home), Lịch sử (History), and **Cài đặt (Settings)**. Home and History are functional; Settings has been a styled placeholder since #001. This feature turns Settings into the app's preferences surface: the one place a user controls their identity to peers, how received files are handled, the app's appearance and language, advanced connection configuration, and where to learn what the app is and how it protects their data.

Preferences set here are **durable** (survive app restarts) and **read by the rest of the app** — the receive flow honors the auto-receive and save-to-library choices, the whole app honors the theme and language choices, and the signaling layer honors the endpoint override. This is the first feature to give the user a persistent voice across the product.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Personalize how I appear to other devices (Priority: P1)

A user opens the Settings tab and sees a profile card showing the name other devices see when pairing (radar, receive prompt). Until now that name was an auto-generated default. The user taps edit, changes it to something recognizable (e.g. "Minh's iPhone"), and saves. From then on, every peer that discovers or receives from this device sees the new name, and the name persists across app restarts.

**Why this priority**: The device name is the single most visible, most-requested piece of personalization, and it directly improves every other connection method already shipped (#003/#007/#008/#009 all show a peer label). It is independently valuable even if nothing else in this feature shipped.

**Independent Test**: Open Settings, edit the device name, restart the app, confirm the new name persists and appears in a nearby/receive peer label.

**Acceptance Scenarios**:

1. **Given** a fresh install with a generated default name, **When** the user opens Settings, **Then** the profile card shows that default name and a note that it is "hiển thị với thiết bị gần đây" (shown to nearby devices).
2. **Given** the profile card, **When** the user edits the name to a valid non-empty value and confirms, **Then** the new name is saved, the card updates immediately, and the change survives an app restart.
3. **Given** the user clears the name field entirely (or enters only whitespace), **When** they try to save, **Then** the app rejects the empty value and keeps the previous name (a device always has a name).
4. **Given** a saved custom name, **When** a peer pairs via any method, **Then** the peer-facing label reflects the custom name rather than the generated default.

---

### User Story 2 - Control how incoming files are handled (Priority: P1)

A user wants received files to land where they expect and to be told when they arrive, without re-deciding every transfer. In Settings they find a group of toggles — **Tự động nhận** (auto-receive), **Lưu vào Thư viện** (save received images/videos to the photo library), and **Thông báo** (notify on a new incoming file). They flip the ones they want; the choices persist and the receive flow honors them on the next transfer.

**Why this priority**: These toggles are the functional core of the Settings screen in the design (Screen 08) and the only ones that change runtime behavior of the already-shipped receive flow. They are what makes Settings more than cosmetic.

**Independent Test**: Toggle each preference, restart the app, confirm each persisted; then run a receive and confirm the behavior matches the toggle state (e.g. auto-receive on → no accept prompt; save-to-library on → image appears in the library).

**Acceptance Scenarios**:

1. **Given** the toggle group, **When** the user flips any toggle, **Then** the new state is saved immediately and is still set after an app restart.
2. **Given** **Tự động nhận** is ON, **When** an incoming transfer arrives, **Then** the transfer is accepted without showing the manual accept/reject prompt. *(Scope of "trusted" is resolved in Clarifications.)*
3. **Given** **Tự động nhận** is OFF (default), **When** an incoming transfer arrives, **Then** the existing manual accept/reject prompt is shown unchanged.
4. **Given** **Lưu vào Thư viện** is ON and a received item is an image or video, **When** the transfer completes, **Then** that item is also placed in the device photo library (in addition to the app's existing save behavior).
5. **Given** a toggle requires an OS permission the user has not granted (photo library, notifications), **When** the user turns it ON, **Then** the app requests the permission and, if denied, reflects that the toggle cannot take effect and offers a path to system settings — it never silently appears ON while doing nothing.

---

### User Story 3 - Set the app's appearance and language (Priority: P2)

A user prefers a dark interface and English copy. In Settings they choose a theme — **Sáng / Tối / Theo hệ thống** (light / dark / follow-system) — and a language — **Tiếng Việt / English / Theo hệ thống**. The whole app updates immediately and remembers the choice next launch.

**Why this priority**: Appearance and language are high-visibility, universally expected preferences, but unlike US1/US2 they don't gate file transfers, so they sit just below the core. The palette is fixed (no color-scheme picker) — only the light/dark *mode* and language change.

**Independent Test**: Switch theme to Tối and language to English, confirm the app re-renders dark + English everywhere, restart, confirm both persisted.

**Acceptance Scenarios**:

1. **Given** the theme selector, **When** the user picks Tối, **Then** every screen renders in the dark palette immediately and after restart.
2. **Given** the theme is set to "Theo hệ thống", **When** the OS switches between light and dark, **Then** the app follows without further input.
3. **Given** the language selector, **When** the user picks English, **Then** all in-app copy switches to English immediately and after restart; picking "Theo hệ thống" follows the OS locale (falling back to Vietnamese for unsupported locales).

---

### User Story 4 - Advanced: point the app at a self-hosted signaling server (Priority: P3)

A privacy-minded or self-hosting user wants Safe Send to use their own signaling relay instead of the bundled default. In an "Advanced" area of Settings they enter a custom signaling endpoint and can run a quick connection diagnostic to confirm it is reachable. The override applies to subsequent pairings; clearing it restores the per-flavor default.

**Why this priority**: A power-user feature with a small audience; valuable for the product's "no-server-holds-data / self-hostable" story but not needed by most users, so it is lower priority and clearly cordoned off as advanced.

**Independent Test**: Enter a custom endpoint, run the diagnostic, confirm reachable/unreachable feedback; start a pairing and confirm it uses the override; clear it and confirm the default returns.

**Acceptance Scenarios**:

1. **Given** the advanced section, **When** the user enters a syntactically valid endpoint and saves, **Then** it persists and is used by the next pairing attempt.
2. **Given** a saved endpoint, **When** the user runs the diagnostic, **Then** the app reports reachable or unreachable with a clear, non-technical result.
3. **Given** the user enters a malformed endpoint, **When** they try to save, **Then** the app rejects it with guidance and keeps the prior value.
4. **Given** a custom endpoint is set, **When** the user clears it, **Then** the app reverts to the built-in per-flavor default.

---

### User Story 5 - Understand and trust the app (About) (Priority: P3)

A user wants to confirm what version they run, read how the app keeps their files private (the "no server holds your data" explainer), view the privacy policy, and rate the app. Settings ends with an About area exposing the app version (e.g. "Safe Send v1.0.0 · WebRTC P2P"), a how-it-works explainer, a privacy policy link, and a "rate this app" action.

**Why this priority**: Trust-building and store-compliance content; important for launch but does not change app behavior, so it is grouped with the other lower-priority items.

**Independent Test**: Open the About area, confirm the displayed version matches the build, open the how-it-works and privacy entries, trigger the rate-app action.

**Acceptance Scenarios**:

1. **Given** the About area, **When** the user views it, **Then** the displayed version matches the installed build and the tagline reads "Safe Send v1.0.0 · WebRTC P2P".
2. **Given** the how-it-works entry, **When** the user opens it, **Then** they see the plain-language explanation that file bytes travel device-to-device and no intermediary server holds them.
3. **Given** the rate-app action, **When** the user triggers it, **Then** the OS's native rate/review experience is presented.

---

### Edge Cases

- **First launch / no saved preferences**: every preference shows a documented default (auto-receive OFF, save-to-library OFF, notifications OFF, theme = follow-system, language = follow-system, signaling endpoint = flavor default, device name = generated default).
- **Permission denied then re-enabled**: if the user denies photo-library or notification permission, the corresponding toggle must not appear active; if they later grant it via system settings, turning the toggle ON works.
- **Auto-receive while a transfer is already in progress**: auto-receive must not hijack or interrupt an in-flight transfer; latest-wins / existing in-transfer protections (#008 FR-014) still apply.
- **Theme/language changed mid-flow**: changing appearance or language while a send/receive flow is open must not crash or lose the in-flight transfer.
- **Invalid signaling override that is unreachable at pairing time**: a saved-but-unreachable endpoint surfaces the existing signaling-unreachable failure (#003), not a silent hang.
- **Device name with emoji / very long string**: the name field accepts unicode/emoji up to 30 characters; over-length input is rejected with feedback and the prior name is kept.
- **Save-to-library for a received file type that is not media**: non-image/video files are unaffected by the save-to-library toggle (they keep the existing app-sandbox + share behavior).

## Requirements *(mandatory)*

### Functional Requirements

**Device profile**
- **FR-001**: The Settings tab MUST display a device-profile card showing the current device name, a letter/initial avatar, and a note that the name is shown to nearby/receiving devices.
- **FR-002**: Users MUST be able to edit the device name, subject to validation: the saved value is trimmed of leading/trailing whitespace, MUST be non-empty after trimming, and MUST be at most **30 characters** (unicode/emoji permitted). The app MUST reject empty/whitespace-only or over-length input and preserve the previous name.
- **FR-003**: The saved device name MUST persist across app restarts and MUST be the value surfaced as this device's peer label in all connection methods (replacing the generated default from #009).
- **FR-004**: On first run with no saved name, the app MUST present a generated default name (the same default behavior shipped in #009).

**Preference toggles**
- **FR-005**: Settings MUST present persistent toggles for **Tự động nhận** (auto-receive), **Lưu vào Thư viện** (save received media to the photo library), and **Thông báo** (notify on incoming file), each defaulting to OFF.
- **FR-006**: Each toggle's state MUST be saved immediately on change and persist across restarts.
- **FR-007**: When **Tự động nhận** is ON, the receive flow MUST auto-accept an incoming transfer **only while the app is in the foreground and the user is on the receive screen** — skipping the manual accept tap — and MUST fall back to the existing manual accept/reject prompt when the app is backgrounded, not on the receive screen, or the toggle is OFF. Auto-accept MUST NOT apply to a transfer that arrives while another transfer is already in progress. (No true unattended/background receive in this release — that awaits the saved-peer registry in v1.1.)
- **FR-008**: When **Lưu vào Thư viện** is ON, completed received items that are images or videos MUST additionally be saved to the device photo library; non-media files are unaffected. This is fully functional in this release (requires photo-library permission per FR-010).
- **FR-009**: When **Thông báo** is ON, the user MUST receive a local on-device notification when a new incoming file transfer arrives. Tapping the notification MUST route into the receive screen for that transfer (the accept/reject prompt or in-progress view, reusing the existing deep-link routing from #008). This is fully functional in this release (requires notification permission per FR-010).
- **FR-010**: Any toggle that depends on an OS permission MUST request that permission when enabled, and if the permission is denied MUST NOT present itself as active — it must reflect the blocked state and offer a route to system settings.

**Appearance & language**
- **FR-011**: Settings MUST let the user choose theme mode among light, dark, and follow-system; the choice MUST apply app-wide immediately and persist. The fixed palette is unchanged (no color-scheme picker).
- **FR-012**: Settings MUST let the user choose language among Vietnamese, English, and follow-system; the choice MUST apply app-wide immediately and persist, with Vietnamese as the fallback for unsupported system locales.

**Advanced: signaling & diagnostics**
- **FR-013**: Settings MUST provide an advanced area to override the signaling endpoint with a user-supplied value; a valid override MUST persist and be used by subsequent pairings, and clearing it MUST restore the per-flavor default.
- **FR-014**: The app MUST validate a supplied endpoint before saving and reject malformed values without losing the prior value. Accepted schemes: `wss://` MUST be accepted in any flavor; `ws://` (plaintext) MUST be accepted only in the **dev** flavor and rejected in **prod** (preserving the "no plaintext signaling in production" guarantee from #003). Any other scheme or malformed URL is rejected with guidance.
- **FR-015**: Settings MUST offer a connection diagnostic that reports, in plain language, whether the active signaling endpoint is reachable.

**About**
- **FR-016**: Settings MUST display the installed app version and the "Safe Send v1.0.0 · WebRTC P2P" tagline, with the version read from the actual build.
- **FR-017**: Settings MUST provide a plain-language "how it works" explainer conveying that file bytes travel device-to-device with no intermediary server holding them, plus a privacy-policy entry. Both the explainer and the privacy policy are **in-app localized screens** (self-contained, no external/hosted URL required in this release; a hosted URL may replace the in-app policy at #011 release prep).
- **FR-018**: Settings MUST provide a "rate this app" action that invokes the platform's native review experience.

**Persistence & cross-feature contract**
- **FR-019**: All preferences MUST be stored locally on the device only (no account, no cloud sync).
- **FR-020**: Preferences MUST be exposed through a single settings contract that other features (receive flow, theme, language, signaling layer) read from, so behavior stays consistent and there is one source of truth per preference.
- **FR-021**: Every preference MUST have a documented default that applies when nothing has been saved yet (see Edge Cases).
- **FR-022**: This release MUST NOT add a download-location folder chooser. Received files keep the existing #005 save model (app sandbox + share sheet), with the optional photo-library copy from FR-008 layered on top for media. (A folder chooser is awkward under the mobile sandbox model and is deferred.)
- **FR-023**: All Settings copy MUST be provided via the app's localization (Vietnamese primary, English secondary), consistent with existing conventions.

### Key Entities

- **Device Profile**: the user-visible identity of this device to peers — primarily a display name (with a derived initial avatar). Replaces the generated default introduced in #009.
- **User Preferences**: the durable set of choices — auto-receive, save-to-library, notifications, theme mode, language, signaling-endpoint override (and download-location behavior pending Q3). Each has a type, a default, and at most one consumer-facing effect.
- **App/Build Info**: read-only facts about the running build (version, tagline) surfaced in About.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can change their device name and see it reflected as their peer label in another device's pairing UI within one transfer, and the name survives an app restart 100% of the time.
- **SC-002**: Every preference set in Settings is still in effect after fully closing and reopening the app (0% preference loss across restarts).
- **SC-003**: Turning on **Tự động nhận** removes the manual accept step on the next incoming transfer; turning it off restores the prompt — both verifiable in a single two-device test.
- **SC-004**: Switching theme or language updates every visible screen without requiring an app restart.
- **SC-005**: No toggle that depends on a denied OS permission ever displays as active while having no effect (0 "silently broken toggle" states).
- **SC-006**: A user can find the app version and the "how it works / privacy" explanation from the Settings tab in under 15 seconds.
- **SC-007**: A custom signaling endpoint, once saved, is used by the next pairing attempt, and clearing it restores the default — verifiable via the built-in diagnostic.

## Assumptions

- **Avatar is a generated letter/initial avatar** (per Screen 08 design "avatar gradient chữ-cái"); uploading a custom photo avatar is out of scope for this feature.
- **No trusted-peer registry exists yet** (saved/favorite peers are a post-v1.0 item per the roadmap), so any "trusted device" semantics for auto-receive must be interpreted within that constraint (see Q1).
- **The fixed light/dark palette from #001 is reused** — this feature controls only theme *mode* and language, never colors.
- **Local persistence only** — preferences live on-device; there is no account system or cloud sync (explicitly out of scope).
- **The signaling override and diagnostic build on the existing per-flavor endpoint config and failure types from #003**; no new signaling protocol is introduced.
- **The receive flow's existing save model (#005: app sandbox + share sheet) remains the baseline**; save-to-library is additive on top of it for media types.
- **Notifications are local (on-device) notifications** tied to an incoming transfer — there is no push-notification / server component. Both save-to-library and notifications are fully implemented this release (Q2).
- **Existing design tokens, shared widgets (ToggleRow, etc.), AppToast, AppLogger, AppRoutes, and ARB VI-primary conventions are reused**; no new design system work.

## Out of Scope

- User accounts, sign-in, or any cloud sync/backup of settings.
- Saved/favorite/trusted-peer management UI (post-v1.0).
- Custom photo avatars.
- Color-scheme / theming beyond the fixed light/dark palette.
- Push notifications or any server-side notification delivery.

## Clarifications

### Session 2026-06-26

- **Q1 — Auto-receive ("Tự động nhận") semantics** → **Foreground skip-tap.** Auto-accept applies only while the app is foregrounded on the receive screen (skip the manual tap); no true unattended/background receive in this release (awaits the v1.1 saved-peer registry). Encoded in FR-007.
- **Q2 — Functional depth of "Lưu vào Thư viện" and "Thông báo"** → **Implement both fully now.** Save-to-library (photo-library save + permission) and local notifications (notification permission) are both fully functional this release, not deferred. Encoded in FR-008, FR-009, FR-010.
- **Q3 — Default download location** → **No folder chooser.** Drop the download-location chooser; rely on the existing #005 app-sandbox + share-sheet model (plus the optional photo-library copy). Encoded in FR-022.
- Q: Which schemes may a custom signaling-endpoint override use? → A: `wss://` in any flavor; `ws://` only in the dev flavor (prod requires `wss://`). Encoded in FR-014.
- Q: Device-name validation bounds? → A: Max 30 characters, unicode/emoji allowed, trimmed, non-empty. Encoded in FR-002.
- Q: What does tapping the incoming-file notification do? → A: Opens the receive screen for that transfer (reusing #008 deep-link routing). Encoded in FR-009.
- Q: Is the privacy policy an in-app screen or a hosted URL? → A: In-app localized screen, no external URL this release. Encoded in FR-017.
