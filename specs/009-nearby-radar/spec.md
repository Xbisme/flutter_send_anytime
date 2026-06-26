# Feature Specification: Nearby Radar (Gần đây)

**Feature Branch**: `009-nearby-radar`
**Created**: 2026-06-26
**Status**: Draft
**Input**: User description: "Spec #009 — Nearby Radar (Gần đây): cách kết nối thứ tư của Safe Send, cho phép hai thiết bị cùng mạng/ở gần pair trực tiếp mà không cần nhập mã 6 số, quét QR hay mở link. Reuse rendezvous/signaling/transport của #003 không đổi — radar chỉ là một entry mới để trao đổi rendezvous identifier (giống QR/share link)."

## Overview

Nearby Radar is the **fourth and final connection method** in Safe Send v1.0. It lets two devices on the same local network pair **without anyone reading out, typing, scanning, or opening anything** — the receiver simply sees the nearby sender appear on a live radar and taps to connect.

It is a new *entry* into the exact same pipeline the other three methods already use. The rendezvous, signaling, and WebRTC transport from Spec #003 are reused **unchanged**: a sender still generates a short-lived rendezvous code and hosts the room exactly as today. Nearby Radar only changes *how that code travels to the receiver* — instead of being read aloud (6-digit), shown as a QR, or sent as a link, it is **advertised over the local network** and **discovered automatically**. Once the receiver obtains the code, the flow is identical to the existing join → accept/reject → transfer path.

## Clarifications

### Session 2026-06-26

