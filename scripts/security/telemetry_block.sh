#!/bin/bash
# Telemetry blocking configuration script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_telemetry_block() {
    log_section "Installing Telemetry Blocking Tools"
    
    # No additional packages needed, using /etc/hosts
    log_success "Telemetry blocking tools (using /etc/hosts) - no installation needed"
}

setup_telemetry_block() {
    log_section "Configuring Telemetry Blocking"
    
    # Check if telemetry blocking is enabled
    local disable_telemetry="${DISABLE_TELEMETRY:-0}"
    
    if [[ "$disable_telemetry" != "1" ]]; then
        log_warn "Telemetry blocking requires --disable-telemetry flag. Skipping..."
        return 0
    fi
    
    log_step "Blocking telemetry endpoints in /etc/hosts"
    local hosts_file="/etc/hosts"
    local hosts_backup="${hosts_file}.brainvault-backup"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would backup and modify $hosts_file"
    else
        # Backup original hosts file
        if ! file_exists "$hosts_backup"; then
            cp "$hosts_file" "$hosts_backup"
            log_success "Backed up original hosts file"
        fi
        
        # Add telemetry blocking entries
        if ! grep -q "# BrainVault Elite Telemetry Block" "$hosts_file"; then
            cat >> "$hosts_file" << 'EOF'

# BrainVault Elite Telemetry Block
# Microsoft Telemetry
0.0.0.0 telemetry.microsoft.com
0.0.0.0 vortex.data.microsoft.com
0.0.0.0 vorte-x.data.microsoft.com
0.0.0.0 watson.telemetry.microsoft.com
0.0.0.0 telemetry.urs.microsoft.com
0.0.0.0 sqm.telemetry.microsoft.com
0.0.0.0 data-ssl.microsoft.com
0.0.0.0 data.microsoft.com

# Google Telemetry
0.0.0.0 telemetry.google.com
0.0.0.0 telemetry.gstatic.com
0.0.0.0 connectivitycheck.gstatic.com
0.0.0.0 clients4.google.com
0.0.0.0 clients2.google.com

# Canonical/Ubuntu Telemetry
0.0.0.0 metrics.ubuntu.com
0.0.0.0 telemetry.canonical.com

# Amazon Telemetry
0.0.0.0 device-metrics-us.amazon.com
0.0.0.0 metrics-na.amazon.com

# Facebook/Meta Telemetry
0.0.0.0 graph.facebook.com
0.0.0.0 analytics.facebook.com

# Apple Telemetry
0.0.0.0 metrics.icloud.com
0.0.0.0 metrics.mzstatic.com
EOF
            log_success "Telemetry blocking entries added to /etc/hosts"
        else
            log_info "Telemetry blocking already configured"
        fi
    fi
    
    log_success "Telemetry blocking configuration completed"
}

check_telemetry_block() {
    log_info "Telemetry Blocking Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if grep -q "# BrainVault Elite Telemetry Block" /etc/hosts; then
            local blocked_count=$(grep -c "^0.0.0.0" /etc/hosts | grep -v "#" || echo "0")
            log_success "Telemetry blocking active: $blocked_count endpoints blocked"
        else
            log_warn "Telemetry blocking not configured"
        fi
    else
        log_warn "[DRY-RUN] Would check telemetry blocking status"
    fi
}
