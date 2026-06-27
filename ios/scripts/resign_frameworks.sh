#!/bin/sh
# #011 — Re-sign embedded frameworks with the app's signing identity.
#
# Workaround for a Flutter native-assets bug: `objective_c.framework` (pulled in
# by live_activities -> objective_c) ships with an invalid signature on iOS
# device builds, so installs fail with
#   "Failed to verify code signature of .../objective_c.framework : 0xe8008014".
# Re-signing every embedded framework at the end of the build fixes it and makes
# incremental `flutter run` reliable (no more `flutter clean` each time).
set -e

# Nothing to do for simulator / no-codesign builds.
[ "${CODE_SIGNING_ALLOWED}" = "YES" ] || exit 0
[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] || exit 0

FW_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
[ -d "${FW_DIR}" ] || exit 0

find "${FW_DIR}" -maxdepth 1 -name '*.framework' -print0 | while IFS= read -r -d '' FW; do
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
    --preserve-metadata=identifier,entitlements,flags --timestamp=none "${FW}"
done
