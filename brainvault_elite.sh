#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${ROOT_DIR}/scripts"

if [[ ! -d "${SCRIPTS_DIR}" ]]; then
    echo "[ERROR] scripts directory not found at ${SCRIPTS_DIR}" >&2
    exit 1
fi

while IFS= read -r module; do
    # shellcheck source=/dev/null
    source "$module"
done < <(find "${SCRIPTS_DIR}" -type f -name '*.sh' | sort)

usage() {
    cat <<'EOF'
BrainVault Elite — Modular DevSecOps + AI Bootstrap

Usage: sudo ./brainvault_elite.sh [options]

Options:
  --dry-run             Simulate actions without applying changes
  --skip-ai             Skip developer + AI stack provisioning
  --skip-security       Skip security hardening stack
  --skip-monitoring     Skip monitoring & backup stack
  --secure              Enable enhanced kernel/network hardening
  --disable-telemetry   Block telemetry endpoints and packages
  --parallel            Execute stack provisioning in parallel
  --debug               Enable verbose debug logging
  --target-user <name>  User to grant container runtime access (default: SUDO_USER or current)
  --help                Show this help message
EOF
}

DRY_RUN="${DRY_RUN:-false}"
SKIP_SECURITY=false
SKIP_AI=false
SKIP_MONITORING=false
SECURE_MODE=false
DISABLE_TELEMETRY=false
PARALLEL_MODE=false
DEBUG_MODE=false
TARGET_USER="${TARGET_USER:-${SUDO_USER:-${USER}}}"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                enable_dry_run
                shift
                ;;
            --skip-ai)
                SKIP_AI=true
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-monitoring)
                SKIP_MONITORING=true
                shift
                ;;
            --secure)
                SECURE_MODE=true
                shift
                ;;
            --disable-telemetry)
                DISABLE_TELEMETRY=true
                shift
                ;;
            --parallel)
                PARALLEL_MODE=true
                shift
                ;;
            --debug)
                DEBUG_MODE=true
                set_log_level "DEBUG"
                shift
                ;;
            --target-user)
                TARGET_USER="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"

    export DRY_RUN SKIP_SECURITY SKIP_AI SKIP_MONITORING SECURE_MODE DISABLE_TELEMETRY PARALLEL_MODE TARGET_USER

    log_section "BrainVault Elite Initialization"
    log_info "[ORCHESTRATOR] Dry run mode: ${DRY_RUN}"
    log_info "[ORCHESTRATOR] Secure mode: ${SECURE_MODE}"
    log_info "[ORCHESTRATOR] Telemetry blocking: ${DISABLE_TELEMETRY}"
    log_info "[ORCHESTRATOR] Parallel mode: ${PARALLEL_MODE}"
    log_debug "[ORCHESTRATOR] Target user: ${TARGET_USER}"

    ensure_dependencies "ORCHESTRATOR" sudo apt-get find sort
    run_apt_update "ORCHESTRATOR" "Refresh apt package index"

    execute_stacks

    log_section "BrainVault Elite Complete"
    log_success "[ORCHESTRATOR] System bootstrap finished"
}

execute_stacks() {
    if [[ "${PARALLEL_MODE}" == "true" ]]; then
        log_warn "[ORCHESTRATOR] Parallel provisioning enabled (experimental)"
        local pids=()

        run_security_stack &
        pids+=($!)

        run_dev_stack &
        pids+=($!)

        run_monitoring_stack &
        pids+=($!)

        local exit_code=0
        local pid
        for pid in "${pids[@]}"; do
            if ! wait "$pid"; then
                exit_code=$?
            fi
        done

        return "$exit_code"
    fi

    run_security_stack
    run_dev_stack
    run_monitoring_stack
}

main "$@"
