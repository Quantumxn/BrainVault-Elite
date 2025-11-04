#!/bin/bash
# fail2ban.sh - Fail2Ban intrusion prevention for BrainVault Elite

install_fail2ban() {
    log_section "🚫 Installing and Configuring Fail2Ban"
    
    # Check if already installed
    if command_exists fail2ban-client; then
        log_info "Fail2Ban is already installed"
    else
        if is_dryrun; then
            add_dryrun_operation "SECURITY" "Install Fail2Ban"
        else
            safe_exec "Installing Fail2Ban" apt-get install -y fail2ban
        fi
    fi
    
    # Configure Fail2Ban
    configure_fail2ban
}

configure_fail2ban() {
    log_info "Configuring Fail2Ban..."
    
    local jail_local="/etc/fail2ban/jail.local"
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Create Fail2Ban jail.local configuration"
        add_dryrun_operation "SECURITY" "Enable SSH protection"
        add_dryrun_operation "SECURITY" "Start Fail2Ban service"
        return 0
    fi
    
    # Create jail.local
    cat > "$jail_local" <<'EOF'
[DEFAULT]
# Ban settings
bantime = 1h
findtime = 10m
maxretry = 5
banaction = ufw

# Email notifications (optional)
destemail = root@localhost
sendername = Fail2Ban
mta = sendmail

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
findtime = 10m

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 10
bantime = 1h

[apache-auth]
enabled = false
port = http,https
filter = apache-auth
logpath = /var/log/apache*/*error.log
maxretry = 3

[nginx-http-auth]
enabled = false
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
EOF
    
    log_success "Fail2Ban configuration created at $jail_local"
    
    # Restart Fail2Ban
    safe_exec "Restarting Fail2Ban" systemctl restart fail2ban
    safe_exec "Enabling Fail2Ban" systemctl enable fail2ban
    
    # Show status
    sleep 2
    log_info "Fail2Ban status:"
    fail2ban-client status || true
    
    log_success "Fail2Ban configured and running"
}

# Check Fail2Ban status
check_fail2ban_status() {
    log_info "Checking Fail2Ban status..."
    
    if ! systemctl is-active --quiet fail2ban; then
        log_warn "Fail2Ban is not running"
        return 1
    fi
    
    log_success "Fail2Ban is active"
    fail2ban-client status sshd 2>/dev/null || log_debug "SSHD jail status unavailable"
    return 0
}

# Unban an IP address
fail2ban_unban() {
    local ip=$1
    
    if [[ -z "$ip" ]]; then
        log_error "No IP address provided"
        return 1
    fi
    
    log_info "Unbanning IP: $ip"
    
    if is_dryrun; then
        add_dryrun_operation "SECURITY" "Unban IP address: $ip"
        return 0
    fi
    
    fail2ban-client set sshd unbanip "$ip" || {
        log_error "Failed to unban $ip"
        return 1
    }
    
    log_success "Unbanned IP: $ip"
}

# Export functions
export -f install_fail2ban
export -f configure_fail2ban
export -f check_fail2ban_status
export -f fail2ban_unban
