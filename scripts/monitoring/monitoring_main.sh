#!/usr/bin/env bash

run_monitoring_stack() {
    local context="MONITORING:MAIN"

    if [[ "${SKIP_MONITORING:-false}" == "true" ]]; then
        log_warn "[$context] Monitoring stack skipped per configuration"
        return 0
    fi

    log_section "Monitoring & Resilience"

    install_monitoring_suite
    setup_monitoring_cron
    setup_backup_system

    log_success "[$context] Monitoring stack completed"
}

export -f run_monitoring_stack
