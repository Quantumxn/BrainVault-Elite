#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/scripts"

if [[ ! -d "${MODULE_DIR}" ]]; then
  echo "[ERROR] Required module directory '${MODULE_DIR}' not found." >&2
  exit 1
fi

shopt -s nullglob
for module in "${MODULE_DIR}"/*.sh; do
  # shellcheck disable=SC1090
  source "${module}"
done
shopt -u nullglob

DRY_RUN=false
SKIP_AI=false
SECURE_MODE=false
DISABLE_TELEMETRY=false

show_usage() {
  cat <<'EOF'
BrainVault Elite — Autonomous Ubuntu Hardening + AI Stack Bootstrap

Usage: brainvault_elite.sh [options]

Options:
  --dry-run             Simulate actions without applying changes
  --skip-ai             Skip AI / development stack installation
  --secure              Enable hardened secure mode (strict policies)
  --disable-telemetry   Disable outbound telemetry via iptables rules
  --help                Show this help message
EOF
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
      --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"
  init_environment
  ensure_root
  register_global_traps
  validate_syntax "${SCRIPT_DIR}"

  log_section "BrainVault Elite Bootstrap"
  log_info "Runtime options — dry_run=${DRY_RUN} skip_ai=${SKIP_AI} secure_mode=${SECURE_MODE} disable_telemetry=${DISABLE_TELEMETRY}"

  preflight_checks

  create_snapshot
  backup_configs
  update_system_packages
  install_core_utilities

  if [[ "${SECURE_MODE}" == true ]]; then
    enable_secure_mode
  fi

  install_security_stack

  if [[ "${DISABLE_TELEMETRY}" == true ]]; then
    setup_telemetry_block
  fi

  if [[ "${SKIP_AI}" == false ]]; then
    install_ai_stack
  else
    log_warn "Skipping AI / development stack per user request."
  fi

  setup_backup_template
  install_monitoring_suite
  create_audit_script
  setup_cron_jobs

  final_cleanup

  print_execution_summary
  print_dry_run_summary
}

main "$@"
