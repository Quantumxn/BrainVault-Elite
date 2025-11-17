#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Container Stack Module
# ================================================================

install_container_stack() {
    local desc="Installing container stack (Docker, Podman)"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Development" "install_container_stack" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    # Install Docker
    if ! command_exists docker; then
        install_pkg docker.io docker-compose || {
            log_error "Failed to install Docker"
            return 1
        }
        
        # Start and enable Docker
        run_cmd "systemctl enable docker" "Enabling Docker service"
        run_cmd "systemctl start docker" "Starting Docker service"
        
        # Add current user to docker group (if not root)
        if [ "$EUID" -ne 0 ] && [ -n "${SUDO_USER:-}" ]; then
            run_cmd "usermod -aG docker $SUDO_USER" "Adding user to docker group"
        fi
    else
        log_info "Docker already installed"
    fi
    
    # Install Podman (optional, lighter alternative)
    if ! command_exists podman; then
        install_pkg podman || {
            log_warn "Failed to install Podman, continuing..."
        }
    fi
    
    log_success "Container stack installation complete"
    mark_module_loaded "container_stack"
    return 0
}
