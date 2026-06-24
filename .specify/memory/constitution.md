<!--
================================================================================
SYNC IMPACT REPORT
================================================================================
Version Change: (none) → 1.0.0 (initial ratification)

This is the first ratified constitution for Safe Send. Adapted from the
Authenticator Portal / Secrypt constitution v2.3.0 (flutter_formly), with the
domain reframed from "secure password vault" to "peer-to-peer file transfer
over WebRTC". Vault/encryption-at-rest principles were replaced by P2P
transport, signaling-privacy, and transfer-reliability principles; the design
system principle was repointed at the imported claude_design tokens.

Principles (15):
  I.    Privacy-First P2P Architecture          (was: Security-First Vault)
  II.   Direct Transfer & Data Minimization     (was: Encryption & Zero-Knowledge)
  III.  BLoC-Driven State Management            (carried)
  IV.   Code Quality & Dart Safety              (carried)
  V.    Result<T> Error Handling                (carried, domain-adapted)
  VI.   Design System & Theming                 (repointed to claude_design tokens)
  VII.  Cross-Platform Native Integration       (was: iOS Platform Integration; now iOS + Android)
  VIII. Transport & Signaling Architecture      (was: Method Channel Architecture)
  IX.   Transfer Reliability & Data Integrity   (was: Data Integrity & Backup Safety)
  X.    go_router Navigation Standards          (carried, IA-adapted)
  XI.   Feature-First Modularity                (carried)
  XII.  Testing Discipline                      (carried, loopback + 2-device)
  XIII. Simplicity & YAGNI                      (carried)
  XIV.  Internationalization by Default         (carried; Vietnamese-first UI)
  XV.   Dependency Hygiene                       (carried)

Templates Requiring Updates:
- .specify/templates/plan-template.md ✅ (generic Constitution Check section
  remains accurate; no inline principle references)
- .specify/templates/spec-template.md ✅
- CLAUDE.md ⚠ pending — to be expanded during Spec #001 to mirror Working Rules
- .claude/claude-app/ui-design-context.md ✅ (Principle VI defers UI detail to it)

Follow-up TODOs: None
================================================================================
-->

# Safe Send Constitution

> App Name: "Safe Send" — cross-platform (iOS + Android, Flutter) peer-to-peer
> file-sharing app, a "Send Anywhere"-style product. Files of any type and any
> size are transferred device-to-device over WebRTC, with **no intermediary
> server holding the data**. Core surfaces: Gửi (Send), Nhận (Receive), Lịch sử
> (History). Four ways to pair: 6-digit key, QR, nearby radar, share link.
> Fixed light & dark palette. UI source of truth:
> `.claude/claude-app/ui-design-context.md`.

## Core Principles

### I. Privacy-First P2P Architecture

The app's defining promise is that file data travels **directly between two
devices** and is never held by an intermediary server. Privacy MUST be embedded
in every layer of the transfer pipeline — not bolted on afterward.

- File bytes MUST flow over a direct, encrypted WebRTC `RTCDataChannel`
  (DTLS-SRTP) between the two peers.
- The **signaling** server MUST carry connection metadata only (SDP, ICE
  candidates, rendezvous identifiers). It MUST NEVER receive, proxy, or persist
  file bytes.
- A **TURN** relay is the only permitted data-relay fallback and ONLY when
  direct NAT traversal fails. Relayed traffic MUST remain end-to-end encrypted
  and MUST NEVER be persisted or logged. Any code path that introduces a TURN
  relay MUST document it where it appears.
- Rendezvous identifiers (6-digit codes, room tokens, share links) MUST be
  short-lived and single-use; they MUST expire and MUST NOT be reusable to
  rejoin a finished session.
- No file contents, file paths, peer identifiers, IP addresses, or rendezvous
  secrets MUST appear in logs, error messages, crash reports, or debug output.
- Input validation MUST occur at every boundary: pasted/entered codes, scanned
  QR payloads, deep links, signaling messages, and incoming transfer manifests.
- Received-file destinations MUST stay within app-sanctioned locations; a
  transfer manifest MUST NEVER be able to direct a write outside them (path
  traversal is rejected).

