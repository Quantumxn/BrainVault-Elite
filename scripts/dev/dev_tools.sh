#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Development Tools Module
# ================================================================

install_dev_tools() {
    local desc="Installing development tools"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Development" "install_dev_tools" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    local dev_packages=(
        "git"
        "build-essential"
        "python3"
        "python3-pip"
        "python3-venv"
        "curl"
        "wget"
        "vim"
        "nano"
        "tree"
        "htop"
        "iotop"
        "nethogs"
        "pv"
        "rsync"
        "jq"
        "unzip"
        "zip"
    )
    
    install_pkg "${dev_packages[@]}" || {
        log_error "Failed to install development tools"
        return 1
    }
    
    log_success "Development tools installation complete"
    mark_module_loaded "dev_tools"
    return 0
}
