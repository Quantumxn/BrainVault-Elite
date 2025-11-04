#!/bin/bash
# AppArmor configuration script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_apparmor() {
    log_section "Installing AppArmor"
    
    # Check if AppArmor is already available (usually pre-installed on Ubuntu)
    if ! command_exists apparmor_status; then
        log_info "Installing AppArmor..."
        dryrun_install "apparmor" "AppArmor security framework"
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y apparmor apparmor-utils
        fi
    else
        log_success "AppArmor is already installed"
    fi
    
    # Verify installation
    if [[ "$DRY_RUN" != "1" ]] && ! command_exists apparmor_status; then
        log_error "AppArmor installation failed"
        return 1
    fi
    
    log_success "AppArmor installation completed"
}

setup_apparmor() {
    log_section "Configuring AppArmor"
    
    # Check if AppArmor is installed
    if ! command_exists apparmor_status; then
        log_error "AppArmor is not installed. Run install_apparmor first."
        return 1
    fi
    
    log_step "Checking AppArmor status"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would check AppArmor status"
    else
        if ! apparmor_status | grep -q "apparmor module is loaded"; then
            log_warn "AppArmor module not loaded. Loading module..."
            aa-enforce /etc/apparmor.d/*
        fi
    fi
    
    log_step "Enforcing AppArmor profiles"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would set AppArmor to enforcing mode"
    else
        aa-enforce /etc/apparmor.d/*
        log_success "AppArmor profiles set to enforcing"
    fi
    
    log_success "AppArmor configuration completed"
}

check_apparmor_status() {
    if command_exists apparmor_status; then
        log_info "AppArmor Status:"
        if [[ "$DRY_RUN" != "1" ]]; then
            apparmor_status
        else
            log_warn "[DRY-RUN] Would check AppArmor status"
        fi
    fi
}
