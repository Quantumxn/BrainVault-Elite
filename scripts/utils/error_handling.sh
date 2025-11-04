#!/usr/bin/env bash
# Provides error handling helpers and dependency checks.

if [[ -n "${BRAINVAULT_ERROR_HANDLING_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_ERROR_HANDLING_SH=1

if ! command -v log_error >/dev/null 2>&1; then
  echo "[ERROR] logging.sh must be sourced before error_handling.sh" >&2
  return 1
fi

_current_step=""

handle_error() {
  local exit_code=$1
  local line_no=$2
  local step_message=${_current_step:-"Unknown step"}
  log_error "Failed at step: ${step_message} (line: ${line_no}, exit: ${exit_code})"
  return $exit_code
}

register_error_trap() {
  trap 'handle_error $? ${LINENO}' ERR
}

with_error_context() {
  local description="$1"
  shift
  _current_step="${description}"
  "$@"
  local status=$?
  _current_step=""
  return $status
}

ensure_dependencies() {
  local missing=()
  local dependency
  for dependency in "$@"; do
    if ! command -v "${dependency}" >/dev/null 2>&1; then
      missing+=("${dependency}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log_error "Missing dependencies: ${missing[*]}"
    return 1
  fi

  log_debug "Dependencies satisfied: $*"
  return 0
}

safe_run() {
  local description="$1"
  shift
  with_error_context "${description}" "$@"
}

perform_step() {
  local description="$1"
  shift
  safe_run "${description}" run_step "${description}" "$@"
}

