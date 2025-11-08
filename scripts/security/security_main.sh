#!/usr/bin/env bash

run_security_stack() {
    local context="SECURITY:MAIN"

    if [[ "${SKIP_SECURITY:-false}" == "true" ]]; then
        log_warn "[$context] Security stack skipped per configuration"
        return 0
    fi

    log_section "Security Hardening"

    install_firewall
    install_fail2ban
    setup_apparmor_profiles
    setup_kernel_hardening
    setup_telemetry_block
    setup_integrity_monitoring

    log_success "[$context] Security stack completed"
}

export -f run_security_stack
