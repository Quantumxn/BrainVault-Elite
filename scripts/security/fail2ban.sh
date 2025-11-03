#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Fail2Ban Configuration Module
# ================================================================

setup_fail2ban() {
    local desc="Configuring Fail2Ban"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Security" "setup_fail2ban" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install Fail2Ban if not present
    if ! command_exists fail2ban-client; then
        install_pkg fail2ban || {
            log_error "Failed to install Fail2Ban"
            return 1
        }
    fi
    
    # Enable and start Fail2Ban
    run_cmd "systemctl enable fail2ban" "Enabling Fail2Ban service"
    run_cmd "systemctl start fail2ban" "Starting Fail2Ban service"
    
    # Create local jail configuration if needed
    local jail_local="/etc/fail2ban/jail.local"
    if [ ! -f "$jail_local" ]; then
        log_info "Creating Fail2Ban jail.local configuration"
        cat > "$jail_local" <<'EOF'
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
        log_success "Created Fail2Ban jail.local configuration"
    fi
    
    log_success "Fail2Ban configuration complete"
    mark_module_loaded "fail2ban"
    return 0
}
