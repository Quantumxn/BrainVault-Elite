#!/usr/bin/env bash

install_firewall() {
    local context="SECURITY:FIREWALL"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get

    run_apt_install "$context" "Install UFW" ufw
    run_step "$context" "Reset existing firewall rules" sudo ufw --force reset
    run_step "$context" "Set default deny incoming" sudo ufw default deny incoming
    run_step "$context" "Set default allow outgoing" sudo ufw default allow outgoing
    run_step "$context" "Allow essential services" sudo ufw allow OpenSSH
    run_step "$context" "Enable UFW" sudo ufw --force enable

    clear_error_handler
    log_success "[$context] Firewall configured with UFW"
}

export -f install_firewall
