#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_MAIN_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_MAIN_SH=1

run_security_installation() {
  log_info "Running security installation pipeline"

  run_functions \
    install_firewall \
    install_fail2ban \
    install_apparmor \
    install_kernel_hardening \
    install_telemetry_block \
    install_integrity

  log_success "Security installation pipeline completed"
}

run_security_configuration() {
  log_info "Applying security configuration"

  run_functions \
    setup_firewall \
    setup_fail2ban \
    setup_apparmor \
    setup_kernel_hardening \
    setup_telemetry_block \
    setup_integrity

  log_success "Security configuration completed"
}

