# Feature Specification: Send Flow (Gửi)

**Feature Branch**: `004-send-flow`
**Created**: 2026-06-24
**Status**: Draft
**Input**: User description: "Build the Send flow (Gửi) — the first end-to-end user-facing transfer feature in Safe Send. The sender picks files on their device and ships them directly to a paired peer over the existing WebRTC transport, watching live progress to completion."

## Overview

The Send flow is the first user-facing transfer experience in Safe Send. A sender opens the flow from the Home screen, picks one or more files of any type and size, receives a short-lived 6-digit code to share with the receiver, and — once the receiver joins — sends the files directly to that peer while watching live progress, ending in a clear success or a clearly-surfaced, retryable failure. The core promise holds throughout: files travel peer-to-peer, with no account, no cloud upload, no size limit, and no intermediary server holding the bytes.

This is one half of the MVP loop; the Receive flow (Nhận) is specified separately (#005). This feature is the user interface and orchestration layer over the already-built 6-digit pairing and WebRTC transport engine — it does not introduce new transport or new pairing mechanics.

## Clarifications

### Session 2026-06-24

- Q: How is the destination peer identified for display on the Progress/Complete screens, given pairing (#003) exchanges no device name and the device profile is owned by #010? → A: Use a generic localized label ("Thiết bị nhận" / "the receiver") for #004; real peer names are added later by #010, with no expansion of the #002/#003 contract.
- Q: After a recoverable failure (expired code, relay unreachable/timeout, declined, connection lost), does "retry" preserve the current file selection or restart from an empty selection? → A: Retry preserves the file selection and returns to pairing (re-issuing a fresh code); only the explicit "send again" on the completion screen starts from an empty selection.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Send files to a paired peer (Priority: P1)

A user has one or more files on their device they want to give to someone with them or reachable. They open Gửi from Home, pick the files, see a 6-digit code, read it out (or otherwise share it) to the receiver, and watch the files transfer to completion once the receiver joins.

**Why this priority**: This is the entire reason the feature exists and the first half of the product's core value (peer-to-peer file sending). Without it there is no sendable MVP. Every other story in this spec is a refinement or failure-handling branch of this one.

**Independent Test**: With a cooperating receiver (the #005 flow or a test harness that joins the code and accepts), a tester can pick files, obtain a code, have the peer join, and confirm all files arrive intact with the sender reaching the completion screen — delivering the full send value on its own.

**Acceptance Scenarios**:

1. **Given** the user is on the file-selection screen with at least one file chosen, **When** they continue and a receiver joins with the displayed code and accepts, **Then** the files transfer and the sender sees a completion screen reporting the number of files, total size, destination peer, and elapsed time.
2. **Given** a transfer is in progress, **When** the user watches the progress screen, **Then** they see an overall percentage, a progress bar, current transfer speed, an estimated time remaining, and which file is currently sending (e.g. "file 2 / 5").
3. **Given** the user reaches the completion screen, **When** they choose to send again, **Then** they return to an empty file-selection screen ready for a new send; **and When** they choose done, **Then** they return to Home.
4. **Given** a multi-file selection, **When** the transfer runs, **Then** files are sent one after another and the transfer is reported complete only after every file has fully transferred and passed its integrity check.

---

### User Story 2 - Build and adjust the file selection (Priority: P1)

Before sending, the user assembles exactly the set of files they intend to send: adding files from the system picker, reviewing each with its name, type, and size, removing any added by mistake, and seeing a running total — and is prevented from continuing with nothing selected.

**Why this priority**: Selection is the unavoidable first step of every send and the user's only chance to control what leaves their device. A wrong or empty selection makes the whole transfer worthless, so this must be correct and is co-critical with Story 1.

**Independent Test**: A tester can open Gửi, add several files, verify per-file metadata and the running total, remove one, confirm the total updates, empty the selection, and confirm the continue action is unavailable — all without ever pairing or transferring.

**Acceptance Scenarios**:

1. **Given** the user opens the Send flow, **When** the screen loads, **Then** the selection is empty and the continue action is unavailable.
2. **Given** the system file picker, **When** the user selects multiple files of any type, **Then** each appears in a selection tray showing its name, file-type indicator, and individual size, plus a header with the item count and combined total size.
3. **Given** files in the tray, **When** the user removes one, **Then** it disappears and the item count and total size update accordingly.
4. **Given** at least one file is selected, **When** the user continues, **Then** the flow advances to pairing; **Given** zero files, the continue action remains unavailable.
5. **Given** the user is asked for file-access permission and denies it, **When** they return to the flow, **Then** they see a clear explanation and a way to retry or open settings, with no crash and no partial selection.

---

### User Story 3 - Pair via a 6-digit code (Priority: P1)

After selecting files, the user is shown a 6-digit code with a visible expiry countdown and a clear instruction to share it with the receiver. When the receiver enters the code and the direct connection opens, the flow advances to transfer automatically.

**Why this priority**: Pairing is the bridge between selection and transfer; without a code to share, no peer can join and Story 1 cannot complete. It is the third co-critical pillar of the MVP send path.

**Independent Test**: A tester can reach the pairing screen, observe a well-formed 6-digit code and a counting-down expiry, have a peer join with that code, and confirm the flow advances to the progress screen automatically — testable with the pairing layer and a joining peer, independent of actual file bytes.

**Acceptance Scenarios**:

1. **Given** the user continues from selection, **When** the pairing screen appears, **Then** a 6-digit code is displayed prominently with an expiry countdown and instructions to share it with the receiver.
2. **Given** the pairing screen, **When** the user views the connection options, **Then** the "Mã 6 số" (6-digit code) option is active and functional, while QR, nearby, and share-link options are visible but clearly marked as coming later.
3. **Given** a valid, unexpired code, **When** the receiver joins and the direct channel opens, **Then** the flow advances to the progress screen without further user action.
4. **Given** the code's expiry countdown reaches zero before any peer joins, **When** the timer elapses, **Then** the user is informed the code expired and offered a way to get a fresh code.

---

### User Story 4 - Cancel a send in progress or while waiting (Priority: P2)

At any point after starting — while waiting for a peer or mid-transfer — the user can stop. Cancelling mid-transfer asks for confirmation first (to prevent an accidental abort of a large transfer), then aborts cleanly and returns the user out of the flow.

**Why this priority**: Users must always be able to back out, and an accidental cancel of a long transfer is costly — but cancellation is a control branch on top of the core send, not the core send itself, so it ranks below the P1 path.

**Independent Test**: A tester can reach the waiting and the transferring states and, in each, trigger cancel — confirming the waiting cancel exits immediately and the transferring cancel requires confirmation before aborting — without needing a successful completion.

**Acceptance Scenarios**:

1. **Given** the user is waiting for a peer on the pairing screen, **When** they leave/cancel, **Then** the pairing session ends and they exit the flow with no lingering code.
2. **Given** a transfer is in progress, **When** the user taps Cancel, **Then** they are asked to confirm before anything is aborted.
3. **Given** the cancel confirmation, **When** the user confirms, **Then** the transfer aborts, the peer is informed it was cancelled, and the user exits the flow; **When** they decline, **Then** the transfer continues uninterrupted.

---

### User Story 5 - Understand and recover from a failed or declined send (Priority: P2)

When something goes wrong — the receiver declines the transfer, the code can't be issued, the relay is unreachable or times out, the room is unavailable, the device is rate-limited, or the connection drops mid-transfer — the user sees a specific, human-readable reason in Vietnamese and a clear way to try again, never a silent stall or a crash.

**Why this priority**: Real transfers fail for many reasons, and a confusing failure destroys trust in a privacy product. But this is the error-handling layer over the happy path, so it ranks below the P1 send itself.

**Independent Test**: A tester can induce each failure condition (decline, expired code, unreachable relay, dropped connection) and confirm each produces a distinct, understandable message with a retry path — testable by simulating each failure independently.

**Acceptance Scenarios**:

1. **Given** the receiver declines the incoming transfer, **When** the decline is received, **Then** the sender sees a clear "declined by receiver" outcome (not a generic or silent failure) and can return or retry with the same file selection.
2. **Given** the relay is unreachable or times out while issuing/serving the code, **When** the failure occurs, **Then** the user sees a specific message for that condition and a retry action.
3. **Given** an active transfer, **When** the connection to the peer is lost mid-transfer, **Then** the user is told the connection dropped and offered a retry, with no crash and no stuck progress bar.
4. **Given** the device is rate-limited or the room is full/unavailable, **When** the user tries to pair, **Then** the corresponding specific message is shown with appropriate next steps.

---

### Edge Cases

- **Empty / zero-byte files**: A selected file of size zero is still a valid item; the total and per-file size display handle 0 bytes gracefully and the file transfers and completes.
- **Very large and many files**: Multi-gigabyte files and large selections transfer without the app loading whole files into memory; progress, speed, and ETA remain responsive.
- **Duplicate file names in one selection**: Two selected files sharing the same name are both sent and both must arrive; naming collisions are resolved on the receiving side (already handled by the transport core).
- **File becomes unavailable after selection**: If a chosen file can no longer be read when its turn to send comes (moved/deleted/permission revoked), the transfer surfaces a specific read-failure rather than silently skipping it.
- **App backgrounded mid-transfer**: Leaving and returning to the app during a transfer is handled without corrupting the transfer state; behaviour on prolonged background is governed by the platform and surfaced as a connection issue if the link drops.
- **Code expires exactly as a peer joins**: The race between expiry and a joining peer resolves to a single deterministic outcome (either connected or expired), never a half-state.
- **Receiver never joins**: If no peer joins before expiry, the user is led to refresh the code rather than waiting indefinitely.
- **Back navigation / accidental exit while waiting**: Navigating back out of the pairing or progress screen is treated consistently with cancel (waiting → silent end; transferring → confirm).
- **Reduced-motion accessibility**: With reduced-motion enabled, the radar and spinner animations are disabled while all status information remains conveyed textually.

## Requirements *(mandatory)*

### Functional Requirements

**File selection**

- **FR-001**: The Send flow MUST open as a full-screen experience with the bottom navigation hidden, launched from the Home "Gửi" action.
- **FR-002**: Users MUST be able to add files via the system file picker, selecting files of any type and selecting multiple files at once.
- **FR-003**: The selection MUST display, for each file, its name, a file-type indicator, and its individual size, plus a header showing the number of selected items and the combined total size.
- **FR-004**: Users MUST be able to add more files to, and remove individual files from, the current selection before continuing, with counts and totals updating immediately.
- **FR-005**: The system MUST prevent continuing to pairing when no files are selected.
- **FR-006**: The system MUST request file-access permission only when the user initiates file selection, and MUST present a clear, recoverable state (retry / open settings) if permission is denied — without crashing or leaving a partial selection. *(Note: the any-type system document picker grants per-file access without a runtime permission prompt on iOS/Android, so on the send path there is no "denied" dialog to handle; the graceful state reduces to a cancelled pick leaving the existing selection unchanged. Runtime permissions are introduced on the save side in #005 — see research.md R3.)*

**Pairing (6-digit)**

- **FR-007**: After the user continues from selection, the system MUST present a pairing screen that displays a sender-generated 6-digit code to share with the receiver.
- **FR-008**: The pairing screen MUST show a live expiry countdown for the code and instruct the user to share the code with the receiver.
- **FR-009**: The pairing screen MUST present the connection methods as the "Mã 6 số" option (functional) alongside QR, nearby, and share-link options that are visible but clearly indicated as not yet available.
- **FR-010**: When a receiver joins with the valid code and the direct connection is established, the system MUST advance to the progress screen automatically without further user input.
- **FR-011**: When the code expires before any peer joins, the system MUST inform the user and offer a way to obtain a fresh code. Expiry is authoritatively enforced server-side (a `roomExpired` outcome from the relay, surfaced as a pairing failure → "lấy mã mới"); the on-screen countdown is a display of `PairingCode.remaining` and does not by itself end the session.
- **FR-012**: The system MUST reuse the existing typed pairing failure outcomes (unreachable, timeout, expired, room full, invalid, rate-limited) and surface each with a distinct, user-readable message.

**Transfer & progress**

- **FR-013**: Once connected, the system MUST send the selected files directly to the paired peer over the existing direct encrypted channel, with no file bytes passing through any intermediary server.
- **FR-014**: The system MUST send multiple files sequentially and stream each file from storage without loading whole files into memory.
- **FR-015**: The progress screen MUST display a "sending" status indicator, a destination-peer label, an overall percentage, a progress bar, the current transfer speed, an estimated time remaining, and the current file with its position in the batch (e.g. "file i / n"). Until device profiles exist (#010), the destination peer MUST be shown as a generic localized label ("Thiết bị nhận" / "the receiver") rather than an actual device name.
- **FR-016**: The system MUST treat a send as complete only when every file has fully transferred and passed its per-file integrity verification.
- **FR-017**: All numeric and technical values shown to the user (percentage, speed, ETA, sizes, the 6-digit code, the countdown) MUST be rendered with monospaced, tabular figures.

**Cancellation & control**

- **FR-018**: Users MUST be able to cancel while waiting for a peer, ending the pairing session and exiting the flow with no lingering active code.
- **FR-019**: Users MUST be able to cancel during an active transfer, and the system MUST require explicit confirmation before aborting an in-progress transfer.
- **FR-020**: On confirmed cancellation during transfer, the system MUST abort the transfer, inform the peer it was cancelled, and exit the flow cleanly.
- **FR-021**: Back navigation or accidental exit MUST be handled consistently with cancellation (waiting → silent end; transferring → confirmation required).

**Completion**

- **FR-022**: On a fully successful send, the system MUST present a completion screen confirming success and reporting the number of files sent, the total size, the destination-peer label (generic localized label per FR-015 until #010), and the elapsed time, with a short summary of the sent files.
- **FR-023**: The completion screen MUST offer a "done" action (return to Home) and a "send again" action (return to an empty selection to start a new send).

**Failure handling**

- **FR-024**: When the receiver declines the transfer, the system MUST present a clear "declined by receiver" outcome distinct from a generic failure, with a way to return or retry.
- **FR-025**: When the connection to the peer is lost mid-transfer, the system MUST inform the user the connection dropped and offer a retry, with no crash and no stuck progress.
- **FR-025a**: On a recoverable failure (expired code, relay unreachable/timeout, room full, rate-limited, receiver declined, connection lost), "retry" MUST preserve the current file selection and return the user to pairing with a freshly issued code; the file selection is cleared to empty only via the explicit "send again" action on the completion screen.
- **FR-026**: When a file selected for sending cannot be read at send time, the system MUST surface a specific read-failure reason rather than silently skipping the file.
- **FR-027**: All user-facing copy in the flow MUST be available in Vietnamese (primary) and English, with Vietnamese shown by default.

**Presentation & accessibility**

- **FR-028**: The flow MUST follow the fixed light/dark design system (no scheme picker), using the primary call-to-action, secondary, and destructive button styles defined for the app.
- **FR-029**: When reduced motion is enabled, decorative animations (the pairing radar and the transfer spinner) MUST be disabled while all status information remains available textually.

### Key Entities *(include if feature involves data)*

- **File selection**: The ordered set of files the user has chosen to send; each entry carries a display name, a file-type indicator, and a size; the set has an item count and a combined total size, and must be non-empty to proceed.
- **Pairing code**: A short-lived 6-digit code generated for this send, with an expiry time and a remaining-time countdown, shared with the receiver to establish the connection.
- **Transfer session**: The unit of work moving the selected files to one peer; tracks overall progress (bytes/percentage), current speed, estimated time remaining, the file currently in flight and its position in the batch, and a terminal outcome (completed / cancelled / failed-with-reason / declined).
- **Destination peer**: The receiver the files are being sent to, shown on the progress and completion screens. In this feature it is represented only by a generic localized label ("Thiết bị nhận" / "the receiver"); an actual device name is introduced later by #010 without changing this flow's contract.
- **Failure outcome**: A typed, human-readable reason a send did not complete (code expired, relay unreachable, relay timeout, room full, invalid code, rate-limited, receiver declined, connection lost, file read failure), each mapped to specific copy and a recovery action.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A sender can go from opening the flow to a displayed, shareable 6-digit code in under 30 seconds (excluding the time spent browsing for files), across both light and dark appearance.
- **SC-002**: Given a receiver that joins and accepts, 100% of selected files arrive at the receiver intact (pass integrity verification) before the sender's completion screen appears.
- **SC-003**: The flow sends multi-gigabyte files and large batches without the app's memory growing in proportion to file size (streamed, not buffered whole).
- **SC-004**: Every failure and declined-transfer condition produces a distinct, human-readable Vietnamese message and an available retry/return action — with zero cases of a silent stall or crash across the enumerated failure conditions.
- **SC-005**: Progress indicators (percentage, speed, ETA, current-file position) update continuously during an active transfer so the user is never left wondering whether the transfer is still moving.
- **SC-006**: Cancelling an in-progress transfer always requires one explicit confirmation, and confirming aborts the transfer and informs the peer in every case; cancelling while only waiting for a peer never requires confirmation.
- **SC-007**: No file bytes are ever sent to or stored on any intermediary server during a transfer — bytes flow only over the direct peer-to-peer channel.

## Assumptions

- **Receive side exists for end-to-end testing**: A cooperating receiver (the #005 Receive flow, or a test harness that joins the code and accepts/declines/cancels) is available to exercise the full send path; this spec does not build the receive UI.
- **Pairing and transport are reused, not rebuilt**: The 6-digit pairing rendezvous and the WebRTC transfer engine (state machine, chunking, per-file integrity, sequential multi-file, streamed I/O) already exist and are consumed by this flow; this feature is the UI and orchestration layer over them.
- **Single peer per send**: A send targets exactly one receiver per session (no simultaneous multi-receiver broadcast).
- **Single active send at a time**: The app handles one send flow at a time; starting a new send ("send again") begins after the previous one has reached a terminal state.
- **6-digit code only for pairing in this spec**: QR, nearby radar, and share-link pairing are out of scope and appear only as clearly-disabled placeholders (delivered in #007 / #009 / #008).
- **No history persistence yet**: A completed or failed send does not yet write a history record (delivered in #006); the completion screen is in-session only.
- **No inbound share-sheet**: Receiving files from other apps' "share" actions ("Send with Safe Send") is out of scope and deferred to a later spec; files enter only via the in-app picker.
- **Settings unchanged**: Device profile, auto-receive, default save location, and theme controls are out of scope (delivered in #010); the flow uses existing defaults.
- **Reachable relay for real transfers**: Validating an actual two-device transfer over a real network requires a reachable signaling relay and remains a manual two-device smoke test; automated verification uses the in-process loopback path.

## Out of Scope

- The Receive flow and the incoming-transfer accept/reject prompt (#005).
- QR pairing (#007), share-link pairing (#008), and nearby-radar pairing (#009) — placeholders only.
- Inbound share-sheet intent from other apps ("Send with Safe Send") — deferred.
- Transfer history persistence and the History tab (#006).
- Settings and preferences (#010).
- Pause/resume of an interrupted transfer (post-v1.0).
