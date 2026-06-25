# Contract — ConnectLink (QR payload URI)

The single source of truth for the QR payload format. Produced by the sender QR panel, consumed by
the receiver scanner; **#008 share-link reuses it verbatim**.

## URI grammar

```
safesend://connect?v=<version>&code=<code>
```

- `scheme`   = `safesend` (== `AppRoutes.deepLinkScheme`)
- `host`     = `connect`
- `v`        = payload version, integer; current = `1`
- `code`     = 6-digit string matching `SignalingProtocol.codePattern` (`^\d{6}$`)

Canonical example: `safesend://connect?v=1&code=042815`

## API (`lib/core/domain/pairing/connect_link.dart`)

```dart
abstract final class ConnectLink {
  /// Current payload version.
  static const int version = 1;

  /// Build the canonical URI for a valid [code]. Asserts isValidCode in debug.
  static String build(String code);

  /// Parse [raw]; returns the code on success or an AppFailure on any deviation.
  static Result<String> parse(String raw);
}
```

### `parse` acceptance matrix

| Input | Result |
|-------|--------|
| `safesend://connect?v=1&code=042815` | `Ok('042815')` |
| `safesend://connect?v=1&code=42815` (5 digits) | `Err(invalidCode)` |
| `safesend://connect?v=2&code=042815` (unknown version) | `Err(invalidCode)` |
| `safesend://connect?code=042815` (no version) | `Err(invalidCode)` |
| `https://example.com/...` / `WIFI:...` / arbitrary text | `Err(invalidCode)` |
| `safesend://send?...` (wrong target) | `Err(invalidCode)` |
| empty / null-ish | `Err(invalidCode)` |

> `parse` validates **syntax only**. A well-formed but expired code passes `parse` and is rejected
> downstream by the existing join path as `roomExpired` (no duplicate expiry logic here).

## Routes & handoff contracts

| Symbol | Contract |
|--------|----------|
| `AppRoutes.qrScan` | full-screen scanner; `context.push<String>` → pops the parsed **code** (or null on back) |
| `ConnectRequest.openScanner` | bool, default false; receiver panel auto-opens the scanner once when true |
| `ConnectResult.method` | `PairingMethod`, default `sixDigitCode`; set to `qr` when paired via QR tab/scanner |

## Invariants

- The scanner page MUST NOT import `PairingCubit` or any signaling type — it only decodes and
  returns a code (Constitution XI/XIII).
- A single valid detection MUST yield exactly one returned code (debounce latch; FR-014).
- Logs MUST NOT contain the code or raw payload — phase/error-type only (Constitution I; FR-024).
