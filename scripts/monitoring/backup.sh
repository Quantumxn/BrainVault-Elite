#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_MONITORING_BACKUP_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_MONITORING_BACKUP_SH=1

install_backup() {
  log_info "Installing backup tooling"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install rclone and encryption utilities" sudo apt-get install -y rclone openssl
  perform_step "Install timeshift" sudo apt-get install -y timeshift

  log_success "Backup tooling installed"
}

setup_backup() {
  log_info "Configuring backup routines"
  ensure_dependencies sudo rclone timeshift || return 1

  perform_step "Create backup config directory" sudo mkdir -p /etc/brainvault
  perform_step "Create backup script" sudo tee /usr/local/bin/brainvault-backup.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
rclone sync /etc remote:brainvault/etc --backup-dir remote:brainvault/$(date +%F)
timeshift --create --comment "BrainVault snapshot"
EOF

  perform_step "Mark backup script executable" sudo chmod +x /usr/local/bin/brainvault-backup.sh

  log_success "Backup routines configured"
}

