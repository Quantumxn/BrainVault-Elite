#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Backup Module
# ================================================================

setup_backup_template() {
    local desc="Setting up backup template"
    
    if [ "${SKIP_BACKUP:-false}" = "true" ]; then
        log_warn "Backup setup skipped per user request"
        return 0
    fi
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Monitoring" "setup_backup_template" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install backup tools
    install_pkg rclone openssl || {
        log_error "Failed to install backup tools"
        return 1
    }
    
    # Create backup directory
    local backup_dir="/opt/brainvault/backups"
    run_cmd "mkdir -p $backup_dir" "Creating backup directory"
    
    # Create encrypted backup script
    local backup_script="/usr/local/bin/elite-backup.sh"
    cat > "$backup_script" <<'EOS'
#!/bin/bash
# BrainVault Elite Backup Script
# Usage: elite-backup.sh [target] [backup-key]

set -euo pipefail

TARGET="${1:-default}"
BACKUP_KEY="${2:-}"
DATE=$(date +%F_%H-%M)
BACKUP_FILE="/opt/brainvault/backups/sys_${DATE}.tar.gz"
LOG_FILE="/var/log/elite-backup.log"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

log "Starting backup to target: $TARGET"

# Create encrypted backup
if [ -n "$BACKUP_KEY" ]; then
    tar -czf - /etc /home /opt/brainvault 2>/dev/null | \
        openssl enc -aes-256-cbc -pbkdf2 -pass pass:"$BACKUP_KEY" \
        -out "$BACKUP_FILE" || {
        log "ERROR: Backup creation failed"
        exit 1
    }
    log "Created encrypted backup: $BACKUP_FILE"
else
    tar -czf "$BACKUP_FILE" /etc /home /opt/brainvault 2>/dev/null || {
        log "ERROR: Backup creation failed"
        exit 1
    }
    log "Created backup: $BACKUP_FILE"
fi

# Upload to remote if rclone is configured
if command -v rclone >/dev/null 2>&1 && rclone listremotes >/dev/null 2>&1; then
    log "Uploading to remote storage..."
    rclone copy "$BACKUP_FILE" "remote:$TARGET" || {
        log "WARNING: Failed to upload to remote storage"
    }
fi

log "Backup complete: $BACKUP_FILE"
EOS
    
    run_cmd "chmod +x $backup_script" "Making backup script executable"
    
    log_success "Backup template setup complete"
    mark_module_loaded "backup"
    return 0
}

create_snapshot() {
    local desc="Creating system snapshot"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Monitoring" "create_snapshot" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    if command_exists timeshift; then
        run_cmd "timeshift --create --comments 'BrainVault pre-install snapshot'" \
            "Creating Timeshift snapshot" "" "false"
    else
        log_warn "Timeshift not found, skipping snapshot"
    fi
    
    mark_module_loaded "snapshot"
    return 0
}

backup_configs() {
    local desc="Backing up configuration files"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Monitoring" "backup_configs" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    local backup_dir="/opt/brainvault/backups/etc_$(date +%F_%H-%M)"
    run_cmd "mkdir -p $backup_dir" "Creating backup directory"
    run_cmd "rsync -a /etc/ $backup_dir/" "Backing up /etc configuration"
    
    log_success "Configuration backup complete: $backup_dir"
    mark_module_loaded "backup_configs"
    return 0
}
