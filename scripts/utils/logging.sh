#!/usr/bin/env bash
# Provides color-coded logging utilities.

if [[ -n "${BRAINVAULT_LOGGING_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_LOGGING_SH=1

# shellcheck disable=SC2034
RESET="\033[0m"
COLOR_INFO="\033[1;34m"
COLOR_WARN="\033[1;33m"
COLOR_ERROR="\033[1;31m"
COLOR_SUCCESS="\033[1;32m"
COLOR_DEBUG="\033[1;36m"

: "${DEBUG_MODE:=false}"

_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

_log() {
  local level="$1"
  local color="$2"
  shift 2
  local message="$*"
  printf '%b[%s] %s%b %s\n' "${color}" "$( _timestamp )" "${level}" "${RESET}" "${message}"
}

log_info() {
  _log INFO "${COLOR_INFO}" "$*"
}

log_warn() {
  _log WARN "${COLOR_WARN}" "$*"
}

log_error() {
  _log ERROR "${COLOR_ERROR}" "$*"
}

log_success() {
  _log SUCCESS "${COLOR_SUCCESS}" "$*"
}

log_debug() {
  if [[ "${DEBUG_MODE}" == "true" ]]; then
    _log DEBUG "${COLOR_DEBUG}" "$*"
  fi
}

