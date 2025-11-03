#!/bin/bash
# ================================================================
# BrainVault Elite - Backup System
# Automated encrypted backups with rclone
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Backup Tools Installation =============

install_backup_tools() {
    log_section "Installing Backup Tools"
    
    local backup_packages=(
        rclone
        restic
        openssl
        gpg
        rsync
        tar
        gzip
        bzip2
        xz-utils
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Backup" "Install backup tools: ${backup_packages[*]}"
        return 0
    fi
    
    install_pkg "${backup_packages[@]}"
    
    log_success "Backup tools installed"
}

# ============= Backup Script Template =============

create_backup_script() {
    log_section "Creating Backup Script"
    
    local backup_script="/usr/local/bin/brainvault-backup"
    local backup_dir="/opt/brainvault/backups"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Backup" "Create encrypted backup script at $backup_script"
        return 0
    fi
    
    log_info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    log_info "Creating backup script: $backup_script"
    
    cat > "$backup_script" <<'EOF'
#!/bin/bash
# ================================================================
# BrainVault Elite - System Backup Script
# Creates encrypted backups and optionally syncs to remote storage
# ================================================================

set -euo pipefail

# Configuration
BACKUP_DIR="/opt/brainvault/backups"
DATE=$(date +%F_%H-%M-%S)
BACKUP_NAME="brainvault_backup_${DATE}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
ENCRYPTED_FILE="${BACKUP_FILE}.enc"
LOG_FILE="/var/log/brainvault-backup.log"

# Default directories to backup
BACKUP_TARGETS=(
    "/etc"
    "/home"
    "/root"
    "/opt/brainvault"
    "/var/log"
)

# Logging function
log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

# Parse arguments
TARGET_NAME="${1:-local}"
ENCRYPTION_PASSWORD="${BACKUP_ENCRYPTION_PASSWORD:-}"

log "Starting backup: $BACKUP_NAME"
log "Target: $TARGET_NAME"

# Create compressed archive
log "Creating compressed archive..."
if tar -czf "$BACKUP_FILE" \
    --exclude='*.tmp' \
    --exclude='*.cache' \
    --exclude='node_modules' \
    --exclude='.git' \
    "${BACKUP_TARGETS[@]}" 2>>"$LOG_FILE"; then
    log "Archive created: $BACKUP_FILE"
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "Backup size: $BACKUP_SIZE"
else
    log "ERROR: Failed to create archive"
    exit 1
fi

# Encrypt if password is provided
if [[ -n "$ENCRYPTION_PASSWORD" ]]; then
    log "Encrypting backup..."
    if echo "$ENCRYPTION_PASSWORD" | openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE" -pass stdin 2>>"$LOG_FILE"; then
        log "Backup encrypted: $ENCRYPTED_FILE"
        rm -f "$BACKUP_FILE"
        BACKUP_FILE="$ENCRYPTED_FILE"
    else
        log "ERROR: Encryption failed"
        exit 1
    fi
fi

# Sync to remote if rclone is configured
if command -v rclone &>/dev/null && [[ "$TARGET_NAME" != "local" ]]; then
    log "Syncing to remote: $TARGET_NAME"
    if rclone copy "$BACKUP_FILE" "${TARGET_NAME}:brainvault-backups/" 2>>"$LOG_FILE"; then
        log "Remote sync completed"
    else
        log "WARNING: Remote sync failed"
    fi
fi

# Cleanup old backups (keep last 7 days)
log "Cleaning up old backups..."
find "$BACKUP_DIR" -name "brainvault_backup_*.tar.gz*" -mtime +7 -delete 2>>"$LOG_FILE"

log "Backup completed successfully"
log "Backup file: $BACKUP_FILE"
EOF
    
    chmod +x "$backup_script"
    log_success "Backup script created: $backup_script"
    
    # Create example rclone config
    local rclone_example="/opt/brainvault/rclone-config-example.conf"
    cat > "$rclone_example" <<'EOF'
# Example rclone configuration
# Copy this to ~/.config/rclone/rclone.conf and configure your remote

[remote]
type = s3
provider = AWS
env_auth = false
access_key_id = YOUR_ACCESS_KEY
secret_access_key = YOUR_SECRET_KEY
region = us-east-1
EOF
    
    log_info "Rclone example configuration created: $rclone_example"
    log_info "To use the backup script:"
    log_info "  1. Set encryption password: export BACKUP_ENCRYPTION_PASSWORD='your-password'"
    log_info "  2. Run backup: sudo brainvault-backup [remote-name]"
}

# ============= Automated Backup Scheduling =============

setup_backup_cron() {
    log_section "Setting Up Automated Backups"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Backup" "Schedule daily automated backups via cron"
        return 0
    fi
    
    log_info "Creating cron job for automated backups..."
    
    # Add to root crontab
    local cron_job="0 3 * * * /usr/local/bin/brainvault-backup >> /var/log/brainvault-backup.log 2>&1"
    
    if ! crontab -l 2>/dev/null | grep -q "brainvault-backup"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log_success "Automated backup scheduled (daily at 3:00 AM)"
    else
        log_info "Backup cron job already exists"
    fi
}

# ============= Restic Repository Setup =============

setup_restic() {
    log_section "Setting Up Restic Backup Repository"
    
    local restic_repo="/opt/brainvault/restic-repo"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Backup" "Initialize Restic backup repository"
        return 0
    fi
    
    log_info "Creating Restic repository: $restic_repo"
    
    mkdir -p "$restic_repo"
    
    log_info "To initialize Restic, run:"
    log_info "  export RESTIC_REPOSITORY=$restic_repo"
    log_info "  export RESTIC_PASSWORD='your-password'"
    log_info "  restic init"
    
    # Create a helper script
    local restic_helper="/usr/local/bin/brainvault-restic"
    cat > "$restic_helper" <<'EOF'
#!/bin/bash
# BrainVault Restic Helper

export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-/opt/brainvault/restic-repo}"

if [[ -z "$RESTIC_PASSWORD" ]]; then
    echo "ERROR: RESTIC_PASSWORD environment variable not set"
    exit 1
fi

restic "$@"
EOF
    
    chmod +x "$restic_helper"
    log_success "Restic helper created: $restic_helper"
}

# ============= Backup System Status =============

show_backup_info() {
    log_section "Backup System Information"
    
    if [[ -f /usr/local/bin/brainvault-backup ]]; then
        log_success "Backup script: /usr/local/bin/brainvault-backup"
    else
        log_warn "Backup script: Not found"
    fi
    
    if crontab -l 2>/dev/null | grep -q "brainvault-backup"; then
        log_success "Automated backups: Enabled"
        log_info "Schedule: $(crontab -l 2>/dev/null | grep brainvault-backup | cut -d' ' -f1-5)"
    else
        log_info "Automated backups: Not scheduled"
    fi
    
    local backup_dir="/opt/brainvault/backups"
    if [[ -d "$backup_dir" ]]; then
        local backup_count
        backup_count=$(find "$backup_dir" -name "*.tar.gz*" 2>/dev/null | wc -l)
        log_info "Existing backups: $backup_count"
        
        if [[ $backup_count -gt 0 ]]; then
            log_info "Latest backup:"
            find "$backup_dir" -name "*.tar.gz*" -type f -printf "  %T@ %p\n" 2>/dev/null | \
                sort -rn | head -1 | awk '{print "  " $2}'
        fi
    fi
}

# Export functions
export -f install_backup_tools create_backup_script setup_backup_cron
export -f setup_restic show_backup_info
