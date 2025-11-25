#!/bin/bash
# Security module main orchestrator

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

# Source security modules
source "${SCRIPT_DIR}/firewall.sh"
source "${SCRIPT_DIR}/fail2ban.sh"
source "${SCRIPT_DIR}/apparmor.sh"
source "${SCRIPT_DIR}/kernel_hardening.sh"
source "${SCRIPT_DIR}/telemetry_block.sh"
source "${SCRIPT_DIR}/integrity.sh"

install_security_stack() {
    log_section "Installing Security Stack"
    
    install_firewall
    install_fail2ban
    install_apparmor
    install_kernel_hardening
    install_telemetry_block
    install_integrity
    
    log_success "Security stack installation completed"
}

setup_security_stack() {
    log_section "Configuring Security Stack"
    
    setup_firewall
    setup_fail2ban
    setup_apparmor
    setup_kernel_hardening
    setup_telemetry_block
    setup_integrity
    
    log_success "Security stack configuration completed"
}

check_security_status() {
    log_section "Security Status Check"
    
    check_firewall_status
    check_fail2ban_status
    check_apparmor_status
    check_kernel_hardening
    check_telemetry_block
    check_integrity_status
    
    log_success "Security status check completed"
}
