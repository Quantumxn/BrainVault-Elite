#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Monitoring Module
# ================================================================

install_monitoring() {
    local desc="Installing monitoring tools"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Monitoring" "install_monitoring" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install monitoring tools
    local monitoring_packages=(
        "netdata"
        "prometheus-node-exporter"
    )
    
    install_pkg "${monitoring_packages[@]}" || {
        log_error "Failed to install monitoring tools"
        return 1
    }
    
    # Enable and start Netdata
    if command_exists netdata; then
        run_cmd "systemctl enable netdata" "Enabling Netdata service"
        run_cmd "systemctl start netdata" "Starting Netdata service"
    fi
    
    # Enable and start Prometheus node exporter
    if command_exists prometheus-node-exporter; then
        run_cmd "systemctl enable prometheus-node-exporter" \
            "Enabling Prometheus node exporter"
        run_cmd "systemctl start prometheus-node-exporter" \
            "Starting Prometheus node exporter"
    fi
    
    log_success "Monitoring tools installation complete"
    mark_module_loaded "monitoring"
    return 0
}

create_audit_script() {
    local desc="Creating audit script"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Monitoring" "create_audit_script" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    local audit_script="/usr/local/bin/elite-audit"
    cat > "$audit_script" <<'EOS'
#!/bin/bash
# BrainVault Elite Audit Script

set -euo pipefail

LOG_FILE="/var/log/elite-audit.log"
DATE=$(date '+%F %T')

log() {
    echo "[$DATE] $*" | tee -a "$LOG_FILE"
}

log "===== BrainVault Elite Audit Started ====="

# Run Lynis audit if available
if command -v lynis >/dev/null 2>&1; then
    log "Running Lynis system audit..."
    lynis audit system >> "$LOG_FILE" 2>&1 || log "Lynis audit completed with warnings"
fi

# Run rkhunter check if available
if command -v rkhunter >/dev/null 2>&1; then
    log "Running rkhunter check..."
    rkhunter --check --skip-keypress --report-warnings-only >> "$LOG_FILE" 2>&1 || log "rkhunter check completed"
fi

# Run AIDE check if available
if command -v aide >/dev/null 2>&1; then
    log "Running AIDE integrity check..."
    aide --check >> "$LOG_FILE" 2>&1 || log "AIDE check completed"
fi

# Check for security updates
if command -v debsecan >/dev/null 2>&1; then
    log "Checking for security updates..."
    debsecan >> "$LOG_FILE" 2>&1 || log "Security update check completed"
fi

log "===== BrainVault Elite Audit Completed ====="
EOS
    
    run_cmd "chmod +x $audit_script" "Making audit script executable"
    
    log_success "Audit script created: $audit_script"
    mark_module_loaded "audit_script"
    return 0
}

setup_cron_jobs() {
    local desc="Setting up cron jobs"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Monitoring" "setup_cron_jobs" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Schedule daily audit
    local cron_job="0 2 * * * /usr/local/bin/elite-audit >> /var/log/elite-audit.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "elite-audit"; then
        log_info "Audit cron job already exists"
    else
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log_success "Scheduled daily audit at 2:00 AM"
    fi
    
    # Schedule weekly backup (if backup script exists)
    if [ -f "/usr/local/bin/elite-backup.sh" ]; then
        local backup_cron="0 3 * * 0 /usr/local/bin/elite-backup.sh weekly >> /var/log/elite-backup.log 2>&1"
        if ! crontab -l 2>/dev/null | grep -q "elite-backup.sh"; then
            (crontab -l 2>/dev/null; echo "$backup_cron") | crontab -
            log_success "Scheduled weekly backup on Sunday at 3:00 AM"
        fi
    fi
    
    log_success "Cron jobs setup complete"
    mark_module_loaded "cron_jobs"
    return 0
}
