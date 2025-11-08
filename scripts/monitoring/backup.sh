#!/usr/bin/env bash

setup_backup_system() {
    local context="MONITORING:BACKUP"
    local config_dir="/etc/brainvault"
    local config_file="${config_dir}/backup.conf"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get openssl

    run_apt_install "$context" "Install backup tooling" rclone restic openssl
    run_step "$context" "Create backup workspace" sudo mkdir -p /opt/brainvault/backup

    if is_dry_run; then
        simulate_file_change "$context" "$config_file"
    else
        run_step "$context" "Create encrypted backup config" bash -c "sudo mkdir -p ${config_dir} && printf '%s\n' '[backup]' 'remote=brainvault:' 'path=/opt/brainvault/backup' 'encryption=aes256' | sudo tee ${config_file} >/dev/null"
        run_step "$context" "Secure backup config permissions" sudo chmod 600 "$config_file"
    fi

    clear_error_handler
    log_success "[$context] Backup system bootstrapped"
}

export -f setup_backup_system
