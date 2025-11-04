#!/bin/bash
# Docker and container tools installation script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_containers() {
    log_section "Installing Container Tools"
    
    # Check if Docker is already installed
    if command_exists docker; then
        log_success "Docker is already installed"
    else
        log_info "Installing Docker..."
        
        if [[ "$DRY_RUN" == "1" ]]; then
            log_warn "[DRY-RUN] Would install Docker and Docker Compose"
        else
            # Install prerequisites
            apt-get update -qq
            apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker's official GPG key
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            
            # Set up Docker repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker Engine
            apt-get update -qq
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            log_success "Docker installed"
        fi
    fi
    
    # Verify installation
    if [[ "$DRY_RUN" != "1" ]] && ! command_exists docker; then
        log_error "Docker installation failed"
        return 1
    fi
    
    log_success "Container tools installation completed"
}

setup_containers() {
    log_section "Configuring Container Tools"
    
    # Check if Docker is installed
    if ! command_exists docker; then
        log_error "Docker is not installed. Run install_containers first."
        return 1
    fi
    
    log_step "Starting Docker service"
    dryrun_service "enable" "docker"
    dryrun_service "start" "docker"
    
    log_step "Adding current user to docker group (if not root)"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would add user to docker group"
    else
        if [[ $EUID -ne 0 ]]; then
            log_warn "Cannot add user to docker group (not running as root)"
        else
            local current_user="${SUDO_USER:-${USER}}"
            if [[ -n "$current_user" ]] && [[ "$current_user" != "root" ]]; then
                usermod -aG docker "$current_user"
                log_success "User $current_user added to docker group"
                log_info "User may need to log out and back in for changes to take effect"
            fi
        fi
    fi
    
    log_step "Testing Docker installation"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would test Docker with 'docker run hello-world'"
    else
        if docker run --rm hello-world >/dev/null 2>&1; then
            log_success "Docker test passed"
        else
            log_warn "Docker test failed (may need service restart)"
        fi
    fi
    
    log_success "Container tools configuration completed"
}

check_containers_status() {
    log_info "Container Tools Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        if command_exists docker; then
            local docker_version=$(docker --version)
            log_success "Docker: $docker_version"
            
            if service_running docker; then
                log_success "Docker service: running"
            else
                log_warn "Docker service: not running"
            fi
            
            if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
                log_success "Docker Compose: available"
            else
                log_warn "Docker Compose: not available"
            fi
        else
            log_warn "Docker not installed"
        fi
    else
        log_warn "[DRY-RUN] Would check container tools status"
    fi
}
