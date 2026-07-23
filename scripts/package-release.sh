#!/usr/bin/env bash
set -euo pipefail

PROJECT="Diskman.xcodeproj"
SCHEME="DiskmanApp"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/DerivedData}"
RELEASE_DIR="${RELEASE_DIR:-build/release}"
APP_PRODUCT_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/Diskman.app"
WIDGET_PRODUCT_PATH="${APP_PRODUCT_PATH}/Contents/PlugIns/DiskmanWidgets.appex"
ZIP_PATH="${RELEASE_DIR}/Diskman.app.zip"
CHECKSUM_PATH="${ZIP_PATH}.sha256"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/diskman-release.XXXXXX")"
STAGED_APP_PATH="${STAGING_DIR}/Diskman.app"
STAGED_WIDGET_PATH="${STAGED_APP_PATH}/Contents/PlugIns/DiskmanWidgets.appex"

cleanup() {
  rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination platform=macOS \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "${APP_PRODUCT_PATH}" ]]; then
  echo "Build did not produce ${APP_PRODUCT_PATH}" >&2
  exit 1
fi

if [[ ! -d "${WIDGET_PRODUCT_PATH}" ]]; then
  echo "Build did not embed ${WIDGET_PRODUCT_PATH}" >&2
  exit 1
fi

echo "Staging clean app bundle..."
ditto --noextattr --noqtn "${APP_PRODUCT_PATH}" "${STAGED_APP_PATH}"

echo "Cleaning extended attributes..."
xattr -cr "${STAGED_APP_PATH}"

echo "Signing widget extension..."
codesign \
  --force \
  --sign - \
  --timestamp=none \
  --entitlements DiskmanWidgets/DiskmanWidgets.entitlements \
  "${STAGED_WIDGET_PATH}"

echo "Cleaning app extended attributes..."
xattr -cr "${STAGED_APP_PATH}"

echo "Signing app..."
codesign \
  --force \
  --sign - \
  --timestamp=none \
  --entitlements DiskmanApp/DiskmanApp.entitlements \
  "${STAGED_APP_PATH}"

echo "Cleaning signed app extended attributes..."
xattr -cr "${STAGED_APP_PATH}"

codesign --verify --deep --strict --verbose=2 "${STAGED_APP_PATH}"

COPYFILE_DISABLE=1 ditto --norsrc -c -k --keepParent "${STAGED_APP_PATH}" "${ZIP_PATH}"
shasum -a 256 "${ZIP_PATH}" > "${CHECKSUM_PATH}"

echo "Created ${ZIP_PATH}"
echo "Created ${CHECKSUM_PATH}"
