# Feature Specification: Share Link

**Feature Branch**: `008-share-link`
**Created**: 2026-06-26
**Status**: Draft
**Input**: User description: "Spec #008 — Share Link: add a third connection method that lets a sender invite a receiver to pair via a shareable link (sent through any app — Messages, Zalo, email), instead of reading a 6-digit code or scanning a QR. Reuses the existing 6-digit signaling rendezvous unchanged. Sender shares the link from the Connect hub; receiver taps the link (app open or closed) and lands straight in the Receive flow with the room already joined. Custom-scheme `safesend://` deep link only — no universal/app links, no web landing fallback. Must handle both warm (app running) and cold (app launched by the link) start. Tags history pairingMethod = shareLink. No transport/engine/protocol changes."

## User Scenarios & Testing *(mandatory)*

Share Link is the third of Safe Send's four connection methods. Like QR (#007), it does not
introduce a new way for two devices to talk — it is another way to exchange the **same** 6-digit
rendezvous code that already pairs two devices (#003). Instead of showing the code on screen for
the peer to read or scan, the sender hands the peer a tappable link. The receiver taps it and is
dropped directly into the Receive flow with the room already joined. Everything after pairing
(accept/reject, transfer, save, history) is unchanged from #004/#005/#006.

The defining difference from QR is **distance**: the two people do not have to be physically next
to each other. The link travels through any messaging channel the sender already uses.

### User Story 1 - Receiver taps a shared link and lands in Receive (Priority: P1)

A person who has been sent a Safe Send invite link (in a chat, message, or email) taps it. Safe
Send opens — whether or not it was already running — joins the sender's pairing session, and
shows the incoming-transfer accept/reject prompt. No code is typed, nothing is scanned.

**Why this priority**: This is the core value of the feature — turning a received link into an
active connection with one tap, across a distance. Without this story there is no share-link
pairing.

**Independent Test**: With a sender hosting a live pairing code, construct the invite link for
that code, then open it on the receiver device both while the app is running and from a fully
closed app — confirm both paths join the same room and reach the accept/reject prompt, identical
to the outcome of typing the code manually.

**Acceptance Scenarios**:

1. **Given** a sender is hosting with a live code and the receiver's app is **already open**,
   **When** the receiver taps the invite link, **Then** the app navigates to the Receive flow,
   joins that code's room, and shows the incoming-transfer prompt without any typing.
2. **Given** the receiver's app is **fully closed**, **When** they tap the invite link, **Then**
   the app launches, finishes startup, joins that code's room, and arrives at the incoming-transfer
   prompt (the link is not lost during launch).
3. **Given** the receiver taps a link whose code has already **expired**, **When** the app
   processes it, **Then** it surfaces an "expired code" toast and lands the receiver on Home (where
   they can start another method), instead of a blank or stuck screen.
4. **Given** the receiver taps a link that is **malformed or not a Safe Send invite** (wrong
   scheme/target, unsupported version, missing/invalid code), **When** the app processes it,
   **Then** it shows a gentle "invalid invite" toast and lands on Home rather than crashing or
   dead-ending.

---

### User Story 2 - Sender shares an invite link from the Connect hub (Priority: P1)

A person sending files reaches the **Kết nối (Connect)** hub and chooses **Chia sẻ link mời**.
The system hands the link to the OS share sheet so they can send it through whatever app they
like. The link represents the pairing session that is already open.

**Why this priority**: The receiver's tap story is meaningless without a valid link to tap. This
story produces and distributes the link. It is P1 alongside Story 1 — together they form the
minimum viable share-link pairing.

**Independent Test**: Open Send → Connect hub → tap **Chia sẻ link mời** → confirm the system
share sheet opens carrying a link that, when parsed, yields the live 6-digit code, and that no new
code or second connection was created by sharing.

**Acceptance Scenarios**:

1. **Given** the sender is on the Connect hub with a live pairing code, **When** they tap
   **Chia sẻ link mời**, **Then** the OS share sheet opens carrying an invite link that encodes the
   active code, ready to send through any app.
2. **Given** the sender shares the link and then keeps hosting, **When** they switch between the
   **Mã 6 số**, **QR**, and share-link actions (in any order, repeatedly), **Then** the pairing
   code stays the same, no new code is generated, no second signaling connection is opened, and the
   in-progress pairing is not interrupted.
3. **Given** the pairing code expires and a new code is issued while the sender is still on the
   Connect hub, **When** they share the link again, **Then** the newly shared link encodes the new
   code (a previously shared link reflects the now-expired code and is handled per Story 1 #3).

---

### User Story 3 - Tapping an invite while busy is handled safely (Priority: P2)

A receiver who is already in the middle of something in Safe Send — most importantly an
in-progress transfer — taps a new invite link. The app must not silently destroy what they were
doing.

**Why this priority**: A link can arrive at any moment, including during an active transfer.
Mishandling it (silently dropping the running transfer, or ignoring the link with no feedback)
would feel broken. Secondary to the core tap-to-connect path because it is an interruption case,
not the main journey.

**Independent Test**: Start a transfer (or be on any active Safe Send screen), then open an invite
link — confirm the app follows the defined interruption rule (see FR-014) and never silently
discards an active transfer.

**Acceptance Scenarios**:

1. **Given** the receiver is in an **active transfer**, **When** an invite link is opened, **Then**
   the app asks for confirmation before leaving the current transfer to join the new session, and
   honoring the prompt either keeps the current transfer or switches deliberately — it never
   abandons the running transfer with no acknowledgement.
2. **Given** the receiver is on a non-transfer Safe Send screen (e.g. Home, History), **When** an
   invite link is opened, **Then** the app navigates into the Receive flow for that invite without
   a confirmation prompt.

---

### Edge Cases

- **Cold-start race**: a link launches the app before navigation/services are ready — the invite
  must be buffered and acted on once the app is ready, never dropped (Story 1 #2).
- **Self-invite on the same device**: the sender taps their own invite link on the host device →
  treated as a not-supported path with a gentle message, not a self-connection attempt (FR-015).
- **Stale link after expiry**: a link tapped after its code has rotated/expired → handled as an
  expired/invalid code, landing on Home with a toast (Story 1 #3).
- **Malformed / foreign link**: correct scheme but malformed query, an unsupported version, or a
  completely unrelated `safesend://` URI → gentle "invalid invite" toast, landing on Home (Story 1
  #4).
- **Multiple links in quick succession**: two invite links opened back-to-back → only the most
  recent is acted on; there is never more than one join attempt in flight.
- **Link opened during active transfer**: covered by Story 3 #1 (confirm before leaving).
- **Link arrives while pairing already in progress** (receiver mid-connect on another method) →
  resolved like the active-screen interruption rule, never two simultaneous join attempts.
- **App backgrounded then resumed by a link**: warm-start handling delivers the invite on resume
  (Story 1 #1).

## Clarifications

### Session 2026-06-26

- Q: When an invite link is opened during an active transfer, what should happen? → A: Show a confirm dialog — on confirm, leave the current transfer and join the new invite; on cancel, stay in the current transfer and discard the invite.
- Q: When the sender taps their own invite link on the device that is hosting it, how should the app respond? → A: Detect that the code matches the device's own active hosting session and show a gentle "this is your own invite link" message; do not attempt to join.
- Q: After an invalid or expired invite link, where should the user land (warm and cold start)? → A: Always land on Home, surfacing the failure as a toast.
- Q: On the sender side, when is a transfer recorded with `pairingMethod = shareLink`? → A: When the sender's last actively-used pairing presentation was the share-link action (last-action-wins among Mã 6 số / QR / Chia sẻ link mời), mirroring #007's QR behavior. Each device records its own local UI path, so the two devices may legitimately differ.

## Requirements *(mandatory)*

### Functional Requirements

**Sender — share the invite link**

- **FR-001**: The Connect hub MUST expose a **Chia sẻ link mời** action that opens the OS share
  sheet carrying the invite link for the active pairing session. (This replaces the placeholder
  stubbed in #004.)
- **FR-002**: The shared invite link MUST encode the device's **active pairing code** so that a
  peer who opens it joins the same rendezvous room.
- **FR-003**: Sharing the link MUST be a third view of the **single** hosting session: invoking it
  MUST NOT generate a new code, open a second signaling connection, or restart an in-progress
  pairing — consistent with the Mã 6 số and QR views (#003/#007).
- **FR-004**: When the active code expires and a new code is issued, a link shared afterward MUST
  encode the new code.
- **FR-005**: The share action MUST accompany the link with friendly, localized invite text
  (Vietnamese primary + English) — e.g. an invitation to receive files via Safe Send — so the
  recipient understands what the link is.

**Invite link payload**

- **FR-006**: The invite link MUST use the custom application scheme in the form
  `safesend://connect?v=1&code=<code>`, where `<code>` is the 6-digit pairing code and `v=1` is the
  payload version — the same versioned payload format introduced in #007.
- **FR-007**: The system MUST parse this link back to a pairing code, accepting only the `safesend`
  scheme + `connect` target + a version it understands + a syntactically valid 6-digit code; any
  deviation MUST be rejected as an invalid invite.
- **FR-008**: The link payload MUST contain only the rendezvous code and version — no file data, no
  device/peer identity, no signaling endpoint.

**Receiver — open the invite link**

- **FR-009**: The application MUST register the `safesend://` scheme with the operating system on
  both iOS and Android, for both the **dev** and **prod** flavors, so that tapping an invite link
  in another app opens Safe Send.
- **FR-010**: The system MUST handle an invite link opened while the app is already running
  (**warm start**) and an invite link that launches the app from a not-running state (**cold
  start**), with the same end result.
- **FR-011**: On a cold start, the invite MUST be retained through application startup and acted on
  once the app is ready; it MUST NOT be lost because services or navigation were not yet
  initialized.
- **FR-012**: On opening a valid invite link, the system MUST navigate into the Receive flow, join
  that code's room automatically, and proceed to the incoming-transfer accept/reject prompt, with
  no code entry.
- **FR-013**: An invite link that is not a valid Safe Send invite (wrong scheme/target, unsupported
  version, malformed, or invalid/expired code) MUST land the user on **Home** and surface the
  failure as a non-blocking toast (same destination for warm and cold start) — it MUST NOT crash,
  show a blank screen, or dead-end the app.
- **FR-014**: If an invite link is opened while a **transfer is in progress**, the system MUST show
  a confirmation dialog before leaving the current transfer: on **confirm**, it leaves the current
  transfer and joins the new invite; on **cancel**, it stays in the current transfer and discards
  the invite. It MUST NOT silently abandon an active transfer. Opening an invite from a
  non-transfer screen proceeds without a confirmation prompt.
- **FR-015**: When an opened invite link's code matches the device's **own** active hosting session
  (self-invite on the host device), the system MUST detect this and show a gentle "this is your own
  invite link" message; it MUST NOT attempt to join.
- **FR-016**: If multiple invite links are opened in quick succession, the system MUST act on only
  the most recent and MUST NOT issue more than one join attempt at a time.

**History & entry points**

- **FR-017**: A transfer paired via the share-link path MUST be recorded with
  `pairingMethod = shareLink`, with no history schema change, for **each device that used the link**:
  the **receiver** that opened the link, and the **sender** whose last actively-used pairing
  presentation was the **Chia sẻ link mời** action (last-action-wins among Mã 6 số / QR / share —
  mirroring #007's QR sender). Each device records its own local UI path; the two devices may
  legitimately record different methods.

**Cross-cutting (constitution)**

- **FR-018**: All user-facing copy (invite text, messages, actions) MUST come from the localization
  resources (Vietnamese primary, English secondary); the pairing code and any numeric/code text
  MUST use the mono + tabular-nums typographic tokens.
- **FR-019**: All visual properties MUST come from the existing design tokens (no hardcoded
  colors); any new UI MUST respect the fixed light/dark palette.
- **FR-020**: All user-facing messages MUST be surfaced through the app's standard toast mechanism
  (never a raw platform messenger), and navigation MUST go through the app's route constants.
- **FR-021**: Logs MUST carry only phase/error-type information — never the pairing code, the link
  payload contents, or peer identifiers.

### Key Entities *(include if feature involves data)*

- **Invite link (pairing payload)**: the versioned connection descriptor exchanged as a tappable
  link — attributes: payload version, 6-digit rendezvous code. It is a transient encoding of the
  existing pairing code (the same payload introduced for QR in #007), not new persisted data.
- **Transfer record (existing)**: gains no new fields; its existing `pairingMethod` attribute now
  takes the `shareLink` value when a transfer was paired via the link path.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A receiver can go from tapping an invite link to the accept/reject prompt in under 10
  seconds, entering zero digits, on both a warm start and a cold (app-closed) start.
- **SC-002**: 100% of invite links produced by a sender encode the live 6-digit code and
  successfully pair when opened by a receiver whose code is still valid.
- **SC-003**: Switching between the Mã 6 số, QR, and share-link views during one pairing never
  changes the code or interrupts an in-progress connection (0 spurious reconnects / code
  regenerations).
- **SC-004**: 100% of invalid invite links (wrong scheme, unsupported version, malformed, expired
  code) are handled without the app crashing or dead-ending — the user always lands on a safe
  screen with a clear next step.
- **SC-005**: 0 active transfers are silently abandoned by an incoming invite link — every
  interruption during a transfer is acknowledged via a confirmation prompt.
- **SC-006**: A share-link-paired transfer appears in History tagged as share-link for the device
  that used the link, 100% of the time.

## Assumptions

- **Reuses the #003 rendezvous unchanged**: the 6-digit code is the rendezvous identifier and the
  signaling room is keyed directly by it; the invite link neither changes room keying nor adds a
  separate token. No changes to the WebRTC transport/engine (#002), the signaling protocol/frames,
  or the `takeTransport` ownership seam.
- **Reuses the #007 payload format**: the `safesend://connect?v=1&code=<code>` payload and its
  build/parse logic introduced for QR are reused verbatim; #008 adds OS-level deep-link handling
  (registration + cold/warm delivery) on top of that existing payload, rather than defining a new
  format.
- **Custom scheme only**: pairing links use the application's own `safesend://` scheme. Universal
  links / Android App Links over an HTTPS domain are **out of scope** — no domain, no
  apple-app-site-association / assetlinks.json hosting.
- **No web fallback**: there is no web landing page and no App Store / Play Store redirect when the
  app is not installed. A link tapped on a device without Safe Send installed does nothing special
  in this scope (deferred to a later release once a domain exists).
- **Connect hub is extended, not duplicated**: the existing Connect page and pairing
  cubit/repository are reused; the share-link action shares the one hosting session rather than
  starting its own.
- **`pairingMethod` reflects the local UI path**: each device records the method it used; the two
  devices may legitimately differ (e.g. sender shared a link, receiver typed the code) and that is
  acceptable.
- **Privacy promise preserved**: the link carries connection metadata only (code + version), never
  file bytes or identity, consistent with "no intermediary server holds the data."
- **New platform capabilities**: an OS deep-link handling capability (scheme registration + cold/
  warm link delivery) and a system-share capability are introduced. Exact package selections +
  versions are resolved at planning time per Constitution XV (fetched from the package registry,
  never guessed).
- **Out of scope**: universal/app links and web fallback (later release), nearby radar (#009),
  settings and real peer names (#010).
