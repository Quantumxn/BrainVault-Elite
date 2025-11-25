#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_MONITORING_CRON_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_MONITORING_CRON_SH=1

install_cron_jobs() {
  log_info "Ensuring cron utilities are available"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install cron and auditd" sudo apt-get install -y cron auditd

  log_success "Cron utilities installed"
}

setup_cron_jobs() {
  log_info "Configuring BrainVault cron jobs"
  ensure_dependencies sudo crontab || return 1

  local cron_entry="0 2 * * * /usr/local/bin/brainvault-backup.sh >/var/log/brainvault-backup.log 2>&1"

  perform_step "Create log directory" sudo mkdir -p /var/log
  perform_step "Install BrainVault cron job" bash -c "(sudo crontab -l 2>/dev/null; echo '${cron_entry}') | sudo crontab -"

  log_success "BrainVault cron jobs configured"
}

