#!/usr/bin/env bash

create_snapshot() {
    log_info "System snapshot preparation"

    if ! command -v timeshift >/dev/null 2>&1; then
        log_warn "Timeshift not available; skipping system snapshot."
        return 0
    fi

    run_cmd "timeshift --create --comments 'BrainVault pre-install snapshot'" \
        "Creating Timeshift snapshot"
}

backup_configs() {
    log_info "Backing up configuration state"

    local backup_dir
    backup_dir="/opt/brainvault/backups/etc_$(date +%F_%H-%M)"

    run_cmd "mkdir -p ${backup_dir}" "Creating backup directory at ${backup_dir}"
    run_cmd "rsync -a /etc/ ${backup_dir}/" "Backing up /etc to ${backup_dir}"
}

update_system_packages() {
    log_info "Updating system packages"
    run_cmd "apt-get update && apt-get -y upgrade" "Updating APT package index and upgrading packages"
}

install_baseline_packages() {
    log_info "Installing baseline utilities"
    install_pkg ca-certificates curl wget gnupg lsb-release software-properties-common htop iotop nethogs tree pv rsync
    log_success "Baseline utility packages ensured"
}
