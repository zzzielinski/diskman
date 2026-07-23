#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Diskman"
REPO="zzzielinski/diskman"
ZIP_NAME="${APP_NAME}.app.zip"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ZIP_NAME}"
INSTALL_DIR="${DISKMAN_INSTALL_DIR:-${HOME}/Applications}"
APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to install ${APP_NAME}." >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "unzip is required to install ${APP_NAME}." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "Downloading ${APP_NAME}..."
curl -fL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${ZIP_NAME}"

echo "Extracting ${APP_NAME}..."
unzip -q "${TMP_DIR}/${ZIP_NAME}" -d "${TMP_DIR}"

if [[ ! -d "${TMP_DIR}/${APP_NAME}.app" ]]; then
  echo "Release archive does not contain ${APP_NAME}.app." >&2
  exit 1
fi

mkdir -p "${INSTALL_DIR}"

if [[ -d "${APP_PATH}" ]]; then
  echo "Replacing existing ${APP_PATH}..."
  rm -rf "${APP_PATH}"
fi

ditto "${TMP_DIR}/${APP_NAME}.app" "${APP_PATH}"

echo "${APP_NAME} installed at ${APP_PATH}"
echo "Open it from Finder or run: open '${APP_PATH}'"
