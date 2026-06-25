# Feature Specification: Receive Flow (Nhận)

**Feature Branch**: `005-receive-flow`
**Created**: 2026-06-25
**Status**: Draft
**Input**: User description: "Build the Receive flow (Nhận) — the second half of the MVP loop in Safe Send, completing pair→send→receive. A user opens Nhận from Home, enters the sender's 6-digit code on the shared Connect hub (role=receiver), and once the direct WebRTC channel opens, an incoming-transfer prompt shows the sender and the file manifest with Accept / Reject. On accept, files stream to disk with live progress, each integrity-verified per-file; on completion the user reaches a Complete summary with Share and Open actions. Save to app sandbox + share sheet — no runtime permission. Accept/Reject always prompted. Error handling parity with #004."

## Overview

The Receive flow is the second user-facing transfer experience in Safe Send and the half that closes the MVP loop: after #004 lets a user **send**, this lets a user **receive**. A receiver opens the flow from the Home screen, enters the 6-digit code the sender read out to them, and — once the direct connection opens — is shown exactly what is about to arrive (who it is from, how many files, which types, the total size) and explicitly chooses to **Accept** or **Reject**. On accept, the files stream directly to the device while the receiver watches live progress, each file integrity-checked as it lands, ending in a clear success summary with **Share** and **Open** actions, or a clearly-surfaced, retryable failure. The core promise holds throughout: files travel peer-to-peer, with no account, no cloud download, no size limit, and no intermediary server holding the bytes.

