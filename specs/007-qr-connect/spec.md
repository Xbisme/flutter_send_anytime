# Feature Specification: QR Connect

**Feature Branch**: `007-qr-connect`
**Created**: 2026-06-25
**Status**: Draft
**Input**: User description: "Spec #007 — QR Connect: add QR-code pairing so two devices connect without typing the 6-digit code, reusing the existing 6-digit signaling rendezvous. Sender shows a QR in a new Connect-hub tab; receiver scans (camera or pick-from-photo) to auto-join. QR encodes a versioned `safesend://connect?v=1&code=NNNNNN` URI, read in-app only (external/system deep-link deferred to #008). First runtime camera permission. Tags history pairingMethod = qr. No transport/engine/protocol changes."

## User Scenarios & Testing *(mandatory)*

QR Connect is the second of Safe Send's four connection methods. It does not introduce a new
way for devices to talk — it is a faster, typo-free way to exchange the **same** 6-digit
rendezvous code that already pairs two devices (#003). The sender presents the code as a QR;
the receiver scans it instead of typing six digits. Everything after pairing (accept/reject,
transfer, save, history) is unchanged from #004/#005/#006.

### User Story 1 - Receiver scans the sender's QR to connect (Priority: P1)

A person receiving files opens **Nhận (Receive)**, taps **Quét mã QR**, points their camera at
the QR shown on the sender's device, and is connected automatically — no digits typed. They
land directly on the incoming-transfer accept/reject prompt.

**Why this priority**: This is the core value of the feature — eliminating manual code entry.
The sender already has a working code display from #003; the receiver's scan path is what makes
QR pairing actually usable. Without this story there is no QR connection.

**Independent Test**: With a sender already displaying a valid pairing code (any method of
showing it), open Receive → Quét mã QR → scan the code → confirm the device joins the same room
and reaches the accept/reject prompt, identical to the outcome of typing the code manually.

**Acceptance Scenarios**:

1. **Given** a sender is hosting with a live code and the receiver is on the Receive entry,
   **When** the receiver opens the QR scanner and a valid Safe Send QR enters the frame,
   **Then** the app joins that code's room and shows the incoming-transfer prompt without any
   typing.
2. **Given** the receiver has never granted camera access, **When** they open the QR scanner,
   **Then** the app requests camera permission with a clear explanation before the camera turns on.
3. **Given** the camera frame contains a QR that is not a Safe Send code (wrong scheme or
   unparseable), **When** it is detected, **Then** the app shows a gentle "not a Safe Send code"
   message and keeps scanning rather than aborting the flow.
4. **Given** the receiver scans a Safe Send QR whose code has already expired, **When** it is
   detected, **Then** the app surfaces an "expired code" message and lets the receiver try again
   (re-scan or switch to manual entry) instead of failing the screen.

---

### User Story 2 - Sender presents the connection as a QR (Priority: P1)

A person sending files reaches the **Kết nối (Connect)** hub and switches to the **QR** tab,
which shows a scannable QR for the current pairing code plus the human-readable digits beneath
it. They hold the screen up for the receiver to scan.

**Why this priority**: The receiver's scan story is meaningless without something valid to scan.
This story produces the QR. It is P1 alongside Story 1 — together they form the minimum viable
QR pairing.

**Independent Test**: Open Send → Connect hub → QR tab → confirm a QR renders that, when decoded
by any QR reader, yields `safesend://connect?v=1&code=<the live 6-digit code>`, and that the
visible digits below it match.

**Acceptance Scenarios**:

1. **Given** the sender is on the Connect hub, **When** they select the QR tab, **Then** a QR
   encoding the active pairing code is displayed together with the same code in readable digits.
2. **Given** the sender is viewing the QR tab, **When** the pairing code expires and a new code
   is issued, **Then** the displayed QR updates to encode the new code without the user leaving
   the tab.
3. **Given** the sender switches between the **Mã 6 số** and **QR** tabs (in either direction,
   repeatedly), **When** they do so, **Then** the pairing code stays the same, no new code is
   generated, and the connection in progress is not interrupted or restarted.

---

### User Story 3 - Scan a QR image from the photo library (Priority: P2)

A receiver who already has a screenshot or photo of a Safe Send QR (e.g. sent to them in a chat)
picks that image from their library inside the scanner instead of using the live camera.

**Why this priority**: Extends QR pairing to cases where the two devices aren't physically
together, and provides the primary fallback when the camera is unavailable or permission is
denied. Valuable but secondary to live scanning.

**Independent Test**: From the QR scanner, choose **an existing QR image** from the library →
confirm the app decodes the same `safesend://connect?v=1&code=…` payload and joins the room
exactly as a live scan would.

**Acceptance Scenarios**:

1. **Given** the receiver is in the QR scanner, **When** they choose to pick an image and select
   a photo containing a valid Safe Send QR, **Then** the app decodes it and joins the room as if
   it had been scanned live.
2. **Given** the receiver selects an image that contains no QR or a non-Safe-Send QR, **When** it
   is processed, **Then** the app shows a "no valid code found" message and remains on the
   scanner.
3. **Given** the receiver has denied camera permission, **When** they open the scanner, **Then**
   pick-from-photo is offered as a usable alternative so they can still pair.

---

### User Story 4 - Camera permission is handled gracefully (Priority: P2)

The first time Safe Send needs the camera, the person sees why it's needed and can grant, deny,
or change their mind later — and a denial never leaves them stuck.

**Why this priority**: This is the app's first runtime permission. Mishandling it (a dead black
screen, an un-recoverable denial) would make QR pairing feel broken even when the rest works.

