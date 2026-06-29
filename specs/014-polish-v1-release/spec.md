# Feature Specification: Polish & v1.0 Release

**Feature Branch**: `014-polish-v1-release`  
**Created**: 2026-06-29  
**Status**: Draft  
**Input**: User description: "Spec #014 — Polish & v1.0 Release. The final spec of Safe Send v1.0: no new user-facing feature, but the hardening + release-readiness sweep that takes the app from 'all features merged' (#001–#013) to a shippable v1.0. Deliver as prioritized, independently-testable user stories: (P1) Resilient transfers with a real TURN fallback + clear failure/retry surfacing; (P1) Security & privacy verification pass; (P2) Accessibility; (P2) UX polish & performance; (P3) Two-device device-validation backlog; (P3) Release-readiness (build & store prep, NOT submission). Quality gate: analyze 0, no dead code, no unused deps, tests green, VI-primary + EN ARB, design tokens only, Constitution-compliant."

## Clarifications

### Session 2026-06-29 (pre-spec, confirmed with user)

- Q: NAT-traversal failure — STUN-only with a documented hook, or a real relay? → A: v1.0 stands up a **real TURN server** and wires an encrypted-relay fallback. TURN relays only DTLS-encrypted bytes and never persists them, so "no intermediary server holds the data" still holds (and is re-stated wherever TURN appears). Endpoint/credentials are configurable per flavor; the deployment choice (self-host coturn vs managed provider) is a plan-time detail.
- Q: Does #014 submit to the App Store / Play? → A: **No.** #014 makes the app release-READY (obfuscation, signing, staged listing assets, prod build runs on a device) but does NOT push the actual submission — the user submits with their own developer accounts.
- Q: How much of the deferred on-device backlog does #014 cover? → A: **All of it** — every deferred two-device smoke, first `pod install`, and signing-Team item accumulated across #002–#013 is run on two real devices before v1.0 is called done.

### Session 2026-06-29 (clarify)

