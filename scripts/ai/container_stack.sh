#!/bin/bash
# ================================================================
# BrainVault Elite - Container Stack Installation
# Docker, Docker Compose, and Podman
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Docker Installation =============

install_docker() {
    log_section "Installing Docker"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Install Docker and Docker Compose"
        add_to_summary "Container Stack" "Configure Docker service"
        return 0
    fi
    
    # Check if Docker is already installed
    if check_command docker; then
        log_info "Docker already installed: $(docker --version)"
        return 0
    fi
    
    log_info "Installing Docker from official repository..."
    
    # Install dependencies
    install_pkg ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    run_cmd "mkdir -p /etc/apt/keyrings" "Create keyrings directory"
    run_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg" \
        "Download Docker GPG key"
    
    # Set up the repository
    log_info "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    run_cmd "apt-get update" "Update package lists for Docker"
    
    # Install Docker Engine
    log_info "Installing Docker Engine..."
    install_pkg docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    run_cmd "systemctl enable docker" "Enable Docker service"
    run_cmd "systemctl start docker" "Start Docker service"
    
    # Verify installation
    if docker --version &>/dev/null; then
        log_success "Docker installed successfully: $(docker --version)"
    else
        log_error "Docker installation verification failed"
        return 1
    fi
}

# ============= Docker User Configuration =============

configure_docker_user() {
    log_section "Configuring Docker User Permissions"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Add user to docker group"
        return 0
    fi
    
    local target_user="${SUDO_USER:-$USER}"
    
    if [[ "$target_user" == "root" ]]; then
        log_info "Running as root, no user configuration needed"
        return 0
    fi
    
    log_info "Adding user $target_user to docker group..."
    
    if usermod -aG docker "$target_user" >>"$LOGFILE" 2>&1; then
        log_success "User $target_user added to docker group"
        log_warn "User needs to log out and back in for group changes to take effect"
        log_info "Or run: newgrp docker"
    else
        log_warn "Failed to add user to docker group"
    fi
}

# ============= Docker Configuration =============

configure_docker() {
    log_section "Configuring Docker Daemon"
    
    local daemon_config="/etc/docker/daemon.json"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Configure Docker daemon settings"
        return 0
    fi
    
    log_info "Creating Docker daemon configuration: $daemon_config"
    
    # Check if config already exists
    if [[ -f "$daemon_config" ]]; then
        log_warn "Docker daemon config already exists, backing up..."
        cp "$daemon_config" "${daemon_config}.backup.$(date +%s)"
    fi
    
    cat > "$daemon_config" <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ],
  "dns": ["8.8.8.8", "8.8.4.4"],
  "metrics-addr": "127.0.0.1:9323",
  "experimental": false,
  "features": {
    "buildkit": true
  }
}
EOF
    
    log_info "Reloading Docker daemon..."
    run_cmd "systemctl daemon-reload" "Reload systemd"
    run_cmd "systemctl restart docker" "Restart Docker" false
    
    log_success "Docker daemon configured"
}

# ============= Podman Installation =============

install_podman() {
    log_section "Installing Podman"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Install Podman (Docker alternative)"
        return 0
    fi
    
    # Check if Podman is already installed
    if check_command podman; then
        log_info "Podman already installed: $(podman --version)"
        return 0
    fi
    
    log_info "Installing Podman..."
    install_pkg podman podman-compose || log_warn "Podman installation failed"
    
    if check_command podman; then
        log_success "Podman installed successfully: $(podman --version)"
    else
        log_warn "Podman installation verification failed"
    fi
}

# ============= Container Tools =============

install_container_tools() {
    log_section "Installing Container Development Tools"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Install container development tools (ctop, dive, etc.)"
        return 0
    fi
    
    # Install ctop (container monitoring)
    if ! check_command ctop; then
        log_info "Installing ctop..."
        run_cmd "wget -qO /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 && chmod +x /usr/local/bin/ctop" \
            "Install ctop" false
    fi
    
    # Install dive (Docker image analysis)
    if ! check_command dive; then
        log_info "Installing dive..."
        run_cmd "wget -qO /tmp/dive.deb https://github.com/wagoodman/dive/releases/download/v0.11.0/dive_0.11.0_linux_amd64.deb && dpkg -i /tmp/dive.deb && rm /tmp/dive.deb" \
            "Install dive" false
    fi
    
    log_success "Container tools installed"
}

# ============= Docker Compose Standalone =============

install_docker_compose_standalone() {
    log_section "Installing Docker Compose Standalone"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Install Docker Compose standalone binary"
        return 0
    fi
    
    # Check if docker compose plugin is available
    if docker compose version &>/dev/null; then
        log_info "Docker Compose plugin already available"
        return 0
    fi
    
    log_info "Installing Docker Compose standalone..."
    
    local compose_version="v2.23.3"
    local compose_url="https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-$(uname -m)"
    
    run_cmd "curl -SL $compose_url -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose" \
        "Install Docker Compose" false
    
    if command -v docker-compose &>/dev/null; then
        log_success "Docker Compose installed: $(docker-compose --version)"
    else
        log_warn "Docker Compose installation failed"
    fi
}

# ============= Container Stack Test =============

test_container_stack() {
    log_section "Testing Container Stack"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Container Stack" "Run Docker hello-world test"
        return 0
    fi
    
    log_info "Running Docker hello-world test..."
    
    if docker run --rm hello-world >>"$LOGFILE" 2>&1; then
        log_success "Docker is working correctly"
    else
        log_warn "Docker test failed (this may be expected in some environments)"
    fi
}

# ============= Container Stack Summary =============

show_container_info() {
    log_section "Container Stack Information"
    
    if check_command docker; then
        log_info "Docker: $(docker --version)"
        
        if systemctl is-active --quiet docker; then
            log_success "Docker service is running"
        else
            log_warn "Docker service is not running"
        fi
    else
        log_info "Docker: Not installed"
    fi
    
    if docker compose version &>/dev/null; then
        log_info "Docker Compose: $(docker compose version --short)"
    elif command -v docker-compose &>/dev/null; then
        log_info "Docker Compose: $(docker-compose --version | cut -d' ' -f3)"
    else
        log_info "Docker Compose: Not installed"
    fi
    
    if check_command podman; then
        log_info "Podman: $(podman --version | cut -d' ' -f3)"
    else
        log_info "Podman: Not installed"
    fi
}

# Export functions
export -f install_docker configure_docker_user configure_docker
export -f install_podman install_container_tools install_docker_compose_standalone
export -f test_container_stack show_container_info
