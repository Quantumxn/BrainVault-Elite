#!/usr/bin/env bash

set -euo pipefail
set -E

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/scripts"
LOG_BASENAME="brainvault_elite_$(date +%F_%H-%M-%S).log"
DEFAULT_LOG_DIR="/var/log"
FALLBACK_LOG_DIR="${SCRIPT_DIR}/logs"
LOGFILE="${DEFAULT_LOG_DIR}/${LOG_BASENAME}"

DRY_RUN=false
SKIP_AI=false
SKIP_SECURITY=false
SKIP_BACKUP=false
SECURE_MODE=false
DISABLE_TELEMETRY=false

declare -a BRAINVAULT_PLANNED_COMMANDS=()
declare -a BRAINVAULT_SUCCESS_COMMANDS=()
declare -a BRAINVAULT_FAILED_COMMANDS=()
declare -a BRAINVAULT_MODULES=()

SCRIPT_EXIT_CODE=0

initialize_logging() {
    if ! touch "${LOGFILE}" 2>/dev/null; then
        mkdir -p "${FALLBACK_LOG_DIR}"
        LOGFILE="${FALLBACK_LOG_DIR}/${LOG_BASENAME}"
        touch "${LOGFILE}" 2>/dev/null || {
            LOGFILE="/tmp/${LOG_BASENAME}"
            touch "${LOGFILE}" 2>/dev/null || {
                echo "[ERROR] Failed to establish writable log file." >&2
                exit 1
            }
        }
        echo "[INFO] Logging redirected to ${LOGFILE}" >&2
    fi
}

timestamp() {
    date '+%F %T'
}

log_stream() {
    local level="$1"
    shift
    local message="$*"
    local ts
    ts="$(timestamp)"
    if [[ "${level}" == "ERROR" ]]; then
        printf '[%s] [%s] %s\n' "${ts}" "${level}" "${message}" | tee -a "${LOGFILE}" >&2
    else
        printf '[%s] [%s] %s\n' "${ts}" "${level}" "${message}" | tee -a "${LOGFILE}"
    fi
}

log_info() {
    log_stream "INFO" "$*"
}

log_warn() {
    log_stream "WARN" "$*"
}

log_error() {
    log_stream "ERROR" "$*"
}

log_success() {
    log_stream "OK" "$*"
}

log_section() {
    log_stream "SECTION" "$*"
}

on_error() {
    local exit_code="$1"
    local line_no="$2"
    log_error "Execution failed with exit code ${exit_code} at line ${line_no}. Review ${LOGFILE} for details."
    SCRIPT_EXIT_CODE="${exit_code}"
}

