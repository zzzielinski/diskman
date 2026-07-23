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

echo "Cleaning extended attributes..."
xattr -cr "${APP_PRODUCT_PATH}"

echo "Signing widget extension..."
codesign \
  --force \
  --sign - \
  --timestamp=none \
  --entitlements DiskmanWidgets/DiskmanWidgets.entitlements \
  "${WIDGET_PRODUCT_PATH}"

echo "Cleaning app extended attributes..."
xattr -cr "${APP_PRODUCT_PATH}"

echo "Signing app..."
codesign \
  --force \
  --sign - \
  --timestamp=none \
  --entitlements DiskmanApp/DiskmanApp.entitlements \
  "${APP_PRODUCT_PATH}"

echo "Cleaning signed app extended attributes..."
xattr -cr "${APP_PRODUCT_PATH}"

codesign --verify --deep --strict --verbose=2 "${APP_PRODUCT_PATH}"

ditto -c -k --keepParent "${APP_PRODUCT_PATH}" "${ZIP_PATH}"
shasum -a 256 "${ZIP_PATH}" > "${CHECKSUM_PATH}"

echo "Created ${ZIP_PATH}"
echo "Created ${CHECKSUM_PATH}"
