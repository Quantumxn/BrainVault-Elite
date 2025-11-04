#!/usr/bin/env bash

set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Load utilities first
source "${PROJECT_ROOT}/scripts/utils/logging.sh"
source "${PROJECT_ROOT}/scripts/utils/error_handling.sh"
source "${PROJECT_ROOT}/scripts/utils/dryrun.sh"

register_error_trap

# Auto-source remaining modules (excluding validate script which is executable)
while IFS= read -r module; do
  case "${module}" in
    *scripts/utils/*|*scripts/validate_syntax.sh) continue ;;
    *) source "${module}" ;;
  esac
done < <(find "${PROJECT_ROOT}/scripts" -type f -name "*.sh" | sort)

# Default runtime flags
: "${DRY_RUN_MODE:=false}"
: "${DEBUG_MODE:=false}"
SKIP_AI=false
SKIP_SECURITY=false
SECURE_MODE=false
DISABLE_TELEMETRY=false
PARALLEL_MODE=false

usage() {
  cat <<'EOF'
BrainVault Elite — Modular DevSecOps + AI Bootstrap

Usage: ./brainvault_elite.sh [options]

Options:
  --dry-run             Simulate actions without making changes
  --skip-ai             Skip development and AI stack
  --skip-security       Skip security hardening
  --secure              Enable enhanced secure mode policies
  --disable-telemetry   Block telemetry endpoints
  --parallel            Run compatible tasks in parallel
  --debug               Enable verbose debug logging
  --validate-only       Only run syntax validation
  -h, --help            Show this help message
EOF
}

parse_args() {
  local validate_only=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        enable_dry_run
        ;;
      --skip-ai)
        SKIP_AI=true
        ;;
      --skip-security)
        SKIP_SECURITY=true
        ;;
      --secure)
        SECURE_MODE=true
        export SECURE_MODE
        ;;
      --disable-telemetry)
        DISABLE_TELEMETRY=true
        export DISABLE_TELEMETRY
        ;;
      --parallel)
        PARALLEL_MODE=true
        ;;
      --debug)
        DEBUG_MODE=true
        export DEBUG_MODE
        ;;
      --validate-only)
        validate_only=true
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  echo "${validate_only}"
}

validate_syntax() {
  local validator="${PROJECT_ROOT}/scripts/validate_syntax.sh"
  if [[ ! -x "${validator}" ]]; then
    log_warn "Validation script not executable or missing at ${validator}"
    return 1
  fi

  log_info "Validating shell syntax"
  bash "${validator}"
}

run_functions() {
  local -a functions=("$@")
  if [[ "${PARALLEL_MODE}" == "true" && ${#functions[@]} -gt 1 ]]; then
    log_debug "Executing functions in parallel: ${functions[*]}"
    local pids=()
    local fn
    for fn in "${functions[@]}"; do
      (
        "${fn}"
      ) &
      pids+=($!)
    done

    local exit_code=0
    for pid in "${pids[@]}"; do
      if ! wait "${pid}"; then
        exit_code=1
      fi
    done
    return "${exit_code}"
  fi

  local fn
  for fn in "${functions[@]}"; do
    "${fn}"
  done
}

main() {
  local validate_only
  validate_only=$(parse_args "$@")

  if [[ "${DEBUG_MODE}" == "true" ]]; then
    log_debug "Debug logging enabled"
  fi

  validate_syntax

  if [[ "${validate_only}" == "true" ]]; then
    log_info "Validation-only mode complete"
    exit 0
  fi

  if [[ "${SKIP_SECURITY}" != "true" ]]; then
    run_functions run_security_installation
    run_functions run_security_configuration
  else
    log_warn "Security stack skipped"
  fi

  if [[ "${SKIP_AI}" != "true" ]]; then
    run_functions run_dev_installation
    run_functions run_dev_configuration
  else
    log_warn "Development and AI stack skipped"
  fi

  run_functions run_monitoring_installation
  run_functions run_monitoring_configuration

  log_success "BrainVault Elite execution completed"
}

main "$@"