**Rationale**: The product exists because users do not trust cloud relays with
their files. If data silently passes through or is retained by a server, the
core value proposition is broken. Treating signaling as metadata-only and TURN
as an encrypted, non-persisted last resort keeps the promise verifiable.

### II. Direct Transfer & Data Minimization

The transfer pipeline MUST move data directly, verify it, and retain the
minimum necessary.

- **Channel security**: rely on WebRTC's mandatory DTLS encryption for the data
  channel; the app MUST NOT disable or weaken it.
- **Integrity**: each file MUST carry an integrity hash (e.g. SHA-256) computed
  on send and verified on receive; a mismatch MUST fail the file with a clear,
  retryable error — never silently accept corrupt data.
- **Streamed I/O**: files MUST be streamed from and to disk in chunks. Loading a
  whole file into memory is FORBIDDEN — the app MUST survive multi-GB transfers
  within a bounded memory budget.
- **Ephemerality**: signaling rendezvous state MUST be ephemeral. The app MUST
  NOT persist the pairing secret after the session establishes.
- **History minimization**: the History feature MAY persist transfer *metadata*
  (peer name, file names/types/sizes/count, timestamp, direction, status) but
  MUST NOT copy or retain transferred file *contents* beyond the user-chosen
  save location.
- **No telemetry of content**: analytics, if ever added via a spec, MUST NEVER
  include file names, contents, peer identities, or rendezvous secrets.

**Rationale**: A file mover should move and forget. Verifying integrity protects
against silent corruption over flaky links; streamed I/O is what makes "no size
limit" real on a phone; minimizing retained state shrinks the blast radius of
any device compromise.

### III. BLoC-Driven State Management

All state management MUST use the BLoC pattern via `flutter_bloc`.
Unidirectional data flow is mandatory: Events → BLoC → State → UI. All Cubits
MUST follow the 4-state pattern.

- Every feature MUST manage state through Cubits (preferred) or Blocs.
- UI widgets MUST NOT contain business logic; they react to state only.
- State classes MUST be immutable using `@freezed` sealed classes.
- **Mandatory 4-state pattern** for all Cubits/Blocs:
  ```
  initial → loading → loaded({required T data}) → error({required AppFailure failure})
  ```
- Extended state variants MUST prefix the base state name (e.g.
  `loadedTransferring`, `loadedConnecting`) — NOT `success`, `failed`, `empty`.
- Long-running transfer/connection progress MUST be modeled as a **state stream
  derived from the transfer state machine** (Principle VIII), not ad-hoc setState.
- Cubit-to-Cubit communication MUST go through shared repositories/services or
  streams — NEVER direct cubit references.
- Side effects (navigation, dialogs, toasts) MUST be triggered via
  `BlocListener`, never from `BlocBuilder`.
- All Cubits MUST be closed to prevent leaks; `bloc_lint` MUST be zero-violation.
- **DI registration**: shared/app-wide Cubits → `@lazySingleton`; screen-scoped
  Cubits → `@injectable`. BlocProvider MUST be page-scoped unless app-wide
  lifetime is explicitly required.

**Rationale**: The 4-state pattern gives every screen consistent
loading/error handling. A transfer app is intrinsically about live, evolving
state (connecting, handshaking, %-complete, failed) — predictable transitions
keep that complexity reviewable.

### IV. Code Quality & Dart Safety

All code MUST use Dart strict analysis with null safety. Linting MUST follow
`very_good_analysis` standards with zero warnings.

- `very_good_analysis` rules MUST produce zero warnings.
- `bloc_lint` recommended rules MUST be enforced.
- Dart analysis MUST enable `strict-casts`, `strict-raw-types`,
  `strict-inference`.
- All state objects MUST be immutable (freezed).
- Every public API MUST have explicit return types and parameter types.
- Error messages shown to users MUST be actionable and non-technical.
- Code MUST be self-documenting; comments only where logic is non-obvious.
- Naming: files `snake_case.dart`; classes `PascalCase`; Cubits `{Feature}Cubit`;
  States `{Feature}State`.

