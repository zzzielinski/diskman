#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Diskman"
APP_BUNDLE_ID="com.zzzielinski.diskman"
WIDGET_BUNDLE_ID="com.zzzielinski.diskman.widgets"
APP_GROUP_ID="group.com.zzzielinski.diskman"
WORKSPACE_ROOT="/Users/maksymilianzielinski/Desktop/diskman_widget"

REMOVE_DATA=true
DRY_RUN=false
EXTRA_APP_PATHS=()
EXTRA_APP_PATHS_COUNT=0

usage() {
  cat <<USAGE
Usage: uninstall.sh [--dry-run] [--keep-data] [--app path/to/Diskman.app]

Uninstalls Diskman and removes local Diskman files, while explicitly preserving:
  ${WORKSPACE_ROOT}

Options:
  --dry-run      Print what would be removed without deleting anything.
  --keep-data    Remove the app only; keep settings, snapshots, and caches.
  --app PATH     Also remove a specific Diskman.app path.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --keep-data)
      REMOVE_DATA=false
      shift
      ;;
    --remove-data)
      REMOVE_DATA=true
      shift
      ;;
    --app)
      if [[ $# -lt 2 ]]; then
        echo "--app requires a path." >&2
        exit 1
      fi
      EXTRA_APP_PATHS+=("$2")
      EXTRA_APP_PATHS_COUNT=$((EXTRA_APP_PATHS_COUNT + 1))
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

run() {
  if [[ "${DRY_RUN}" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

canonical_path() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    /usr/bin/perl -MCwd=abs_path -e 'print abs_path(shift)' "${path}"
  else
    local parent
    parent="$(dirname "${path}")"
    local base
    base="$(basename "${path}")"
    if [[ -e "${parent}" ]]; then
      printf '%s/%s' "$(/usr/bin/perl -MCwd=abs_path -e 'print abs_path(shift)' "${parent}")" "${base}"
    else
      printf '%s' "${path}"
    fi
  fi
}

is_workspace_path() {
  local path="$1"
  local canonical
  canonical="$(canonical_path "${path}")"
  [[ "${canonical}" == "${WORKSPACE_ROOT}" || "${canonical}" == "${WORKSPACE_ROOT}/"* ]]
}

remove_path() {
  local path="$1"
  local label="${2:-${path}}"

  if [[ ! -e "${path}" ]]; then
    echo "Not found: ${label}"
    return
  fi

  if is_workspace_path "${path}"; then
    echo "Skipping workspace path: ${path}"
    return
  fi

  echo "Removing ${label}: ${path}"
  run rm -rf "${path}"
}

forget_defaults() {
  local domain="$1"
  if [[ "${DRY_RUN}" == true ]]; then
    echo "[dry-run] defaults delete ${domain}"
    return
  fi

  defaults delete "${domain}" >/dev/null 2>&1 || true
}

quit_diskman() {
  echo "Quitting ${APP_NAME} if it is running..."
  run osascript -e "tell application id \"${APP_BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true
  sleep 1
  run pkill -x "${APP_NAME}" >/dev/null 2>&1 || true
}

unregister_widgets() {
  if ! command -v pluginkit >/dev/null 2>&1; then
    return
  fi

  echo "Unregistering widget extension..."
  run pluginkit -r -i "${WIDGET_BUNDLE_ID}" >/dev/null 2>&1 || true
}

refresh_system_caches() {
  local lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
  if [[ -x "${lsregister}" ]]; then
    echo "Refreshing Launch Services..."
    run "${lsregister}" -kill -r -domain user >/dev/null 2>&1 || true
  fi

  echo "Refreshing macOS widget cache..."
  run pkill -x chronod >/dev/null 2>&1 || true
}

app_paths=(
  "${HOME}/Applications/${APP_NAME}.app"
  "/Applications/${APP_NAME}.app"
)

if [[ -n "${DISKMAN_INSTALL_DIR:-}" && "${DISKMAN_INSTALL_DIR}" != "${HOME}/Applications" ]]; then
  app_paths+=("${DISKMAN_INSTALL_DIR}/${APP_NAME}.app")
fi

if [[ "${EXTRA_APP_PATHS_COUNT}" -gt 0 ]]; then
  for app_path in "${EXTRA_APP_PATHS[@]}"; do
    app_paths+=("${app_path}")
  done
fi

data_paths=(
  "${HOME}/Library/Group Containers/${APP_GROUP_ID}"
  "${HOME}/Library/Application Support/${APP_NAME}"
  "${HOME}/Library/Caches/${APP_BUNDLE_ID}"
  "${HOME}/Library/Caches/${WIDGET_BUNDLE_ID}"
  "${HOME}/Library/HTTPStorages/${APP_BUNDLE_ID}"
  "${HOME}/Library/HTTPStorages/${WIDGET_BUNDLE_ID}"
  "${HOME}/Library/Preferences/${APP_BUNDLE_ID}.plist"
  "${HOME}/Library/Preferences/${WIDGET_BUNDLE_ID}.plist"
  "${HOME}/Library/Saved Application State/${APP_BUNDLE_ID}.savedState"
  "${HOME}/Library/Logs/${APP_NAME}"
)

echo "Diskman uninstall started."
quit_diskman
unregister_widgets

for app_path in "${app_paths[@]}"; do
  remove_path "${app_path}" "application bundle"
done

if [[ "${REMOVE_DATA}" == true ]]; then
  echo "Removing Diskman settings, snapshots, caches, and logs..."
  for data_path in "${data_paths[@]}"; do
    remove_path "${data_path}"
  done
  forget_defaults "${APP_BUNDLE_ID}"
  forget_defaults "${WIDGET_BUNDLE_ID}"
  forget_defaults "${APP_GROUP_ID}"
else
  echo "Keeping Diskman settings, snapshots, caches, and logs."
fi

refresh_system_caches

echo "Diskman uninstall finished."