- Q: TURN relay — which flavors use a real relay? → A: **Both dev + prod** use a real TURN with **separate per-flavor credentials** (so the relay fallback is device-testable on dev, matching the per-flavor endpoint pattern from #003/#010).
- Q: Is the relayed connection shown to the user, or fully transparent? → A: **Subtle indicator** on the progress screen when the relay is in use (e.g. a small "relayed · encrypted" badge), localized + accessibility-labeled — transparency without alarm.
- Q: What largest single-file size must the bounded-memory performance test validate against? → A: **≥4 GB single file** — crossing the 4 GB / 32-bit-offset boundary is the meaningful stress point for streamed I/O (proves no whole-file-in-memory and no integer-offset overflow).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A transfer succeeds even when direct P2P fails (Priority: P1)

Two users on networks that block a direct peer-to-peer connection (symmetric NAT, carrier-grade NAT, restrictive corporate/public Wi-Fi) pair and start a transfer. Instead of stalling forever or failing with a cryptic error, the connection automatically falls back to relaying the **encrypted** stream through a TURN server, and the files transfer to completion. If a transfer is disrupted mid-flight — the connection drops, the peer disconnects, the app is backgrounded past the OS limit, or signaling is lost — the user sees a clear, localized state explaining what happened with a way to retry, never a silent hang.

**Why this priority**: Direct WebRTC fails on a meaningful fraction of real-world networks; without a relay fallback those users simply cannot transfer at all. This is the single biggest reliability gap between the current MVP and a shippable product, and it underpins the app's core promise that "any two devices can send files."

**Independent Test**: On a network configuration that defeats direct connection (e.g. two devices behind restrictive NATs / different networks), pair and send files; confirm the transfer completes via relay. Separately, force each disruption (kill Wi-Fi mid-transfer, background the app, drop the peer) and confirm a clear failure state + retry path appears every time, with no hang and no orphaned/incomplete files presented as complete.

**Acceptance Scenarios**:

1. **Given** two peers whose networks prevent a direct connection, **When** they start a transfer, **Then** the connection establishes via the TURN relay and the files transfer to completion with normal progress.
2. **Given** a relayed (or direct) transfer in progress, **When** the connection drops or the peer disconnects, **Then** a clear localized failure state is shown with a retry action, already-verified files are retained as a partial result, and nothing incomplete is reported as complete.
3. **Given** a transfer that cannot establish any path (direct and relay both fail), **When** the attempt times out, **Then** the user sees a distinct, actionable "couldn't connect" message rather than an indefinite spinner.
4. **Given** signaling is briefly lost during pairing/negotiation, **When** the loss is transient, **Then** the system recovers or surfaces a clear retryable error rather than failing silently.
5. **Given** the relay path is in use, **When** files transfer, **Then** the bytes on the relay remain end-to-end encrypted and are never persisted by the relay (privacy promise preserved).
6. **Given** a transfer using the relay path, **When** the user views the progress screen, **Then** a subtle localized "relayed · encrypted" indicator is shown (and announced by a screen reader), whereas a direct transfer shows no such indicator.

---

### User Story 2 - The privacy promise is verified, not assumed (Priority: P1)

A privacy-conscious user (and a store reviewer) needs assurance that Safe Send's central claim — no intermediary server holds the data — actually holds in the shipped build, including with TURN now in the path. The app and its servers are audited so that: the signaling relay carries connection metadata only; the direct/relayed channel is end-to-end encrypted; the TURN relay only forwards encrypted bytes and persists nothing; and no file bytes, file paths, peer identifiers, pairing codes, device names, or endpoints ever appear in logs. The "how it works / privacy" explainer in the app accurately reflects the TURN addition.

**Why this priority**: TURN widens the surface where bytes leave the device, so the trust foundation of the product must be re-audited rather than presumed. A privacy regression here would undermine the entire value proposition and is the kind of issue that must be caught before release, not after.

**Independent Test**: Inspect signaling traffic and confirm it carries no file bytes; confirm the data channel is encrypted; run a relayed transfer and confirm the relay neither decrypts nor persists payloads; grep all app + server logs across a full transfer (success, failure, cancel, relay) and confirm zero sensitive values; read the in-app privacy explainer and confirm it correctly describes STUN/TURN behavior.

**Acceptance Scenarios**:

1. **Given** any pairing method and a full transfer lifecycle (success, failure, cancel, relay-fallback), **When** all app and server logs are inspected, **Then** no file bytes, paths, peer identifiers, pairing codes, device names, or signaling endpoints appear in them.
2. **Given** a transfer over the relay, **When** the relayed traffic is inspected, **Then** payloads are encrypted end-to-end and the relay stores nothing after the session ends.
3. **Given** the signaling relay during pairing and negotiation, **When** its traffic is inspected, **Then** it carries only connection-setup metadata and never file content.
4. **Given** the in-app "how it works / privacy" content, **When** a user reads it, **Then** it accurately states that signaling carries metadata only and TURN relays encrypted bytes without persistence.

---

### User Story 3 - The app is usable with assistive technology (Priority: P2)

A user who relies on a screen reader (VoiceOver on iOS, TalkBack on Android), large text, or reduced motion can complete every core task — pair, send, receive, view history, change settings, open a received file — without barriers. Controls are announced meaningfully, the pairing code and progress are readable aloud, layouts hold up at large text sizes, and motion-heavy elements (the radar, progress animations) honor the Reduced Motion setting.

**Why this priority**: Accessibility is a baseline release requirement and an explicit store-review gate, not an optional enhancement. A core flow that is unusable with a screen reader can block release outright.

**Independent Test**: With VoiceOver/TalkBack enabled, traverse each screen and complete the send and receive flows end to end; confirm every interactive control is announced with a meaningful label and the pairing code, progress, and file lists are conveyed. Set the largest Dynamic Type / font scale and confirm no critical content is clipped or unreachable. Enable Reduced Motion and confirm the radar and progress animations are reduced or stilled.

**Acceptance Scenarios**:

1. **Given** a screen reader is active, **When** the user navigates any screen, **Then** every interactive element (buttons, toggles, code fields, player controls, file rows) is announced with a clear, localized label and role.
2. **Given** a screen reader is active during pairing and transfer, **When** the user listens, **Then** the pairing code, connection state, and transfer progress are conveyed without relying on color or animation alone.
3. **Given** the system font scale is set to its largest setting, **When** the user opens each screen, **Then** primary content and actions remain visible and operable without clipping or overlap.
4. **Given** Reduced Motion is enabled, **When** the user reaches the radar or a transfer-progress screen, **Then** the animation is reduced or replaced with a static equivalent.

---

### User Story 4 - The app feels finished and handles large transfers (Priority: P2)

A user transferring large or numerous files (a multi-gigabyte video, a batch of hundreds of files) experiences a responsive app that doesn't run out of memory or freeze, and gets tactile/visual confirmation at the moments that matter — a haptic tap on connect, on completion, and on failure. Every screen looks correct in both light and dark mode, with nothing mis-colored or low-contrast.

**Why this priority**: These are the felt-quality differences between an MVP and a shippable app. The streamed-memory guarantee in particular must be proven on real large files, since exceeding the memory ceiling would crash exactly the transfers users care most about.

**Independent Test**: Transfer a multi-GB single file and a many-file batch on real devices; confirm the app stays responsive, completes the transfer, and peak memory stays bounded (does not scale with file size). Trigger connect, complete, and fail and confirm distinct haptic feedback. Toggle dark mode and walk every screen confirming correct tokens/contrast. Measure cold start.

**Acceptance Scenarios**:

1. **Given** a single file of at least 4 GB (crossing the 4 GB / 32-bit-offset boundary), **When** it is sent and received, **Then** the transfer completes, the UI stays responsive, and peak memory stays within a bounded ceiling that does not grow with file size.
2. **Given** a batch of many files, **When** it is transferred, **Then** all files complete (or fail cleanly with a partial result) without exhausting memory or freezing the UI.
3. **Given** a transfer reaches connect, completion, or failure, **When** each moment occurs, **Then** the user receives appropriate haptic feedback for that event.
4. **Given** dark mode is enabled, **When** the user views every screen, **Then** all colors come from the design tokens with no hardcoded/mis-tokened values and adequate contrast.
5. **Given** a cold launch, **When** the user opens the app, **Then** it reaches an interactive home screen within an acceptable cold-start time.

---

### User Story 5 - The whole app is validated on real hardware (Priority: P3)

Before v1.0 is declared done, every transfer path is exercised on two physical devices — not just in CI loopback tests. The full pair → send → receive → save loop is run across all four connection methods (6-digit code, QR, share link, nearby radar), plus background transfer and the in-app viewers, clearing the backlog of deferred two-device smokes, first `pod install`s, and signing-Team setup accumulated across specs #002–#013.

**Why this priority**: This app's core value is a two-device transfer, and loopback CI cannot validate real NAT traversal, real throughput, native pods, or platform background behavior. Shipping with an untested device backlog risks discovering basic breakage in the field. It is P3 because it gates the release rather than producing new functionality, and depends on the P1/P2 work being in place to test.

**Independent Test**: On two real devices (iOS and Android), run the documented smoke matrix: each of the four connection methods through a complete transfer and save; a backgrounded transfer on each platform; and opening received files in each in-app viewer. Record pass/fail per cell; every core cell must pass.

**Acceptance Scenarios**:

1. **Given** two physical devices, **When** the full pair → send → receive → save loop is run via each of the four connection methods, **Then** every method completes a transfer successfully and the files are saved/openable.
2. **Given** an in-progress transfer, **When** the app is backgrounded on each platform, **Then** the documented background behavior holds (Android sustains to completion; iOS displays + grace, then clean fallback).
3. **Given** received files of each supported type, **When** they are opened on device, **Then** the in-app viewers render them correctly.
4. **Given** the iOS project, **When** `pod install` is run and the app is built with a signing Team, **Then** the prod build installs and runs on a real device.

---

### User Story 6 - The app is ready to submit to the stores (Priority: P3)

A maintainer has everything needed to publish: a production build that is obfuscated and signed, valid provisioning, and a complete set of staged store-listing assets — metadata, screenshots, privacy policy, and the answers for Apple's privacy-nutrition and Google's data-safety forms — accurately reflecting the app's actual data behavior (no data collected/held by a server). The prod build runs on a real device. The actual store submission is intentionally left to the maintainer's own developer accounts.

**Why this priority**: This is the last mile to shipping, but it depends on all prior stories being complete (you cannot finalize listing/privacy answers until behavior is final) and it produces release artifacts rather than user-facing functionality, so it is P3.

**Independent Test**: Produce a release build for both platforms with obfuscation + signing and confirm it installs and runs on a real device. Review the staged listing package (metadata, screenshots, privacy policy, data-safety/privacy-nutrition answers) for completeness and accuracy against the app's real behavior. Confirm no submission is actually pushed.

**Acceptance Scenarios**:

1. **Given** the production configuration, **When** a release build is produced for each platform, **Then** it is code-obfuscated, correctly signed/provisioned, and installs and runs on a real device.
2. **Given** the staged store assets, **When** they are reviewed, **Then** metadata, screenshots, a privacy policy, and the data-safety / privacy-nutrition answers are present, complete, and accurately describe the app's data behavior.
3. **Given** the release-readiness work, **When** it is complete, **Then** no actual store submission has been pushed (the maintainer submits separately).

---

### Edge Cases

- **Relay unavailable / misconfigured**: if the TURN server is unreachable or credentials are invalid, direct transfers must still work and the user must get a clear "couldn't connect" message when both paths fail — never a silent hang.
- **Relay credentials expire mid-session**: an in-flight relayed transfer must fail cleanly (partial retained) rather than corrupt or hang.
- **Disruption during the relay path specifically**: dropped relay connection is surfaced and retryable like any other mid-transfer failure.
- **Reduced Motion + screen reader together**: both settings honored simultaneously without conflict.
- **Largest font scale on dense screens** (Connect code grid, progress, history rows): content reflows or scrolls rather than clipping.
- **Memory pressure on low-end devices** during a multi-GB transfer: streamed I/O keeps peak memory bounded; the OS does not kill the app for memory.
- **Haptics on devices without a taptic engine / with haptics disabled**: feedback degrades gracefully (no crash, no error).
- **Dark/light mode switched mid-session**: every screen updates correctly with no stale or mis-tokened colors.
- **Store privacy form vs reality drift**: the staged answers must match actual behavior even after the TURN addition (encrypted relay, no persistence).

## Requirements *(mandatory)*

### Functional Requirements

**Resilience & TURN fallback (US1)**

- **FR-001**: The system MUST automatically relay the encrypted transfer through a TURN server when a direct peer-to-peer connection cannot be established, so transfers succeed across restrictive NATs/firewalls.
- **FR-002**: The TURN relay MUST forward only end-to-end-encrypted bytes and MUST NOT persist file content; the "no intermediary server holds the data" promise MUST be preserved and re-stated wherever TURN is surfaced to users.
- **FR-003**: TURN endpoint and credentials MUST be configurable per flavor (dev/prod) and MUST NOT be hardcoded secrets in the shipped client in a way that leaks them into logs or version control. Both the dev and prod flavors MUST point at a real (live) TURN relay using separate per-flavor credentials, so the relay fallback path is exercisable on dev device builds.
- **FR-004**: The system MUST prefer a direct connection and use the relay only as a fallback (relay is not the default path when direct is available).
- **FR-004a**: When a transfer is using the relay path, the system MUST show a subtle, non-blocking indicator on the progress screen (e.g. a "relayed · encrypted" badge) that is localized and accessibility-labeled; direct transfers show no such indicator.
- **FR-005**: When a transfer is disrupted mid-flight (connection drop, peer disconnect, app backgrounded past the OS limit, signaling loss), the system MUST surface a clear, localized failure state with a retry path and MUST NOT hang indefinitely.
- **FR-006**: On mid-transfer failure, the system MUST retain already-verified files as a partial result and MUST NOT present an incomplete transfer as complete.
- **FR-007**: When neither a direct nor a relayed path can be established, the system MUST show a distinct, actionable "couldn't connect" state after a bounded timeout rather than an indefinite spinner.
- **FR-008**: If the TURN server is unreachable or misconfigured, direct transfers MUST continue to work unaffected.

**Security & privacy verification (US2)**

- **FR-009**: The signaling relay MUST carry connection-setup metadata only and MUST NOT carry file bytes (verified, not assumed).
- **FR-010**: The transfer channel (direct or relayed) MUST be end-to-end encrypted.
- **FR-011**: No file bytes, file paths, peer identifiers, pairing codes, device names, or signaling/TURN endpoints MUST appear in any app or server log, across all lifecycle outcomes (success, failure, cancel, relay).
- **FR-012**: The in-app "how it works / privacy" explainer MUST accurately describe STUN/TURN behavior, including that the relay only forwards encrypted bytes and persists nothing.
- **FR-013**: The security verification MUST be documented (what was checked and the result) so it can be re-run for future releases.

**Accessibility (US3)**

- **FR-014**: Every interactive element on every screen MUST expose a clear, localized accessibility label and role for VoiceOver/TalkBack.
- **FR-015**: The pairing code, connection state, and transfer progress MUST be conveyed to assistive technology without relying on color or animation alone.
- **FR-016**: All screens MUST remain usable (no clipped or unreachable critical content/actions) at the system's largest standard font scale.
- **FR-017**: Motion-heavy UI (radar, progress animations) MUST honor the OS Reduced Motion setting with a reduced or static equivalent.

**UX polish & performance (US4)**

- **FR-018**: The system MUST provide haptic feedback on connect, completion, and failure, degrading gracefully on devices without haptics or with haptics disabled.
- **FR-019**: Every screen MUST render correctly in both light and dark mode using design tokens only (no hardcoded colors), with adequate contrast.
- **FR-020**: File transfers MUST use streamed I/O such that peak memory stays within a bounded ceiling that does not grow with file size, for both multi-gigabyte single files and many-file batches.
- **FR-021**: The app MUST remain responsive (no UI freeze) during large and many-file transfers.
- **FR-022**: The app MUST reach an interactive home screen within an acceptable cold-start time — target **≤ 3 seconds** on a typical supported device (iOS 13+/Android 8+), confirmed against a measured device baseline.

**Device validation (US5)**

- **FR-023**: The full pair → send → receive → save loop MUST be validated on two physical devices for all four connection methods (6-digit, QR, share link, nearby).
- **FR-024**: Background transfer behavior MUST be validated on two physical devices on both platforms, and the in-app viewers MUST be validated opening received files on device.
- **FR-025**: The iOS `pod install` and a signing-Team build MUST be completed so the prod build installs and runs on a real device, clearing the deferred native backlog from #002–#013.
- **FR-026**: The device-validation results MUST be recorded as a pass/fail smoke matrix.

**Release readiness (US6)**

- **FR-027**: A production release build MUST be code-obfuscated and correctly signed/provisioned for each platform and MUST install and run on a real device.
- **FR-028**: A complete set of store-listing assets MUST be staged: metadata, screenshots, a privacy policy, and the Apple privacy-nutrition + Google data-safety form answers, all accurately reflecting the app's real data behavior.
- **FR-029**: The system MUST NOT push an actual store submission as part of this feature (release-ready, not released).

**Cross-cutting quality gate (whole feature)**

- **FR-030**: Static analysis MUST report zero issues, with no dead code and no unused dependencies.
- **FR-031**: All existing automated tests MUST pass, plus new tests covering the resilience/relay-fallback decision logic and the failure-surfacing/retry behavior.
- **FR-032**: All user-facing copy added or changed MUST be provided via localization (Vietnamese primary + English).

### Key Entities *(include if data involved)*

- **TURN configuration**: the per-flavor relay settings the client uses when direct connection fails — endpoint(s) and credentials. Not persisted as user data; treated as configuration, never logged. The deployment target (self-host vs managed) and credential model (e.g. static vs time-limited) are plan-time details.
- **Transfer failure state**: a localized, user-facing classification of why a transfer could not start or complete (couldn't-connect, connection-lost, peer-disconnected, signaling-lost, relay-unavailable), each mapped to clear copy and a retry affordance. Extends the existing failure model; no new persisted entity.
- **Device-validation smoke matrix**: a recorded checklist of connection-method × platform × scenario cells with pass/fail outcomes, produced during US5. A release artifact, not in-app data.
- **Store-listing package**: the staged set of metadata, screenshots, privacy policy, and privacy/data-safety answers. A release artifact, not in-app data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a network that defeats direct connection, a transfer completes successfully via the relay in 100% of attempts where at least one peer can reach the TURN server.
- **SC-002**: 100% of mid-transfer disruptions (connection drop, peer disconnect, background-past-limit, signaling loss) result in a clear failure state with a retry path within a bounded time — zero indefinite hangs.
- **SC-003**: A full grep of all app and server logs across every transfer lifecycle outcome finds zero occurrences of file bytes, paths, peer identifiers, pairing codes, device names, or endpoints.
- **SC-004**: Relayed transfers are verifiably encrypted end-to-end and the relay retains nothing after the session — confirmed by inspection.
- **SC-005**: Every core flow (pair, send, receive, history, settings, view file) is completable end to end with a screen reader active, and all interactive controls are announced.
- **SC-006**: Every screen remains usable with no clipped critical content at the largest standard font scale, and motion-heavy screens honor Reduced Motion.
- **SC-007**: A single file of at least 4 GB and a many-file batch each transfer to completion on real devices with peak memory bounded (not scaling with file size) and no UI freeze.
- **SC-008**: Distinct haptic feedback fires on connect, complete, and fail; every screen is correct in both light and dark mode.
- **SC-009**: The two-device smoke matrix shows a pass for every core cell (four connection methods × the pair→send→receive→save loop, plus background transfer and viewers) on real hardware.
- **SC-010**: A signed, obfuscated production build installs and runs on a real device for both platforms.
- **SC-011**: The staged store-listing package is complete and its privacy/data-safety answers match the app's real behavior, with no actual submission pushed.
- **SC-012**: Static analysis reports zero issues; the full automated test suite passes including the new resilience/failure-path tests.

## Assumptions

- **TURN deployment + credential model are plan-time details**: v1.0 commits to a real TURN relay, but whether it is self-hosted coturn or a managed provider, and whether credentials are static or time-limited, is decided at `/speckit.plan` (Constitution XV for any new package/native change). The relay is configurable per flavor.
- **TURN bandwidth cost is accepted for v1.0 without an in-app usage cap**: relay is used only as a fallback (most transfers stay direct), and no per-user relay quota is introduced in v1.0; the operational cost consideration is documented for the maintainer.
- **Acceptable cold-start time** is taken as a reasonable mobile default (interactive home within a few seconds on a typical supported device, iOS 13+/Android 8+); the exact target is confirmed at plan against measured baselines.
- **"Bounded memory ceiling"** means peak memory does not scale with file size (streamed I/O already mandated since #002); the validation target is a single file of **≥4 GB** (crossing the 4 GB / 32-bit-offset boundary), and the concrete ceiling/throughput numbers are confirmed against measured device baselines at plan/implementation.
- **Largest font scale** refers to the platform's standard accessibility text-size range (not unbounded custom scaling).
- **Additive over the existing engine where possible**: TURN integration extends the existing ICE configuration and failure-handling rather than redesigning the transfer engine, signaling protocol, or DB schema; new resilience copy is added via ARB.
- **Store assets are staged, not submitted**: screenshots/metadata/privacy answers are prepared in the repo or a documented location; the maintainer performs the actual upload/submission with their own Apple/Google accounts.
- **Reuses existing surfaces**: the privacy explainer updated here is the existing in-app how-it-works/privacy page from #010; failure copy extends the existing `AppFailure` model and toast/dialog patterns.

## Dependencies

- **#002 Transport Core** — the ICE/connection layer and transfer state machine that TURN fallback and failure-surfacing extend; the streamed-I/O guarantee being verified for performance.
- **#003 Signaling + STUN/TURN hook** — the documented empty TURN hook and per-flavor signaling config this spec fills in with a real relay.
- **#004/#005 Send/Receive flows** — the progress/failure/retry UI that resilience states surface through.
- **#007–#009 connection methods** — the four pairing paths validated on device in US5.
- **#010 Settings** — the in-app privacy/how-it-works explainer updated in US2; the signaling-endpoint override pattern TURN config aligns with.
- **#011 Background Transfer** — the background behavior validated on device in US5 and referenced by the background-past-limit failure case.
- **#013 In-App Viewers** — the viewers validated on device in US5.

## Out of Scope (post-v1.0)

- The actual store submission/review (the maintainer submits separately).
- Resume of interrupted transfers (a v1.1 feature).
- Saved/trusted peers + auto-accept rules.
- Desktop (macOS/Windows) and web targets.
- Any new connection method, file type, or in-app viewer.
- A self-hosting bundle / one-click TURN+signaling distribution (documented for v1.1).
- Per-user relay usage quotas or billing.