This feature is the user interface and orchestration layer over the already-built 6-digit pairing (#003) and WebRTC transport engine (#002) — it introduces **no new transport and no new pairing mechanics**. It reuses the role-parameterized Connect hub (#004) for the receiver side and shares the Progress and Complete screens with the Send flow. After this feature merges, the **MVP checkpoint** is reached: a full pair → send → receive → save loop works end-to-end, ready for two-device dogfooding.

## Clarifications

### Session 2026-06-25

- Q: Where are received files saved on each platform? → A: App sandbox + share sheet — iOS app Documents exposed via Files (UIFileSharingEnabled), Android app-specific directory; the user reaches/exports them via Share and Open actions. NO runtime storage permission is requested (`permission_handler` stays deferred). Public Downloads / "ask each time" destinations are deferred to #010.
- Q: When a peer connects and the manifest arrives, is an Accept/Reject prompt always shown? → A: Always prompt. Every incoming transfer surfaces the sender + manifest with Accept / Reject; there is no auto-accept in #005 (auto-receive from trusted devices is owned by #010).
- Q: How is the sender identified for display on the incoming-transfer prompt, Progress, and Complete screens, given pairing (#003) exchanges no device name? → A: Use a generic localized label ("Người gửi" / "the sender") for #005, matching the #004 generic-peer decision; real peer names arrive in #010 with no expansion of the #002/#003 contract.
- Q: After a recoverable failure (expired/invalid code, relay unreachable/timeout, rejected by the protocol, connection lost), does "retry" preserve the entered code? → A: Retry preserves the entered 6-digit code and returns the user to the code-entry/pairing step so they can re-submit or re-enter; only leaving the flow clears it.
- Q: On a mid-transfer failure (e.g. integrity mismatch on file 3 of 5, or a dropped connection), what happens to files already fully received and verified before it? → A: Keep the already-completed-and-verified files; only the in-flight file and any not-yet-received files are discarded. The terminal screen reports a partial outcome ("nhận X / N tệp"). This matches the #002 engine (per-file atomic finalize) — no rollback of finalized files.
- Q: After the receiver taps Reject at the incoming-transfer prompt, where does the app go? → A: Back to Home (Reject = "I don't want this" → exit the flow). This is distinct from a recoverable failure, which returns to code-entry with the code preserved.
- Q: On the Complete screen for a multi-file receive, how do Open / Share behave? → A: Show a list of received files (FileRow) with a per-file Open action, plus a single Share action that hands all received files to the system share sheet.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive files from a paired peer (Priority: P1)

A user is told (verbally, or via a shared code) that someone wants to send them files. They open Nhận from Home, type in the 6-digit code, and once connected are shown what is about to arrive. They accept, watch the files transfer to completion, and end on a screen confirming what they received, from where they can open or share the files.

**Why this priority**: This is the entire reason the feature exists and the second half of the product's core value (peer-to-peer file receiving). Without it the MVP loop is incomplete — files can be sent but never landed. Every other story in this spec is a refinement or failure-handling branch of this one.

**Independent Test**: With a cooperating sender (the #004 flow or a test harness that hosts a code and offers files), a tester can enter the code, see the incoming manifest, accept, and confirm every file arrives intact and reaches the completion screen — delivering the full receive value on its own.

**Acceptance Scenarios**:

1. **Given** the user is on the code-entry screen, **When** they enter a valid 6-digit code that a sender is currently hosting, **Then** the direct connection opens and the incoming-transfer prompt appears showing the sender label, file count, total size, and file types.
2. **Given** the incoming-transfer prompt is shown, **When** the user accepts, **Then** the files transfer one after another and the receiver sees an overall percentage, a progress bar, current transfer speed, an estimated time remaining, and which file is currently arriving (e.g. "file 2 / 5").
3. **Given** a transfer completes, **When** the receiver reaches the completion screen, **Then** it reports the number of files, total size, the sender label, and elapsed time, and offers actions to open or share the received files.
4. **Given** a multi-file transfer, **When** the files arrive, **Then** the transfer is reported complete only after every file has fully arrived and passed its per-file integrity check.
5. **Given** the user reaches the completion screen, **When** they choose done, **Then** they return to Home.

---

### User Story 2 - Decide on an incoming transfer (Accept / Reject) (Priority: P1)

Before any bytes are written to their device, the receiver is shown who is sending and exactly what they are sending, and explicitly chooses to accept or reject. Rejecting must leave nothing on the device and cleanly end the connection for both sides.

**Why this priority**: Consent is the safety boundary of receiving — a user must never have files written to their device without an explicit choice, and must be able to refuse. This is co-critical with Story 1; receiving without a clear accept/reject gate would be unacceptable.

**Independent Test**: A tester can connect to a hosting sender, see the manifest prompt, choose Reject, and confirm no files are written and both sides end cleanly; then in a separate run choose Accept and confirm the transfer proceeds.

**Acceptance Scenarios**:

1. **Given** a connection has opened and a manifest has arrived, **When** the prompt is shown, **Then** it displays the sender label, the file count, the combined total size, and an indication of the file types, with Accept and Reject actions.
2. **Given** the incoming-transfer prompt, **When** the user rejects, **Then** no files are written to the device, the sender is informed the transfer was declined, the connection ends, and the receiver is returned to a clear end state (back to code entry or Home).
3. **Given** the incoming-transfer prompt, **When** the user accepts, **Then** the flow advances to live progress and files begin arriving.
4. **Given** the prompt is shown, **When** the connection drops before the user decides, **Then** the user sees a clear "connection lost" state with a way to retry, and nothing is left half-written.

---

### User Story 3 - Pair via a 6-digit code (receiver side) (Priority: P1)

After opening Nhận, the user enters the sender's 6-digit code into a clear entry field, sees immediate feedback while connecting, and is advanced automatically to the incoming-transfer prompt once the direct connection opens. Invalid, expired, or full-room codes produce clear, recoverable errors.

**Why this priority**: Code entry is the receiver's only way into the transfer; if it is unclear or its errors are opaque, the user can never receive. It is the entry gate for Stories 1 and 2 and shares the same priority.

**Independent Test**: A tester can open Nhận, enter a code, and observe each outcome — connecting feedback on a valid hosted code, and clear distinct errors for an unknown/expired code, an already-full room, and an unreachable relay — without needing a real file transfer to follow.

**Acceptance Scenarios**:

1. **Given** the receiver lands on the code-entry screen, **When** it loads, **Then** an empty 6-digit entry field is focused and the connect action is unavailable until a complete code is entered.
2. **Given** a complete 6-digit code is entered, **When** the user connects, **Then** they see a connecting state, and on success advance to the incoming-transfer prompt.
3. **Given** the user enters a code that is unknown or expired, **When** they connect, **Then** they see a clear message that the code is invalid or expired, with the entered code preserved so they can correct or retry.
4. **Given** the user enters a code whose room is already full (two peers connected), **When** they connect, **Then** they see a clear "room full" message and can retry with a different code.
5. **Given** the signaling relay is unreachable or times out, **When** the user connects, **Then** they see a clear connection-problem message with a retry that preserves the entered code.

---

### User Story 4 - Save, open, and share received files (Priority: P2)

After a successful transfer, the received files are persisted on the device and the receiver can open them in an appropriate app or hand them to the system share sheet (to save into Files/Downloads, send onward, etc.) — without the app having requested any storage permission.

**Why this priority**: Receiving files the user cannot then reach has little value, so persistence + an export path is important; but the core transfer and consent gate (Stories 1–3) must work first, making this a strong P2 that rounds out the experience.

**Independent Test**: After a completed transfer, a tester can use the Open action to launch a received file in a system viewer and the Share action to push it to the share sheet, confirming the files exist on disk and are reachable, with no permission prompt having appeared.

**Acceptance Scenarios**:

1. **Given** a transfer has completed, **When** the receiver chooses Open on a received file, **Then** the file opens in an appropriate system viewer/app.
2. **Given** a transfer has completed, **When** the receiver chooses Share, **Then** the system share sheet appears offering to save or forward the received file(s).
3. **Given** the receive flow runs end-to-end, **When** files are written and exported, **Then** at no point is the user asked to grant a storage/photos runtime permission.
4. **Given** an incoming file name collides with an existing file in the destination, **When** it is written, **Then** it is saved without overwriting the existing file (a non-destructive distinct name is used).

---

### Edge Cases

- **Code entry**: partial/short code → connect disabled; non-digit input rejected; pasting a code fills the field; leading-zero codes (`000123`) accepted.
- **Expired mid-wait**: the entered code expires between entry and a sender hosting it → invalid/expired error, code preserved for retry.
- **Sender cancels**: sender cancels before sending or mid-transfer → receiver sees a clear "transfer cancelled/connection lost" state, the in-flight file is discarded, already-completed-and-verified files are kept as a partial outcome (FR-013a), with a retry path.
- **Receiver cancels mid-transfer**: a cancel-confirmation dialog ("Huỷ lượt truyền? Tiến độ sẽ mất") → on confirm, the transfer aborts, the in-flight file is discarded (completed files kept per FR-013a), the sender is informed, and the user returns to a clear end state.
- **Integrity mismatch**: a file's computed hash does not match the sender's → that file fails and is discarded; already-completed files are kept and the transfer ends in a clearly-surfaced partial/failure outcome rather than silently keeping the corrupt file.
- **App backgrounded mid-transfer**: documented as a known limitation for #005; full background-resilience is owned by #011 (the transfer is not expected to survive backgrounding in this spec).
- **Disk/write failure** while saving a chunk → clearly-surfaced failure, partial data discarded, retry offered.
- **Reduce-Motion**: connecting spinner and any radar/animation are disabled, matching #004.
- **Reject vs. cancel**: rejecting at the prompt (before accepting) is distinct from cancelling an in-progress transfer; both leave nothing usable on the device.

## Requirements *(mandatory)*

### Functional Requirements

#### Entry & pairing (receiver)
- **FR-001**: The system MUST launch the Receive flow as a full-screen, navigation-less flow from the Home "Nhận" action.
- **FR-002**: The system MUST present a 6-digit code-entry step using the shared Connect hub in a receiver role, with a focused entry field and a connect action that is unavailable until a complete 6-digit code is entered.
- **FR-003**: The system MUST accept any 6-digit code in the full `000000`–`999999` range, preserving leading zeros, and MUST reject non-digit input.
- **FR-004**: On submitting a complete code, the system MUST show a connecting state and, on a successful direct connection, advance automatically to the incoming-transfer prompt.
- **FR-005**: The system MUST reuse the existing 6-digit pairing mechanics (#003) and the existing WebRTC transport (#002) without introducing new pairing or transport mechanics.

#### Incoming-transfer decision
- **FR-006**: On connection, before any file bytes are written to disk, the system MUST present an incoming-transfer prompt showing the sender label, the file count, the combined total size, and an indication of the file types.
- **FR-007**: The system MUST always prompt for an explicit Accept or Reject decision; it MUST NOT auto-accept any incoming transfer in this feature.
- **FR-008**: On Accept, the system MUST advance to live progress and begin receiving files to disk.
- **FR-009**: On Reject, the system MUST write no files, inform the sender the transfer was declined, end the connection cleanly, and return the receiver to Home (Reject exits the flow — distinct from a recoverable failure, which returns to code-entry).
- **FR-010**: The system MUST display the sender as a generic localized label ("Người gửi") wherever a peer identity is shown (prompt, progress, complete), with no dependency on a device name from #002/#003.

#### Transfer & progress
- **FR-011**: During an accepted transfer, the system MUST stream each file's bytes to disk incrementally (never holding a whole file in memory), driven by the existing transfer state machine.
- **FR-012**: The system MUST display live overall progress: percentage, progress bar, current transfer speed, estimated time remaining, and the current file position (e.g. "file N / M").
- **FR-013**: The system MUST verify each received file's integrity (per-file hash from #002); a mismatch MUST fail that file and end the transfer in a surfaced failure rather than keeping the corrupt file.
- **FR-013a**: On a mid-transfer failure (integrity mismatch, connection lost, or write error), the system MUST keep files already fully received and verified, discard only the in-flight file and any not-yet-received files, and present a partial terminal outcome reporting how many of the offered files arrived (e.g. "nhận X / N tệp"). It MUST NOT roll back already-finalized files.
- **FR-014**: The system MUST report the transfer fully complete only after every accepted file has fully arrived and passed its integrity check; a transfer that ends with some-but-not-all files is a partial outcome (FR-013a), not a full success.
- **FR-015**: The system MUST allow the receiver to cancel an in-progress transfer via a confirmation dialog; on confirm it MUST abort the transfer, discard partial data, inform the sender, and return to a clear end state.

#### Saving & export
- **FR-016**: The system MUST persist received files to an app-owned location that requires no runtime storage/photos permission (iOS app Documents exposed to the Files app; Android app-specific storage).
- **FR-017**: The system MUST write incoming files non-destructively — a name collision with an existing file MUST NOT overwrite it (a distinct name is used).
- **FR-018**: While receiving, the system MUST write to a quarantined/temporary location and only finalize a file to its destination after it passes its integrity check.
- **FR-019**: On completion, the system MUST present the received files as a list (FileRow) with a per-file Open action (launch that file in an appropriate system viewer) and a single Share action that hands all received files to the system share sheet.
- **FR-020**: The system MUST NOT request any storage or photo-library runtime permission at any point in the receive flow.

#### Completion & failure
- **FR-021**: On success, the system MUST show a completion summary reporting file count, total size, sender label, and elapsed time, the per-file list (FR-019), and Done; Done returns to Home. A partial outcome (FR-013a) uses the same screen but reports the received-vs-offered count and surfaces that the transfer did not fully complete.
- **FR-022**: The system MUST surface recoverable failures (invalid/expired code, room full, relay unreachable/timeout, rejected by the protocol, connection lost, file write/read failure) as clear, distinct, user-facing messages.
- **FR-023**: For recoverable failures, the system MUST offer a retry that preserves the entered 6-digit code and returns the user to the code-entry/pairing step; only leaving the flow clears the code.
- **FR-024**: The system MUST reuse the existing failure model and message-mapping approach established in #003/#004 (a receive-side mapper over the shared failure variants), adding receive-specific copy only where needed.
- **FR-025**: On any terminal or abandoned state (reject, cancel, failure), the system MUST leave no half-written/unverified partial file on the device (the in-flight quarantine file is discarded) and MUST release the connection and resources. Files already finalized and verified before the terminal state are retained per FR-013a; on Reject (before accepting) nothing has been written, so nothing is kept.

#### Localization & accessibility
- **FR-026**: All user-facing strings MUST be provided via the localization system (Vietnamese primary, English secondary), consistent with the rest of the app.
- **FR-027**: The flow MUST honor Reduce-Motion by disabling the connecting spinner and any animated pairing visuals, matching #004.
- **FR-028**: Interactive and status elements (code entry, accept/reject, progress, complete actions) MUST carry accessibility labels.

### Key Entities *(include if feature involves data)*

- **Incoming transfer offer**: what the sender proposes to send, shown at the prompt — sender label, file count, total size, file-type summary; derived from the transfer manifest (#002), held only for the duration of the session.
- **Received file**: a single arrived file — name, type, size, integrity status, and final on-device location; written via a temporary/quarantine location then finalized.
- **Receive session**: one end-to-end receive attempt — the entered code, the connection/transfer state (driven by the #002 state machine), per-file and overall progress, and a terminal outcome (completed / partial / rejected / cancelled / failed), where "partial" keeps the files that arrived and verified before an interruption (FR-013a).
- **Receive failure**: a recoverable or terminal error mapped to user-facing copy (reusing the shared failure variants), carrying enough context to drive the retry-preserving-code behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A receiver can go from opening Nhận to a displayed incoming-transfer prompt, against a sender currently hosting a code, in under 30 seconds on a typical local network.
- **SC-002**: 100% of received files that reach the completion screen pass their per-file integrity check (no corrupt file is ever presented as successfully received).
- **SC-003**: In 100% of reject, cancel, and failure outcomes, no half-written/unverified file remains on the device; any file presented to the user as "received" (including in a partial outcome) has passed its integrity check.
- **SC-004**: The complete receive flow (enter code → accept → transfer → save → open/share) can be performed without the user encountering any storage/photos permission prompt.
- **SC-005**: Each of the recoverable error conditions (invalid/expired code, room full, relay unreachable/timeout, declined, connection lost) produces a distinct, understandable message and a retry that keeps the entered code — verifiable for every listed condition.
- **SC-006**: Every received file that reaches the completion screen can be opened in a system viewer and handed to the share sheet.
- **SC-007**: Combined with #004, two devices can complete a full pair → send → receive → save loop via a 6-digit code (the MVP checkpoint), with the sender's chosen files arriving intact on the receiver.

## Assumptions

- **Cooperating sender exists**: the receiver pairs against a device running the #004 Send flow (or an equivalent test harness) that hosts a 6-digit code and offers files; this spec does not build the sender.
- **No new transport/pairing**: the WebRTC transport (#002) and 6-digit signaling/pairing (#003) are reused unchanged in mechanics; the only engine addition is an additive seam to receive over the already-opened pairing transport (no second handshake), mirroring the send-side seam added in #004.
- **Shared Progress/Complete**: the Progress and Complete screens are shared between Send and Receive; making them reusable across both features (without features importing each other) is part of this work.
- **Generic peer identity**: the sender is shown as a generic localized label until device profiles arrive in #010; no device name is exchanged by #002/#003.
- **Save location**: received files land in app-owned storage reachable via the Files app (iOS) / app-specific storage (Android) and the share sheet; public Downloads, "ask each time", and save-to-photo-library are deferred to #010. No runtime permission is required, so `permission_handler` remains deferred.
- **Always-prompt**: every incoming transfer is explicitly accepted or rejected; auto-receive from trusted devices is owned by #010.
- **Single active transfer**: one receive session at a time; concurrent/queued incoming transfers are out of scope.
- **Background limitation**: the transfer is not expected to survive the app being backgrounded mid-transfer; full background/interruption resilience is owned by #011.
- **History**: writing a history record on a terminal receive outcome is owned by #006; this spec exposes the terminal state but does not persist history.
- **Out of scope**: history persistence (#006); QR / share-link / nearby-radar receive entry points (#007–#009); auto-receive, save-location preferences, and real peer names (#010); two-physical-device receive smoke test and background resilience (deferred / #011).
