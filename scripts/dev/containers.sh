#!/bin/bash
# containers.sh - Docker and container tools for BrainVault Elite

install_docker() {
    log_section "🐳 Installing Docker"
    
    if command_exists docker; then
        log_info "Docker is already installed: $(docker --version)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "CONTAINERS" "Install Docker Engine"
        add_dryrun_operation "CONTAINERS" "Configure Docker for non-root user"
        return 0
    fi
    
    log_info "Installing Docker dependencies..."
    
    # Install dependencies
    safe_exec "Installing Docker dependencies" apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker GPG key
    log_info "Adding Docker GPG key..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || {
        log_error "Failed to add Docker GPG key"
        return 1
    }
    
    # Add Docker repository
    log_info "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update and install Docker
    safe_exec "Updating package list" apt-get update
    safe_exec "Installing Docker" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Verify installation
    if command_exists docker; then
        log_success "Docker installed: $(docker --version)"
    else
        log_error "Docker installation failed"
        return 1
    fi
    
    # Start and enable Docker
    safe_exec "Starting Docker" systemctl start docker
    safe_exec "Enabling Docker" systemctl enable docker
    
    # Configure Docker
    configure_docker
    
    log_success "Docker installation completed"
}

configure_docker() {
    log_info "Configuring Docker..."
    
    # Add current user to docker group
    local current_user="${SUDO_USER:-$USER}"
    if [[ -n "$current_user" ]] && [[ "$current_user" != "root" ]]; then
        log_info "Adding user $current_user to docker group..."
        usermod -aG docker "$current_user" || log_warn "Failed to add user to docker group"
        log_info "User needs to log out and back in for group changes to take effect"
    fi
    
    # Create Docker daemon configuration
    local docker_daemon_json="/etc/docker/daemon.json"
    
    if [[ ! -f "$docker_daemon_json" ]]; then
        log_info "Creating Docker daemon configuration..."
        cat > "$docker_daemon_json" <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
        
        # Restart Docker to apply configuration
        safe_exec "Restarting Docker" systemctl restart docker
        log_success "Docker daemon configured"
    else
        log_debug "Docker daemon configuration already exists"
    fi
}

# Install Docker Compose (standalone)
install_docker_compose_standalone() {
    log_info "Checking Docker Compose..."
    
    if docker compose version &>/dev/null; then
        log_info "Docker Compose (plugin) is already available"
        return 0
    fi
    
    if command_exists docker-compose; then
        log_info "Docker Compose (standalone) is already installed: $(docker-compose --version)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "CONTAINERS" "Install Docker Compose standalone"
        return 0
    fi
    
    log_info "Installing Docker Compose standalone..."
    
    local compose_version="v2.24.0"
    local compose_url="https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)"
    
    curl -L "$compose_url" -o /usr/local/bin/docker-compose || {
        log_error "Failed to download Docker Compose"
        return 1
    }
    
    chmod +x /usr/local/bin/docker-compose
    
    if command_exists docker-compose; then
        log_success "Docker Compose installed: $(docker-compose --version)"
    else
        log_error "Docker Compose installation failed"
        return 1
    fi
}

# Test Docker installation
test_docker() {
    log_info "Testing Docker installation..."
    
    if is_dryrun; then
        add_dryrun_operation "CONTAINERS" "Test Docker with hello-world container"
        return 0
    fi
    
    if ! command_exists docker; then
        log_error "Docker is not installed"
        return 1
    fi
    
    log_info "Running Docker hello-world test..."
    docker run --rm hello-world &>/dev/null || {
        log_error "Docker test failed"
        return 1
    }
    
    log_success "Docker is working correctly"
}

# Install Podman (alternative to Docker)
install_podman() {
    log_info "Installing Podman..."
    
    if command_exists podman; then
        log_info "Podman is already installed: $(podman --version)"
        return 0
    fi
    
    if is_dryrun; then
        add_dryrun_operation "CONTAINERS" "Install Podman"
        return 0
    fi
    
    safe_exec "Installing Podman" apt-get install -y podman || {
        log_error "Failed to install Podman"
        return 1
    }
    
    if command_exists podman; then
        log_success "Podman installed: $(podman --version)"
    else
        log_error "Podman installation failed"
        return 1
    fi
}

# Install container scanning tools
install_container_security_tools() {
    log_section "🔍 Installing Container Security Tools"
    
    if is_dryrun; then
        add_dryrun_operation "CONTAINERS" "Install Trivy vulnerability scanner"
        return 0
    fi
    
    # Install Trivy
    install_trivy
}

install_trivy() {
    log_info "Installing Trivy..."
    
    if command_exists trivy; then
        log_info "Trivy is already installed: $(trivy --version)"
        return 0
    fi
    
    # Add Trivy repository
    log_info "Adding Trivy repository..."
    
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
        tee /etc/apt/sources.list.d/trivy.list
    
    safe_exec "Updating package list" apt-get update
    safe_exec "Installing Trivy" apt-get install -y trivy || {
        log_error "Failed to install Trivy"
        return 1
    }
    
    if command_exists trivy; then
        log_success "Trivy installed: $(trivy --version 2>&1 | head -1)"
    else
        log_error "Trivy installation failed"
        return 1
    fi
}

# Clean up Docker
cleanup_docker() {
    log_info "Cleaning up Docker..."
    
    if is_dryrun; then
        add_dryrun_operation "CONTAINERS" "Clean up Docker images and containers"
        return 0
    fi
    
    if ! command_exists docker; then
        log_warn "Docker is not installed"
        return 1
    fi
    
    # Remove stopped containers
    docker container prune -f || true
    
    # Remove unused images
    docker image prune -a -f || true
    
    # Remove unused volumes
    docker volume prune -f || true
    
    # Remove unused networks
    docker network prune -f || true
    
    log_success "Docker cleanup completed"
}

# Show Docker info
show_docker_info() {
    log_section "🐳 Docker Information"
    
    if ! command_exists docker; then
        log_warn "Docker is not installed"
        return 1
    fi
    
    echo ""
    echo "Docker Version: $(docker --version)"
    
    if docker compose version &>/dev/null; then
        echo "Docker Compose: $(docker compose version)"
    elif command_exists docker-compose; then
        echo "Docker Compose: $(docker-compose --version)"
    fi
    
    echo ""
    echo "Docker Status:"
    systemctl status docker --no-pager -l 2>/dev/null | head -5 || echo "Unable to get status"
    
    echo ""
    echo "Disk Usage:"
    docker system df 2>/dev/null || echo "Unable to get disk usage"
    
    echo ""
}

# Export functions
export -f install_docker
export -f configure_docker
export -f install_docker_compose_standalone
export -f test_docker
export -f install_podman
export -f install_container_security_tools
export -f install_trivy
export -f cleanup_docker
export -f show_docker_info
