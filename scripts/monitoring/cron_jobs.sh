#!/bin/bash
# Cron jobs and automated tasks script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_cron_jobs() {
    log_section "Installing Cron Job System"
    
    # Cron is usually pre-installed
    if ! command_exists cron; then
        log_info "Installing cron..."
        dryrun_install "cron" "Cron daemon"
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y cron
        fi
    else
        log_success "Cron is already installed"
    fi
    
    log_success "Cron job system installation completed"
}

setup_cron_jobs() {
    log_section "Configuring Cron Jobs"
    
    # Check if cron is installed
    if ! command_exists cron; then
        log_error "Cron is not installed. Run install_cron_jobs first."
        return 1
    fi
    
    log_step "Setting up system audit cron jobs"
    local cron_file="/etc/cron.d/brainvault-audit"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create cron jobs: $cron_file"
    else
        cat > "$cron_file" << 'EOF'
# BrainVault Elite System Audit Cron Jobs
# Daily system health check
0 2 * * * root /opt/brainvault/scripts/health_check.sh >> /var/log/brainvault/health.log 2>&1

# Weekly AIDE integrity check
0 3 * * 0 root /usr/bin/aide --check >> /var/log/brainvault/aide.log 2>&1

# Daily backup (if backup script exists)
0 1 * * * root [ -f /opt/brainvault/scripts/backup.sh ] && /opt/brainvault/scripts/backup.sh >> /var/log/brainvault/backup.log 2>&1

# Weekly system update check
0 4 * * 0 root apt-get update -qq && apt-get upgrade -s >> /var/log/brainvault/updates.log 2>&1
EOF
        chmod 644 "$cron_file"
        log_success "Cron jobs configured"
    fi
    
    log_step "Creating health check script"
    local health_script="/opt/brainvault/scripts/health_check.sh"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create health check script"
    else
        mkdir -p "/opt/brainvault/scripts" "/var/log/brainvault"
        
        cat > "$health_script" << 'EOF'
#!/bin/bash
# BrainVault Elite Health Check Script

LOG_FILE="/var/log/brainvault/health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting health check..."

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $DISK_USAGE -gt 80 ]]; then
    echo "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check memory
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [[ $MEM_USAGE -gt 90 ]]; then
    echo "WARNING: Memory usage is ${MEM_USAGE}%"
fi

# Check critical services
SERVICES=("ufw" "fail2ban" "docker")
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "OK: Service $service is running"
    else
        echo "WARNING: Service $service is not running"
    fi
done

echo "[$DATE] Health check completed"
EOF
        chmod +x "$health_script"
        log_success "Health check script created"
    fi
    
    log_step "Starting cron service"
    dryrun_service "enable" "cron"
    dryrun_service "start" "cron"
    
    log_success "Cron jobs configuration completed"
}

check_cron_jobs_status() {
    log_info "Cron Jobs Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if service_running cron; then
            log_success "Cron service: running"
            
            if [[ -f "/etc/cron.d/brainvault-audit" ]]; then
                log_success "BrainVault cron jobs: configured"
                log_info "Scheduled jobs:"
                cat /etc/cron.d/brainvault-audit | grep -v "^#" | grep -v "^$" || true
            else
                log_warn "BrainVault cron jobs: not configured"
            fi
        else
            log_warn "Cron service: not running"
        fi
    else
        log_warn "[DRY-RUN] Would check cron jobs status"
    fi
}
