#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_FIREWALL_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_FIREWALL_SH=1

install_firewall() {
  log_info "Installing firewall components"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Update package cache for firewall" sudo apt-get update
  perform_step "Install UFW package" sudo apt-get install -y ufw

  log_success "Firewall installation completed"
}

setup_firewall() {
  log_info "Configuring firewall defaults"
  ensure_dependencies sudo ufw || return 1

  perform_step "Allow SSH in firewall" sudo ufw allow OpenSSH
  perform_step "Set default deny incoming" sudo ufw default deny incoming
  perform_step "Set default allow outgoing" sudo ufw default allow outgoing
  perform_step "Enable UFW firewall" sudo ufw --force enable

  log_success "Firewall configuration applied"
}

