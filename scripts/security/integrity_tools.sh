#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Integrity & Audit Tools Module
# ================================================================

setup_integrity_tools() {
    local desc="Setting up integrity and audit tools"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Security" "setup_integrity_tools" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install security audit tools
    local security_tools=(
        "lynis"
        "chkrootkit"
        "rkhunter"
        "aide-common"
        "auditd"
        "needrestart"
        "debsecan"
    )
    
    for tool in "${security_tools[@]}"; do
        if ! command_exists "$tool"; then
            install_pkg "$tool" || {
                log_warn "Failed to install $tool, continuing..."
            }
        fi
    done
    
    # Update rkhunter database
    if command_exists rkhunter; then
        run_cmd "rkhunter --update" "Updating rkhunter database" "" "false"
    fi
    
    # Initialize AIDE database
    if command_exists aide; then
        log_info "Initializing AIDE database (this may take a while)..."
        run_cmd "aideinit" "Initializing AIDE database" "" "false"
    fi
    
    log_success "Integrity tools setup complete"
    mark_module_loaded "integrity_tools"
    return 0
}
