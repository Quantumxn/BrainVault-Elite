#!/bin/bash
# backup.sh - Encrypted backup system for BrainVault Elite

install_backup_tools() {
    log_section "💾 Installing Backup Tools"
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Install rclone and backup utilities"
        return 0
    fi
    
    local backup_tools=(
        "rclone"
        "rsync"
        "tar"
        "gzip"
    )
    
    for tool in "${backup_tools[@]}"; do
        if ! command_exists "$tool"; then
            safe_exec "Installing $tool" apt-get install -y "$tool" || log_warn "Failed to install $tool"
        else
            log_debug "$tool already installed"
        fi
    done
    
    log_success "Backup tools installed"
}

# Configure backup directories
setup_backup_directories() {
    log_info "Setting up backup directories..."
    
    local backup_root="/var/backups/brainvault"
    local backup_dirs=(
        "$backup_root/system"
        "$backup_root/configs"
        "$backup_root/databases"
        "$backup_root/encrypted"
    )
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Create backup directory structure"
        return 0
    fi
    
    for dir in "${backup_dirs[@]}"; do
        mkdir -p "$dir"
        chmod 700 "$dir"
        log_debug "Created: $dir"
    done
    
    log_success "Backup directories created at $backup_root"
}

# Backup system configuration
backup_system_config() {
    log_section "📦 Backing Up System Configuration"
    
    local backup_dir="/var/backups/brainvault/configs"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/system_config_$timestamp.tar.gz"
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Backup system configuration to $backup_file"
        return 0
    fi
    
    log_info "Creating system configuration backup..."
    
    local config_dirs=(
        "/etc"
        "/root/.ssh"
        "/home/*/.ssh"
    )
    
    # Create backup
    tar czf "$backup_file" \
        --exclude="/etc/ssl/private" \
        --exclude="/etc/shadow*" \
        --exclude="/etc/gshadow*" \
        /etc \
        /root/.ssh 2>/dev/null || true
    
    if [[ -f "$backup_file" ]]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "System config backed up: $backup_file ($size)"
        
        # Encrypt backup
        encrypt_backup "$backup_file"
    else
        log_error "Failed to create backup"
        return 1
    fi
}

# Encrypt backup file
encrypt_backup() {
    local backup_file=$1
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Encrypting backup..."
    
    local encrypted_file="${backup_file}.enc"
    local password="${BACKUP_PASSWORD:-BrainVault_Secure_$(date +%Y)}"
    
    # Encrypt using OpenSSL
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$backup_file" -out "$encrypted_file" -k "$password" || {
        log_error "Encryption failed"
        return 1
    }
    
    if [[ -f "$encrypted_file" ]]; then
        log_success "Backup encrypted: $encrypted_file"
        
        # Optionally remove unencrypted backup
        if [[ "${REMOVE_UNENCRYPTED:-1}" == "1" ]]; then
            rm -f "$backup_file"
            log_debug "Removed unencrypted backup"
        fi
    else
        log_error "Encryption failed"
        return 1
    fi
}

# Decrypt backup file
decrypt_backup() {
    local encrypted_file=$1
    local password=${2:-}
    
    if [[ ! -f "$encrypted_file" ]]; then
        log_error "Encrypted file not found: $encrypted_file"
        return 1
    fi
    
    if [[ -z "$password" ]]; then
        log_error "Password required for decryption"
        return 1
    fi
    
    log_info "Decrypting backup..."
    
    local decrypted_file="${encrypted_file%.enc}"
    
    openssl enc -aes-256-cbc -d -pbkdf2 -in "$encrypted_file" -out "$decrypted_file" -k "$password" || {
        log_error "Decryption failed"
        return 1
    }
    
    if [[ -f "$decrypted_file" ]]; then
        log_success "Backup decrypted: $decrypted_file"
    else
        log_error "Decryption failed"
        return 1
    fi
}

