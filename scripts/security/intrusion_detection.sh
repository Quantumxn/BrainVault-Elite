#!/bin/bash
# ================================================================
# BrainVault Elite - Intrusion Detection & Prevention
# Fail2ban, AppArmor, and audit tools
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Fail2ban Setup =============

setup_fail2ban() {
    log_section "Configuring Fail2ban"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Install and configure Fail2ban"
        add_to_summary "Security" "Enable Fail2ban service"
        return 0
    fi
    
    # Check if Fail2ban is installed
    if ! check_command fail2ban-client fail2ban; then
        log_error "Fail2ban not installed. Installing..."
        install_pkg fail2ban || error_exit "Failed to install Fail2ban"
    fi
    
    # Create custom configuration
    local config_file="/etc/fail2ban/jail.local"
    log_info "Creating Fail2ban configuration: $config_file"
    
    cat > "$config_file" <<'EOF'
[DEFAULT]
# Ban settings
bantime  = 1h
findtime = 10m
maxretry = 5

# Email notifications (configure as needed)
destemail = root@localhost
sender = fail2ban@localhost
action = %(action_)s

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 24h

[sshd-ddos]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 10
findtime = 2m

[apache-auth]
enabled = false
port = http,https
logpath = %(apache_error_log)s

[nginx-botsearch]
enabled = false
port = http,https
logpath = %(nginx_error_log)s
maxretry = 2
EOF
    
    log_info "Enabling and starting Fail2ban service..."
    run_cmd "systemctl enable fail2ban" "Enable Fail2ban"
    run_cmd "systemctl restart fail2ban" "Start Fail2ban"
    
    # Wait for service to start
    sleep 2
    
    # Verify status
    if systemctl is-active --quiet fail2ban; then
        log_success "Fail2ban is running"
        
        log_info "Active jails:"
        fail2ban-client status 2>/dev/null | while read -r line; do
            log_info "  $line"
        done
    else
        log_error "Fail2ban failed to start"
        return 1
    fi
}

# ============= AppArmor Setup =============

setup_apparmor() {
    log_section "Configuring AppArmor"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Enable and enforce AppArmor profiles"
        return 0
    fi
    
    # Check if AppArmor is installed
    if ! check_command aa-status apparmor; then
        log_error "AppArmor not installed. Installing..."
        install_pkg apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra || \
            error_exit "Failed to install AppArmor"
    fi
    
    log_info "Enabling AppArmor service..."
    run_cmd "systemctl enable apparmor" "Enable AppArmor"
    run_cmd "systemctl start apparmor" "Start AppArmor"
    
    # Load all profiles
    log_info "Loading AppArmor profiles..."
    if [[ -d /etc/apparmor.d ]]; then
        local profile_count
        profile_count=$(find /etc/apparmor.d -type f -name '[a-z]*' | wc -l)
        log_info "Found $profile_count AppArmor profiles"
        
        run_cmd "aa-enforce /etc/apparmor.d/*" "Enforce AppArmor profiles" false
    fi
    
    # Show status
    log_info "AppArmor status:"
    if command -v aa-status &>/dev/null; then
        aa-status --pretty-json 2>/dev/null | jq -r '.profiles | to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || \
            aa-status 2>/dev/null | head -10 | while read -r line; do
                log_info "  $line"
            done
    fi
    
    log_success "AppArmor configured successfully"
}

# ============= Audit System =============

setup_audit_system() {
    log_section "Configuring Audit System (auditd)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Install and configure auditd"
        return 0
    fi
    
    # Check if auditd is installed
    if ! check_command auditctl auditd; then
        log_info "Installing auditd..."
        install_pkg auditd audispd-plugins || error_exit "Failed to install auditd"
    fi
    
    log_info "Configuring audit rules..."
    
    # Add audit rules
    cat > /etc/audit/rules.d/brainvault.rules <<'EOF'
# BrainVault Elite Audit Rules

# Monitor file changes in critical directories
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Monitor authentication events
-w /var/log/auth.log -p wa -k auth_log
-w /var/log/faillog -p wa -k login_failures

# Monitor network configuration
-w /etc/hosts -p wa -k network_config
-w /etc/network/ -p wa -k network_config

# Monitor systemd
-w /etc/systemd/ -p wa -k systemd_config

# Monitor kernel module loading
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
EOF
    
    log_info "Enabling and starting auditd..."
    run_cmd "systemctl enable auditd" "Enable auditd"
    run_cmd "systemctl restart auditd" "Start auditd"
    
    log_success "Audit system configured"
}

# ============= Rootkit Detection =============

setup_integrity_tools() {
    log_section "Setting Up Integrity Check Tools"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Install rkhunter and chkrootkit"
        add_to_summary "Security" "Update rkhunter database"
        return 0
    fi
    
    # Install tools
    log_info "Installing rootkit detection tools..."
    install_pkg rkhunter chkrootkit || log_warn "Failed to install some integrity tools"
    
    # Update rkhunter database
    if check_command rkhunter; then
        log_info "Updating rkhunter database..."
        run_cmd "rkhunter --update" "Update rkhunter" false
        run_cmd "rkhunter --propupd" "Update rkhunter properties" false
        
        log_info "Running initial rkhunter check..."
        run_cmd "rkhunter --check --skip-keypress --report-warnings-only" "Run rkhunter check" false
    fi
    
    log_success "Integrity tools configured"
}

# ============= Telemetry Blocking =============

setup_telemetry_block() {
    log_section "Blocking Telemetry Endpoints"
    
    if [[ "$DISABLE_TELEMETRY_BLOCK" == "true" ]]; then
        log_info "Telemetry blocking disabled by user request"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Block common telemetry endpoints with iptables"
        return 0
    fi
    
    log_warn "Setting up basic telemetry blocking..."
    log_warn "Note: This is a simple pattern-based approach and may not catch everything"
    
    # Create a more sophisticated approach using /etc/hosts
    local hosts_file="/etc/hosts"
    local telemetry_domains=(
        "telemetry.microsoft.com"
        "watson.telemetry.microsoft.com"
        "vortex.data.microsoft.com"
        "settings-win.data.microsoft.com"
        "telemetry.ubuntu.com"
        "popcon.ubuntu.com"
        "metrics.ubuntu.com"
    )
    
    log_info "Adding telemetry domains to /etc/hosts..."
    for domain in "${telemetry_domains[@]}"; do
        if ! grep -q "$domain" "$hosts_file"; then
            echo "0.0.0.0 $domain" >> "$hosts_file"
            log_info "  Blocked: $domain"
        fi
    done
    
    log_success "Telemetry blocking configured"
}

# ============= Security Audit =============

run_security_audit() {
    log_section "Running Security Audit"
    
    log_info "Checking Fail2ban status..."
    if systemctl is-active --quiet fail2ban; then
        log_success "Fail2ban is active"
    else
        log_warn "Fail2ban is not running"
    fi
    
    log_info "Checking AppArmor status..."
    if systemctl is-active --quiet apparmor; then
        log_success "AppArmor is active"
    else
        log_warn "AppArmor is not running"
    fi
    
    log_info "Checking audit system status..."
    if systemctl is-active --quiet auditd; then
        log_success "Auditd is active"
    else
        log_warn "Auditd is not running"
    fi
}

# Export functions
export -f setup_fail2ban setup_apparmor setup_audit_system
export -f setup_integrity_tools setup_telemetry_block run_security_audit