print_dry_run_summary() {
    if [[ ${#BRAINVAULT_PLANNED_COMMANDS[@]} -eq 0 ]]; then
        log_info "No commands were scheduled during this run."
        return
    fi

    printf '\n%s\n' "=== BrainVault Elite Dry-Run Summary ==="
    for entry in "${BRAINVAULT_PLANNED_COMMANDS[@]}"; do
        printf ' - %s\n' "${entry}"
    done
    printf '%s\n\n' "========================================"
}

print_execution_summary() {
    local status_message
    if [[ ${SCRIPT_EXIT_CODE} -eq 0 ]]; then
        status_message="Completed successfully"
    else
        status_message="Completed with errors (exit ${SCRIPT_EXIT_CODE})"
    fi

    printf '\n%s\n' "=== BrainVault Elite Execution Summary (${status_message}) ==="

    if [[ ${#BRAINVAULT_SUCCESS_COMMANDS[@]} -gt 0 ]]; then
        printf 'Successful actions:\n'
        for entry in "${BRAINVAULT_SUCCESS_COMMANDS[@]}"; do
            printf ' ✓ %s\n' "${entry}"
        done
        printf '\n'
    fi

    if [[ ${#BRAINVAULT_FAILED_COMMANDS[@]} -gt 0 ]]; then
        printf 'Failed actions:\n'
        for entry in "${BRAINVAULT_FAILED_COMMANDS[@]}"; do
            printf ' ✗ %s\n' "${entry}"
        done
        printf '\n'
    fi

    printf '%s\n\n' "============================================================"
}

on_exit() {
    local exit_code="${1:-0}"
    if [[ "${SCRIPT_EXIT_CODE}" -eq 0 ]]; then
        SCRIPT_EXIT_CODE="${exit_code}"
    fi
    local final_rc="${SCRIPT_EXIT_CODE}"
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_dry_run_summary
    else
        print_execution_summary
    fi
    return "${final_rc}"
}

run_cmd() {
    local command="$1"
    local description="${2:-$1}"
    local allow_failure="${3:-false}"

    BRAINVAULT_PLANNED_COMMANDS+=("${description} :: ${command}")

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] ${description}"
        log_info "         ${command}"
        return 0
    fi

    log_info "${description}"
    if eval "${command}" >>"${LOGFILE}" 2>&1; then
        log_success "${description}"
        BRAINVAULT_SUCCESS_COMMANDS+=("${description}")
        return 0
    else
        local rc=$?
        if [[ "${allow_failure}" == "true" ]]; then
            log_warn "${description} failed (exit ${rc}) but marked as non-blocking."
            BRAINVAULT_FAILED_COMMANDS+=("(non-blocking) ${description} (exit ${rc})")
        else
            log_error "${description} failed (exit ${rc}). See ${LOGFILE}."
            BRAINVAULT_FAILED_COMMANDS+=("${description} (exit ${rc})")
            SCRIPT_EXIT_CODE=${rc}
        fi
        return ${rc}
    fi
}

install_pkg() {
    local packages=("$@")
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "install_pkg invoked without packages."
        return 0
    fi
    local pkg_list
    pkg_list="${packages[*]}"
    run_cmd "apt-get install -y ${pkg_list}" "Installing packages: ${pkg_list}"
}

usage() {
    cat <<'USAGE'
BrainVault Elite — Autonomous Ubuntu Hardening + AI Stack Bootstrap

Usage: brainvault_elite.sh [options]

Options:
  --dry-run             Simulate actions without making changes.
  --skip-ai             Skip installation of the AI/development stack.
  --secure              Focus on security hardening (implies --skip-ai and --disable-telemetry).
  --disable-telemetry   Deploy outbound telemetry blocking rules.
  --skip-security       Skip security hardening modules (not recommended).
  --skip-backup         Skip backup & monitoring provisioning.
  -h, --help            Display this help message and exit.
USAGE
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --skip-ai)
                SKIP_AI=true
                ;;
            --secure)
                SECURE_MODE=true
                ;;
            --disable-telemetry)
                DISABLE_TELEMETRY=true
                ;;
            --skip-security)
                SKIP_SECURITY=true
                ;;
            --skip-backup)
                SKIP_BACKUP=true
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

    if [[ "${SECURE_MODE}" == "true" ]]; then
        SKIP_AI=true
        DISABLE_TELEMETRY=true
        SKIP_SECURITY=false
        log_info "SECURE mode enabled: AI stack disabled, telemetry blocking enforced."
    fi
}

load_modules() {
    if [[ ! -d "${MODULE_DIR}" ]]; then
        log_warn "Module directory ${MODULE_DIR} not found."
        return
    fi

    shopt -s nullglob
    local module
    for module in "${MODULE_DIR}"/*.sh; do
        # shellcheck source=/dev/null
        source "${module}"
        BRAINVAULT_MODULES+=("$(basename "${module}")")
        log_info "Loaded module: $(basename "${module}")"
    done
    shopt -u nullglob

    if [[ ${#BRAINVAULT_MODULES[@]} -eq 0 ]]; then
        log_warn "No modules were loaded from ${MODULE_DIR}."
    fi
}

ensure_prerequisites() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        return
    fi
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "BrainVault Elite requires root privileges."
        exit 1
    fi
}

main() {
    initialize_logging
    trap 'on_error $? $LINENO' ERR
    trap 'on_exit $?' EXIT

    parse_args "$@"
    ensure_prerequisites

    log_section "BrainVault Elite initialization"
    log_info "Log file: ${LOGFILE}"
    log_info "Options: DRY_RUN=${DRY_RUN} SKIP_SECURITY=${SKIP_SECURITY} SKIP_AI=${SKIP_AI} SKIP_BACKUP=${SKIP_BACKUP} SECURE_MODE=${SECURE_MODE} DISABLE_TELEMETRY=${DISABLE_TELEMETRY}"

    load_modules

    if declare -f create_snapshot >/dev/null 2>&1; then
        create_snapshot
    fi
    if declare -f backup_configs >/dev/null 2>&1; then
        backup_configs
    fi
    if declare -f update_system_packages >/dev/null 2>&1; then
        update_system_packages
    fi
    if declare -f install_baseline_packages >/dev/null 2>&1; then
        install_baseline_packages
    fi

    if [[ "${SKIP_SECURITY}" == "false" ]]; then
        log_section "Security hardening"
        if declare -f install_security_packages >/dev/null 2>&1; then
            install_security_packages
        fi
        if declare -f setup_firewall >/dev/null 2>&1; then
            setup_firewall
        fi
        if declare -f setup_fail2ban >/dev/null 2>&1; then
            setup_fail2ban
        fi
        if declare -f setup_apparmor >/dev/null 2>&1; then
            setup_apparmor
        fi
        if [[ "${DISABLE_TELEMETRY}" == "true" ]] && declare -f setup_telemetry_block >/dev/null 2>&1; then
            setup_telemetry_block
        else
            log_warn "Telemetry blocking not requested; skipping firewall egress rules."
        fi
        if declare -f setup_kernel_hardening >/dev/null 2>&1; then
            setup_kernel_hardening
        fi
        if declare -f setup_integrity_tools >/dev/null 2>&1; then
            setup_integrity_tools
        fi
    else
        log_warn "Security stack skipped per user request."
    fi

    if [[ "${SKIP_AI}" == "false" ]]; then
        log_section "AI / Developer stack"
        if declare -f install_dev_tools >/dev/null 2>&1; then
            install_dev_tools
        fi
        if declare -f install_container_stack >/dev/null 2>&1; then
            install_container_stack
        fi
        if declare -f install_python_stack >/dev/null 2>&1; then
            install_python_stack
        fi
    else
        log_warn "AI / Dev stack installation skipped per user request."
    fi

    if [[ "${SKIP_BACKUP}" == "false" ]]; then
        log_section "Backup, monitoring, and audit"
        if declare -f setup_backup_template >/dev/null 2>&1; then
            setup_backup_template
        fi
        if declare -f install_monitoring >/dev/null 2>&1; then
            install_monitoring
        fi
        if declare -f create_audit_script >/dev/null 2>&1; then
            create_audit_script
        fi
        if declare -f setup_cron_jobs >/dev/null 2>&1; then
            setup_cron_jobs
        fi
    else
        log_warn "Backup & monitoring provisioning skipped per user request."
    fi

    if declare -f final_steps >/dev/null 2>&1; then
        final_steps
    fi

    SCRIPT_EXIT_CODE=0
}

main "$@"
