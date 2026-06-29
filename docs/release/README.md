# Safe Send — v1.0 Release Artifacts (#014)

Staging area for everything needed to ship v1.0. Per the spec, #014 makes the
app **release-ready but does NOT submit** — the maintainer submits with their
own Apple/Google accounts (FR-029).

## Contents

| File | Purpose | Task |
|---|---|---|
| [security-verification.md](security-verification.md) | Re-runnable privacy/security audit (signaling, DTLS, TURN, logs) | US2 / T025 |
| [smoke-matrix.md](smoke-matrix.md) | Two-device on-device validation backlog (#002–#013) | US5 |
| [store-listing.md](store-listing.md) | Metadata, screenshots, privacy policy, data-safety/nutrition answers | US6 / T044–T046 |
| [a11y-audit.md](a11y-audit.md) | Per-screen VoiceOver/TalkBack + Dynamic Type + Reduced Motion checklist | US3 / T028 |
| [dark-mode-audit.md](dark-mode-audit.md) | Per-screen dark-mode / token / contrast checklist | US4 / T034 |

## Build commands (T043)

```sh
# iOS (prod, obfuscated + split debug info)
flutter build ipa --flavor prod -t lib/main_prod.dart \
  --obfuscate --split-debug-info=build/symbols/ios

# Android (prod, obfuscated)
flutter build appbundle --flavor prod -t lib/main_prod.dart \
  --obfuscate --split-debug-info=build/symbols/android
```

Signing/provisioning is configured in `ios/` (signing Team) and
`android/app/build.gradle` (release signingConfig). Confirm the prod build
installs + runs on a real device before considering US6 done.
