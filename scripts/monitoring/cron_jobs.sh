#!/usr/bin/env bash

setup_monitoring_cron() {
    local context="MONITORING:CRON"
    local cron_file="/etc/cron.d/brainvault-monitoring"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo tee

    if is_dry_run; then
        simulate_file_change "$context" "$cron_file"
    else
        run_step "$context" "Configure monitoring cron jobs" bash -c "printf '%s\n' '# BrainVault Elite monitoring jobs' '0 * * * * root /usr/sbin/logrotate /etc/logrotate.conf' '30 2 * * * root /usr/sbin/aide.wrapper --check' '15 */6 * * * root /usr/bin/rkhunter --check --sk' | sudo tee ${cron_file} >/dev/null"
    fi

    clear_error_handler
    log_success "[$context] Monitoring cron jobs scheduled"
}

export -f setup_monitoring_cron
