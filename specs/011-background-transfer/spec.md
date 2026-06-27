# Feature Specification: Background Transfer

**Feature Branch**: `011-background-transfer`
**Created**: 2026-06-27
**Status**: Draft
**Input**: User description: "Background Transfer — keep an in-flight file transfer running and visible while the Safe Send app is backgrounded or the device is locked, on both iOS and Android."

## Clarifications

### Session 2026-06-27

- Q: When the user taps "Huỷ" on the Android background notification, does it cancel immediately or open the app to confirm? → A: Cancel immediately (no confirm); the in-app Cancel keeps its confirmation dialog.
- Q: If Android notification permission is denied, what happens when the user backgrounds an active transfer? → A: The transfer keeps running to the extent the platform allows; the foreground service still posts its OS-required ongoing notice where mandated; reduced notification visibility is accepted and surfaced honestly, never blocking the transfer.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Watch a transfer finish while the app is in the background (Priority: P1)

A user starts a file transfer (sending or receiving) that will take a while. They leave Safe Send — switch to another app, or lock the phone — expecting the transfer to keep going and to be able to glance at its progress without reopening the app. The transfer keeps running within the limits the operating system allows, and live progress appears on a background surface: an iOS Live Activity (Lock Screen + Dynamic Island) or an Android ongoing notification.

**Why this priority**: This is the entire reason the feature exists. Transfers can run for minutes; forcing the user to keep Safe Send open and the screen awake the whole time makes the product feel broken for any non-trivial transfer. Delivering just this story — the transfer survives backgrounding and shows live progress — is a complete, demonstrable improvement.

**Independent Test**: Start a multi-file transfer between two devices, then background the app / lock the device on one side. Confirm the transfer continues and that a background surface shows live progress (direction, file count, peer name, percent, speed, bytes done/total, ETA) updating as it proceeds, then settles to a final state when the transfer completes.

**Acceptance Scenarios**:

1. **Given** an active transfer in the transferring state, **When** the user backgrounds the app or locks the device, **Then** the transfer keeps running (within OS background limits) and a background surface appears showing live progress for the current transfer.
2. **Given** a background surface is showing progress, **When** the transfer advances, **Then** the surface's percent, speed, bytes-done/total, and ETA update to match the in-app progress for the same transfer.
3. **Given** a sending transfer, **When** the background surface is shown, **Then** it is visually marked as "sending" (gửi) with the send accent; **Given** a receiving transfer, **Then** it is marked as "receiving" (nhận) with the receive accent.
4. **Given** a transfer completes successfully while backgrounded, **When** it reaches the done state, **Then** the background surface updates to a final/complete state and is cleaned up rather than left showing stale in-progress numbers.

---

### User Story 2 - Act on the transfer from the background surface (Priority: P2)

While a transfer runs in the background, the user wants to jump back into the app to see full details, or to stop the transfer without first reopening the app. Tapping the surface returns them to the in-app progress screen for that transfer; on Android, a Cancel action on the notification stops the transfer outright.

**Why this priority**: Viewing progress (P1) is the core value; interacting with it is the natural next step but the feature is still useful without it. Cancel-from-surface and tap-to-return reduce friction once the surface exists.

**Independent Test**: With a transfer running in the background, tap the surface and confirm it opens the in-app progress screen showing the same transfer. Separately, on Android, tap the notification's Cancel action and confirm the transfer stops on both peers and the notification is removed.

**Acceptance Scenarios**:

1. **Given** a background surface for an active transfer, **When** the user taps the surface body, **Then** Safe Send comes to the foreground showing the in-app progress screen for that same transfer (no duplicate or second transfer is started).
2. **Given** the Android notification for an active transfer, **When** the user taps its "Huỷ" (Cancel) action, **Then** the transfer is cancelled immediately (no extra confirmation prompt) through the same path as the in-app Cancel, the other peer is notified of the cancellation, and the notification is removed.
3. **Given** a transfer running in the background, **When** the user returns to the app, **Then** the in-app progress screen and the background surface show the same state with no stale or duplicated progress.
4. **Given** the user cancelled the transfer from the surface, **When** they next open the app, **Then** the app reflects the cancelled outcome consistently (it does not appear to still be running).

