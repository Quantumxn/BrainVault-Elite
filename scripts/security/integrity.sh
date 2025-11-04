#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_INTEGRITY_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_INTEGRITY_SH=1

install_integrity() {
  log_info "Installing system integrity tooling"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install AIDE and rootkit scanners" sudo apt-get install -y aide aide-common chkrootkit rkhunter

  log_success "System integrity tooling installed"
}

setup_integrity() {
  log_info "Configuring integrity monitoring"
  ensure_dependencies sudo aide || return 1

  perform_step "Initialize AIDE database" sudo aideinit
  perform_step "Move AIDE database into place" sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
  perform_step "Update rkhunter database" sudo rkhunter --propupd

  log_success "Integrity monitoring configured"
}

