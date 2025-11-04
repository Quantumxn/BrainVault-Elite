#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Firewall Configuration Module
# ================================================================

setup_firewall() {
    local desc="Configuring UFW firewall"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Security" "setup_firewall" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install UFW if not present
    if ! command_exists ufw; then
        install_pkg ufw || {
            log_error "Failed to install UFW"
            return 1
        }
    fi
    
    # Configure firewall rules
    run_cmd "ufw --force reset" "Resetting UFW rules" "" "false"
    run_cmd "ufw default deny incoming" "Setting default deny incoming"
    run_cmd "ufw default allow outgoing" "Setting default allow outgoing"
    
    # Allow SSH (important to not lock yourself out)
    if [ -n "${SSH_PORT:-}" ]; then
        run_cmd "ufw allow ${SSH_PORT}/tcp" "Allowing SSH on port $SSH_PORT"
    else
        run_cmd "ufw allow 22/tcp" "Allowing SSH on port 22"
    fi
    
    # Enable firewall
    run_cmd "ufw --force enable" "Enabling UFW firewall"
    
    log_success "Firewall configuration complete"
    mark_module_loaded "firewall"
    return 0
}
