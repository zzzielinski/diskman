#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Diskman"
INSTALL_DIR="${DISKMAN_INSTALL_DIR:-${HOME}/Applications}"
APP_PATH="${INSTALL_DIR}/${APP_NAME}.app"
APP_GROUP_ID="group.com.zzzielinski.diskman"
APP_GROUP_CONTAINER="${HOME}/Library/Group Containers/${APP_GROUP_ID}"

if [[ -d "${APP_PATH}" ]]; then
  echo "Removing ${APP_PATH}..."
  rm -rf "${APP_PATH}"
else
  echo "${APP_PATH} does not exist."
fi

if [[ "${1:-}" == "--remove-data" ]]; then
  if [[ -d "${APP_GROUP_CONTAINER}" ]]; then
    echo "Removing local Diskman data..."
    rm -rf "${APP_GROUP_CONTAINER}"
  fi
else
  echo "Local widget snapshots and settings were kept."
  echo "Run with --remove-data to remove ${APP_GROUP_CONTAINER}"
fi

echo "${APP_NAME} uninstalled."
