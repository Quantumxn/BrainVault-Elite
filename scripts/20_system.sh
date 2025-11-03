#!/usr/bin/env bash

create_snapshot() {
  log_section "System Snapshot"
  if command -v timeshift >/dev/null 2>&1; then
    run_cmd "timeshift --create --comments 'BrainVault pre-install snapshot'" "Creating Timeshift snapshot"
  else
    log_warn "Timeshift not found. Skipping snapshot creation."
  fi
}

backup_configs() {
  log_section "Configuration Backup"
  local backup_root="/opt/brainvault/backups"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_dir="${backup_root}/etc_${timestamp}"

  run_cmd "mkdir -p ${backup_dir}" "Creating backup directory ${backup_dir}"
  run_cmd "rsync -a /etc/ ${backup_dir}/" "Backing up /etc configuration"
}

update_system_packages() {
  log_section "System Updates"
  run_cmd "apt-get update" "Updating package lists"
  run_cmd "DEBIAN_FRONTEND=noninteractive apt-get -y upgrade" "Upgrading system packages"
}

install_core_utilities() {
  log_section "Core Utilities"
  install_pkg ca-certificates curl wget gnupg lsb-release software-properties-common htop iotop nethogs tree pv rsync
}

final_cleanup() {
  log_section "Final Cleanup"
  run_cmd "apt-get autoremove -y" "Removing unused packages"
  run_cmd "apt-get clean" "Cleaning package cache"
  log_success "Installation workflow completed. Reboot recommended."
}
