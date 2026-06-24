# Feature Specification: Signaling Server & 6-Digit Key Pairing

**Feature Branch**: `003-signaling-6digit`
**Created**: 2026-06-24
**Status**: Draft
**Input**: User description: "Spec #003 — Signaling Server + 6-Digit Key Pairing. Add the rendezvous layer so two real devices can find each other and exchange WebRTC handshake metadata, letting the #002 transfer engine open a real peer-to-peer DataChannel. A lightweight, stateless, self-hostable signaling relay introduces exactly two peers per room and never sees file bytes. The sender generates a short-lived 6-digit code; the receiver enters it to join the same room. Upholds the core promise: no intermediary server holds the data."

## Overview

Spec #002 delivered the WebRTC transfer engine, but it can only run against an in-process loopback — two real devices behind different networks have no way to discover one another or exchange the connection-handshake metadata (SDP offer/answer and ICE candidates) that WebRTC requires. This feature adds the missing **rendezvous layer**: a lightweight signaling service plus a 6-digit pairing code that lets two phones agree on a connection. Once the handshake completes, the existing #002 engine opens a direct, encrypted peer-to-peer channel and the signaling service steps out of the way.

This is blocking foundation work for every transfer feature (#004 Send, #005 Receive). It ships the **engine and pairing logic only** — the user-facing Connect / Receive screens are built in #004/#005. It is validated by automated integration tests; any UI here is at most a throwaway debug screen.

**Core promise upheld**: the signaling service relays only connection metadata and a short-lived code. It MUST NEVER see, store, or relay file bytes — those always flow peer-to-peer over the WebRTC channel from #002.

## Clarifications

### Session 2026-06-24

- Q: How should the service defend the join path against code guessing / abuse (open relay)? → A: Per-connection rate limiting on join attempts (cap consecutive invalid codes + throttle); no auth in v1.
- Q: What surface enables the deferred manual two-device smoke test before #004/#005 exist? → A: A minimal dev-flavor-only debug screen (generate code / enter code / show connection state), excluded from prod builds.
- Q: What is the exact 6-digit code format/range? → A: Full range 000000–999999 (1,000,000 codes), always exactly 6 digits with leading zeros preserved.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pair two devices with a 6-digit code and open a direct connection (Priority: P1)

A person who wants to send files generates a 6-digit code on their device. A second person enters that code on their device. Behind the scenes the two devices exchange the connection handshake through the signaling service, and a direct encrypted peer-to-peer channel opens between them — ready for a transfer. This is the entire reason the feature exists; without it no real two-device transfer is possible.

**Why this priority**: This is the happy-path rendezvous. It unblocks the MVP transfer loop (#004/#005). Every other scenario is a variation or failure mode of this one.

**Independent Test**: Run the signaling service in-process with two independent clients. Client A requests a code; client B joins with that code; assert both peers complete the SDP/ICE exchange and a peer-to-peer data channel reaches the "open" state — with zero file bytes ever passing through the signaling service.

**Acceptance Scenarios**:

1. **Given** the signaling service is running, **When** the sending device requests a pairing code, **Then** it receives a unique 6-digit numeric code bound to a private room with a visible time-to-live.
2. **Given** a sender holds a valid, unexpired code, **When** the receiving device submits that exact code, **Then** both devices are joined to the same room and each is notified that its peer has arrived.
3. **Given** both peers are in the same room, **When** the connection handshake metadata is exchanged through the service, **Then** the metadata is relayed faithfully between exactly the two peers and the direct peer-to-peer channel reaches the open/connected state.
4. **Given** the peer-to-peer channel is open, **When** the transfer engine begins moving data, **Then** all data flows directly device-to-device and none of it passes through the signaling service.

---

### User Story 2 - Pairing fails clearly and safely (Priority: P2)

When a code can't be used — it expired, was mistyped, or the room is already full — the person trying to join gets a clear, specific reason rather than a silent hang, and can recover (regenerate or re-enter).

**Why this priority**: A rendezvous that fails opaquely is unusable in the field. Clear failure handling is required before #004/#005 can present trustworthy UI, but it sits on top of the P1 happy path.

**Independent Test**: Drive each failure case against the in-process service and assert the joining client receives the correct, distinct outcome (expired vs. invalid vs. room-full) and the room state stays consistent.

**Acceptance Scenarios**:

1. **Given** a code whose time-to-live has elapsed, **When** the receiver submits it, **Then** the receiver is told the code has expired and no room join occurs; the sender must generate a new code to continue.
2. **Given** a code that was never issued or was mistyped, **When** the receiver submits it, **Then** the receiver is told the code is invalid and no room join occurs.
3. **Given** a room that already contains its two peers, **When** a third device submits the same code, **Then** the third device is rejected with a room-full reason and the existing pair is undisturbed.
4. **Given** a sender has generated a code, **When** the sender requests another before pairing completes, **Then** the previous code is invalidated and only the newest code is usable (one active code per sender at a time).

---

### User Story 3 - Connections clean up and the service stays stateless (Priority: P3)

If either device drops mid-handshake, closes the app, or the code simply expires unused, the signaling service discards the room and the surviving peer is informed. The service keeps nothing after a session ends.

**Why this priority**: Resource cleanup and ephemerality protect both the privacy promise and the service's ability to run indefinitely on minimal resources. It is essential for production but is a robustness layer over the core pairing.

**Independent Test**: Establish a room, forcibly disconnect one peer, and assert the surviving peer is notified, the room is removed, and a follow-up attempt to use the same code is rejected. Assert no room or code state remains after both peers leave.

**Acceptance Scenarios**:

1. **Given** two peers in a room, **When** one peer disconnects, **Then** the surviving peer is notified its peer left and the room is torn down.
2. **Given** a code was generated but never used, **When** its time-to-live elapses, **Then** the code and its room are discarded automatically and the code can no longer be joined.
3. **Given** a completed or abandoned session, **When** both peers have left, **Then** the service retains no record of the room, the code, or any exchanged metadata.

---

### Edge Cases

- **Code reuse after expiry**: an expired code's digits may later be re-issued to a different sender; a stale entry must never join the wrong room.
- **Race on join**: two receivers submit the same valid code near-simultaneously — exactly one becomes the second peer; the other gets room-full.
- **Sender never returns**: receiver joins but the sender has already disconnected — the receiver is told its peer is gone rather than waiting indefinitely.
- **Service restart**: in-memory rooms vanish on restart; outstanding codes simply stop working (treated as invalid) — acceptable because codes are short-lived and there is no persistence to recover.
- **Malformed or oversized signaling message**: the service rejects/ignores anything that is not a recognized handshake-metadata message and never forwards unexpected payloads (defense against using signaling to smuggle data).
- **Network unavailable when generating/entering a code**: the requesting device surfaces a connection error rather than a stuck state.
- **Endpoint differs per environment**: dev and prod point at different signaling endpoints; a build must connect to the endpoint configured for its environment.

## Requirements *(mandatory)*

### Functional Requirements

**Pairing code**

- **FR-001**: The system MUST let a sending device obtain a pairing code that uniquely identifies a private session.
- **FR-002**: Each pairing code MUST be a numeric code spanning the full range `000000`–`999999` (1,000,000 possible codes), always represented, displayed, and entered as exactly 6 digits with leading zeros preserved.
- **FR-003**: Each pairing code MUST be unique among all currently-active codes; on collision a different code MUST be issued.
- **FR-004**: Each pairing code MUST expire 5 minutes after issuance, after which it can no longer be used to join.
- **FR-005**: The remaining validity (time-to-live) of an active code MUST be available to the sending device so a countdown can be shown.
- **FR-006**: A sender MUST have at most one active code at a time; generating a new code MUST invalidate the previous one.

**Rendezvous & relay**

- **FR-007**: A receiving device MUST be able to join a session by submitting a valid, unexpired pairing code.
- **FR-008**: Each session MUST admit exactly two participants (one sender, one receiver); a further join attempt MUST be rejected as room-full.
- **FR-009**: When the second participant joins, each participant MUST be notified that its peer is present.
- **FR-010**: The system MUST relay connection-handshake metadata (session description offer/answer and connectivity candidates) between exactly the two participants of a session, faithfully and in order, and to no one else.
- **FR-011**: The relay MUST carry only connection-handshake metadata and pairing-control messages; it MUST reject or ignore any unrecognized or non-conforming message and MUST NOT relay file content of any kind.
- **FR-011a**: The service MUST rate-limit join attempts per connection — capping consecutive invalid-code submissions and throttling repeated attempts — so the 6-digit code space cannot be feasibly enumerated; no user authentication is required in v1.
- **FR-012**: The client-to-service message protocol MUST be explicitly defined and versioned, covering at minimum: request-code, join (code + role), peer-present, room-full, code-expired, invalid-code, relay session-description, relay connectivity-candidate, and peer-left. Each message's purpose and required fields MUST be documented.

**Lifecycle & statelessness**

- **FR-013**: A session and its code MUST be discarded automatically when its code expires unused, when either participant disconnects, or when both participants leave.
- **FR-014**: When one participant disconnects, the surviving participant MUST be notified that its peer has left.
- **FR-015**: The signaling service MUST hold all session state in memory only, with no persistence to durable storage, and MUST retain nothing after a session ends.
- **FR-016**: The signaling service MUST be self-hostable and accompanied by documentation describing how to run it.

**Client integration**

- **FR-017**: The app MUST drive the rendezvous through the existing transfer-engine signaling abstraction (from #002) so the engine works unchanged; the new network path MUST be a drop-in alternative to the existing in-process test path.
- **FR-018**: The app MUST be configured with connection-helper (STUN) settings so devices on different networks can establish a direct connection, using freely available public helpers by default.
- **FR-019**: The app MUST expose a documented, configurable relay-fallback (TURN) hook for the case where a direct connection cannot be established; this hook MUST NOT be backed by a running relay in this feature, and where it appears it MUST be documented as carrying only encrypted, non-persisted traffic.
- **FR-020**: The signaling endpoint and connection-helper configuration MUST be configurable per environment (dev / prod).
- **FR-021**: The pairing capabilities (generate code, enter code, observe connection lifecycle state) MUST be exposed in a form the later Send (#004) and Receive (#005) screens can consume without rework.
- **FR-021a**: A minimal debug surface MUST be provided to exercise the pairing flow manually (generate code, enter code, observe connection lifecycle state) for the deferred two-device smoke test. It MUST be available only in the dev flavor and MUST NOT appear in prod builds.

**Privacy & quality**

- **FR-022**: Logs and diagnostics — on both client and service — MUST contain only connection phase and error type; they MUST NOT contain file bytes, file metadata, participant identifiers, network addresses, or handshake-metadata payloads.
- **FR-023**: All user-facing messages introduced by this feature (e.g. code expired, invalid code) MUST be provided in Vietnamese as the primary language with English available.

### Key Entities

- **Pairing Code**: a short-lived 6-digit numeric value that maps to exactly one session; attributes — the digits, issue time, expiry time (issue + 5 min), and the role that created it (sender).
- **Session (Room)**: an ephemeral rendezvous holding at most two participants identified by a pairing code; attributes — the bound code, current participants, lifecycle state; exists only in memory and only until it ends.
- **Participant**: one of the two devices in a session, distinguished by role (sender / receiver); the conduit through which handshake metadata is relayed.
- **Signaling Message**: a versioned, typed control or relay message exchanged between a device and the service (e.g. request-code, join, peer-present, room-full, code-expired, invalid-code, relay session-description, relay connectivity-candidate, peer-left).
- **Connection Configuration**: the per-environment settings a device uses to reach the signaling service and to establish connectivity (signaling endpoint, connection-helper/STUN settings, optional relay-fallback/TURN hook).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Two independent devices that exchange a valid 6-digit code establish a direct peer-to-peer connection ready for transfer, with no manual configuration beyond reading and typing the code.
- **SC-002**: Across the full pairing flow, **zero** file bytes pass through the signaling service — verified by inspecting everything the service handles.
- **SC-003**: Every pairing failure (expired code, invalid code, room-full, peer-left) produces a distinct, specific outcome the joining device can act on — no silent hangs.
- **SC-004**: An unused code becomes unusable exactly at its 5-minute expiry, and the associated session leaves no residue in the service afterward.
- **SC-005**: After any session ends (completed, abandoned, or disconnected), the signaling service holds no record of the code, session, or any relayed metadata.
- **SC-006**: The pairing + handshake loop — including the success path, all failure paths, code expiry, collision re-issue, room-full rejection, and mid-handshake disconnect — is covered by automated tests that run the real signaling service in-process with two real clients, with no physical devices or external server required.
- **SC-007**: A new developer can start the signaling service locally and run the full test suite using only the in-repo documentation.
- **SC-008**: All project quality gates pass: static analysis reports zero issues across app and service code, the full test suite passes, and formatting is clean.

## Assumptions

- **Sender generates the code** (confirmed in pre-spec alignment): the sending device issues the 6-digit code and the receiving device enters it. This matches the "share a file, show a code" mental model.
- **Code parameters** (confirmed): full `000000`–`999999` range with leading zeros preserved, 5-minute time-to-live, one active code per sender, regenerate on collision, per-connection join rate limiting.
- **Signaling technology** (confirmed direction): a lightweight in-repo service that reuses the project's primary language and shares protocol definitions with the app; it runs on localhost for development and LAN testing in this feature, with public-host deployment deferred to a later spec.
- **Connection helpers**: freely available public STUN servers are sufficient for the common case; a relay (TURN) fallback is wired as a documented hook only and is not stood up here (deferred to #011 Polish & Release).
- **No production UI in scope**: the Connect "Mã 6 số" screen (#004) and Receive screen (#005) are out of scope. Validation is via integration tests; a minimal **dev-flavor-only** debug screen (FR-021a) is the single permitted in-app surface, solely to enable the deferred manual two-device smoke.
- **Reuse, don't fork**: this feature plugs into the existing #002 transfer engine and its signaling abstraction; it does not modify or replace the transport.
- **Two-physical-device smoke test** over a real network (real NAT traversal, public host, real throughput) is an explicitly **deferred manual task**, tracked in the tasks banner like prior transfer specs — it cannot be validated in CI.
- **Platform targets unchanged**: iOS 13+ / Android 8 (API 26)+.
- **One active pairing per device at a time** is assumed sufficient for v1; concurrent multi-session pairing from a single device is out of scope.

## Out of Scope

- The user-facing Connect / "Mã 6 số" UI (#004) and the Receive UI (#005); only throwaway debug surfaces, if any, here.
- QR, share-link, and nearby-radar pairing methods (#007 / #008 / #009) — they will reuse this same rendezvous later.
- A production-deployed signaling service and a running relay (TURN) server (#011).
- File selection, transfer history/persistence, or anything that touches file bytes.
- Resuming or reconnecting an interrupted session (post-v1.0).

## Dependencies

- **#002 WebRTC Transport & Transfer Protocol Core** — provides the transfer engine and the signaling abstraction this feature implements; must remain unchanged.
- **#001 Project Foundation** — provides per-environment configuration, logging discipline, localization, and DI used here.
