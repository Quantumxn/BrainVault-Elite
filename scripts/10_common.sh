#!/usr/bin/env bash

declare -ag EXECUTION_EVENTS=()
declare -ag DRY_RUN_COMMANDS=()

RUN_ID="${RUN_ID:-}"
LOG_DIR="${LOG_DIR:-}"

init_environment() {
  RUN_ID="brainvault_$(date +%Y%m%d_%H%M%S)"
  LOG_DIR="${LOG_DIR:-/var/log}"
  if [[ ! -w "${LOG_DIR}" ]]; then
    LOG_DIR="${SCRIPT_DIR}/logs"
    mkdir -p "${LOG_DIR}"
  fi

  LOG_FILE="${LOG_DIR}/${RUN_ID}.log"
  if ! touch "${LOG_FILE}" 2>/dev/null; then
    LOG_FILE="${SCRIPT_DIR}/${RUN_ID}.log"
    if ! touch "${LOG_FILE}" 2>/dev/null; then
      echo "[ERROR] Unable to initialize log file." >&2
      exit 1
    fi
  fi

  logging_initialize "${LOG_FILE}"
  log_section "Environment Initialization"
  log_info "Log file: ${LOG_FILE}"
  log_info "Working directory: ${SCRIPT_DIR}"
}

ensure_root() {
  if [[ ${EUID} -ne 0 ]]; then
    log_error "BrainVault Elite must run as root."
    exit 1
  fi
}

handle_error() {
  local exit_code="$1"
  local failed_command="$2"
  local source_line="$3"
  log_error "Command '${failed_command}' failed with exit code ${exit_code} at line ${source_line}."
  print_execution_summary
  print_dry_run_summary
  exit "${exit_code}"
}

on_exit() {
  local exit_code=$?
  if [[ ${exit_code} -eq 0 ]]; then
    log_success "BrainVault Elite completed successfully."
  else
    log_warn "BrainVault Elite exited with status ${exit_code}."
  fi
}

register_global_traps() {
  trap 'handle_error $? "${BASH_COMMAND}" ${LINENO}' ERR
  trap 'on_exit' EXIT
}

record_execution_event() {
  EXECUTION_EVENTS+=("$1")
}

record_dry_run() {
  DRY_RUN_COMMANDS+=("$1")
  log_dry_run "$1"
}

run_cmd() {
  local cmd="$1"
  local description="$2"

  log_info "${description}"
  if [[ "${DRY_RUN}" == true ]]; then
    record_dry_run "${description} :: ${cmd}"
    return 0
  fi

  if eval "${cmd}"; then
    log_success "Completed: ${description}"
    record_execution_event "${description}"
    return 0
  fi

  local exit_code=$?
  log_error "Failed: ${description}"
  return "${exit_code}"
}

install_pkg() {
  local packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then
    log_warn "install_pkg called without packages."
    return 0
  fi
  local pkg_list shell_cmd
  pkg_list="${packages[*]}"
  shell_cmd="DEBIAN_FRONTEND=noninteractive apt-get install -y ${pkg_list}"
  run_cmd "${shell_cmd}" "Installing packages: ${pkg_list}"
}

write_file() {
  local target="$1"
  local content="$2"
  local description="$3"

  log_info "${description}"
  if [[ "${DRY_RUN}" == true ]]; then
    local dry_message
    dry_message=$(printf "%s :: write contents to %s" "${description}" "${target}")
    record_dry_run "${dry_message}"
    return 0
  fi

  printf '%s\n' "${content}" >"${target}"
  local exit_code=$?
  if [[ ${exit_code} -eq 0 ]]; then
    chmod 0640 "${target}" 2>/dev/null || true
    log_success "Wrote ${target}"
    record_execution_event "${description}"
    return 0
  fi

  log_error "Failed to write ${target}"
  return ${exit_code}
}

validate_syntax() {
  local root_dir="$1"
  log_section "Syntax Validation"
  local errors=0
  while IFS= read -r -d '' script_file; do
    if bash -n "${script_file}"; then
      log_debug "Syntax OK: ${script_file}"
    else
      log_error "Syntax error detected in ${script_file}"
      ((errors++))
    fi
  done < <(find "${root_dir}" -maxdepth 2 -type f -name '*.sh' -print0)

  if (( errors > 0 )); then
    log_error "Bash syntax validation failed."
    exit 1
  fi
  log_success "All bash scripts passed syntax validation."
}

preflight_checks() {
  log_section "Preflight Checks"
  local -a required_commands=(apt-get systemctl rsync tee)
  local missing=0
  for cmd in "${required_commands[@]}"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      log_warn "Missing required command: ${cmd}"
      ((missing++))
    fi
  done
  if (( missing > 0 )); then
    log_warn "Some required commands are missing. Installation steps may fail."
  else
    log_success "Preflight checks passed."
  fi
}

print_execution_summary() {
  if [[ ${#EXECUTION_EVENTS[@]} -eq 0 ]]; then
    log_summary "No actions were executed."
    return
  fi
  log_section "Execution Summary"
  for entry in "${EXECUTION_EVENTS[@]}"; do
    log_summary "✔ ${entry}"
  done
}

print_dry_run_summary() {
  if [[ "${DRY_RUN}" != true ]]; then
    return
  fi
  log_section "Dry-Run Summary"
  if [[ ${#DRY_RUN_COMMANDS[@]} -eq 0 ]]; then
    log_summary "No commands were registered in dry-run mode."
    return
  fi
  local index=1
  for entry in "${DRY_RUN_COMMANDS[@]}"; do
    log_summary "${index}. ${entry}"
    ((index++))
  done
}
