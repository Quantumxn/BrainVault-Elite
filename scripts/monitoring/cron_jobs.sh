#!/bin/bash
# cron_jobs.sh - Automated task scheduling for BrainVault Elite

setup_cron_jobs() {
    log_section "⏰ Setting Up Automated Cron Jobs"
    
    if is_dryrun; then
        add_dryrun_operation "CRON" "Setup automated backup jobs"
        add_dryrun_operation "CRON" "Setup security audit jobs"
        add_dryrun_operation "CRON" "Setup system health checks"
        return 0
    fi
    
    # Create cron job directory
    mkdir -p /etc/cron.d
    
    # Setup daily backup
    setup_backup_cron
    
    # Setup weekly security audit
    setup_security_audit_cron
    
    # Setup system health monitoring
    setup_health_check_cron
    
    # Setup log cleanup
    setup_log_cleanup_cron
    
    log_success "Cron jobs configured"
}

# Daily backup cron job
setup_backup_cron() {
    log_info "Setting up daily backup cron job..."
    
    local cron_file="/etc/cron.d/brainvault_backup"
    
    cat > "$cron_file" <<'EOF'
# BrainVault Elite - Daily Backup
# Runs at 2:00 AM every day
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 2 * * * root /bin/bash -c 'source /workspace/scripts/utils/logging.sh; source /workspace/scripts/monitoring/backup.sh; run_full_backup >> /var/log/brainvault_backup.log 2>&1'
EOF
    
    chmod 644 "$cron_file"
    log_success "Daily backup cron job created"
}

# Weekly security audit cron job
setup_security_audit_cron() {
    log_info "Setting up weekly security audit cron job..."
    
    local cron_file="/etc/cron.d/brainvault_security"
    
    cat > "$cron_file" <<'EOF'
# BrainVault Elite - Weekly Security Audit
# Runs at 3:00 AM every Sunday
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 3 * * 0 root /bin/bash -c 'source /workspace/scripts/utils/logging.sh; source /workspace/scripts/security/security_main.sh; run_security_audit >> /var/log/brainvault_security.log 2>&1'
EOF
    
    chmod 644 "$cron_file"
    log_success "Weekly security audit cron job created"
}

# System health check cron job
setup_health_check_cron() {
    log_info "Setting up hourly health check cron job..."
    
    local cron_file="/etc/cron.d/brainvault_health"
    
    cat > "$cron_file" <<'EOF'
# BrainVault Elite - Hourly Health Check
# Runs every hour
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 * * * * root /bin/bash -c 'source /workspace/scripts/utils/logging.sh; source /workspace/scripts/monitoring/monitoring.sh; check_resource_alerts >> /var/log/brainvault_health.log 2>&1'
EOF
    
    chmod 644 "$cron_file"
    log_success "Hourly health check cron job created"
}

# Log cleanup cron job
setup_log_cleanup_cron() {
    log_info "Setting up weekly log cleanup cron job..."
    
    local cron_file="/etc/cron.d/brainvault_cleanup"
    
    cat > "$cron_file" <<'EOF'
# BrainVault Elite - Weekly Log Cleanup
# Runs at 4:00 AM every Sunday
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 4 * * 0 root find /var/log/brainvault*.log -mtime +30 -delete
0 5 * * 0 root /bin/bash -c 'source /workspace/scripts/monitoring/backup.sh; cleanup_old_backups 30'
EOF
    
    chmod 644 "$cron_file"
    log_success "Weekly log cleanup cron job created"
}

# AIDE integrity check cron job
setup_aide_cron() {
    log_info "Setting up weekly AIDE integrity check..."
    
    if ! command_exists aide; then
        log_warn "AIDE not installed, skipping cron setup"
        return 1
    fi
    
    local cron_file="/etc/cron.d/brainvault_aide"
    
    cat > "$cron_file" <<'EOF'
# BrainVault Elite - Weekly AIDE Integrity Check
# Runs at 1:00 AM every Monday
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 1 * * 1 root /usr/bin/aide --check >> /var/log/brainvault_aide.log 2>&1
EOF
    
    chmod 644 "$cron_file"
    log_success "Weekly AIDE check cron job created"
}