# Backup databases
backup_databases() {
    log_info "Backing up databases..."
    
    local backup_dir="/var/backups/brainvault/databases"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Backup databases"
        return 0
    fi
    
    # MySQL/MariaDB backup
    if command_exists mysqldump; then
        log_info "Backing up MySQL databases..."
        mysqldump --all-databases > "$backup_dir/mysql_$timestamp.sql" 2>/dev/null || log_warn "MySQL backup failed"
    fi
    
    # PostgreSQL backup
    if command_exists pg_dumpall; then
        log_info "Backing up PostgreSQL databases..."
        sudo -u postgres pg_dumpall > "$backup_dir/postgres_$timestamp.sql" 2>/dev/null || log_warn "PostgreSQL backup failed"
    fi
    
    log_success "Database backup completed"
}

# Configure rclone for cloud backup
setup_rclone() {
    log_info "Setting up rclone..."
    
    if ! command_exists rclone; then
        log_error "rclone is not installed"
        return 1
    fi
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Configure rclone for cloud backup"
        return 0
    fi
    
    log_info "rclone is installed. Configure manually with: rclone config"
    log_info "Example remotes: S3, Google Drive, Dropbox, etc."
}

# Sync backup to cloud
sync_to_cloud() {
    local remote_name=${1:-}
    local local_dir="/var/backups/brainvault"
    
    if [[ -z "$remote_name" ]]; then
        log_error "Remote name required (e.g., 's3:bucket-name')"
        return 1
    fi
    
    if ! command_exists rclone; then
        log_error "rclone is not installed"
        return 1
    fi
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Sync backups to cloud: $remote_name"
        return 0
    fi
    
    log_info "Syncing backups to cloud: $remote_name"
    
    rclone sync "$local_dir" "$remote_name" \
        --progress \
        --transfers 4 \
        --checkers 8 \
        --delete-excluded \
        --exclude "*.tmp" || {
        log_error "Cloud sync failed"
        return 1
    }
    
    log_success "Backups synced to cloud"
}

# Cleanup old backups
cleanup_old_backups() {
    log_info "Cleaning up old backups..."
    
    local backup_root="/var/backups/brainvault"
    local keep_days=${1:-30}
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Remove backups older than $keep_days days"
        return 0
    fi
    
    log_info "Removing backups older than $keep_days days..."
    
    find "$backup_root" -type f -mtime "+$keep_days" -delete 2>/dev/null || log_warn "Cleanup failed"
    
    local remaining=$(find "$backup_root" -type f | wc -l)
    log_success "Cleanup completed. $remaining backup files remaining"
}

# Full backup routine
run_full_backup() {
    log_section "💾 RUNNING FULL BACKUP"
    
    # Setup directories
    setup_backup_directories
    
    # Backup system config
    backup_system_config
    
    # Backup databases
    backup_databases
    
    # Cleanup old backups
    cleanup_old_backups 30
    
    log_success "Full backup completed"
}

# Restore from backup
restore_from_backup() {
    local backup_file=$1
    
    if [[ -z "$backup_file" ]]; then
        log_error "Backup file required"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_warn "⚠️  RESTORE OPERATION - This will overwrite existing files!"
    
    if is_dryrun; then
        add_dryrun_operation "BACKUP" "Restore from backup: $backup_file"
        return 0
    fi
    
    read -p "Are you sure you want to restore? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    log_info "Restoring from backup: $backup_file"
    
    # Extract backup
    tar xzf "$backup_file" -C / || {
        log_error "Restore failed"
        return 1
    }
    
    log_success "Restore completed"
}

# Export functions
export -f install_backup_tools
export -f setup_backup_directories
export -f backup_system_config
export -f encrypt_backup
export -f decrypt_backup
export -f backup_databases
export -f setup_rclone
export -f sync_to_cloud
export -f cleanup_old_backups
export -f run_full_backup
export -f restore_from_backup
