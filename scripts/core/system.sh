#!/bin/bash
# ================================================================
# BrainVault Elite - Core System Functions
# System snapshots, backups, and initialization
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= System Snapshot Functions =============

create_snapshot() {
    log_section "Creating System Snapshot"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Core" "Create system snapshot with Timeshift"
    fi
    
    if command -v timeshift &>/dev/null; then
        run_cmd "timeshift --create --comments 'BrainVault Elite pre-install snapshot' --scripted" \
            "Creating Timeshift snapshot" \
            false
    else
        log_warn "Timeshift not found. Install with: sudo apt install timeshift"
        log_info "Snapshot creation skipped"
    fi
}

# ============= Configuration Backup Functions =============

backup_configs() {
    log_section "Backing Up System Configuration"
    
    local backup_dir="/opt/brainvault/backups/etc_$(date +%F_%H-%M-%S)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Core" "Backup /etc to $backup_dir"
        return 0
    fi
    
    log_info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir" || error_exit "Failed to create backup directory"
    
    log_info "Backing up /etc directory..."
    if rsync -a --info=progress2 /etc/ "$backup_dir" >>"$LOGFILE" 2>&1; then
        log_success "Configuration backup completed: $backup_dir"
        
        # Create a manifest
        local manifest="$backup_dir/manifest.txt"
        {
            echo "BrainVault Elite Configuration Backup"
            echo "Date: $(date)"
            echo "Hostname: $(hostname)"
            echo "Kernel: $(uname -r)"
            echo "Files: $(find "$backup_dir" -type f | wc -l)"
            echo "Size: $(du -sh "$backup_dir" | cut -f1)"
        } > "$manifest"
        
        log_info "Backup manifest created: $manifest"
    else
        log_error "Configuration backup failed"
        return 1
    fi
}

# ============= System Update Functions =============

update_system() {
    log_section "Updating System Packages"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Core" "Update and upgrade all system packages"
        return 0
    fi
    
    log_info "Updating package lists..."
    run_cmd "apt-get update" "Updating package lists"
    
    log_info "Upgrading installed packages..."
    run_cmd "DEBIAN_FRONTEND=noninteractive apt-get -y upgrade" "Upgrading packages"
    
    log_info "Performing dist-upgrade..."
    run_cmd "DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade" "Distribution upgrade" false
    
    log_success "System update completed"
}

# ============= Essential Tools Installation =============

install_essential_tools() {
    log_section "Installing Essential Tools"
    
    local essential_packages=(
        ca-certificates
        curl
        wget
        gnupg
        lsb-release
        software-properties-common
        apt-transport-https
        htop
        iotop
        nethogs
        tree
        pv
        rsync
        unzip
        zip
        jq
        vim
        tmux
        git
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Core" "Install essential tools: ${essential_packages[*]}"
        return 0
    fi
    
    install_pkg "${essential_packages[@]}"
}

# ============= System Information =============

show_system_info() {
    log_section "System Information"
    
    log_info "Hostname: $(hostname)"
    log_info "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    log_info "Kernel: $(uname -r)"
    log_info "Architecture: $(uname -m)"
    log_info "CPU: $(nproc) cores"
    log_info "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    log_info "Disk: $(df -h / | awk 'NR==2 {print $4 " available"}')"
}

# ============= Cleanup Functions =============

cleanup_system() {
    log_section "System Cleanup"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Core" "Remove unused packages and clean package cache"
        return 0
    fi
    
    log_info "Removing unused packages..."
    run_cmd "apt-get autoremove -y" "Autoremove" false
    
    log_info "Cleaning package cache..."
    run_cmd "apt-get clean" "Clean cache" false
    
    log_info "Removing old log files (older than 30 days)..."
    run_cmd "find /var/log -type f -name '*.log' -mtime +30 -delete" "Clean old logs" false
    
    log_success "System cleanup completed"
}

# ============= Final Steps =============

final_steps() {
    cleanup_system
    
    log_section "Installation Complete"
    log_success "BrainVault Elite installation completed successfully!"
    log_info "Log file: $LOGFILE"
    log_warn "A system reboot is recommended to apply all changes"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info ""
        log_info "To reboot now, run: sudo reboot"
    fi
}

# Export functions
export -f create_snapshot backup_configs update_system install_essential_tools
export -f show_system_info cleanup_system final_steps
