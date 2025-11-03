#!/bin/bash
# ================================================================
# BrainVault Elite - System Monitoring
# Netdata, Prometheus exporters, and audit tools
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Netdata Installation =============

install_netdata() {
    log_section "Installing Netdata Real-time Monitoring"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Monitoring" "Install Netdata monitoring system"
        add_to_summary "Monitoring" "Configure Netdata to start on boot"
        return 0
    fi
    
    # Check if Netdata is already installed
    if check_command netdata; then
        log_info "Netdata already installed"
        return 0
    fi
    
    log_info "Installing Netdata..."
    
    # Install from repository (faster than kickstart script)
    if install_pkg netdata 2>/dev/null; then
        log_success "Netdata installed from repository"
    else
        log_info "Repository installation failed, trying kickstart script..."
        
        # Use official kickstart script
        if curl -fsSL https://get.netdata.cloud/kickstart.sh | bash -s -- --dont-wait >>"$LOGFILE" 2>&1; then
            log_success "Netdata installed via kickstart script"
        else
            log_error "Netdata installation failed"
            return 1
        fi
    fi
    
    # Enable and start service
    run_cmd "systemctl enable netdata" "Enable Netdata"
    run_cmd "systemctl start netdata" "Start Netdata"
    
    # Wait for service
    sleep 3
    
    if systemctl is-active --quiet netdata; then
        log_success "Netdata is running"
        log_info "Access Netdata at: http://localhost:19999"
    else
        log_warn "Netdata service failed to start"
    fi
}

# ============= Prometheus Exporters =============

