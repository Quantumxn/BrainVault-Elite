#!/bin/bash
# Fail2Ban configuration script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_fail2ban() {
    log_section "Installing Fail2Ban"
    
    # Check dependencies
    if ! check_dependencies fail2ban-server; then
        log_info "Installing Fail2Ban..."
        dryrun_install "fail2ban" "Fail2Ban intrusion prevention"
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y fail2ban
        fi
    else
        log_success "Fail2Ban is already installed"
    fi
    
    # Verify installation
    if [[ "$DRY_RUN" != "1" ]] && ! command_exists fail2ban-server; then
        log_error "Fail2Ban installation failed"
        return 1
    fi
    
    log_success "Fail2Ban installation completed"
}

setup_fail2ban() {
    log_section "Configuring Fail2Ban"
    
    # Check if Fail2Ban is installed
    if ! command_exists fail2ban-server; then
        log_error "Fail2Ban is not installed. Run install_fail2ban first."
        return 1
    fi
    
    local jail_local="/etc/fail2ban/jail.local"
    
    log_step "Creating Fail2Ban configuration"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create $jail_local"
    else
        cat > "$jail_local" << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_)s

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
        log_success "Fail2Ban configuration created"
    fi
    
    log_step "Starting Fail2Ban service"
    dryrun_service "restart" "fail2ban"
    dryrun_service "enable" "fail2ban"
    
    log_success "Fail2Ban configuration completed"
}

check_fail2ban_status() {
    if command_exists fail2ban-client; then
        log_info "Fail2Ban Status:"
        if [[ "$DRY_RUN" != "1" ]]; then
            fail2ban-client status
        else
            log_warn "[DRY-RUN] Would check Fail2Ban status"
        fi
    fi
}