**Independent Test**: Drive each permission state — first-ask, granted, denied, permanently
denied/restricted — and confirm each shows appropriate copy and an actionable next step (camera
on, retry, open Settings, or use pick-from-photo).

**Acceptance Scenarios**:

1. **Given** permission has never been asked, **When** the scanner opens, **Then** the system
   prompt appears with an app-provided reason, and on grant the camera preview starts.
2. **Given** permission was permanently denied, **When** the scanner opens, **Then** the app
   explains the camera is blocked and offers an **Open Settings** action plus the pick-from-photo
   alternative, instead of a blank preview.
3. **Given** the receiver granted permission earlier, **When** they reopen the scanner, **Then**
   the camera starts immediately with no repeat prompt.

---

### Edge Cases

- **Tab-switch mid-pairing**: switching Mã 6 số ↔ QR while a peer is joining must not drop or
  restart the session (covered by Story 2 #3).
- **Stale QR after expiry**: a receiver scans a QR whose code has since rotated → treated as an
  expired/invalid code with a retry path (Story 1 #4).
- **Malformed / foreign QR**: correct URI scheme but malformed query, or a completely unrelated
  QR → ignored with a gentle message; scanning continues (Story 1 #3).
- **Duplicate rapid detections**: the same QR detected many times per second must result in a
  single join attempt, not repeated joins.
- **Self-scan / wrong role**: a sender's own device scanning isn't a supported path; the scanner
  lives on the receive side only.
- **Backgrounding the scanner**: leaving the app or screen while the camera is live must release
  the camera and resume cleanly on return.
- **Permission revoked between sessions**: a previously granted permission later revoked in OS
  settings falls back to the denied handling on next open.
- **No camera hardware** (rare): pick-from-photo remains available.

## Clarifications

### Session 2026-06-25

- Q: Where does the receiver's QR scanner live? → A: A dedicated full-screen scanner page pushed from a "Quét mã QR" button on the receiver's code-entry panel (Screen 04); the Connect-hub QR tab is sender-only (receiver role shows no scanner tab).
- Q: Include low-light scan aids? → A: Both — a torch/flashlight toggle on the scanner and an automatic screen-brightness boost while the sender displays the QR (brightness restored on leave; no flashing, respecting accessibility/Reduce-Motion).

## Requirements *(mandatory)*

### Functional Requirements

**Sender — present QR**

- **FR-001**: The Connect hub MUST expose a **QR** tab alongside the existing **Mã 6 số** tab
  (the **Gần đây** tab remains stubbed for #009). This QR tab is **sender-only** — in the
  receiver role the Connect hub MUST NOT present a scanner tab (the receiver scans via the
  dedicated page in FR-009).
- **FR-002**: The QR tab MUST render a scannable QR encoding the device's active pairing code.
- **FR-003**: The QR tab MUST also display the same pairing code as human-readable digits so a
  peer can fall back to manual entry.
- **FR-004**: The QR and the 6-digit display MUST be two views of a **single** hosting session:
  switching tabs MUST NOT generate a new code, open a second signaling connection, or restart an
  in-progress pairing.
- **FR-005**: When the active code expires and a new code is issued while the QR tab is visible,
  the displayed QR MUST update to encode the new code.
- **FR-005a**: While the QR tab is showing a QR, the system MUST temporarily boost screen
  brightness so the code scans reliably, and MUST restore the previous brightness when the QR is
  no longer shown (tab left, screen dismissed, or app backgrounded). The boost MUST be a steady
  level change (no flashing) consistent with accessibility expectations.

**QR payload**

- **FR-006**: The encoded payload MUST be the URI `safesend://connect?v=1&code=<code>` where
  `<code>` is the 6-digit pairing code and `v=1` is the payload version.
- **FR-007**: The system MUST parse this payload back to a pairing code when scanning, accepting
  only the `safesend` scheme + `connect` target + a version it understands + a syntactically
  valid 6-digit code.
- **FR-008**: The payload MUST contain only the rendezvous code and version — no file data, no
  device/peer identity, no signaling endpoint.

**Receiver — scan QR**

- **FR-009**: The receiver's code-entry panel (Screen 04) MUST offer a **Quét mã QR** button
  that opens a **dedicated full-screen scanner page** (camera-based QR scanner). The scanner is
  reached only from this button, not as a Connect-hub tab.
- **FR-010**: On detecting a valid Safe Send QR, the system MUST join that code's room
  automatically and proceed to the incoming-transfer accept/reject prompt, with no digit entry.
- **FR-011**: The scanner MUST also let the user pick an existing image from their photo library
  and decode a Safe Send QR from it, joining the room identically to a live scan.
- **FR-012**: A scanned/imported payload that is not a valid Safe Send code (wrong scheme,
  unsupported version, malformed, or no QR found) MUST produce a non-blocking message and leave
  the user able to continue (keep scanning / re-pick / switch to manual entry) — it MUST NOT
  abort or error out the flow.
- **FR-013**: A scanned payload carrying an expired or already-consumed code MUST be surfaced as
  such with a retry path, reusing the same expiry/invalid-code handling as manual entry.
- **FR-014**: Repeated detections of the same QR MUST result in exactly one join attempt.

**Camera permission**

- **FR-015**: The system MUST request camera permission at the point the scanner is opened, with
  an app-provided rationale string (Vietnamese primary + English), including the required iOS
  usage-description.
- **FR-016**: The system MUST handle granted, denied, restricted, and permanently-denied states
  distinctly, and for a blocked camera MUST offer an **Open Settings** action and the
  pick-from-photo alternative rather than a non-functional preview.
- **FR-017**: The camera MUST be released when the scanner is dismissed or the app is
  backgrounded, and resume cleanly when reopened.
- **FR-017a**: The scanner MUST provide a torch/flashlight toggle for scanning in low light
  (shown only when the device supports it), defaulting to off.

**History & entry points**

- **FR-018**: A transfer paired via the QR path MUST be recorded with `pairingMethod = qr` for
  the device that used QR (the receiver that scanned; the sender presenting the QR), with no
  history schema change.
- **FR-019**: The Home **Quét QR** quick action MUST route into the receiver QR-scan entry.

**Cross-cutting (constitution)**

- **FR-020**: All user-facing copy MUST come from the localization resources (Vietnamese primary,
  English secondary); the pairing code and any numeric/code text MUST use the mono + tabular-nums
  typographic tokens.
- **FR-021**: All visual properties MUST come from the existing design tokens (no hardcoded
  colors); QR rendering and scanner chrome MUST respect the fixed light/dark palette.
- **FR-022**: Reduce-Motion settings MUST be respected (no jarring scanner/QR animation).
- **FR-023**: The QR (announcing the underlying code) and scan controls MUST carry accessibility
  labels.
- **FR-024**: Logs MUST carry only phase/error-type information — never the pairing code, the QR
  payload contents, or peer identifiers.

### Key Entities *(include if feature involves data)*

- **Pairing payload**: the versioned connection descriptor exchanged visually as a QR —
  attributes: payload version, 6-digit rendezvous code. It is a transient encoding of the
  existing pairing code, not new persisted data.
- **Transfer record (existing)**: gains no new fields; its existing `pairingMethod` attribute now
  takes the `qr` value when a transfer was paired via QR.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A receiver can go from opening Receive to the accept/reject prompt by scanning the
  sender's QR in under 10 seconds, entering zero digits.
- **SC-002**: 100% of QR codes produced by a sender on the QR tab decode to the live 6-digit code
  and successfully pair when scanned by a receiver.
- **SC-003**: Switching between the Mã 6 số and QR tabs any number of times during one pairing
  never changes the code or interrupts an in-progress connection (0 spurious reconnects / code
  regenerations).
- **SC-004**: Every non-Safe-Send or invalid QR is handled without the scan flow crashing or
  dead-ending — the user always has a clear next step (100% of invalid-input cases recoverable).
- **SC-005**: A user who denies camera permission can still complete pairing via pick-from-photo
  or manual code entry (no permission denial fully blocks connecting).
- **SC-006**: A QR-paired transfer appears in History tagged as QR for the device that used QR,
  100% of the time.

## Assumptions

- **Reuses the #003 rendezvous unchanged**: the 6-digit code is the rendezvous identifier and the
  signaling room is keyed directly by it; QR neither changes room keying nor adds a separate
  token. No changes to the WebRTC transport/engine (#002), the signaling protocol/frames, or the
  `takeTransport` ownership seam.
- **In-app reading only**: #007 produces and parses the `safesend://` payload only via the app's
  own camera/photo scanner. Making the OS treat that URI as a launchable deep link (Associated
  Domains / Android App Links / external URI handling) is **deferred to #008**, which will reuse
  this exact payload format.
- **Connect hub is extended, not duplicated**: the existing Connect page and pairing
  cubit/repository are reused; the QR tab shares the one hosting session rather than starting its
  own.
- **`pairingMethod` reflects the local UI path**: each device records the method it used; the two
  devices may legitimately differ (e.g. sender shows QR, receiver typed the code) and that is
  acceptable.
- **Scanner lives on the receive side**: there is no sender-side scanning in this scope.
- **New platform capabilities**: a QR rendering capability and a camera-scanning capability
  (covering camera permission + pick-from-photo) are introduced; the camera is the app's first
  runtime permission. Exact package selections + versions are resolved at planning time per
  Constitution XV (fetched from the package registry, never guessed).
- **Privacy promise preserved**: the QR carries connection metadata only (code + version), never
  file bytes or identity, consistent with "no intermediary server holds the data."
- **Out of scope**: share-link generation and external deep-linking (#008), nearby radar (#009),
  settings and real peer names (#010).