# System update cron job
setup_update_cron() {
    log_info "Setting up automatic security updates..."
    
    if is_dryrun; then
        add_dryrun_operation "CRON" "Setup automatic security updates"
        return 0
    fi
    
    # Install unattended-upgrades
    if ! dpkg -l | grep -q unattended-upgrades; then
        safe_exec "Installing unattended-upgrades" apt-get install -y unattended-upgrades
    fi
    
    # Configure unattended-upgrades
    cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF
    
    # Enable automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    
    log_success "Automatic security updates configured"
}

# Docker cleanup cron job
setup_docker_cleanup_cron() {
    log_info "Setting up weekly Docker cleanup..."
    
    if ! command_exists docker; then
        log_warn "Docker not installed, skipping cron setup"
        return 1
    fi
    
    local cron_file="/etc/cron.d/brainvault_docker_cleanup"
    
    cat > "$cron_file" <<'EOF'
# BrainVault Elite - Weekly Docker Cleanup
# Runs at 5:00 AM every Saturday
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 5 * * 6 root /usr/bin/docker system prune -af --volumes >> /var/log/brainvault_docker.log 2>&1
EOF
    
    chmod 644 "$cron_file"
    log_success "Weekly Docker cleanup cron job created"
}

# List all BrainVault cron jobs
list_cron_jobs() {
    log_section "📋 BrainVault Cron Jobs"
    
    echo ""
    echo "Active cron jobs:"
    echo ""
    
    local cron_files=$(find /etc/cron.d -name "brainvault_*" 2>/dev/null)
    
    if [[ -z "$cron_files" ]]; then
        log_info "No BrainVault cron jobs found"
        return 0
    fi
    
    for cron_file in $cron_files; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "File: $(basename "$cron_file")"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        grep -v "^#" "$cron_file" | grep -v "^$" | sed 's/^/  /'
        echo ""
    done
}

# Remove all BrainVault cron jobs
remove_cron_jobs() {
    log_info "Removing BrainVault cron jobs..."
    
    if is_dryrun; then
        add_dryrun_operation "CRON" "Remove all BrainVault cron jobs"
        return 0
    fi
    
    local cron_files=$(find /etc/cron.d -name "brainvault_*" 2>/dev/null)
    
    if [[ -z "$cron_files" ]]; then
        log_info "No BrainVault cron jobs found"
        return 0
    fi
    
    for cron_file in $cron_files; do
        rm -f "$cron_file"
        log_info "Removed: $(basename "$cron_file")"
    done
    
    log_success "All BrainVault cron jobs removed"
}

# Test cron job configuration
test_cron_jobs() {
    log_section "🧪 Testing Cron Job Configuration"
    
    log_info "Checking cron service..."
    
    if ! systemctl is-active --quiet cron; then
        log_error "Cron service is not running"
        return 1
    fi
    
    log_success "Cron service is running"
    
    # Check syntax of cron files
    local cron_files=$(find /etc/cron.d -name "brainvault_*" 2>/dev/null)
    
    for cron_file in $cron_files; do
        if [[ -f "$cron_file" ]]; then
            log_info "Checking: $(basename "$cron_file")"
            
            # Basic syntax check
            if grep -q "^[0-9*]" "$cron_file"; then
                log_success "  Syntax OK"
            else
                log_warn "  No cron entries found"
            fi
        fi
    done
    
    log_success "Cron job configuration test completed"
}

# Enable all monitoring cron jobs
enable_all_cron_jobs() {
    log_section "⏰ ENABLING ALL MONITORING CRON JOBS"
    
    setup_backup_cron
    setup_security_audit_cron
    setup_health_check_cron
    setup_log_cleanup_cron
    
    if command_exists aide; then
        setup_aide_cron
    fi
    
    if command_exists docker; then
        setup_docker_cleanup_cron
    fi
    
    setup_update_cron
    
    # Restart cron service
    if ! is_dryrun; then
        safe_exec "Restarting cron service" systemctl restart cron
    fi
    
    log_success "All cron jobs enabled"
}

# Export functions
export -f setup_cron_jobs
export -f setup_backup_cron
export -f setup_security_audit_cron
export -f setup_health_check_cron
export -f setup_log_cleanup_cron
export -f setup_aide_cron
export -f setup_update_cron
export -f setup_docker_cleanup_cron
export -f list_cron_jobs
export -f remove_cron_jobs
export -f test_cron_jobs
export -f enable_all_cron_jobs