**Rationale**: Null safety and immutability prevent whole categories of bugs.
Concurrency around sockets, isolates, and file streams is unforgiving of silent
state inconsistencies.

### V. Result\<T\> Error Handling

All async operations that can fail MUST return `Result<T>` instead of throwing.
Exceptions are reserved for truly exceptional (programmer-error) situations.

- Repository/service methods MUST return `Result<T>`.
- `AppFailure` sealed class MUST enumerate known failure modes, including:
  - `permissionDenied`, `cameraUnavailable`
  - `signalingUnreachable`, `signalingTimeout`, `roomExpired`, `roomFull`,
    `invalidCode`
  - `peerUnreachable`, `iceFailed`, `connectionLost`, `dataChannelClosed`
  - `transferCancelled`, `transferRejected`, `integrityCheckFailed`
  - `fileReadFailed`, `fileWriteFailed`, `storageFull`, `unsupportedPath`
  - `networkError`
  - `unknown({String? message, Object? error})`
- Cubits MUST handle `Result<T>` via `.fold()` — emit `loaded` on success,
  `error` on failure. try/catch in Cubits is FORBIDDEN; repositories/services
  catch and wrap.
- User-facing error text MUST come from `AppFailure` mapping (localized),
  NOT raw exception messages.

**Rationale**: P2P transfer fails in many ordinary ways (peer walks out of
range, NAT blocks, code expires). Making each an explicit, named outcome forces
graceful handling and clear user messaging instead of opaque crashes.

### VI. Design System & Theming

The app MUST use a centralized design system whose tokens and components derive
from the imported **claude_design** project (`SafeSend`), distilled in
`.claude/claude-app/ui-design-context.md`. All visual properties MUST come from
theme tokens — never hardcoded. Inputs and buttons MUST be built through
centralized factories; inline configuration is FORBIDDEN.

