<!-- SPECKIT START -->
# Safe Send — Agent Context

Active feature: **#001 Project Foundation & Navigation** (branch `001-project-foundation`).
Current plan: [specs/001-project-foundation/plan.md](specs/001-project-foundation/plan.md)
Spec: [specs/001-project-foundation/spec.md](specs/001-project-foundation/spec.md)

## Project meta (read these first)
- Constitution (authoritative, 15 principles): [.specify/memory/constitution.md](.specify/memory/constitution.md)
- Roadmap: [.claude/claude-app/sdd-roadmap.md](.claude/claude-app/sdd-roadmap.md)
- Project context: [.claude/claude-app/project-context.md](.claude/claude-app/project-context.md)
- UI design source of truth: [.claude/claude-app/ui-design-context.md](.claude/claude-app/ui-design-context.md)
- Dev workflow: [.claude/claude-app/dev-workflow.md](.claude/claude-app/dev-workflow.md)

## What Safe Send is
Cross-platform (iOS + Android, Flutter) P2P file-sharing app over WebRTC — **no intermediary server holds the data**. Surfaces: Gửi (Send) / Nhận (Receive) / Lịch sử (History). Pairing: 6-digit / QR / nearby radar / share link. Fixed light & dark palette.

## Stack (current — #001)
- Flutter (latest stable) / Dart 3.5+; Clean Architecture + feature-first; BLoC (`flutter_bloc` 9.1.1, 4-state freezed); DI `get_it` 9.2.1 + `injectable` 3.0.0; router `go_router` 17.3.0 (StatefulShellRoute, scheme `safesend://`).
- UI: fixed design tokens (Sora + JetBrains Mono bundled fonts), `lucide_icons_flutter` 3.1.14+2, `flutter_svg` 2.3.0, `toastification` 3.2.0, splash via `flutter_native_splash` 2.4.8.
- Codegen: `freezed` 3.2.5 / `json_serializable` 6.14.0 / `build_runner` 2.15.0. i18n: ARB + `intl` 0.20.2 (VI primary, EN; VI fallback). Lint: `very_good_analysis` 10.3.0 + `bloc_lint`. Test: `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5.
- Target: iOS 13.0+ / Android 8.0 (API 26)+. Flavors: dev (`app.safesend.dev`) / prod (`app.safesend`). No networking/persistence in #001.

## Key rules (see constitution for full list)
- `lib/core/` MUST NOT import `lib/features/`. Shared widget library lives in `core/presentation/`.
- BLoC 4-state freezed; inject Use Cases (not repos) into Cubits; page-scoped providers.
- All visual props from design tokens (semantic aliases) — never hardcode hex. Numeric/technical text uses mono + tabular figures.
- `AppToast` for messages (never raw ScaffoldMessenger); `AppLogger` for logs (never print). `AppRoutes` constants; `context.go/push/pop` only.
- All UI strings via ARB (VI primary). Pre-commit: `dart format` · `flutter analyze` (0) · `flutter test` · `bloc lint` (0). Package versions: fetch from pub.dev, never guess (Constitution XV).
<!-- SPECKIT END -->