- Q: Thiết bị không cùng mạng thì tìm nhau thế nào? → A: v1 **chỉ same-network (Wi-Fi/LAN)**; khác mạng → empty-state hướng dẫn về cùng Wi-Fi + gợi ý dùng cách kết nối khác (QR/mã 6 số). BLE/off-Wi-Fi defer v1.1.
- Q: Thiết bị đã từng kết nối có hiện trên radar không? → A: **Không** — radar chỉ hiện thiết bị đang live-advertising. Không lưu/không hiện danh sách "đã từng kết nối"; saved/favorite peers + trusted auto-accept để v1.1.
- Q: Hướng radar — ai quảng bá, ai dò? → A: **Sender quảng bá, receiver dò + chạm để join** (giữ rendezvous #003 nguyên vẹn). Radar device-rows ở màn Nhận; tab "Gần đây" của Connect = trạng thái discoverable của sender. Không làm kiểu AirDrop (sender dò receiver).
- Q: Sender thành discoverable bằng cách nào? → A: **Tự quảng bá ngay khi mở tab "Gần đây"**, tự dừng khi rời tab/nền. Không có toggle riêng trong #009; việc vào/rời tab chính là discoverability control (FR-014). Toggle global bền vững để Settings #010.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receiver discovers a nearby sender and taps to connect (Priority: P1)

A sender has picked files and is on the Connect screen's **"Gần đây"** tab, making the device discoverable on the local network. A receiver, on the same Wi-Fi, opens **Nhận (Receive)** and — without typing a code — sees the sender appear as a nearby device. They tap **Nhận** on that device row and are taken straight into the existing incoming-transfer prompt (sender label + file manifest) to **Accept / Reject**.

**Why this priority**: This is the entire value of the feature — connecting two nearby devices with zero manual code exchange. Everything else is supporting scaffolding. If only this slice ships, Nearby Radar already delivers a usable fourth connection method.

**Independent Test**: With two devices on the same network, a sender advertising on the "Gần đây" tab, the receiver opens Nhận, sees exactly one nearby device row for the sender, taps it, and reaches the accept/reject prompt — then completes a real transfer. No code is ever typed.

**Acceptance Scenarios**:

1. **Given** a sender is advertising on the "Gần đây" tab and a receiver opens Nhận on the same network, **When** discovery runs, **Then** the sender appears as a nearby device row showing its device name and avatar within a few seconds.
2. **Given** the receiver sees the nearby sender, **When** they tap **Nhận** on that row, **Then** the app joins the sender's room automatically (reusing the advertised rendezvous code) and shows the incoming-transfer prompt with the sender's file manifest.
3. **Given** the receiver accepts the prompt, **When** the transfer runs, **Then** files stream and save exactly as with the other connection methods, and the completed transfer is recorded with `pairingMethod = nearby`.
4. **Given** the receiver taps **Từ chối (Reject)** at the prompt, **When** they decline, **Then** no transfer occurs and the receiver returns to the prior screen, with no record created (consistent with FR-001 of #006).
5. **Given** the sender's advertised code has expired or the sender stopped advertising, **When** the receiver taps that (now stale) device row, **Then** the join fails gracefully with a clear localized message and the device disappears from the list — never a dead-end.

---

### User Story 2 - Sender becomes discoverable and sees connection happen (Priority: P2)

A sender, after selecting files, opens the Connect hub and switches to the **"Gần đây"** tab. The tab shows an animated radar conveying "you are discoverable to nearby devices", along with the same live rendezvous code/countdown that backs the other tabs. When a nearby receiver connects, the sender transitions into the live transfer progress exactly as with the other methods.

**Why this priority**: Discovery requires the sender to actively advertise; without a clear, controllable "I am discoverable" surface there is nothing for the receiver to find, and users need confidence/feedback about being broadcast. It is P2 because it is the necessary counterpart to P1 but carries no independent end-user value on its own.

**Independent Test**: A sender picks files, opens the "Gần đây" tab, and observes the radar/discoverable state plus the live code and countdown; a second device on the network can then find it (verifies advertising is live). Leaving the tab / backgrounding the app stops advertising (verifies lifecycle).

**Acceptance Scenarios**:

1. **Given** a sender has selected files and opened the Connect hub, **When** they switch to the "Gần đây" tab, **Then** the device begins advertising on the local network and the tab shows an animated radar "discoverable" state plus the same live code and expiry countdown as the other tabs.
2. **Given** the sender is on the "Gần đây" tab, **When** they switch back to "Mã 6 số" or "QR", **Then** no new rendezvous code is generated and no second room/socket is opened (one hosting session across all tabs).
3. **Given** the sender is advertising, **When** they leave the Connect flow or the app moves to the background, **Then** advertising stops promptly and the device no longer appears to others.
4. **Given** a nearby receiver connects via the radar, **When** the room handshake completes, **Then** the sender transitions into the shared transfer progress screen and advertising stops.

---

### User Story 3 - Nearby entry points and discoverability control (Priority: P3)

A user can reach the nearby experience quickly from the Home screen's **"Thiết bị gần"** quick action, and can control whether their device is discoverable. Before any local-network broadcasting happens, the app requests the required local-network permission with a clear rationale, and the user is informed that their device name is broadcast to nearby devices.

**Why this priority**: These are convenience and trust/permission affordances. They improve discoverability and address the privacy of broadcasting a device name, but the core pairing (P1+P2) works without them. P3 because it polishes reach and consent rather than enabling the core loop.

**Independent Test**: From Home, tapping "Thiết bị gần" lands the user on the nearby experience; on first use the local-network permission prompt appears with a rationale; denying it shows a recoverable state (explain + retry/settings) rather than a dead screen.

**Acceptance Scenarios**:

1. **Given** a user on Home, **When** they tap the "Thiết bị gần" quick action, **Then** they land on the nearby connection surface ready to advertise or browse.
2. **Given** the app needs local-network access for the first time, **When** the user reaches the nearby surface, **Then** a permission rationale is shown and access is requested before any advertising or browsing begins.
3. **Given** the user denies or has permanently denied local-network permission, **When** they reach the nearby surface, **Then** the app shows a clear explanation with a path to retry or open Settings (and no broadcasting occurs), never a blank/dead radar.
4. **Given** discovery is active, **When** the user views the surface, **Then** a clear privacy note communicates that their device name is broadcast to nearby devices.

---

### Edge Cases

- **Devices on different networks / Wi-Fi off**: nothing is discovered; the radar shows an empty "no nearby devices" state with guidance (e.g., ensure both devices are on the same Wi-Fi), not an error.
- **Multiple senders advertising at once**: the receiver's radar lists each as a distinct device row; tapping one connects only to that device.
- **Two devices with the same display name**: both still appear and are individually tappable (distinguished by a stable per-advertisement identity, not only the human name).
- **Stale advertisement** (sender stopped/expired but still listed briefly): tapping it fails gracefully and the entry is removed; the list self-heals as advertisements time out.
- **Permission revoked mid-session**: advertising/browsing stops and the surface returns to the permission-required state.
- **App backgrounded mid-discovery**: advertising and browsing pause; resuming foreground re-advertises/re-browses.
- **Receiver taps a device whose room is already full / already transferring**: surfaces the existing "room full / busy" failure clearly and keeps the radar usable.
- **A device discovering itself**: a device never lists its own advertisement as a connectable peer.
- **Reduced Motion enabled**: the radar wave animation is disabled and a static equivalent state is shown (no loss of function).

## Requirements *(mandatory)*

### Functional Requirements

**Discovery & advertising**

- **FR-001**: The system MUST allow a sender (a device hosting an active rendezvous) to advertise its presence on the local network so nearby Safe Send devices can discover it.
- **FR-002**: The advertisement MUST carry enough information for a receiver to (a) display the sender as a human-recognizable device (display name + avatar derivation) and (b) obtain the rendezvous identifier needed to join the sender's existing room.
- **FR-003**: The system MUST allow a receiver to browse for nearby advertising Safe Send devices and present them as a live, self-updating list/radar (devices appear when found and disappear when they stop advertising or time out).
- **FR-004**: The system MUST NOT list a device's own advertisement as a connectable peer (self-discovery is suppressed).
- **FR-005**: Advertising and browsing MUST be tied to app foreground and the relevant nearby surface: they start when the user is on the nearby surface (with permission granted) and stop promptly when the user leaves it or the app is backgrounded.

**Pairing via radar (reusing #003 unchanged)**

- **FR-006**: Tapping a discovered device MUST initiate pairing automatically by joining that device's existing rendezvous room using the advertised identifier — with **no manual code entry, scan, or link**.
- **FR-007**: The system MUST reuse the existing Spec #003 rendezvous, signaling, and Spec #002 transport without modification — Nearby Radar only changes how the rendezvous identifier is exchanged. No changes to the signaling protocol, transport, transfer protocol, or persisted history schema.
- **FR-008**: After a successful radar join, the receiver MUST be taken into the existing incoming-transfer prompt (sender label + file manifest) with **Accept / Reject**, identical to the other connection methods.
- **FR-009**: The sender MUST treat the "Gần đây" tab as the same hosting session as the other Connect tabs: switching between "Mã 6 số" / "QR" / "Gần đây" MUST NOT generate a new code or open a second room/socket.
- **FR-010**: A completed transfer paired via radar MUST be recorded with `pairingMethod = nearby` on both sides (sender last-action-wins; receiver from the radar join), reusing the already-reserved enum with **no schema change**.

**Permissions, lifecycle, privacy**

- **FR-011**: The system MUST request the platform local-network permission (and any platform-required nearby permissions) with a clear rationale **before** advertising or browsing begins.
- **FR-012**: When the required permission is denied or permanently denied, the system MUST show a clear, recoverable state (explanation + retry or open-Settings path) and MUST NOT advertise or browse — never a dead/blank radar.
- **FR-013**: The system MUST clearly inform the user that their device name is broadcast to nearby devices while discovery is active (privacy note).
- **FR-014**: Discoverability MUST be controlled by presence on the "Gần đây" tab: the device starts advertising on entering the tab (after permission) and stops on leaving the tab or backgrounding the app. No separate in-screen discoverability toggle is added in this feature; a persistent global "discoverable" setting is deferred to Spec #010.

**Entry points & resilience**

- **FR-015**: The Home screen MUST offer a "Thiết bị gần" quick action that lands the user on the nearby connection surface.
- **FR-016**: When no nearby devices are found, the system MUST show a distinct empty state with guidance (e.g., same-Wi-Fi hint), distinguishable from a permission-blocked state.
- **FR-017**: Tapping a stale/expired/unreachable advertised device MUST fail gracefully with a clear localized message and remove that entry, keeping the radar usable (no dead-end).
- **FR-018**: All user-facing copy MUST be provided via localization (Vietnamese primary, English secondary), and all messages MUST use the standard toast/messaging surface; logs MUST NOT contain device names, network addresses, rendezvous codes, or other sensitive discovery data.
- **FR-019**: The radar animation MUST respect Reduced Motion (disabled with a static equivalent), consistent with the rest of the app.

### Key Entities

- **Nearby Device (discovered peer)**: a Safe Send device currently advertising on the local network. Attributes: a stable per-advertisement identity, a human display name, an avatar derivation, the rendezvous identifier needed to join, and a freshness/last-seen state. Lifecycle: appears on discovery, refreshes while seen, disappears on stop/timeout.
- **Local Advertisement (own broadcast)**: this device's outgoing presence while it is the discoverable sender. Carries display name + the live rendezvous identifier for its active hosting session. Exists only while advertising is active.
- **Rendezvous identifier**: unchanged from Spec #003 — the short-lived code/room that both peers converge on. Radar transports it; it does not define it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With two devices on the same network and the sender discoverable, the receiver sees the sender appear on the radar within 5 seconds in the common case.
- **SC-002**: A user can go from "open Nhận" to "incoming-transfer prompt" via radar with **zero** characters typed and **zero** scans — a single tap on the discovered device.
- **SC-003**: A device that stops advertising disappears from a browsing receiver's radar within 10 seconds (no indefinitely stale phantom devices).
- **SC-004**: 100% of nearby pairings that reach a transfer use the existing #003 rendezvous and #002 transport unchanged (verified by no edits to the signaling/transport/protocol/history-schema modules).
- **SC-005**: Permission is gated per platform reality: on **Android** no advertising or browsing starts before the runtime permission is granted; on **iOS** (no pre-request API exists) the rationale is shown before discovery starts and the OS Local Network prompt governs access (the act of starting mDNS is what triggers it, before any peer can connect). In all cases a permission denial resolves to a recoverable, non-dead-end state.
- **SC-006**: The first-attempt success rate for "see a nearby device → tap → reach the accept/reject prompt" is high enough to feel effortless in dogfooding (target ≥ 90% on the same network), with failures always surfaced clearly rather than silently.

## Assumptions

- **Discovery direction (decided — Clarification 2026-06-26)**: To reuse Spec #003 **unchanged**, the **sender** (who already generates and hosts the rendezvous code per the existing sender-generated rule) is the party that **advertises**, and the **receiver** is the party that **browses and taps to join**. Accordingly, the radar "blip list / tap-to-connect" device rows live on the **Receive** surface, while the Connect hub's "Gần đây" tab presents the **sender's discoverable/advertising** state. The AirDrop-style inverse (sender browses for waiting receivers) is **rejected** because it would invert #003's code-generation role.
- **Network reach for v1 (decided — Clarification 2026-06-26)**: Discovery targets devices on the **same local network (Wi-Fi/LAN) only**. When the two devices are not on the same network, the radar shows the empty/no-devices state with guidance to join the same Wi-Fi and a pointer to the other connection methods (QR / 6-digit). **BLE / off-Wi-Fi discovery is out of scope for v1** (deferred to v1.1); internet-wide discovery remains out of scope. No Bluetooth permission or BLE dependency is introduced.
- **Device identity until Settings (#010)**: The broadcast display name and avatar use a sensible default device identity (e.g., a platform-derived name) until the editable device profile lands in Spec #010; no dependency on #010 to ship #009.
- **Discoverability default (decided — Clarification 2026-06-26)**: A device advertises automatically while the sender is on the "Gần đây" tab in the foreground, and stops on leaving the tab or backgrounding — no separate toggle (the tab presence *is* the control, FR-014). A persistent global "always discoverable" background mode / Settings toggle is deferred to Spec #010.
- **No new persistence / no known-device list (decided — Clarification 2026-06-26)**: The radar shows **only devices currently live-advertising**. Discovered devices are ephemeral runtime state; nothing about discovery — including any "previously connected" / known-peer list — is persisted in #009. Saved/favorite peers + trusted auto-accept are explicitly v1.1. Only the resulting *transfer* is recorded (via the existing #006 path) with `pairingMethod = nearby`.
- **Architecture/process constraints (Constitution)**: `core/` MUST NOT import `features/`; the discovery capability is exposed via a core-pure service seam consumed by features through DI, mirroring how #007/#008 added core seams. BLoC 4-state cubits, design-token visuals, `AppRoutes`/`context.go|push`, `AppToast`, `AppLogger`, and ARB (VI primary) apply throughout.
- **Reuse of prior surfaces**: The accept/reject prompt, progress, and complete screens are reused from #004/#005 unchanged; the Connect hub and Receive screens are extended additively (the "Gần đây" tab and the nearby device rows), consistent with how QR (#007) extended them.

## Dependencies

- **Spec #003** (signaling + 6-digit rendezvous) — reused unchanged; the rendezvous code is the identifier the radar transports.
- **Spec #002** (WebRTC transport) — reused unchanged for the actual transfer.
- **Spec #004 / #005** (Send / Receive flows) — the radar plugs into the existing Connect hub and Receive surfaces and hands off to the existing accept/reject → progress → complete path.
- **Spec #006** (history) — reuses the reserved `pairingMethod = nearby` enum value; no schema change.
- **Spec #010** (Settings) — *not* a dependency; the device-profile name/avatar is a default until #010, and a global discoverability toggle is deferred.