- **Fixed palette**: the app ships a single fixed light + dark palette. A
  user-facing color-scheme picker is FORBIDDEN; only light/dark/follow-system
  mode is allowed (Spec #010).
- **Color**: use **semantic token aliases** (`accent`, `surface-card`,
  `text-secondary`, `border-strong`, etc.) — NEVER hardcode hex at call sites.
  Brand green `#00C853` + teal accents per the token file.
- **Typography**: **Sora** (display/body) + **JetBrains Mono** (codes, sizes,
  speeds, ETAs, timestamps) via the design tokens. All numeric/technical values
  MUST use the mono family with tabular figures.
- **Spacing / radius / shadow / motion**: from the design tokens
  (`ui-design-context.md` is authoritative where the source CSS and the rendered
  screens disagree — rendered screens win, e.g. soft 16–22px card radii).
- **Icons**: Lucide set (as used in the design), via a single icon dependency
  chosen at Spec #001 — NEVER mix in Flutter `Icons`/`CupertinoIcons` ad hoc.
- **Shared widgets**: reusable components (PrimaryButton/SecondaryButton/
  DangerButton, FileChip/FileRow, CodeBox, SegmentedTabs, ToggleRow,
  StatTile/QuickActionCard, AppToast, flow AppBar) MUST be built once in
  `lib/core/presentation/` (Spec #001) and reused — duplicating their markup per
  feature is FORBIDDEN.
- **CTA convention**: primary CTA = full-width pill with the brand gradient;
  secondary = pill with a 2px border; consistent 52px height.
- **Toasts**: use the centralized `AppToast` utility — NEVER call
  `ScaffoldMessenger.showSnackBar` directly.
- **Reduce Motion**: motion-heavy elements (radar pulse, transfer spinner) MUST
  degrade to a static state when Reduce Motion is on.
- **Navigation IA**: bottom nav is exactly 3 tabs (Trang chủ / Lịch sử / Cài
  đặt); Gửi and Nhận are Home actions that push nav-less flows. Flow screens
  hide the bottom nav.

**Rationale**: The product ships a deliberate, fixed visual identity. Centralized
tokens and factories keep light/dark correct and prevent the per-call-site drift
that is the most common source of visual inconsistency.

### VII. Cross-Platform Native Integration

The app targets **iOS and Android** and MUST feel native on both, following each
platform's conventions while sharing core logic in Dart.

- Platform-appropriate affordances MUST be used for alerts, action sheets, and
  pickers (Cupertino on iOS, Material on Android) without forking business logic.
- All phone screen sizes MUST be supported, including notch / Dynamic Island and
  Android display cutouts; the layout MUST adapt responsively.
- **Permissions** MUST be requested contextually and degrade gracefully when
  denied: Local Network (iOS 14+) and nearby-Wi-Fi/Bluetooth (Android 12+) for
  the radar; camera for QR; storage/photos for picking and saving.
- Inbound OS integrations MUST be supported where scoped: share-sheet "Send with
  Safe Send" intents, and universal/app links + `safesend://` deep links for
  share-link pairing.
- Accessibility MUST be honored on both platforms: screen readers
  (VoiceOver/TalkBack), Dynamic Type / font scaling, Reduce Motion.
- Haptic feedback MUST be used for key moments (connect, transfer complete,
  failure, cancel).

**Rationale**: A file-sharing app lives or dies on cross-device reach. Both
platforms are first-class, and the native discovery/permission models differ
enough that they must be respected explicitly.

### VIII. Transport & Signaling Architecture

The connection stack MUST be organized as three clean layers, and every pairing
method MUST converge on the same pipeline rather than forking it.

- **Layers**: (1) Pairing/Discovery → (2) Signaling → (3) WebRTC DataChannel
  transport. The four pairing methods (6-digit, QR, share link, nearby radar)
  are only different ways to obtain the **same rendezvous identifier**; they MUST
  feed one shared signaling/transport path.
- **Signaling boundary**: signaling messages MUST be limited to SDP, ICE
  candidates, and rendezvous control. A `SignalingChannel` interface MUST
  abstract the transport so the engine is testable without a live server
  (an in-process loopback implementation MUST exist for tests — Principle XII).
- **Transfer state machine** is the single source of truth:
  `idle → connecting → handshaking → transferring → done | failed | cancelled`,
  exposed as a stream that drives Send and Receive UI identically. UIs MUST NOT
  maintain a parallel notion of progress.
- **Transfer protocol** (framing over the data channel) MUST be explicit and
  versioned: a manifest message (names, sizes, mime, count), chunk frames
  (sequence + payload), progress/ack, completion + per-file integrity, and
  cancel/abort. Backpressure (the data channel's buffered-amount threshold) MUST
  be respected.
- **Configuration**: signaling endpoint and STUN/TURN config MUST be per-flavor
  and centralized — NEVER hardcoded at call sites. The signaling relay is a
  self-hostable component living in `server/`.
- **Constants**: channel/event names and protocol message types MUST be defined
  in one place — NEVER duplicated as string literals.

**Rationale**: Collapsing every pairing method onto one signaling/transport path
is what keeps four "ways to connect" from becoming four codebases. A single
state machine makes Send and Receive mirror each other and makes progress
behavior testable.

### IX. Transfer Reliability & Data Integrity

A transfer MUST either complete verifiably or fail cleanly — never corrupt data
or leave half-written files presented as whole.

- Per-file integrity verification (Principle II) MUST gate "complete".
- Interruptions (peer disconnect, network drop, app backgrounded mid-transfer,
  ICE failure) MUST be detected and surfaced with a clear, retryable error;
  the app MUST NOT hang indefinitely.
- Partially received files MUST be quarantined/temp until verified, then moved
  into place atomically — a failed transfer MUST NOT leave a truncated file at
  the final destination.
- History persistence (drift) migrations MUST be non-destructive and
  backward-compatible; migration tests MUST cover every prior schema version,
  not just N-1.
- Malformed signaling/manifest/protocol input MUST be handled gracefully (reject
  and surface, not crash).
- Cancellation MUST be honored promptly on both ends and MUST tear down the peer
  connection and release file handles.

**Rationale**: Users forward received files onward; a silently-truncated file is
worse than a visible failure. Atomicity and integrity checks make "it said done"
mean the bytes are actually there and correct.

### X. go_router Navigation Standards

All navigation MUST use go_router with centralized route constants. Deep links
MUST be validated before processing.

- **Route constants**: centralized in an `AppRoutes` abstract final class —
  NEVER hardcode path strings.
- **Navigation**: ALWAYS use `context.go()` / `context.push()` / `context.pop()`
  — NEVER `Navigator.of(context)` directly.
- **Tab shell**: `StatefulShellRoute.indexedStack` for the 3 tabs (Trang chủ /
  Lịch sử / Cài đặt) with stable keys to prevent rebuilds.
- **Flow routes**: Send and Receive flows are pushed full-screen routes that
  hide the bottom nav (per Principle VI's IA).
- **Deep links**: validate scheme and parameters before routing; reject
  malformed `safesend://` links and expired/invalid rendezvous payloads.
- **URL scheme**: `safesend://` for deep links and share-link pairing.
- **Stacked modals**: when dismissing then opening, dismiss first and open in a
  post-frame callback — two modals MUST NOT be pushed in the same frame.

**Rationale**: Centralized routing prevents broken navigation and ensures
deep-link validation (a security boundary) cannot be bypassed.

### XI. Feature-First Modularity

The codebase MUST be organized by feature using Clean Architecture. Each feature
MUST be independently developable and testable.

- Directory structure:
  ```
  lib/
    core/
      config/        # App + flavor config, signaling endpoint
      constants/     # Routes, channel/event names, protocol types, asset keys
      di/            # get_it + injectable setup
      domain/        # Result<T>, AppFailure, AppCubit base, transfer entities
      data/          # drift database + DAOs (history)
      presentation/  # Shared widget library + tokens consumers
      router/        # go_router config
      services/      # WebRtcService, SignalingClient, TransferEngine, FileService
      theme/         # AppColors + design tokens
      utils/         # AppLogger, formatters
    features/
      home/  send/  receive/  history/  pairing/  settings/
        data/         # Repository impls, data sources
        domain/       # Models, use cases, repo interfaces
        presentation/ # Cubits, pages, widgets
  ```
- `lib/core/` MUST NOT import from `lib/features/*/`.
- `lib/features/<A>/` MUST NOT import internal files of `lib/features/<B>/`.
- Domain layer MUST NOT import data-layer implementations.
- Cross-feature communication MUST go through core services or DI.
- Repository → Repository dependency is FORBIDDEN; use a UseCase or Service to
  orchestrate.
- DI: `@lazySingleton` for services and shared cubits; `@injectable` for
  screen-scoped cubits; `@singleton` (eager) is FORBIDDEN.

**Rationale**: Clean boundaries let the pairing methods, transfer flows, and
history evolve independently, and keep the transport engine in `core/` free of
feature coupling.

### XII. Testing Discipline

Unit tests are REQUIRED for business logic and data transformations. BLoC tests
are REQUIRED for all Cubits. Widget tests are REQUIRED for transfer-critical
flows.

- Unit tests MUST cover: the transfer protocol (framing, chunking, reassembly,
  integrity), the transfer state machine, signaling message handling, file
  services, formatters, and pairing-code logic.
- The transport engine MUST be testable WITHOUT a live server or second device,
  using the in-process **loopback `SignalingChannel`** (Principle VIII).
- BLoC tests MUST cover all Cubits via `bloc_test`.
- Widget tests MUST cover: Send file-selection, Connect/pairing entry, Receive
  accept/reject, and progress rendering.
- **Two-physical-device smoke tests** are a REQUIRED (often deferred) manual
  task on every transfer-touching spec — pairing, NAT traversal, and real
  throughput cannot be validated in CI. They MUST be tracked in the spec's
  `tasks.md` banner.
- Coverage is NOT gated by a hard CI threshold; reviewers judge adequacy by
  critical-path coverage. Tests MUST be deterministic (no flakiness) and use
  `mocktail`.
- Standard command:
  `very_good test --test-randomize-ordering-seed random`.

**Rationale**: The loopback channel makes the otherwise-untestable P2P engine
fully exercised in CI; the explicit two-device gate acknowledges what CI
genuinely cannot prove and keeps it from being silently skipped.

### XIII. Simplicity & YAGNI

The app MUST stay focused on its core purpose: fast, private, direct file
transfer. Features MUST be built with minimum complexity; premature abstractions
are forbidden.

- Start with the simplest viable implementation per feature.
- Do NOT add configurability, feature flags, or plugin systems unless a spec
  explicitly requires them.
- Prefer Flutter/Dart standard-library solutions over third-party packages when
  capability is equivalent.
- Package additions MUST be justified by a concrete current need.
- Three similar lines are better than a premature abstraction.
- Do NOT add accounts, cloud sync, resume, or trusted-peer features until a spec
  explicitly scopes them (they are post-v1.0).

**Rationale**: A transfer tool benefits from a small surface — less code is less
to break on a flaky link and less to keep private.

### XIV. Internationalization by Default

All user-facing strings MUST be internationalized via Flutter's ARB system. No
hardcoded UI strings.

- All user-facing text MUST live in ARB files under `lib/l10n/arb/`.
- `context.l10n` MUST be used to access localized strings.
- New strings MUST include `@description` annotations.
- Date, time, number, size, and rate formatting MUST use locale-aware `intl`
  formatters.
- Error and validation messages MUST be localized (from `AppFailure` mapping).
- **Primary in-app UI language: Vietnamese** (Gửi / Nhận / Lịch sử); Secondary:
  English. Code, comments, docs, and commits are in English.

**Rationale**: The product's primary audience is Vietnamese; the UI must read
naturally in Vietnamese first, while staying translatable.

### XV. Dependency Hygiene

When adding a new third-party package — or upgrading one — the version and
documentation MUST be fetched from the official source. Versions MUST NOT be
guessed, copied from training data, or carried over from unrelated projects.

- **Latest version sourcing**: before adding to `pubspec.yaml`, look up the
  latest stable on `pub.dev`; for native iOS pods use the CocoaPods Specs repo /
  upstream release page; for SPM/Gradle use upstream tags.
- **Official documentation**: consult the package's official docs for public API
  surface, breaking-change notes, transitive native dependencies, and minimum
  platform versions. Inferring API shape from memory is FORBIDDEN.
- **Native-heavy plugins**: `flutter_webrtc`, camera/scanner, and discovery
  plugins (mDNS/BLE) pull in significant native code — their minimum iOS/Android
  versions, required permissions/entitlements, and transitive pods MUST be
  verified at plan time, before the Dart code is written.
- **Major-version upgrades**: review the CHANGELOG and migration guide BEFORE
  modifying `pubspec.yaml`; cite the breaking changes that affect Safe Send (or
  state that none do) in the PR/spec.
- **Lock files**: `pubspec.lock` and `ios/Podfile.lock` MUST be committed;
  unexpected churn signals an unintended transitive upgrade and MUST be reviewed.
- **Constraints**: new dependencies MUST use a caret constraint (`^X.Y.Z`)
  pinned to the latest stable; `any`/open-ended ranges are FORBIDDEN.
- **No fictional packages**: every package MUST exist on the official registry
  under the exact name written; if not found, stop and ask the user rather than
  guessing a similar name.

**Rationale**: This stack leans on heavy native plugins (WebRTC, camera,
discovery) where a wrong version or an unverified transitive dependency surfaces
only at build/`pod install` time, after the Dart is written. A 30-second
registry lookup at plan time prevents that rework.

## Technical Standards

### Platform & Stack

- **Framework**: Flutter (latest stable) with Dart (latest stable).
- **Target Platforms**: iOS + Android (phones; tablets adapt responsively).
  Desktop/web are post-v1.0.
- **Architecture**: Clean Architecture + MVVM, feature-first.
- **State Management**: Cubit (preferred) / BLoC via `flutter_bloc`.
- **WebRTC**: `flutter_webrtc` (RTCPeerConnection + RTCDataChannel);
  integrity hashing via `crypto`.
- **Signaling**: `web_socket_channel` client → a self-hostable relay in
  `server/`; STUN config + optional encrypted TURN fallback.
- **Local persistence**: drift (SQLite) for transfer history only.
- **DI**: get_it + injectable (`@lazySingleton` / `@injectable`).
- **Router**: go_router with StatefulShellRoute; scheme `safesend://`.
- **Design**: fixed light/dark palette + design tokens from claude_design
  (`ui-design-context.md`); fonts Sora + JetBrains Mono via google_fonts;
  Lucide icons; brand SVGs via flutter_svg.
- **Pairing**: qr_flutter (render) + mobile_scanner (scan); app_links (deep
  links); mDNS/UDP multicast + network_info_plus (and BLE if chosen) for radar.
- **Files**: file_picker, receive_sharing_intent, path_provider, share_plus,
  open_filex; permission_handler.
- **Linting**: very_good_analysis + bloc_lint (zero warnings).
- **Testing**: bloc_test, mocktail, very_good test.
- **i18n**: Flutter ARB + intl (Vietnamese primary, English secondary).
- **Build Flavors**: development, production (per-flavor signaling endpoint +
  bundle id).

### Core Domains

- **Home**: entry surface; Gửi/Nhận actions; recent media & transfers.
- **Send**: file selection (any type, multi-select), session orchestration.
- **Receive**: incoming-transfer prompt, accept/reject, save.
- **Pairing**: 6-digit key, QR, nearby radar, share link → one rendezvous.
- **Transport**: signaling client, WebRTC connection, transfer protocol +
  state machine.
- **History**: persisted transfer metadata, by-day list, re-send.
- **Settings**: device profile, auto-receive, save-to-library, notifications,
  theme, signaling endpoint.

## Development Workflow

### Pre-Commit Checklist (MANDATORY)

```bash
dart format .                    # Format code
flutter analyze                  # Zero warnings
flutter test                     # All tests pass
dart run bloc_tools:bloc lint .  # Zero BLoC violations
```

### Testing Gates

All pull requests MUST pass:

1. All unit and BLoC tests pass.
2. All widget tests pass.
3. Static analysis with zero warnings (`flutter analyze`).
4. BLoC lint with zero violations.
5. Code formatting verified (`dart format`).

### Review Requirements

- All code changes MUST be reviewed before merge.
- Privacy-sensitive changes (signaling, TURN, transport, logging) MUST receive
  additional scrutiny against Principles I & II.
- New package additions MUST be justified and verified per Principle XV.
- History schema changes MUST include migration verification.
- Transfer-protocol changes MUST include loopback round-trip tests and a noted
  two-device smoke test.

### Quality Checks

- Pairing MUST be verified under: valid code, wrong code, expired code, room
  full, and signaling unreachable.
- Transfer round-trip MUST be verified: send → receive → integrity match →
  correct save location.
- Resilience MUST be verified: peer disconnect mid-transfer, network drop,
  app backgrounded, NAT-traversal failure → TURN fallback.
- Throughput and memory MUST be profiled on a large (multi-GB) and a many-file
  transfer to confirm streamed-I/O bounds.
- The "no server holds data" promise MUST be re-verified whenever signaling or
  transport changes: signaling carries no bytes; DTLS active; TURN (if used) not
  persisted/logged.

## Governance

This constitution establishes non-negotiable principles for Safe Send
development. All implementation decisions MUST align with these principles.
On any conflict between this constitution and other guidance, the constitution
wins; `CLAUDE.md` provides runtime development guidance subordinate to it.

### Amendment Process

1. Proposed amendments MUST be documented with rationale.
2. Amendments MUST be reviewed for impact on existing code.
3. Breaking changes require a migration plan before approval.
4. Version MUST be incremented per semantic versioning:
   - MAJOR: principle removal or incompatible redefinition.
   - MINOR: new principle or material expansion.
   - PATCH: clarification or wording refinement.

### Compliance

- All pull requests MUST verify compliance with relevant principles.
- Complexity exceeding these standards MUST be explicitly justified.
- Deviations MUST be documented with rationale and approved by the project lead.
- Use `CLAUDE.md` for runtime development guidance and
  `.claude/claude-app/ui-design-context.md` for UI compliance.

**Version**: 1.0.0 | **Ratified**: 2026-06-24 | **Last Amended**: 2026-06-24
