#!/bin/bash
# apparmor.sh - AppArmor MAC security for BrainVault Elite

install_apparmor() {
    log_section "🛡️ Installing and Configuring AppArmor"
    
    # Check if AppArmor is installed
    if command_exists aa-status; then
        log_info "AppArmor is already installed"
    else
        if is_dryrun; then
            add_dryrun_operation "SECURITY" "Install AppArmor and utilities"
        else
            safe_exec "Installing AppArmor" apt-get install -y apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra
        fi
    fi
    
    # Configure AppArmor
    configure_apparmor
}

configure_apparmor() {
    log_info "Configuring AppArmor..."
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Enable AppArmor service"
        add_dryrun_operation "SECURITY" "Load AppArmor profiles"
        add_dryrun_operation "SECURITY" "Set profiles to enforce mode"
        return 0
    fi
    
    # Enable AppArmor
    safe_exec "Enabling AppArmor" systemctl enable apparmor
    safe_exec "Starting AppArmor" systemctl start apparmor
    
    # Check if AppArmor is running
    if ! aa-enabled 2>/dev/null; then
        log_warn "AppArmor is not enabled in kernel. May require reboot."
        return 1
    fi
    
    log_success "AppArmor is enabled"
    
    # Show status
    log_info "AppArmor status:"
    aa-status 2>/dev/null || log_warn "Cannot retrieve AppArmor status"
    
    log_success "AppArmor configured successfully"
}

# Set profile to enforce mode
apparmor_enforce() {
    local profile=$1
    
    if [[ -z "$profile" ]]; then
        log_error "No profile specified"
        return 1
    fi
    
    log_info "Setting profile to enforce mode: $profile"
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Set AppArmor profile to enforce: $profile"
        return 0
    fi
    
    if ! aa-enforce "$profile" 2>/dev/null; then
        log_warn "Failed to enforce profile: $profile"
        return 1
    fi
    
    log_success "Profile enforced: $profile"
}

# Set profile to complain mode
apparmor_complain() {
    local profile=$1
    
    if [[ -z "$profile" ]]; then
        log_error "No profile specified"
        return 1
    fi
    
    log_info "Setting profile to complain mode: $profile"
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Set AppArmor profile to complain: $profile"
        return 0
    fi
    
    if ! aa-complain "$profile" 2>/dev/null; then
        log_warn "Failed to set complain mode: $profile"
        return 1
    fi
    
    log_success "Profile set to complain mode: $profile"
}

# Enable common profiles
enable_common_profiles() {
    log_info "Enabling common AppArmor profiles..."
    
    local profiles=(
        "/usr/sbin/tcpdump"
        "/usr/bin/man"
        "/usr/sbin/rsyslogd"
    )
    
    for profile in "${profiles[@]}"; do
        if [[ -f "/etc/apparmor.d${profile}" ]]; then
            apparmor_enforce "$profile" || log_warn "Could not enforce $profile"
        else
            log_debug "Profile not found: $profile"
        fi
    done
    
    log_success "Common profiles processed"
}

# Check AppArmor status
check_apparmor_status() {
    log_info "Checking AppArmor status..."
    
    if ! command_exists aa-status; then
        log_error "AppArmor is not installed"
        return 1
    fi
    
    if ! aa-enabled 2>/dev/null; then
        log_warn "AppArmor is not enabled"
        return 1
    fi
    
    log_success "AppArmor is active and enforcing"
    return 0
}

# Export functions
export -f install_apparmor
export -f configure_apparmor
export -f apparmor_enforce
export -f apparmor_complain
export -f enable_common_profiles
export -f check_apparmor_status
