#!/usr/bin/env bash

# Global logging state
LOG_INITIALIZED=${LOG_INITIALIZED:-false}
LOG_COLORS_ENABLED=${LOG_COLORS_ENABLED:-false}
LOG_COLOR_RESET=${LOG_COLOR_RESET:-""}

declare -Ag LOG_COLOR_MAP=()

_logging_detect_color_support() {
  if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    local colors
    colors=$(tput colors 2>/dev/null || echo 0)
    if [[ ${colors} -ge 8 ]]; then
      LOG_COLORS_ENABLED=true
      LOG_COLOR_MAP[INFO]='\033[1;34m'
      LOG_COLOR_MAP[WARN]='\033[1;33m'
      LOG_COLOR_MAP[ERROR]='\033[1;31m'
      LOG_COLOR_MAP[SUCCESS]='\033[1;32m'
      LOG_COLOR_MAP[SUMMARY]='\033[1;35m'
      LOG_COLOR_MAP[SECTION]='\033[1;36m'
      LOG_COLOR_MAP[DEBUG]='\033[0;36m'
      LOG_COLOR_RESET='\033[0m'
      return
    fi
  fi
  LOG_COLORS_ENABLED=false
  LOG_COLOR_RESET=''
}

_logging_format_prefix() {
  local level="$1"
  printf '[%s] [%s]' "$(date '+%F %T')" "${level}"
}

_logging_emit() {
  local level="$1"
  local message="$2"
  local prefix
  prefix=$(_logging_format_prefix "${level}")
  local line="${prefix} ${message}"

  if [[ "${LOG_COLORS_ENABLED}" == true ]]; then
    local color="${LOG_COLOR_MAP[${level}]:-}"
    if [[ -n "${color}" ]]; then
      printf '%b%s%b\n' "${color}" "${line}" "${LOG_COLOR_RESET}" >&2
    else
      printf '%s\n' "${line}" >&2
    fi
  else
    printf '%s\n' "${line}" >&2
  fi

  if [[ "${LOG_INITIALIZED}" == true && -n "${LOG_FILE:-}" ]]; then
    printf '%s\n' "${line}" >>"${LOG_FILE}" 2>/dev/null || true
  fi
}

log_info() {
  _logging_emit INFO "$*"
}

log_debug() {
  if [[ "${LOG_LEVEL:-INFO}" == DEBUG ]]; then
    _logging_emit DEBUG "$*"
  fi
}

log_warn() {
  _logging_emit WARN "$*"
}

log_error() {
  _logging_emit ERROR "$*"
}

log_success() {
  _logging_emit SUCCESS "$*"
}

log_summary() {
  _logging_emit SUMMARY "$*"
}

log_section() {
  local title="$*"
  if [[ -n "${title}" ]]; then
    _logging_emit SECTION "==== ${title} ===="
  else
    _logging_emit SECTION "========================================"
  fi
}

log_dry_run() {
  _logging_emit INFO "(dry-run) $*"
}

logging_initialize() {
  LOG_FILE="$1"
  LOG_LEVEL="${LOG_LEVEL:-INFO}"
  LOG_INITIALIZED=true
  _logging_detect_color_support
}
