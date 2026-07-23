#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Diskman"
INSTALL_DIR="${DISKMAN_INSTALL_DIR:-${HOME}/Applications}"
APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "${APP_NAME} is not installed at ${APP_PATH}." >&2
  echo "Install it first or set DISKMAN_INSTALL_DIR to the folder containing ${APP_NAME}.app." >&2
  exit 1
fi

open "${APP_PATH}"
