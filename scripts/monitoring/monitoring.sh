#!/usr/bin/env bash

install_monitoring_suite() {
    local context="MONITORING:STACK"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get systemctl

    run_apt_install "$context" "Install monitoring agents" netdata prometheus-node-exporter
    run_step "$context" "Enable Netdata" sudo systemctl enable --now netdata
    run_step "$context" "Enable Node Exporter" sudo systemctl enable --now prometheus-node-exporter

    clear_error_handler
    log_success "[$context] Monitoring agents active"
}

export -f install_monitoring_suite
