#!/bin/bash
# Backup and integrity script (rclone + encryption)

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_backup() {
    log_section "Installing Backup Tools"
    
    local packages=("rclone" "openssl")
    local missing_packages=()
    
    # Check dependencies
    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "Installing backup tools..."
        for pkg in "${missing_packages[@]}"; do
            dryrun_install "$pkg" "Backup tool: $pkg"
        done
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            
            # Install rclone (may need manual installation)
            if ! package_installed rclone; then
                # Try to install via package manager first
                apt-get install -y rclone || {
                    log_info "Installing rclone via official installer..."
                    curl https://rclone.org/install.sh | bash
                }
            fi
            
            apt-get install -y openssl
        fi
    else
        log_success "Backup tools already installed"
    fi
    
    # Verify installation
    for pkg in "${packages[@]}"; do
        if [[ "$DRY_RUN" != "1" ]]; then
            if [[ "$pkg" == "rclone" ]] && ! command_exists rclone; then
                log_error "rclone installation failed"
                return 1
            elif [[ "$pkg" == "openssl" ]] && ! command_exists openssl; then
                log_error "openssl installation failed"
                return 1
            fi
        fi
    done
    
    log_success "Backup tools installation completed"
}

setup_backup() {
    log_section "Configuring Backup System"
    
    # Check if tools are installed
    if ! command_exists rclone || ! command_exists openssl; then
        log_error "Backup tools not installed. Run install_backup first."
        return 1
    fi
    
    log_step "Creating backup directories"
    local backup_dir="/opt/brainvault/backups"
    local backup_script="/opt/brainvault/scripts/backup.sh"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create backup directories and scripts"
    else
        mkdir -p "$backup_dir" "/opt/brainvault/scripts"
        
        # Create backup script
        cat > "$backup_script" << 'BACKUP_EOF'
#!/bin/bash
# BrainVault Elite Backup Script
# Uses rclone + OpenSSL encryption

BACKUP_DIR="/opt/brainvault/backups"
ENCRYPT_KEY="${BACKUP_ENCRYPT_KEY:-}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"

# Create encrypted backup
backup_encrypt() {
    local source="$1"
    local dest="$2"
    
    if [[ -z "$ENCRYPT_KEY" ]]; then
        echo "ERROR: BACKUP_ENCRYPT_KEY not set"
        return 1
    fi
    
    tar czf - "$source" | openssl enc -aes-256-cbc -salt -k "$ENCRYPT_KEY" -out "$dest"
}

# Main backup function
main_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/backup_${timestamp}.tar.gz.enc"
    
    # Backup important directories
    backup_encrypt /etc "${BACKUP_DIR}/etc_backup_${timestamp}.tar.gz.enc"
    backup_encrypt /home "${BACKUP_DIR}/home_backup_${timestamp}.tar.gz.enc"
    
    # Sync to remote if configured
    if [[ -n "$RCLONE_REMOTE" ]]; then
        rclone sync "$BACKUP_DIR" "$RCLONE_REMOTE:/brainvault-backups" --quiet
    fi
    
    echo "Backup completed: $backup_file"
}

main_backup
BACKUP_EOF
        chmod +x "$backup_script"
        log_success "Backup script created"
    fi
    
    log_step "Setting up backup encryption key"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would generate backup encryption key"
    else
        local key_file="/opt/brainvault/.backup_key"
        if [[ ! -f "$key_file" ]]; then
            openssl rand -base64 32 > "$key_file"
            chmod 600 "$key_file"
            log_success "Backup encryption key generated"
            log_warn "Store this key securely: $key_file"
        fi
    fi
    
    log_info "Backup system configured. Configure RCLONE_REMOTE and BACKUP_ENCRYPT_KEY for full functionality."
    log_success "Backup configuration completed"
}

check_backup_status() {
    log_info "Backup System Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if command_exists rclone; then
            local rclone_version=$(rclone version | head -n1)
            log_success "rclone: $rclone_version"
        else
            log_warn "rclone: not installed"
        fi
        
        if command_exists openssl; then
            local openssl_version=$(openssl version)
            log_success "openssl: $openssl_version"
        else
            log_warn "openssl: not installed"
        fi
        
        if [[ -d "/opt/brainvault/backups" ]]; then
            local backup_count=$(find /opt/brainvault/backups -name "*.enc" 2>/dev/null | wc -l)
            log_success "Backup directory exists: $backup_count backups found"
        else
            log_warn "Backup directory not configured"
        fi
    else
        log_warn "[DRY-RUN] Would check backup system status"
    fi
}
