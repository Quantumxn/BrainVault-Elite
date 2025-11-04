#!/usr/bin/env bash
# Provides dry-run simulation controls and execution helpers.

if [[ -n "${BRAINVAULT_DRYRUN_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_DRYRUN_SH=1

if ! command -v log_info >/dev/null 2>&1; then
  echo "[ERROR] logging.sh must be sourced before dryrun.sh" >&2
  return 1
fi

: "${DRY_RUN_MODE:=false}"

enable_dry_run() {
  DRY_RUN_MODE=true
  export DRY_RUN_MODE
  log_warn "Dry-run mode enabled: actions will be simulated"
}

disable_dry_run() {
  DRY_RUN_MODE=false
  export DRY_RUN_MODE
}

is_dry_run() {
  [[ "${DRY_RUN_MODE}" == "true" ]]
}

run_step() {
  local description="$1"
  shift
  if is_dry_run; then
    log_info "[DRY-RUN] ${description}"
    return 0
  fi

  if [[ $# -eq 0 ]]; then
    log_warn "run_step invoked without a command for: ${description}"
    return 0
  fi

  "$@"
}