install_prometheus_exporters() {
    log_section "Installing Prometheus Exporters"
    
    local exporters=(
        prometheus-node-exporter
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Monitoring" "Install Prometheus node exporter"
        return 0
    fi
    
    log_info "Installing Prometheus exporters..."
    install_pkg "${exporters[@]}" || log_warn "Some exporters failed to install"
    
    # Enable and start node exporter
    if check_command prometheus-node-exporter || systemctl list-unit-files | grep -q prometheus-node-exporter; then
        run_cmd "systemctl enable prometheus-node-exporter" "Enable node exporter" false
        run_cmd "systemctl start prometheus-node-exporter" "Start node exporter" false
        
        if systemctl is-active --quiet prometheus-node-exporter; then
            log_success "Prometheus node exporter is running on port 9100"
        fi
    fi
}

# ============= Audit Script Creation =============

create_audit_script() {
    log_section "Creating System Audit Script"
    
    local audit_script="/usr/local/bin/brainvault-audit"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Monitoring" "Create comprehensive audit script"
        return 0
    fi
    
    log_info "Creating audit script: $audit_script"
    
    cat > "$audit_script" <<'EOF'
#!/bin/bash
# ================================================================
# BrainVault Elite - System Security Audit
# Comprehensive security audit and health check
# ================================================================

set -euo pipefail

LOG_FILE="/var/log/brainvault-audit.log"
REPORT_FILE="/var/log/brainvault-audit-report_$(date +%F_%H-%M).txt"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

section() {
    echo "" | tee -a "$REPORT_FILE"
    echo "========================================" | tee -a "$REPORT_FILE"
    echo "$1" | tee -a "$REPORT_FILE"
    echo "========================================" | tee -a "$REPORT_FILE"
    log "$1"
}

# Start audit
log "Starting BrainVault Elite security audit"
{
    echo "BrainVault Elite Security Audit Report"
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
} > "$REPORT_FILE"

# System Information
section "System Information"
{
    echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage: $(free -h | awk 'NR==2 {printf "%s / %s (%.1f%%)\n", $3, $2, $3/$2*100}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {printf "%s / %s (%s)\n", $3, $2, $5}')"
} >> "$REPORT_FILE"

# Security Services Status
section "Security Services"
{
    for service in ufw fail2ban apparmor auditd; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "✓ $service: ACTIVE"
        else
            echo "✗ $service: INACTIVE"
        fi
    done
} >> "$REPORT_FILE"

# Firewall Status
section "Firewall Rules"
if command -v ufw &>/dev/null; then
    ufw status numbered >> "$REPORT_FILE" 2>&1 || echo "UFW status unavailable" >> "$REPORT_FILE"
fi

# Failed Login Attempts
section "Recent Failed Login Attempts"
if [[ -f /var/log/auth.log ]]; then
    grep "Failed password" /var/log/auth.log | tail -20 >> "$REPORT_FILE" 2>&1 || \
        echo "No recent failed logins" >> "$REPORT_FILE"
fi

# Listening Ports
section "Listening Ports"
ss -tulpn | grep LISTEN >> "$REPORT_FILE" 2>&1 || netstat -tulpn | grep LISTEN >> "$REPORT_FILE" 2>&1

# User Accounts
section "User Accounts"
{
    echo "Total users: $(wc -l < /etc/passwd)"
    echo "Users with shell access:"
    grep -v '/nologin\|/false' /etc/passwd | cut -d: -f1 | tr '\n' ', '
    echo ""
} >> "$REPORT_FILE"

# SUID/SGID Files
section "SUID/SGID Files (Summary)"
{
    echo "Count: $(find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | wc -l)"
    echo "Critical paths:"
    find /bin /sbin /usr/bin /usr/sbin -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -20
} >> "$REPORT_FILE"

# World-writable Files
section "World-Writable Files (Sample)"
{
    echo "Count: $(find / -type f -perm -002 2>/dev/null | wc -l)"
    find /tmp /var/tmp -type f -perm -002 2>/dev/null | head -10
} >> "$REPORT_FILE"

# Package Updates
section "Available Updates"
if command -v apt &>/dev/null; then
    apt list --upgradable 2>/dev/null | tail -20 >> "$REPORT_FILE"
fi

# Lynis Audit (if available)
if command -v lynis &>/dev/null; then
    section "Lynis Security Audit"
    log "Running Lynis audit (this may take a few minutes)..."
    lynis audit system --quick --quiet >> "$REPORT_FILE" 2>&1 || echo "Lynis audit failed" >> "$REPORT_FILE"
fi

# Rootkit Check (if available)
if command -v rkhunter &>/dev/null; then
    section "Rootkit Hunter Check"
    log "Running rkhunter (this may take a few minutes)..."
    rkhunter --check --skip-keypress --report-warnings-only >> "$REPORT_FILE" 2>&1 || \
        echo "rkhunter check completed with warnings" >> "$REPORT_FILE"
fi

# Summary
section "Audit Summary"
{
    echo "Audit completed successfully"
    echo "Report saved to: $REPORT_FILE"
    echo "Log file: $LOG_FILE"
} >> "$REPORT_FILE"

log "Audit completed"
log "Report: $REPORT_FILE"

# Display report location
echo ""
echo "Audit report saved to: $REPORT_FILE"
echo "To view: cat $REPORT_FILE"
EOF
    
    chmod +x "$audit_script"
    log_success "Audit script created: $audit_script"
}

# ============= Lynis Installation =============

install_security_audit_tools() {
    log_section "Installing Security Audit Tools"
    
    local audit_tools=(
        lynis
        chkrootkit
        rkhunter
        aide
        debsums
        needrestart
        debsecan
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Monitoring" "Install security audit tools: ${audit_tools[*]}"
        return 0
    fi
    
    install_pkg "${audit_tools[@]}" || log_warn "Some audit tools failed to install"
    
    # Initialize AIDE if installed
    if check_command aide; then
        log_info "Initializing AIDE database (this may take a while)..."
        run_cmd "aideinit" "Initialize AIDE database" false || log_warn "AIDE init failed"
    fi
}

# ============= Scheduled Audits =============

setup_audit_cron() {
    log_section "Scheduling Automated Security Audits"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Monitoring" "Schedule daily security audits via cron"
        return 0
    fi
    
    log_info "Creating cron job for automated audits..."
    
    local cron_job="0 2 * * * /usr/local/bin/brainvault-audit >> /var/log/brainvault-audit.log 2>&1"
    
    if ! crontab -l 2>/dev/null | grep -q "brainvault-audit"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log_success "Automated audit scheduled (daily at 2:00 AM)"
    else
        log_info "Audit cron job already exists"
    fi
}

# ============= Monitoring Status =============

show_monitoring_info() {
    log_section "Monitoring System Information"
    
    # Netdata
    if systemctl is-active --quiet netdata 2>/dev/null; then
        log_success "Netdata: Running (http://localhost:19999)"
    else
        log_info "Netdata: Not installed or not running"
    fi
    
    # Prometheus
    if systemctl is-active --quiet prometheus-node-exporter 2>/dev/null; then
        log_success "Prometheus Node Exporter: Running (http://localhost:9100/metrics)"
    else
        log_info "Prometheus Node Exporter: Not installed or not running"
    fi
    
    # Audit tools
    if [[ -f /usr/local/bin/brainvault-audit ]]; then
        log_success "Audit script: /usr/local/bin/brainvault-audit"
    else
        log_warn "Audit script: Not found"
    fi
    
    if crontab -l 2>/dev/null | grep -q "brainvault-audit"; then
        log_success "Automated audits: Enabled"
    else
        log_info "Automated audits: Not scheduled"
    fi
}

# Export functions
export -f install_netdata install_prometheus_exporters create_audit_script
export -f install_security_audit_tools setup_audit_cron show_monitoring_info
