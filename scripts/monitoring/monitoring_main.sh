#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Monitoring Module Main
# ================================================================

# Source individual monitoring modules
source_monitoring_modules() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Source all monitoring modules
    for module in "$script_dir"/*.sh; do
        if [ -f "$module" ] && [ "$(basename "$module")" != "monitoring_main.sh" ]; then
            log_debug "Loading monitoring module: $(basename "$module")"
            source "$module" || {
                log_error "Failed to load monitoring module: $module"
                return 1
            }
        fi
    done
}

# Main monitoring setup function
install_monitoring_stack() {
    log_info "📊 Setting up monitoring and backup..."
    
    # Source all monitoring modules
    source_monitoring_modules || {
        log_error "Failed to load monitoring modules"
        return 1
    }
    
    # Create snapshot and backup configs
    create_snapshot || log_warn "Snapshot creation had issues"
    backup_configs || log_warn "Config backup had issues"
    
    # Setup backup template
    setup_backup_template || log_warn "Backup template setup had issues"
    
    # Install monitoring tools
    install_monitoring || log_warn "Monitoring installation had issues"
    
    # Create audit script
    create_audit_script || log_warn "Audit script creation had issues"
    
    # Setup cron jobs
    setup_cron_jobs || log_warn "Cron jobs setup had issues"
    
    log_success "Monitoring and backup setup complete"
    return 0
}
