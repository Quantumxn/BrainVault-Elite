#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_APPARMOR_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_APPARMOR_SH=1

install_apparmor() {
  log_info "Installing AppArmor packages"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install AppArmor utilities" sudo apt-get install -y apparmor apparmor-utils

  log_success "AppArmor installation completed"
}

setup_apparmor() {
  log_info "Enforcing AppArmor profiles"
  ensure_dependencies sudo aa-status apparmor_parser || return 1

  perform_step "Set AppArmor to enforce mode" sudo aa-enforce /etc/apparmor.d/*
  perform_step "Reload AppArmor profiles" sudo systemctl reload apparmor

  log_success "AppArmor profiles enforced"
}