---

### User Story 3 - Graceful failure when the OS suspends the transfer (Priority: P3)

The operating system may stop a backgrounded transfer before it finishes (background-time limits, low power, the system reclaiming resources). When that happens, the user should not be left with a silently dead transfer or a stuck progress surface. On returning to the app they see a clear explanation that the transfer was interrupted, any files that were already fully received are kept, and they can retry.

**Why this priority**: It hardens the feature against the real platform constraint that background execution is not guaranteed (especially on iOS). The happy path (P1/P2) is demonstrable without it, but shipping without graceful failure would leave confusing dead-ends.

**Independent Test**: Force a backgrounded transfer to be suspended by the OS (e.g., long transfer left backgrounded past the platform's allowance). Confirm that on returning to the app the user sees a clear interrupted-transfer message, that fully-received files are retained as a partial outcome, that a retry path is offered, and that the background surface does not remain showing stale progress.

**Acceptance Scenarios**:

1. **Given** a transfer running in the background, **When** the OS suspends or time-limits it before completion, **Then** the transfer ends in a failed/interrupted state (no attempt is made to resume the partial transfer).
2. **Given** an OS-suspended transfer, **When** the user returns to the app, **Then** they see a clear, localized message that the transfer was interrupted, with a retry option.
3. **Given** a receiving transfer that was interrupted, **When** it failed, **Then** any files that were already fully received and verified are kept (partial outcome) consistent with the existing receive behavior, and incomplete files are not presented as received.
4. **Given** the transfer was interrupted, **When** it reaches the failed state, **Then** the background surface is updated/cleaned up and not left frozen on the last in-progress numbers.

---

### Edge Cases

- **Multiple transfers**: The app supports one active transfer at a time (per the existing flows). If a new transfer cannot start while another is active, the background surface always reflects the single active transfer; there is no ambiguity about which transfer is shown.
- **iOS without Live Activity support**: On iOS versions / devices that do not support Live Activities, the rich Lock Screen / Dynamic Island surface is unavailable. The transfer still attempts to continue in the background within OS limits, and the user is still informed of a backgrounded arrival via the existing notification mechanism where applicable; no crash or dead surface results. (See Assumptions.)
- **Permission denied (Android notifications)**: If the user has denied notification permission, the transfer still runs in the background to the extent the platform allows — it is never blocked solely by the absence of a user-visible notification. The foreground service still posts its OS-required ongoing notice where the platform mandates one to keep the service alive; the reduced notification visibility is surfaced honestly rather than treated as a failure. The app does not force a permission prompt or hold the transfer in the foreground over this.
- **Rapid background/foreground toggling**: Quickly switching the app in and out of the background must not spawn duplicate surfaces or duplicate transfers; the surface count and transfer state stay consistent.
- **Transfer ends while app is foregrounded**: If the transfer completes/fails/cancels while the app is in the foreground, no background surface should linger; surfaces created during a background stint are cleaned up on return.
- **Cancel races completion**: If the user taps Cancel on the surface at the same moment the transfer is completing, the outcome resolves to a single consistent terminal state on both peers (not "completed" on one and "cancelled" on the other beyond what the existing engine already guarantees).
- **Device-locked start**: Backgrounding via screen-lock vs. via switching apps must both trigger the surface and keep-alive behavior.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST keep an already-started transfer (sending or receiving) running while the app is backgrounded or the device is locked, to the extent the host operating system permits background execution.
- **FR-002**: On iOS, the system MUST present a Live Activity showing live transfer progress on the Lock Screen and in the Dynamic Island (compact, minimal, and expanded states), for both sending and receiving transfers.
- **FR-003**: On Android, the system MUST present an ongoing foreground-service notification that cannot be dismissed by swiping while the transfer is active, showing live transfer progress with a progress bar, for both sending and receiving transfers.
- **FR-004**: Each background surface MUST display: transfer direction (sending/receiving), file count, peer/device name, overall percent complete, current transfer speed, bytes transferred / total bytes, and estimated time remaining.
- **FR-005**: Background surfaces MUST be driven solely by the existing transfer state stream (the single source of truth); the system MUST NOT maintain a second, independent progress model for background display.
- **FR-006**: Background surfaces MUST update to reflect the same state snapshots that drive the in-app progress screen, so the two never disagree about the active transfer's progress.
- **FR-007**: The Android notification MUST provide a single "Huỷ" (Cancel) action that cancels the transfer **immediately without an additional confirmation prompt**, through the same underlying cancel path as the in-app Cancel (including notifying the remote peer) and then removes the notification. (The in-app Cancel button retains its confirmation dialog; only the notification action skips it.)
- **FR-008**: Tapping the body of a background surface MUST bring Safe Send to the foreground and show the in-app progress screen for the same active transfer, without starting a new transfer.
- **FR-009**: When the user returns the app to the foreground, the in-app progress screen and any background surface MUST reconcile to the same state, with no stale, frozen, or duplicated progress.
- **FR-010**: When a transfer reaches a terminal state (completed, failed, or cancelled), the system MUST update the background surface to a final state and then dismiss/clean it up; it MUST NOT leave a surface showing stale in-progress numbers.
- **FR-011**: If the operating system suspends or time-limits the transfer before completion, the system MUST end the transfer in a clean failed/interrupted state and MUST NOT attempt to resume the partially-completed transfer.
- **FR-012**: After an OS-induced interruption, the system MUST surface a clear, localized failure to the user on return to the app and MUST offer a retry path.
- **FR-013**: For an interrupted receiving transfer, the system MUST retain any files that were already fully received and integrity-verified (partial outcome), consistent with the existing receive flow, and MUST NOT present incomplete files as received.
- **FR-014**: Background surfaces MUST display connection/transfer metadata only (device name, file count, sizes, progress) and MUST NOT expose file contents; the system MUST NOT log file bytes or sensitive identifiers in support of this feature.
- **FR-015**: All user-facing text on the background surfaces and related messages MUST be Vietnamese-first with an English localization, following the existing localization convention.
- **FR-016**: Background surfaces MUST follow the fixed design language at the **content level**: send transfers use the brand (green) accent and an up indicator; receive transfers use the vivid (blue) accent and a down indicator; numeric values use the monospace numeric style. This is a content/token requirement, **not** a pixel-match of the design mock's card chrome — the surface container may be OS-system-styled where the platform mandates it (notably the Android ongoing notification, which uses the standard system template tinted with the accent). The iOS Live Activity, being custom, matches the mock closely. (Reference: ui-design-context.md → "OS Surfaces — Background Transfer".)
- **FR-017**: The system MUST NOT offer a pause/resume control on any background surface; only Cancel is supported for v1.0.
- **FR-018**: The system MUST ensure that rapid or repeated background/foreground transitions do not create duplicate surfaces or duplicate transfers; at most one background surface exists for the single active transfer.
- **FR-019**: When notification permission is denied (Android), the system MUST still keep a backgrounded transfer running to the extent the platform allows and MUST NOT block the transfer or force a permission prompt over it; the OS-required ongoing service notice is still posted where the platform mandates it, and reduced user-facing notification visibility is surfaced honestly rather than treated as a transfer failure.

### Key Entities

- **Active transfer (existing)**: The single in-flight transfer the app already tracks via its transfer state machine — direction, peer name, file list, byte totals, current progress, speed/ETA, and terminal status. This feature consumes that entity; it does not introduce a new progress model.
- **Background progress surface (conceptual)**: The OS-rendered representation of the active transfer while the app is backgrounded — an iOS Live Activity or an Android foreground-service notification. It is a *view* of the active transfer's state, with a lifecycle bounded by the transfer's transferring → terminal states.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A transfer started and then backgrounded continues to completion on at least one platform path where the OS permits sustained background execution (e.g., Android foreground service), verified by a two-device transfer that finishes with the initiating device backgrounded the entire time.
- **SC-002**: While a transfer runs in the background, the background surface reflects the same progress as the in-app screen within one update cycle — a user comparing the two never sees them disagree by more than the normal refresh interval.
- **SC-003**: 100% of transfers that reach a terminal state (completed, failed, or cancelled) result in the background surface settling to a final state and being cleaned up — no surface is ever left frozen on stale in-progress numbers.
- **SC-004**: Cancelling from the Android notification stops the transfer on both peers and removes the notification, indistinguishable in outcome from cancelling inside the app.
- **SC-005**: When the OS interrupts a backgrounded transfer, the user always receives a clear interrupted-transfer message with a retry option on returning to the app, and any fully-received files are retained — zero cases of a silently dead transfer or a misleading "received" file that is actually incomplete.
- **SC-006**: Tapping a background surface returns the user to the correct in-app progress screen for the active transfer in 100% of attempts, never starting a duplicate transfer.

## Assumptions

- **Single active transfer**: The app continues to support one active transfer at a time; the background surface therefore represents exactly one transfer with no multi-transfer disambiguation needed.
- **Driven by the existing engine**: This feature adds presentation + background-execution plumbing around the existing #002 transfer state machine and the #004/#005 Send/Receive flows; it does not change the transfer protocol, signaling, or integrity guarantees.
- **iOS background limits**: iOS does not guarantee unbounded background execution for this kind of work. Long transfers left backgrounded on iOS may be suspended by the OS; that case is handled by the graceful-failure path (User Story 3), not by promising indefinite background runtime. The Live Activity may continue to display a last-known/stale-then-final state per the OS's own update model.
- **iOS Live Activity availability**: Live Activities require a sufficiently recent iOS version and capable hardware for the Dynamic Island. On devices/versions without Live Activity support, the rich surface is gracefully unavailable (no crash, no dead surface); the transfer still attempts to run in the background within OS limits and the existing arrival-notification behavior (from Settings, #010) still applies where relevant. The minimum iOS version that receives the rich Live Activity surface is to be confirmed at planning.
- **Android foreground service requirement**: On Android, the ongoing notification is the mechanism that keeps the service alive; where the platform requires the notification (and its permission) for the service to run, that coupling is accepted and surfaced honestly if the permission is denied.
- **Cancel-only**: Per the product decision recorded in ui-design-context.md (2026-06-27), there is no pause/resume; the "Tạm dừng" button in the source design mock is intentionally omitted.
- **Reuses existing partial-outcome behavior**: Retaining fully-received files on interruption reuses the receive flow's existing partial-outcome handling (#005); this feature does not define new file-retention semantics.
- **Notification/permission groundwork exists**: Notification permission handling and a local-notification path were introduced in Settings (#010) and are assumed available to build upon.

## Dependencies

- **#002 Transport & Transfer Protocol Core** — the transfer state machine / snapshot stream that all surfaces render.
- **#004 Send Flow** and **#005 Receive Flow** — the in-app progress screens and terminal/partial-outcome handling this feature wraps and returns to.
- **#010 Settings & Preferences** — existing notification permission handling and local-notification plumbing.

## Out of Scope (deferred)

- Transfers surviving a **full app termination** (force-quit / OS kill) — only backgrounding and screen-lock are supported.
- **Pause / resume** of a transfer — only Cancel is supported (v1.1).
- **Resuming** an interrupted or partially-completed transfer — v1.1.
- **Push-initiated background wake** (there is no server to push from) — v1.1+.
