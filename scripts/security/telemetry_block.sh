#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Telemetry Blocking Module
# ================================================================

setup_telemetry_block() {
    local desc="Configuring telemetry blocking"
    
    if [ "${DISABLE_TELEMETRY:-false}" = "true" ]; then
        log_warn "Telemetry blocking disabled per user request"
        return 0
    fi
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Security" "setup_telemetry_block" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install iptables-persistent if not present
    if ! command_exists iptables; then
        install_pkg iptables iptables-persistent || {
            log_error "Failed to install iptables"
            return 1
        }
    fi
    
    # Block common telemetry endpoints
    local telemetry_hosts=(
        "telemetry.microsoft.com"
        "vortex.data.microsoft.com"
        "settings-win.data.microsoft.com"
        "v10.vortex-win.data.microsoft.com"
        "telemetry.ubuntu.com"
        "metrics.ubuntu.com"
    )
    
    for host in "${telemetry_hosts[@]}"; do
        run_cmd "iptables -A OUTPUT -d $host -j DROP" \
            "Blocking telemetry host: $host" "" "false"
    done
    
    # Save iptables rules
    if command_exists netfilter-persistent; then
        run_cmd "netfilter-persistent save" "Saving iptables rules"
    elif [ -d "/etc/iptables" ]; then
        run_cmd "iptables-save > /etc/iptables/rules.v4" "Saving iptables rules"
    fi
    
    log_success "Telemetry blocking configuration complete"
    mark_module_loaded "telemetry_block"
    return 0
}
