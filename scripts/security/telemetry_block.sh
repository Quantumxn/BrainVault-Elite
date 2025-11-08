#!/usr/bin/env bash

setup_telemetry_block() {
    local context="SECURITY:TELEMETRY"
    local hosts_file="/etc/hosts"
    local telemetry_hosts=(
        "telemetry.ubuntu.com"
        "popcon.ubuntu.com"
        "metrics.ubuntu.com"
        "motd.ubuntu.com"
        "connectivity-check.ubuntu.com"
    )

    register_error_handler "$context"

    if [[ "${DISABLE_TELEMETRY:-false}" != "true" ]]; then
        log_debug "[$context] Telemetry blocking disabled by configuration"
        clear_error_handler
        return 0
    fi

    ensure_dependencies "$context" sudo tee grep systemctl

    if is_dry_run; then
        simulate_file_change "$context" "$hosts_file"
    else
        local host
        for host in "${telemetry_hosts[@]}"; do
            run_step "$context" "Block telemetry endpoint ${host}" bash -c "grep -q '${host}' ${hosts_file} || echo '0.0.0.0 ${host}' | sudo tee -a ${hosts_file} >/dev/null"
        done
    fi

    run_step "$context" "Disable motd news services" sudo systemctl disable --now motd-news.service motd-news.timer
    run_apt_purge "$context" "Purge canonical telemetry packages" ubuntu-report popularity-contest

    clear_error_handler
    log_success "[$context] Telemetry endpoints blocked"
}

export -f setup_telemetry_block
