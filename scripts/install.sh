#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Diskman"
APP_BUNDLE_ID="com.zzzielinski.diskman"
WIDGET_BUNDLE_ID="com.zzzielinski.diskman.widgets"
REPO="zzzielinski/diskman"
ZIP_NAME="${APP_NAME}.app.zip"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ZIP_NAME}"
INSTALL_DIR="${DISKMAN_INSTALL_DIR:-${HOME}/Applications}"
APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"
WIDGET_PATH="${APP_PATH}/Contents/PlugIns/${APP_NAME}Widgets.appex"
LOCAL_ZIP_PATH="${DISKMAN_ZIP_PATH:-}"
OPEN_AFTER_INSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --open)
      OPEN_AFTER_INSTALL=true
      shift
      ;;
    --zip)
      if [[ $# -lt 2 ]]; then
        echo "--zip requires a path to ${ZIP_NAME}." >&2
        exit 1
      fi
      LOCAL_ZIP_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: install.sh [--open] [--zip path/to/${ZIP_NAME}]" >&2
      exit 1
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  if [[ -z "${LOCAL_ZIP_PATH}" ]]; then
    echo "curl is required to download and install ${APP_NAME}." >&2
    exit 1
  fi
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

if [[ -n "${LOCAL_ZIP_PATH}" ]]; then
  if [[ ! -f "${LOCAL_ZIP_PATH}" ]]; then
    echo "Local archive does not exist: ${LOCAL_ZIP_PATH}" >&2
    exit 1
  fi

  echo "Using local ${APP_NAME} archive: ${LOCAL_ZIP_PATH}"
  cp "${LOCAL_ZIP_PATH}" "${TMP_DIR}/${ZIP_NAME}"
else
  echo "Downloading ${APP_NAME}..."
  curl -fL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${ZIP_NAME}"
fi

echo "Extracting ${APP_NAME}..."
unzip -q "${TMP_DIR}/${ZIP_NAME}" -d "${TMP_DIR}"

if [[ ! -d "${TMP_DIR}/${APP_NAME}.app" ]]; then
  echo "Release archive does not contain ${APP_NAME}.app." >&2
  exit 1
fi

mkdir -p "${INSTALL_DIR}"

if pgrep -x "${APP_NAME}" >/dev/null 2>&1; then
  echo "Quitting running ${APP_NAME}..."
  osascript -e "tell application id \"${APP_BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true
  sleep 1
fi

if command -v pluginkit >/dev/null 2>&1; then
  echo "Unregistering old widget extension..."
  pluginkit -r -i "${WIDGET_BUNDLE_ID}" >/dev/null 2>&1 || true
  if [[ -d "${WIDGET_PATH}" ]]; then
    pluginkit -r "${WIDGET_PATH}" >/dev/null 2>&1 || true
  fi
fi

if [[ -d "${APP_PATH}" ]]; then
  echo "Replacing existing ${APP_PATH}..."
  rm -rf "${APP_PATH}"
fi

ditto "${TMP_DIR}/${APP_NAME}.app" "${APP_PATH}"
touch "${APP_PATH}" >/dev/null 2>&1 || true
if [[ -d "${WIDGET_PATH}" ]]; then
  touch "${WIDGET_PATH}" >/dev/null 2>&1 || true
fi

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
if [[ -x "${LSREGISTER}" ]]; then
  "${LSREGISTER}" -f -R "${APP_PATH}" >/dev/null 2>&1 || true
  if [[ -d "${WIDGET_PATH}" ]]; then
    "${LSREGISTER}" -f -R "${WIDGET_PATH}" >/dev/null 2>&1 || true
  fi
fi

if [[ -d "${WIDGET_PATH}" ]] && command -v pluginkit >/dev/null 2>&1; then
  pluginkit -a "${WIDGET_PATH}" >/dev/null 2>&1 || true
fi

echo "Refreshing macOS widget and icon caches..."
pkill -x chronod >/dev/null 2>&1 || true
pkill -x iconservicesagent >/dev/null 2>&1 || true

echo "${APP_NAME} installed at ${APP_PATH}"
if [[ "${OPEN_AFTER_INSTALL}" == true ]]; then
  open "${APP_PATH}"
else
  echo "Open it from Finder or run: open '${APP_PATH}'"
fi
