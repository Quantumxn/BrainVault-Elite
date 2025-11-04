#!/bin/bash
# monitoring_main.sh - Main monitoring orchestrator for BrainVault Elite

setup_monitoring_stack() {
    log_section "📊 MONITORING STACK INSTALLATION"
    
    if [[ "${SKIP_MONITORING:-0}" == "1" ]]; then
        log_warn "Skipping monitoring stack (--skip-monitoring flag)"
        return 0
    fi
    
    # Install monitoring tools
    install_monitoring_tools
    
    # Setup backup system
    install_backup_tools
    setup_backup_directories
    
    # Configure log rotation
    setup_log_rotation
    
    # Setup cron jobs
    enable_all_cron_jobs
    
    # Initial health check
    run_health_check
    
    log_success "Monitoring stack installation completed"
}

# Quick monitoring setup
quick_monitoring_setup() {
    log_section "⚡ QUICK MONITORING SETUP"
    
    log_info "Installing essential monitoring tools..."
    
    # Basic monitoring
    install_basic_monitoring_tools
    setup_log_rotation
    
    # Essential cron jobs
    setup_backup_cron
    setup_health_check_cron
    
    log_success "Quick monitoring setup completed"
}

# Full monitoring setup
full_monitoring_setup() {
    log_section "🚀 FULL MONITORING SETUP"
    
    log_info "Installing complete monitoring environment..."
    
    # All monitoring tools
    install_monitoring_tools
    
    # Backup system
    install_backup_tools
    setup_backup_directories
    setup_rclone
    
    # Log management
    setup_log_rotation
    
    # All cron jobs
    enable_all_cron_jobs
    
    # Initial backup
    run_full_backup
    
    # Health check
    run_health_check
    
    log_success "Full monitoring setup completed"
}

# Run comprehensive system audit
run_comprehensive_audit() {
    log_section "🔍 COMPREHENSIVE SYSTEM AUDIT"
    
    # System health
    run_health_check
    
    # Resource monitoring
    monitor_resources
    
    # Check for alerts
    check_resource_alerts
    
    # Security audit
    if type -t run_security_audit >/dev/null; then
        run_security_audit
    fi
    
    # Integrity check
    if command_exists aide && [[ -f /var/lib/aide/aide.db ]]; then
        run_aide_check || true
    fi
    
    # Show monitoring status
    show_monitoring_status
    
    log_success "Comprehensive audit completed"
}

# Daily maintenance routine
run_daily_maintenance() {
    log_section "🔧 DAILY MAINTENANCE ROUTINE"
    
    log_info "Running daily maintenance tasks..."
    
    # Update package list
    if ! is_dryrun; then
        apt-get update -qq || log_warn "Package update failed"
    fi
    
    # Check for security updates
    if command_exists apt-get; then
        local security_updates=$(apt-get upgrade -s | grep -i security | wc -l)
        if [[ $security_updates -gt 0 ]]; then
            log_warn "$security_updates security update(s) available"
        else
            log_success "No security updates needed"
        fi
    fi
    
    # Run health check
    run_health_check
    
    # Check resource alerts
    check_resource_alerts
    
    # Cleanup old logs
    if ! is_dryrun; then
        find /var/log -name "*.log" -mtime +30 -type f -delete 2>/dev/null || true
    fi
    
    log_success "Daily maintenance completed"
}

# Weekly maintenance routine
run_weekly_maintenance() {
    log_section "🔧 WEEKLY MAINTENANCE ROUTINE"
    
    log_info "Running weekly maintenance tasks..."
    
    # Full backup
    run_full_backup
    
    # Security audit
    if type -t run_security_audit >/dev/null; then
        run_security_audit
    fi
    
    # Integrity check
    if command_exists aide; then
        run_aide_check || true
    fi
    
    # Cleanup old backups
    cleanup_old_backups 30
    
    # Docker cleanup
    if command_exists docker; then
        cleanup_docker
    fi
    
    log_success "Weekly maintenance completed"
}

# Emergency response
emergency_response() {
    log_section "🚨 EMERGENCY RESPONSE"
    
    log_warn "Running emergency diagnostic..."
    
    # Quick health check
    run_health_check
    
    # Check for high resource usage
    check_resource_alerts
    
    # Show top processes
    echo ""
    echo "Top CPU Processes:"
    ps aux --sort=-%cpu | head -11
    
    echo ""
    echo "Top Memory Processes:"
    ps aux --sort=-%mem | head -11
    
    # Check disk space
    echo ""
    echo "Disk Space:"
    df -h | grep -vE "tmpfs|devtmpfs"
    
    # Check network connections
    echo ""
    echo "Active Network Connections:"
    ss -tunap | grep ESTAB | head -10
    
    # Recent errors in syslog
    echo ""
    echo "Recent System Errors:"
    grep -i error /var/log/syslog | tail -10 2>/dev/null || echo "No recent errors"
    
    log_info "Emergency diagnostic completed"
}

# Show monitoring dashboard
show_monitoring_dashboard() {
    log_section "📊 MONITORING DASHBOARD"
    
    # System health
    run_health_check
    
    # Monitoring status
    show_monitoring_status
    
    # Cron jobs
    echo ""
    echo "Scheduled Tasks:"
    list_cron_jobs | grep -v "^$" | head -20
    
    # Recent backups
    echo ""
    echo "Recent Backups:"
    if [[ -d /var/backups/brainvault ]]; then
        find /var/backups/brainvault -type f -mtime -7 -exec ls -lh {} \; 2>/dev/null | head -10 || echo "No recent backups"
    else
        echo "Backup directory not found"
    fi
    
    # Log summary
    echo ""
    echo "Log Summary:"
    if [[ -f /var/log/brainvault_health.log ]]; then
        echo "  Health log: $(wc -l < /var/log/brainvault_health.log) lines"
    fi
    if [[ -f /var/log/brainvault_backup.log ]]; then
        echo "  Backup log: $(wc -l < /var/log/brainvault_backup.log) lines"
    fi
    if [[ -f /var/log/brainvault_security.log ]]; then
        echo "  Security log: $(wc -l < /var/log/brainvault_security.log) lines"
    fi
    
    echo ""
}

# Generate monitoring report
generate_monitoring_report() {
    local report_file="/tmp/brainvault_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Generating monitoring report..."
    
    {
        echo "╔══════════════════════════════════════════════════════╗"
        echo "║     BrainVault Elite - System Monitoring Report     ║"
        echo "║     Generated: $(date)              ║"
        echo "╚══════════════════════════════════════════════════════╝"
        echo ""
        
        # System information
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(lsb_release -d | cut -f2-)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo ""
        
        # Health check
        run_health_check
        
        # Resource monitoring
        monitor_resources
        
        # Security status
        if type -t show_security_status >/dev/null; then
            show_security_status
        fi
        
        # Monitoring status
        show_monitoring_status
        
        # Cron jobs
        list_cron_jobs
        
    } > "$report_file"
    
    log_success "Report generated: $report_file"
    echo "$report_file"
}

# Export functions
export -f setup_monitoring_stack
export -f quick_monitoring_setup
export -f full_monitoring_setup
export -f run_comprehensive_audit
export -f run_daily_maintenance
export -f run_weekly_maintenance
export -f emergency_response
export -f show_monitoring_dashboard
export -f generate_monitoring_report
