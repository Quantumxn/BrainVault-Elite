#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Security Module Main
# ================================================================

# Source individual security modules
source_security_modules() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Source all security modules
    for module in "$script_dir"/*.sh; do
        if [ -f "$module" ] && [ "$(basename "$module")" != "security_main.sh" ]; then
            log_debug "Loading security module: $(basename "$module")"
            source "$module" || {
                log_error "Failed to load security module: $module"
                return 1
            }
        fi
    done
}

# Main security setup function
install_security_stack() {
    if [ "${SKIP_SECURITY:-false}" = "true" ]; then
        log_warn "Security stack installation skipped per user request"
        return 0
    fi
    
    log_info "🔐 Installing security stack..."
    
    # Source all security modules
    source_security_modules || {
        log_error "Failed to load security modules"
        return 1
    }
    
    # Install security packages
    local security_packages=(
        "ufw"
        "fail2ban"
        "apparmor"
        "apparmor-utils"
        "apparmor-profiles-extra"
        "lynis"
        "chkrootkit"
        "rkhunter"
        "aide-common"
        "auditd"
        "needrestart"
        "debsecan"
    )
    
    install_pkg "${security_packages[@]}" || {
        log_error "Failed to install security packages"
        return 1
    }
    
    # Configure security components
    setup_firewall || log_warn "Firewall setup had issues"
    setup_fail2ban || log_warn "Fail2Ban setup had issues"
    setup_apparmor || log_warn "AppArmor setup had issues"
    
    if [ "${DISABLE_TELEMETRY:-false}" != "true" ]; then
        setup_telemetry_block || log_warn "Telemetry blocking setup had issues"
    fi
    
    setup_kernel_hardening || log_warn "Kernel hardening setup had issues"
    setup_integrity_tools || log_warn "Integrity tools setup had issues"
    
    log_success "Security stack installation complete"
    return 0
}
