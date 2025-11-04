#!/bin/bash
# Monitoring module main orchestrator

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

# Source monitoring modules
source "${SCRIPT_DIR}/backup.sh"
source "${SCRIPT_DIR}/monitoring.sh"
source "${SCRIPT_DIR}/cron_jobs.sh"

install_monitoring_stack() {
    log_section "Installing Monitoring Stack"
    
    install_backup
    install_monitoring
    install_cron_jobs
    
    log_success "Monitoring stack installation completed"
}

setup_monitoring_stack() {
    log_section "Configuring Monitoring Stack"
    
    setup_backup
    setup_monitoring
    setup_cron_jobs
    
    log_success "Monitoring stack configuration completed"
}

check_monitoring_stack_status() {
    log_section "Monitoring Status Check"
    
    check_backup_status
    check_monitoring_status
    check_cron_jobs_status
    
    log_success "Monitoring status check completed"
}
