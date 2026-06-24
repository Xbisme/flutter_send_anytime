# Feature Specification: WebRTC Transport & Transfer Protocol Core

**Feature Branch**: `002-webrtc-transport-core`  
**Created**: 2026-06-24  
**Status**: Draft  
**Input**: User description: "WebRTC Transport & Transfer Protocol Core — the engine that moves files directly between two devices, with NO UI and NO real signaling server."

## Overview

This feature is the **transport engine** at the heart of Safe Send: the component that actually moves file bytes directly from one device to another over an encrypted peer-to-peer channel, with no intermediary server ever holding the data. It has **no user interface** and does **not** include the real signaling server or any pairing method — those are delivered by later features that plug into this engine.

Because a peer-to-peer transfer engine is normally impossible to test without two physical devices and a live server, this feature also delivers a **pluggable signaling abstraction** with an **in-process loopback implementation**, so the entire engine can be exercised end-to-end by automated tests on a single machine.

The "users" of this feature are the downstream Send (#004) and Receive (#005) flows that consume the engine, and ultimately the end user whose files arrive intact, privately, and without size limits. Acceptance is framed around the observable behavior of a transfer rather than any screen.

## Clarifications

### Session 2026-06-24

- Q: Does the #002 protocol include a receiver accept/reject step for the manifest, or is accept/reject deferred to #005? → A: Include it now — the protocol has an explicit manifest accept/reject step; the engine exposes a decision hook (loopback tests auto-accept), and a rejection surfaces as `transferRejected`. #005 only wires UI to the existing hook.
- Q: If one file in a multi-file session fails (integrity / read / write), does the session abort or continue with the remaining files? → A: Fail-fast — any file failure transitions the whole session to `failed`, remaining files are not transferred, and partial artifacts are cleaned up.
- Q: How does the receiver handle a destination filename that already exists (or two files in one session sharing a name)? → A: Auto-rename, never overwrite — append a unique suffix (e.g. `name (1).ext`) so an existing file is never lost.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Single-file direct transfer, verified intact (Priority: P1)

Two engine instances (a sender and a receiver) connect to each other through a pluggable signaling channel and transfer one file directly. The file is read from disk in pieces on the sender, streamed across the direct encrypted channel, written to disk in pieces on the receiver, verified against its integrity hash, and only then placed at its final destination. Both sides observe the transfer move through a predictable sequence of states ending in "done".

**Why this priority**: This is the irreducible core of the product — a file moving directly between two peers and arriving provably intact. Every later pairing method and transfer screen is just a different way to reach this exact path. Without it, nothing else in the roadmap can function.

**Independent Test**: Using the in-process loopback signaling channel, connect two engine instances, send one temporary file, and assert: the received file is byte-identical to the source, its integrity check passes, the final file exists only at the intended destination, and both engines report the transfer state sequence `idle → connecting → handshaking → transferring → done`.

**Acceptance Scenarios**:

1. **Given** two engines connected over the loopback signaling channel, **When** the sender transfers one file referenced by a disk path, **Then** the receiver writes a byte-identical copy to its destination and both engines end in state `done`.
2. **Given** a transfer in progress, **When** bytes are flowing, **Then** both engines emit per-file and overall byte-progress updates that increase monotonically and reach 100% on completion.
3. **Given** a completed transfer, **When** the receiver finalizes the file, **Then** the file's computed integrity hash matches the sender's declared hash before the file is marked complete.
4. **Given** a completed or terminated transfer, **When** the engine tears down, **Then** the peer connection is closed and all file handles and transient resources are released.

---

### User Story 2 - Multi-file session as a single unit (Priority: P2)

A sender selects several files to send to one receiver. The engine describes the whole batch in a single session manifest (each file's name, size, type, and the total count), then transfers the files sequentially — one fully before the next — reporting both per-file progress and overall session progress, and completing only when every file has arrived and been verified.

**Why this priority**: Real transfers are usually more than one file. Batching them into one verified session (rather than N disconnected transfers) is how the product presents a coherent "send these files" experience and how History (#006) later records a transfer. It depends on the single-file path from US1.

**Independent Test**: Over the loopback channel, send a batch of multiple temporary files of differing sizes; assert each is received byte-identical and integrity-verified, files complete in order, overall progress accounts for all bytes across all files, and the session ends in `done` only after the last file is verified.

**Acceptance Scenarios**:

1. **Given** a session manifest listing multiple files, **When** the session runs, **Then** files transfer one at a time in the manifest order and each is integrity-verified before the next begins.
2. **Given** a multi-file session, **When** progress is observed, **Then** overall progress reflects total bytes across all files while per-file progress resets per file.
3. **Given** a multi-file session, **When** the last file is verified, **Then** the session — and only then the session — reports `done`.
4. **Given** a multi-file session, **When** any one file fails to verify or write, **Then** the whole session transitions to `failed`, no further files are transferred, and no partial files remain at the destination.

---

### User Story 3 - Cancel and clean teardown from either side (Priority: P2)

Either the sender or the receiver can cancel an in-progress transfer at any time. The cancellation is honored promptly on both ends: the peer connection is torn down, file handles are released, no partial file is left at the destination, and both engines settle into a `cancelled` terminal state.

**Why this priority**: Transfers are routinely abandoned (wrong file, wrong recipient, taking too long). A cancel that leaves a half-written file or a leaked connection is a correctness and privacy defect. It builds directly on US1/US2.

**Independent Test**: Start a transfer over loopback, trigger cancel from the sender in one run and from the receiver in another; assert both engines reach `cancelled`, the connection is closed, no file remains at the final destination, and any temporary/quarantine artifacts are removed.

**Acceptance Scenarios**:

1. **Given** a transfer in `transferring`, **When** the sender cancels, **Then** both engines stop promptly, reach `cancelled`, and the receiver leaves no file at the final destination.
2. **Given** a transfer in `transferring`, **When** the receiver cancels, **Then** both engines stop promptly, reach `cancelled`, and the sender releases its file handles.
3. **Given** any cancellation, **When** teardown completes, **Then** no temporary/quarantine files for the cancelled transfer remain on disk.

---

### User Story 4 - Failures are detected, named, and leave no corrupt artifact (Priority: P3)

When something goes wrong — a file arrives corrupted, the peer disconnects, the connection cannot be established, or a malformed protocol/manifest message is received — the engine detects it, surfaces an explicit named failure (not a crash and not an indefinite hang), and never presents a corrupt or truncated file as complete.

**Why this priority**: P2P transfer fails in many ordinary ways. Turning each into a clear, named, retryable outcome is what lets the Send/Receive UIs show actionable messages and what keeps a flaky link from corrupting data. It hardens the paths from US1–US3.

**Independent Test**: Over loopback, inject (a) a corrupted chunk, (b) a mid-transfer peer disconnect, (c) a malformed manifest; assert each yields the corresponding named failure, the engine settles in `failed` without hanging, and in the corruption case no file is left at the destination.

**Acceptance Scenarios**:

1. **Given** a received file whose content does not match its declared integrity hash, **When** verification runs, **Then** the file fails with an integrity-failure outcome, is not placed at the destination, and the failure is retryable.
2. **Given** an active transfer, **When** the peer disconnects unexpectedly, **Then** both engines detect the loss within a bounded time and report a connection-lost failure rather than hanging.
3. **Given** an incoming malformed or unexpected protocol/manifest message, **When** it is received, **Then** the engine rejects it with a named failure and does not crash.
4. **Given** a connection that cannot be established, **When** negotiation fails, **Then** the engine reports a peer-unreachable / negotiation-failure outcome within a bounded time.
5. **Given** a received session manifest, **When** the receiver rejects it via the decision hook, **Then** no file data flows, the sender surfaces `transferRejected`, and both ends tear down cleanly with no file written.

---

### User Story 5 - Large-file transfer within a bounded memory budget (Priority: P3)

The engine transfers very large files (multi-gigabyte) without ever loading a whole file into memory, on either side, by streaming from and to disk and respecting the channel's flow control so a fast sender cannot overrun a slow receiver.

**Why this priority**: "No size limit" is a headline promise of the product. It is only real if memory stays bounded regardless of file size. It refines the transport behavior established in US1–US2.

**Independent Test**: Over loopback, transfer a file far larger than a reasonable memory budget (or simulate one) with a deliberately slow consumer; assert the transfer completes intact and that peak memory stays bounded (does not scale with file size) and that the sender pauses when the channel's outbound buffer is saturated.

**Acceptance Scenarios**:

1. **Given** a file larger than the engine's memory budget, **When** it is transferred, **Then** it completes intact and peak memory does not grow proportionally to file size.
2. **Given** a receiver that consumes slowly, **When** the sender's outbound buffer reaches its high threshold, **Then** the sender pauses sending until the buffer drains below the low threshold, and the transfer still completes intact.

---

### Edge Cases

- **Zero-byte file**: a 0-byte file in a session transfers and verifies as complete (hash of empty content) without stalling.
- **Duplicate / same-name files in one session**: multiple files with identical names in one session are each delivered under a unique auto-generated name (e.g. `name (1).ext`) without overwriting one another at the destination.
- **Destination already exists**: when a target filename already exists at the destination, the engine auto-renames the incoming file with a unique suffix rather than overwriting the existing file.
- **Sender file disappears mid-transfer**: if a source file becomes unreadable after the session starts, that file fails with a file-read failure and the session surfaces it rather than hanging.
- **Receiver storage fills mid-transfer**: a write failure due to insufficient space surfaces a storage-full failure and leaves no truncated file at the destination.
- **Cancel during handshake** (before any bytes flow): resolves to `cancelled` with full teardown, same as cancel during transfer.
- **Signaling message arrives out of order or after teardown**: late/stale signaling input is ignored safely and does not reopen a finished session.
- **Fresh transfer after a terminal state**: a new transfer after a completed or failed one starts from `idle` with no residual state from the prior session.

## Requirements *(mandatory)*

### Functional Requirements

**Connection lifecycle**

- **FR-001**: The engine MUST establish a direct peer-to-peer connection between exactly two peers (a sender role and a receiver role).
- **FR-002**: The engine MUST exchange connection-setup metadata (session-description offer/answer and connectivity candidates) exclusively through a pluggable signaling abstraction, and MUST NOT transmit any file bytes over that signaling path.
- **FR-003**: The engine MUST expose the live connection state and the transfer state as observable streams.
- **FR-004**: The engine MUST tear down cleanly on completion, failure, or cancellation — closing the peer connection and releasing all file handles and transient resources.
- **FR-005**: The engine MUST accept an injectable connection configuration (the set of connectivity/relay servers) rather than hardcoding any endpoint. For this feature it ships injectable with no real endpoint required (loopback needs none); real endpoints are wired by a later feature.

**Signaling abstraction & testability**

- **FR-006**: The engine MUST depend only on an abstract signaling channel interface; no concrete network transport may be referenced by the engine itself.
- **FR-007**: The feature MUST provide an in-process loopback signaling implementation that connects two engine instances directly within one process, enabling full end-to-end automated testing without any server or second device.
- **FR-008**: Late, stale, duplicate, or out-of-order signaling messages MUST be handled safely and MUST NOT corrupt or reopen a finished session.

**Direct encrypted transport**

- **FR-009**: Once connected, file bytes MUST flow over a reliable, ordered, direct data channel between the two peers.
- **FR-010**: The channel's built-in transport encryption MUST remain enabled and MUST NOT be weakened or disabled.
- **FR-011**: The engine MUST respect the data channel's outbound flow control (backpressure), pausing transmission when the outbound buffer is saturated and resuming when it drains, so a fast sender cannot overrun a slow receiver or exceed the memory budget.

**Transfer session & protocol**

- **FR-012**: The engine MUST model a transfer as a session that carries one or more files as a single unit, described by exactly one session manifest (per-file name, size, type, and total file count).
- **FR-013**: Within a session, files MUST be transferred sequentially — one file completely before the next begins — in the manifest order.
- **FR-013A**: A session is fail-fast: if any file fails (integrity mismatch, read failure, or write failure), the entire session MUST transition to `failed`, the remaining files MUST NOT be transferred, and all partial/temporary artifacts MUST be cleaned up. (No partial-success / per-file-skip behavior in v1.0.)
- **FR-014**: The transfer protocol MUST be explicit and versioned, defining at minimum: a session manifest message, a manifest accept/reject response, ordered file data frames, progress/acknowledgement signaling, per-file completion, whole-session completion, and cancel/abort initiated by either side.
- **FR-014A**: After receiving the session manifest and before any file data frames flow, the receiver MUST accept or reject the session. The engine MUST expose a decision hook for this choice (the in-process loopback implementation auto-accepts). A rejection MUST be conveyed to the sender, surface as `transferRejected` on the sender, and tear down both ends cleanly with no file written.
- **FR-015**: Malformed, unexpected, or out-of-sequence protocol or manifest input MUST be rejected gracefully as a named failure and MUST NOT crash the engine.

**Streamed I/O & integrity**

- **FR-016**: Files MUST be read from disk in pieces on the sender and written to disk in pieces on the receiver; a whole file MUST NEVER be loaded into memory in full.
- **FR-017**: Peak memory use MUST stay bounded and MUST NOT scale with file size; the engine MUST handle multi-gigabyte files within that bounded budget.
- **FR-018**: The engine MUST ingest files to send through a file-source abstraction (references to files on disk), independent of any file-picker UI.
- **FR-019**: Each file MUST carry a SHA-256 integrity hash computed in a streaming fashion on send and re-computed on receive. A separate session-level hash is explicitly NOT used.
- **FR-020**: A received file MUST be marked complete ONLY after its computed hash matches the sender's declared hash; on mismatch the file MUST fail with a clear, retryable integrity-failure outcome and MUST NOT be presented as complete.

**Atomic delivery**

- **FR-021**: Incoming file data MUST be written to a temporary/quarantine location and moved into its final destination ONLY after integrity verification passes. When the target filename already exists at the destination, the engine MUST auto-rename the incoming file with a unique suffix (e.g. `name (1).ext`) and MUST NEVER overwrite an existing file.
- **FR-022**: A failed or cancelled transfer MUST NEVER leave a truncated or unverified file at the final destination; temporary/quarantine artifacts for terminated transfers MUST be cleaned up.
- **FR-023**: Received-file destinations MUST stay within sanctioned locations; a manifest MUST NOT be able to direct a write outside them (path-traversal attempts are rejected).

**State machine & progress**

- **FR-024**: The engine MUST expose a single transfer state machine as the source of truth with the sequence `idle → connecting → handshaking → transferring → done | failed | cancelled`; consumers MUST NOT need to maintain a parallel notion of progress.
- **FR-025**: Progress MUST include both per-file and overall byte progress sufficient for a consumer to later compute percentage, speed, and ETA (computing the displayed speed/ETA is the consumer's responsibility, not this feature's).
- **FR-026**: Terminal states (`done`, `failed`, `cancelled`) MUST be final for a given session; a new transfer MUST begin from `idle` with no residual state.

**Resilience & cancellation**

- **FR-027**: Peer disconnect, network drop, connectivity-negotiation failure, and integrity failure MUST each be detected and surfaced as an explicit, named failure within a bounded time; the engine MUST NOT hang indefinitely.
- **FR-028**: Cancellation MUST be honored promptly on both ends and MUST trigger full teardown (connection closed, handles released) on both the sender and the receiver.

**Failure taxonomy & error handling**

- **FR-029**: All engine operations that can fail MUST report outcomes through the project's `Result<T>` convention rather than throwing for ordinary failures.
- **FR-030**: Failures MUST map to the established named failure types, including at minimum: `peerUnreachable`, `iceFailed`, `connectionLost`, `dataChannelClosed`, `transferCancelled`, `transferRejected`, `integrityCheckFailed`, `fileReadFailed`, `fileWriteFailed`, `storageFull`, `networkError`, and `unknown`.

**Privacy & logging**

- **FR-031**: The signaling path MUST carry connection metadata only and MUST NEVER receive, proxy, or persist file bytes.
- **FR-032**: No file contents, file paths, peer identifiers, IP addresses, or rendezvous secrets MUST appear in logs, error messages, or debug output; logging MUST go through the project logger.
- **FR-033**: Any relay-based connectivity fallback (where bytes pass through a relay because direct connection failed) MUST keep traffic end-to-end encrypted and MUST NEVER persist or log relayed bytes. (This feature ships no real relay endpoint; the constraint governs the abstraction and any later wiring.)

### Key Entities

- **Transfer Session**: A single unit of work moving one or more files between two peers. Attributes: a session identifier, the ordered list of files, overall byte total, overall progress, current state, and terminal outcome. Owns exactly one manifest.
- **Session Manifest**: The metadata describing a session's contents, sent before bytes flow. Attributes per file: name, size, content type, and declared integrity hash; plus total file count and total byte size.
- **File Transfer Item**: One file within a session. Attributes: name, size, type, declared integrity hash, per-file progress, per-file state/outcome, and (on receive) its temporary/quarantine location and final destination.
- **Transfer State**: The engine's single source-of-truth state value and progress snapshot (per-file + overall), exposed as a stream.
- **Signaling Channel (abstraction)**: The pluggable interface for exchanging session-description and connectivity metadata between peers; never carries file bytes. Has an in-process loopback implementation for tests and (later) a real network implementation.
- **File Source (abstraction)**: A reference to a file on disk that the engine can stream from, decoupling the engine from any file-selection UI.
- **Connection Configuration**: The injectable set of connectivity/relay servers used to establish the peer connection; contains no hardcoded endpoints in this feature.
- **Protocol Message**: A versioned framing unit over the data channel — one of: manifest, manifest accept/reject response, file data frame, progress/ack, per-file completion, session completion, or cancel/abort.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A complete single-file transfer can be exercised end-to-end (connect → manifest → stream → verify → place) using only the in-process loopback channel, with no live server and no second physical device.
- **SC-002**: For every successful transfer, the received file(s) are byte-identical to the source(s) and pass integrity verification 100% of the time across single-file and multi-file sessions.
- **SC-003**: No failed, cancelled, or integrity-mismatched transfer ever leaves a file at the final destination — verified at 100% across the corruption, cancellation, and storage-failure test cases.
- **SC-004**: Peak memory during a transfer remains bounded and does not scale with file size — a file far larger than the memory budget transfers successfully without proportional memory growth.
- **SC-005**: Every defined failure scenario (corrupted chunk, peer disconnect, malformed manifest, negotiation failure) resolves to its corresponding named failure within a bounded time, with zero indefinite hangs and zero unhandled crashes.
- **SC-006**: Cancellation from either side reaches a `cancelled` terminal state on both ends and releases all connections and file handles, with no leaked resources detectable after teardown.
- **SC-007**: The signaling path can be inspected to confirm it carries only connection metadata and never any file bytes.
- **SC-008**: Engine logs, errors, and debug output contain no file contents, file paths, peer identifiers, IP addresses, or rendezvous secrets.
- **SC-009**: The automated test suite covers, at minimum: single-file round-trip, multi-file round-trip, manifest accept and manifest reject (`transferRejected`), multi-file fail-fast (one file fails → whole session `failed`, no partial files left), filename-collision auto-rename, cancel-from-sender, cancel-from-receiver, corrupted-chunk integrity failure, malformed-manifest rejection, backpressure under a slow consumer, and clean teardown — and all pass deterministically.

## Assumptions

- **Engine-only scope**: This feature delivers Dart-level transport logic and its loopback test harness only. No screens, no real signaling server, no pairing methods, no file-picker, no save-to-library, no history persistence — those are later features that consume this engine.
- **Two-party transfers**: A session is strictly between two peers (one sender, one receiver). Group/broadcast transfer is out of scope.
- **Sequential multi-file**: Files in a session transfer one at a time in manifest order (decision confirmed); interleaved/parallel multi-file transfer is out of scope for v1.0.
- **Per-file integrity only**: Integrity is verified per file with SHA-256 (decision confirmed); there is no separate whole-session hash.
- **Injectable connectivity config, deferred endpoints**: The connection configuration is injectable; this feature ships with no real connectivity/relay endpoint wired (loopback needs none). Real per-flavor endpoints and any documented encrypted-only relay fallback are wired by the signaling feature (#003).
- **Filename collision handling**: When a destination filename already exists (or two files in one session share a name), the engine auto-renames the incoming file with a unique suffix (e.g. `name (1).ext`) and never overwrites an existing file (decision confirmed). The exact suffix format is finalized at planning.
- **Bounded-time detection**: "Within a bounded time" for disconnect/negotiation failures means a configurable timeout exists and is enforced; specific durations are tuned at planning, not fixed by this spec.
- **Memory budget**: A bounded per-transfer memory budget exists and is independent of file size; the concrete budget/chunk sizing is determined at planning and validated by the large-file test.
- **Two-device smoke test is deferred**: Real NAT traversal and real throughput cannot be validated in CI; a two-physical-device smoke test is a required but deferred manual task, tracked in this feature's `tasks.md`.
- **Reuses #001 foundations**: The engine builds on the existing `Result<T>`, `AppFailure`, logger, and dependency-injection foundations delivered in feature #001, and lives in the shared `core/` layer (no dependency on any `features/` module).

## Out of Scope

- Any user interface, screens, or widgets (this feature is the engine only).
- The real WebSocket signaling server and all pairing methods — 6-digit key, QR, share link, nearby radar (#003 and later).
- File-selection UI / inbound share intents (#004) and save-to-platform-location / share-out (#005).
- Transfer history persistence (#006).
- Resume of interrupted transfers and trusted-peer auto-accept (post-v1.0).
- Computing and rendering displayed transfer speed / ETA (consumers compute these from the progress this engine exposes).
