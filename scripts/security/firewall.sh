#!/bin/bash
# UFW Firewall configuration script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_firewall() {
    log_section "Installing UFW Firewall"
    
    # Check dependencies
    if ! check_dependencies ufw; then
        log_info "Installing UFW..."
        dryrun_install "ufw" "UFW Firewall"
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y ufw
        fi
    else
        log_success "UFW is already installed"
    fi
    
    # Verify installation
    if [[ "$DRY_RUN" != "1" ]] && ! command_exists ufw; then
        log_error "UFW installation failed"
        return 1
    fi
    
    log_success "Firewall installation completed"
}

setup_firewall() {
    log_section "Configuring UFW Firewall"
    
    # Check if UFW is installed
    if ! command_exists ufw; then
        log_error "UFW is not installed. Run install_firewall first."
        return 1
    fi
    
    log_step "Setting default policies"
    dryrun_exec "ufw --force reset" "Resetting UFW rules"
    dryrun_exec "ufw default deny incoming" "Deny incoming by default"
    dryrun_exec "ufw default allow outgoing" "Allow outgoing by default"
    
    log_step "Allowing essential services"
    dryrun_exec "ufw allow ssh/tcp" "Allow SSH"
    dryrun_exec "ufw allow 80/tcp" "Allow HTTP"
    dryrun_exec "ufw allow 443/tcp" "Allow HTTPS"
    
    log_step "Enabling UFW"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would enable UFW firewall"
    else
        ufw --force enable
        log_success "UFW firewall enabled"
    fi
    
    log_success "Firewall configuration completed"
}

check_firewall_status() {
    if command_exists ufw; then
        log_info "UFW Status:"
        if [[ "$DRY_RUN" != "1" ]]; then
            ufw status verbose
        else
            log_warn "[DRY-RUN] Would check UFW status"
        fi
    fi
}
