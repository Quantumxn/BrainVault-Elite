#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Development/AI Stack Module Main
# ================================================================

# Source individual dev modules
source_dev_modules() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Source all dev modules
    for module in "$script_dir"/*.sh; do
        if [ -f "$module" ] && [ "$(basename "$module")" != "dev_main.sh" ]; then
            log_debug "Loading dev module: $(basename "$module")"
            source "$module" || {
                log_error "Failed to load dev module: $module"
                return 1
            }
        fi
    done
}

# Main dev/AI stack installation function
install_dev_stack() {
    if [ "${SKIP_AI:-false}" = "true" ]; then
        log_warn "AI/Dev stack installation skipped per user request"
        return 0
    fi
    
    log_info "🤖 Installing AI / development stack..."
    
    # Source all dev modules
    source_dev_modules || {
        log_error "Failed to load dev modules"
        return 1
    }
    
    # Install development tools
    install_dev_tools || {
        log_error "Failed to install development tools"
        return 1
    }
    
    # Install container stack
    install_container_stack || {
        log_warn "Container stack installation had issues"
    }
    
    # Install Python AI stack
    install_python_stack || {
        log_warn "Python stack installation had issues"
    }
    
    log_success "AI/Dev stack installation complete"
    return 0
}
