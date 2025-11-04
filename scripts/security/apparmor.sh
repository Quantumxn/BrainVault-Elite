#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — AppArmor Configuration Module
# ================================================================

setup_apparmor() {
    local desc="Configuring AppArmor"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Security" "setup_apparmor" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install AppArmor if not present
    if ! command_exists apparmor_status; then
        install_pkg apparmor apparmor-utils apparmor-profiles-extra || {
            log_error "Failed to install AppArmor"
            return 1
        }
    fi
    
    # Enable and start AppArmor
    run_cmd "systemctl enable apparmor" "Enabling AppArmor service"
    run_cmd "systemctl start apparmor" "Starting AppArmor service"
    
    # Load AppArmor profiles
    run_cmd "aa-enforce /etc/apparmor.d/*" "Enforcing AppArmor profiles" "" "false"
    
    log_success "AppArmor configuration complete"
    mark_module_loaded "apparmor"
    return 0
}
