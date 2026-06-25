# Feature Specification: Lịch sử (History)

**Feature Branch**: `006-history`
**Created**: 2026-06-25
**Status**: Draft
**Input**: User description: "#006 Lịch sử (History) — Persist and browse transfer history. Use a local database to store a record for every completed/failed/cancelled transfer: direction (sent/received), peer name, file names/types/sizes/count, total bytes, timestamp, terminal status, and the pairing method used. The History tab shows a list grouped by day with direction-colored avatars (gửi=accent / nhận=info), supports search and filter (by direction and date), and a detail page per record. Quick actions: re-send (sender side → repopulate the Send tray when the files still exist), open a received file, delete a single record, and clear all. Hook into core/ transfer lifecycle so #004 Send and #005 Receive both write a record on terminal transfer state, and backfill the Home screen's recent lists from the same store. Reuse existing design tokens and shared widgets; VI-primary l10n. Out of scope: cloud history, cross-device sync."

## Overview

History (Lịch sử) is the first feature in Safe Send whose value is **memory** rather than a live transfer: it records every transfer the device takes part in and lets the user look back over them. After the MVP loop (#004 Send + #005 Receive) closes, a transfer that finishes — whether it succeeded, failed, or was cancelled — currently leaves no trace once the Complete screen is dismissed. This feature persists each finished transfer locally and surfaces it in the **Lịch sử tab**: a day-grouped list of what was sent and received, with direction-colored entries, search and filter, and a detail page per transfer. It also rounds out two existing surfaces that were stubbed with mock data in #001 — the Home screen's "recent" lists — by feeding them from the same real store.

This feature is a **persistence + browsing layer on top of the already-built transfer engine**: it introduces no new transport, pairing, or transfer mechanics. Send (#004) and Receive (#005) reach a terminal transfer state today; this feature adds a single hook in `core/` so both flows write one history record on that terminal state, without the two features importing each other or History. From the recorded history the user can take a few practical follow-up actions — re-send a previous batch (sender side, when the original files still exist), open a file they received, and prune the list (delete one record, or clear all). All history lives only on the device; there is no account, no cloud, and no cross-device sync.

## Clarifications

### Session 2026-06-25

- Q: Which terminal outcomes create a history record (given many failures happen at the pairing stage before any transfer starts)? → A: Record only once a transfer is **agreed and started** (manifest exchanged and accepted) — this captures completed / partial / cancelled / mid-transfer-failed outcomes. Pairing-stage failures (invalid/expired code, room full, relay unreachable, declined/rejected before accepting, or a drop before the manifest is exchanged) are **not** recorded; they remain transient and are surfaced inline in the Send/Receive flow only.
- Q: When deleting a received record or clearing all history, what happens to the received file(s) on disk? → A: **Record-only** — files always stay on the device; deleting a record or clearing all removes only history entries, never the underlying files. On-device storage cleanup is deferred to #010 Settings.
- Q: How should re-send behave when only some of a sent record's original files still exist? → A: **All-or-nothing** — re-send is available only when every original source file is still present; if any is missing, re-send is unavailable with a clear "files no longer available" indication (no partial/subset re-send in #006).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse past transfers (Priority: P1)

After sending and receiving files, a user opens the Lịch sử tab and sees every past transfer listed newest-first, grouped by day, each entry showing at a glance the direction (sent vs received), the peer, the files involved, the total size, the time, and whether it completed. Scrolling back shows older days.

**Why this priority**: This is the core reason the feature exists — without the browsable list there is no history. Every other story (detail, search/filter, actions) is a refinement of, or an action launched from, this list. It is also the first feature that proves transfers are being durably recorded at all.

**Independent Test**: After completing at least one send and one receive (via the #004/#005 flows or a harness that drives a terminal transfer state), a tester opens the Lịch sử tab and confirms both transfers appear as distinct, correctly-labeled entries grouped under their day, with sent and received visually distinguished — delivering the browse value on its own.

**Acceptance Scenarios**:

1. **Given** the user has completed one or more transfers, **When** they open the Lịch sử tab, **Then** each transfer appears as a list entry showing direction, peer label, a file summary (count and/or names), total size, the time, and a status indication, ordered newest-first.
2. **Given** transfers occurred across multiple days, **When** the user views the list, **Then** entries are grouped under day section headers (e.g. "Hôm nay", "Hôm qua", or a date) with the most recent day first.
3. **Given** a sent transfer and a received transfer, **When** both are shown in the list, **Then** they are visually distinguished by direction (sent = accent, received = info) via a direction-colored avatar/icon.
4. **Given** the user has never completed a transfer, **When** they open the Lịch sử tab, **Then** an empty state is shown explaining that completed transfers will appear here.
5. **Given** a transfer has just reached a terminal state in the Send or Receive flow, **When** the user opens the Lịch sử tab afterward, **Then** that transfer is present as a new record.

---

### User Story 2 - Record every finished transfer (Priority: P1)

Whenever a transfer reaches a terminal state — fully completed, partial, failed, or cancelled — in either the Send or the Receive flow, the app writes one durable record capturing what happened, so it survives app restarts and appears in history.

**Why this priority**: Recording is the foundation the entire feature stands on; the list (Story 1) is empty without it. It is co-critical with Story 1 — they are two halves of the same capability (write, then read). Capturing failed/cancelled transfers, not just successes, is part of giving the user an honest record.

**Independent Test**: A tester drives a transfer to each terminal outcome (completed, partial, failed, cancelled) on both the send and receive side, restarts the app, and confirms a correctly-populated record exists for each outcome with the right direction, peer label, file summary, total size, timestamp, status, and pairing method.

**Acceptance Scenarios**:

1. **Given** a send or receive transfer reaches a successful terminal state, **When** the flow finishes, **Then** exactly one history record is written capturing direction, peer label, the file list (names/types/sizes), file count, total bytes, timestamp, status, and the pairing method used.
2. **Given** a transfer ends partially, fails, or is cancelled, **When** the flow reaches that terminal state, **Then** a history record is still written with the corresponding status (partial / failed / cancelled) and whatever file/byte detail is known.
3. **Given** a record has been written, **When** the app is closed and reopened, **Then** the record is still present (it is durably persisted on the device).
4. **Given** the same transfer reaches a terminal state once, **When** the record is written, **Then** exactly one record is created for it (a terminal transfer is not double-recorded).
5. **Given** the Send and Receive features and History, **When** a record is written from a terminal transfer state, **Then** it happens through a shared core hook without Send/Receive importing History or each other.

---

### User Story 3 - Inspect a transfer's details (Priority: P2)

From the list, the user taps a transfer and sees a detail page with everything recorded about it: direction, peer, the full list of files (with type and size each), total size and count, the exact date/time, the outcome status, and how the two devices were paired.

**Why this priority**: The list shows a summary; users frequently want the full breakdown of a specific transfer (which files, exact time, why it failed). It is a strong P2 that makes the recorded data actually useful, but the list and recording (P1) must exist first.

**Independent Test**: With at least one multi-file record present, a tester taps it and confirms the detail page shows the complete file list and all recorded metadata, and that the per-record actions are reachable from it.

**Acceptance Scenarios**:

1. **Given** a transfer record exists, **When** the user taps it in the list, **Then** a detail page opens showing direction, peer label, the full per-file list (name, type, size), total count and size, the date and time, the outcome status, and the pairing method.
2. **Given** the detail page is open, **When** the user views it, **Then** the per-record actions relevant to that record (re-send / open / delete) are available from it.
3. **Given** the user is on the detail page, **When** they go back, **Then** they return to the history list at the same scroll position.

---

### User Story 4 - Search and filter history (Priority: P2)

As the history grows, the user narrows it down — typing into a search field to find transfers by peer or file name, and applying filters to show only sent or only received transfers, or a particular date range.

**Why this priority**: Search/filter only matters once there is enough history to be worth narrowing, so it follows the list and detail. It meaningfully improves the experience for active users but is not required for the feature to deliver value, making it a clear P2.

**Independent Test**: With a set of records spanning both directions and several days/peers, a tester searches a term and confirms only matching records show, then applies a direction filter and a date filter and confirms the list narrows accordingly, and clearing them restores the full list.

**Acceptance Scenarios**:

1. **Given** multiple records exist, **When** the user types a query, **Then** the list shows only records whose peer label or file names match the query, preserving day grouping.
2. **Given** multiple records of both directions, **When** the user filters by direction (sent / received), **Then** only records of that direction are shown.
3. **Given** records across several days, **When** the user filters by a date or date range, **Then** only records within that range are shown.
4. **Given** a search or filter is active and yields no matches, **When** the list renders, **Then** a clear "no results" state is shown distinct from the never-had-history empty state.
5. **Given** an active search/filter, **When** the user clears it, **Then** the full history list is restored.

---

### User Story 5 - Act on a past transfer (re-send / open / delete / clear) (Priority: P2)

From a history entry or its detail page, the user takes a follow-up action: re-send a batch they previously sent (when the original files are still on the device), open a file they received, delete a single record, or clear the entire history.

**Why this priority**: These actions turn a passive log into a useful tool, but each depends on the list/detail (P1/early-P2) existing. They are valuable conveniences rather than the core of the feature, so P2.

**Independent Test**: A tester re-sends a sent record whose files still exist and confirms the Send flow opens pre-populated with those files; opens a received file and confirms it launches in a system viewer; deletes a single record and confirms it disappears and stays gone after restart; clears all and confirms the history empties (with confirmation).

**Acceptance Scenarios**:

1. **Given** a sent record whose original source files still exist on the device, **When** the user chooses re-send, **Then** the Send flow opens with those files pre-populated in the selection tray, ready to pair and send again.
2. **Given** a sent record whose original source files no longer exist, **When** the user views re-send, **Then** the action is unavailable (disabled or hidden) with a clear indication that the files are no longer available, and no broken Send flow is launched.
3. **Given** a received record whose file still exists on the device, **When** the user chooses open on that file, **Then** it opens in an appropriate system viewer.
4. **Given** any record, **When** the user deletes it, **Then** it is removed from the list and does not reappear after an app restart.
5. **Given** the history has records, **When** the user chooses clear all, **Then** a confirmation is required and, on confirm, all records are removed and the empty state is shown.
6. **Given** a record is deleted or all history is cleared, **When** the removal completes, **Then** only the history records are removed; this is distinct from deleting the underlying files (default behavior leaves received files on the device).

---

### User Story 6 - See recent activity on Home (Priority: P3)

The Home screen's "recent" area — which showed placeholder data since #001 — now reflects the user's actual most recent transfers, giving a quick at-a-glance view without opening the History tab.

**Why this priority**: It reuses the same store the rest of the feature builds and is a nice finishing touch that removes the last mock data, but the History tab itself delivers the feature's value, so this is P3.

**Independent Test**: After completing a transfer, a tester opens Home and confirms that transfer appears in the recent area (replacing the previous mock entries), and that tapping through reaches the same history detail.

**Acceptance Scenarios**:

1. **Given** the user has completed transfers, **When** they view Home, **Then** the recent area shows their most recent real transfers (a small fixed number), newest-first, instead of placeholder data.
2. **Given** no transfers have ever completed, **When** the user views Home, **Then** the recent area shows an appropriate empty/encouraging state rather than mock entries.
3. **Given** a recent transfer is shown on Home, **When** the user taps it, **Then** they reach the same detail view used by the History tab.

---

### Edge Cases

- **Failed/cancelled records**: a transfer that was agreed-and-started but then failed or was cancelled before any byte landed (e.g. accepted, then connection dropped) still records a terminal entry with the appropriate status and whatever is known; entries with no/partial file detail render gracefully. Pairing-stage failures before the manifest is accepted (bad/expired code, room full, declined-before-accept, drop before manifest) are not recorded (Clarifications 2026-06-25).
- **Partial receive**: a partial outcome (FR-013a from #005, "nhận X / N tệp") is recorded with a partial status and the files that actually arrived.
- **Re-send with missing files**: some-but-not-all source files still exist → behavior is defined (see Assumptions: re-send is offered only when all original files still exist, otherwise unavailable) so the user is never dropped into a half-broken Send.
- **Open a moved/deleted received file**: the recorded file is no longer at its location → open surfaces a clear "file no longer available" message instead of failing silently.
- **Very large history**: the list remains responsive with hundreds/thousands of records (lazy/section rendering); search/filter still return quickly.
- **Clear all with confirmation**: clear-all is irreversible for the records and must be confirmed; a mis-tap must not wipe history.
- **Timezone/day boundaries**: day grouping uses the device's local day; a transfer near midnight falls under its local-time day.
- **Concurrent write while browsing**: a transfer completing while the user is on the History tab results in the new record appearing (on refresh/next load) without corrupting the view.
- **Record vs file lifecycle**: deleting a history record does not, by default, delete the received file on disk (and cannot delete an already-sent file from the recipient); the two lifecycles are independent.

## Requirements *(mandatory)*

### Functional Requirements

#### Recording (the core hook)
- **FR-001**: The system MUST write exactly one history record when an **agreed-and-started** transfer (one whose manifest has been exchanged and accepted) reaches a terminal state in either the Send (#004) or Receive (#005) flow. Pairing-stage failures that occur before a manifest is accepted (invalid/expired code, room full, relay unreachable, declined/rejected before accept, drop before manifest) MUST NOT create a record.
- **FR-002**: Each record MUST capture: direction (sent / received), a peer label, the list of files (each with name, type, and size), file count, total bytes, a timestamp, the terminal status, and the pairing method used.
- **FR-003**: For agreed-and-started transfers (FR-001), the system MUST record every terminal outcome — completed, partial, failed (mid-transfer), and cancelled — not only successful ones, storing the corresponding status.
- **FR-004**: A given terminal transfer MUST result in exactly one record (no duplicate recording of the same transfer).
- **FR-005**: Recording MUST occur through a shared hook exposed by `core/` such that the Send and Receive features write records without importing History or each other (no `lib/core/` → `lib/features/` import; features depend on the core hook).
- **FR-006**: Records MUST be durably persisted on the device and survive app restarts.
- **FR-007**: The pairing method MUST be recorded as the method actually used (6-digit code for the current MVP; the field MUST accommodate the future QR / link / nearby methods without schema change).
- **FR-008**: The peer label MUST be the same generic localized label used in #004/#005 today, with the record structured so a real device name (arriving in #010) can populate it later without a schema change.

#### Browsing (the History tab)
- **FR-009**: The system MUST present a History (Lịch sử) tab listing all recorded transfers, ordered newest-first.
- **FR-010**: The list MUST be grouped by day with section headers, the most recent day first, using the device's local day boundaries.
- **FR-011**: Each list entry MUST show the direction (visually distinguished — sent = accent, received = info — via a direction-colored avatar/icon), the peer label, a file summary, total size, the time, and a status indication.
- **FR-012**: The system MUST show a distinct empty state when no transfers have ever been recorded.
- **FR-013**: The list MUST remain responsive with a large number of records (incremental/section rendering; no requirement to hold all records in memory at once for rendering).

#### Detail
- **FR-014**: Tapping a list entry MUST open a detail page showing the full recorded data: direction, peer label, the complete per-file list (name, type, size), total count and size, the exact date and time, the outcome status, and the pairing method.
- **FR-015**: The detail page MUST expose the per-record actions relevant to that record (re-send / open / delete).

#### Search & filter
- **FR-016**: The system MUST let the user search history by a text query matching the peer label and/or file names, preserving day grouping in the results.
- **FR-017**: The system MUST let the user filter by direction (sent / received).
- **FR-018**: The system MUST let the user filter by date or date range.
- **FR-019**: When an active search/filter yields no matches, the system MUST show a "no results" state distinct from the never-had-history empty state, and clearing the search/filter MUST restore the full list.

#### Actions
- **FR-020**: For a sent record whose original source files all still exist on the device, the system MUST offer re-send, which opens the Send flow with those files pre-populated in the selection tray.
- **FR-021**: For a sent record whose original source files are not all available, the system MUST make re-send unavailable (disabled or hidden) with a clear indication, and MUST NOT launch a broken Send flow.
- **FR-022**: For a received record whose file still exists, the system MUST offer open, launching the file in an appropriate system viewer; if the file is no longer available, it MUST surface a clear "file no longer available" message.
- **FR-023**: The system MUST let the user delete a single record; a deleted record MUST NOT reappear after an app restart.
- **FR-024**: The system MUST let the user clear all history, requiring an explicit confirmation before removal.
- **FR-025**: Deleting a record or clearing all history MUST remove only the history records by default; it MUST NOT delete the underlying received files from the device (record lifecycle and file lifecycle are independent).

#### Home backfill
- **FR-026**: The Home screen's "recent" area MUST be populated from the same history store, showing the most recent real transfers (a small fixed number) newest-first, replacing the #001 mock data.
- **FR-027**: When no transfers have been recorded, the Home recent area MUST show an appropriate empty/encouraging state rather than mock entries.
- **FR-028**: A recent item on Home MUST navigate to the same detail view used by the History tab.

#### Localization & accessibility
- **FR-029**: All user-facing strings MUST be provided via the localization system (Vietnamese primary, English secondary), consistent with the rest of the app.
- **FR-030**: Numeric/technical values in history (sizes, counts, dates/times) MUST follow the app's established formatting conventions (mono + tabular figures where the design system specifies).
- **FR-031**: Interactive and status elements (list entries, filters, search, actions, confirmations) MUST carry accessibility labels.

### Key Entities *(include if feature involves data)*

- **Transfer record**: one finished transfer — direction (sent/received), peer label, terminal status (completed / partial / failed / cancelled), file count, total bytes, timestamp, pairing method, and a reference to its files. The unit shown in the list, the detail page, and the Home recent area.
- **Recorded file**: a single file belonging to a transfer record — name, type (mime/extension), size, and (for received files) its on-device location so it can be opened later; (for sent files) the original source reference so re-send can check availability and repopulate the tray.
- **History query**: the active browse state — search text, direction filter, and date/range filter — applied over the records to produce the displayed, day-grouped list.
- **Recording hook**: the `core/`-owned seam that the Send and Receive flows call on a terminal transfer state to persist a record, decoupling the two features from History.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After completing a send and a receive, both appear as correctly-labeled, direction-distinguished entries in the History tab, grouped under their day — verifiable on first open of the tab.
- **SC-002**: 100% of transfers that reach a terminal state (completed, partial, failed, or cancelled) in the Send or Receive flow produce exactly one persisted history record, with no duplicates and no missed terminal outcomes.
- **SC-003**: History records survive an app restart — a record visible before closing the app is still present after reopening it.
- **SC-004**: From a list of records spanning both directions and multiple days/peers, a search query and each filter (direction, date) narrows the list to exactly the matching records, and clearing restores the full list — verifiable for each filter type.
- **SC-005**: Re-send from a sent record whose files still exist opens the Send flow pre-populated with those exact files; for a record whose files are missing, re-send is unavailable and no broken flow is launched — verifiable for both cases.
- **SC-006**: Deleting a single record removes it permanently (gone after restart) and clear-all empties the history after confirmation; neither action deletes received files from the device.
- **SC-007**: The Home recent area shows the user's actual most recent transfers (no mock data remaining) and tapping one reaches the same detail view as the History tab.
- **SC-008**: The History list and search/filter remain responsive (no perceptible lag on a typical device) with at least several hundred records present.

## Assumptions

- **Local-only**: all history is stored on the device with no account, cloud backup, or cross-device sync; uninstalling the app clears it. Cloud history and sync are explicitly out of scope.
- **Recording trigger**: records are written on the terminal transfer state already exposed by the #002 state machine and surfaced by #004/#005; this feature adds the persistence + a `core/` hook, not new transfer mechanics.
- **One record per transfer**: a transfer is recorded once, at its terminal state; in-progress transfers are not pre-recorded and live progress is not persisted.
- **Peer label**: the generic localized peer label from #004/#005 is stored now; real device names (from #010) can populate the same field later without a schema change.
- **Pairing method**: only the 6-digit method exists today, so it is what gets recorded; the field is designed to hold QR / link / nearby values added by #007–#009 without a schema change.
- **Re-send availability**: re-send is offered only when **all** of a sent record's original source files still exist on the device; if any are missing, re-send is unavailable with a clear indication (avoids partial/broken re-sends). Re-send re-enters the existing Send flow (new pairing, new code) — it does not reconnect to the original peer.
- **Open received file**: opening relies on the received file still being at its recorded location (app-owned storage from #005); if the user moved/deleted it via the Files app, open surfaces a clear unavailable message.
- **Delete is record-only**: deleting a record or clearing all removes history entries, not the underlying received files on disk; file deletion is not part of this feature (could be revisited in #010 settings).
- **Recent count on Home**: the Home recent area shows a small fixed number of the newest records (assumed ~5, to match the #001 home layout); the exact count follows the existing Home design.
- **Retention**: history is retained indefinitely until the user deletes records or clears all; there is no automatic expiry or size cap in this feature.
- **Reuse**: the History UI reuses the existing design tokens and shared widget library (FileRow, list/section patterns, empty states, confirmation dialogs) and the existing failure/formatting conventions; it adds History-specific copy only where needed.
- **Out of scope**: cloud history and cross-device sync; deleting underlying files from history; editing/annotating records; per-record analytics; QR/link/nearby pairing-method capture beyond reserving the field (#007–#009); real peer names and history-related settings such as retention limits (#010).
