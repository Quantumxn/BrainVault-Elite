#!/bin/bash
# firewall.sh - UFW firewall configuration for BrainVault Elite

install_ufw() {
    log_section "🔥 Installing and Configuring UFW Firewall"
    
    # Check if UFW is already installed
    if command_exists ufw; then
        log_info "UFW is already installed"
    else
        if is_dryrun; then
            add_dryrun_operation "FIREWALL" "Install UFW firewall"
        else
            safe_exec "Installing UFW" apt-get install -y ufw
        fi
    fi
    
    # Configure UFW
    configure_ufw
}

configure_ufw() {
    log_info "Configuring UFW firewall rules..."
    
    if is_dryrun; then
        add_dryrun_operation "FIREWALL" "Set default deny incoming policy"
        add_dryrun_operation "FIREWALL" "Set default allow outgoing policy"
        add_dryrun_operation "FIREWALL" "Allow SSH (port 22)"
        add_dryrun_operation "FIREWALL" "Allow HTTP (port 80)"
        add_dryrun_operation "FIREWALL" "Allow HTTPS (port 443)"
        add_dryrun_operation "FIREWALL" "Enable UFW firewall"
        return 0
    fi
    
    # Set default policies
    safe_exec "Setting default deny incoming" ufw default deny incoming
    safe_exec "Setting default allow outgoing" ufw default allow outgoing
    
    # Allow SSH
    safe_exec "Allowing SSH" ufw allow 22/tcp
    
    # Allow HTTP/HTTPS
    safe_exec "Allowing HTTP" ufw allow 80/tcp
    safe_exec "Allowing HTTPS" ufw allow 443/tcp
    
    # Allow common development ports (conditional)
    if [[ "${ALLOW_DEV_PORTS:-0}" == "1" ]]; then
        log_info "Allowing development ports..."
        safe_exec "Allowing port 3000" ufw allow 3000/tcp  # React/Node
        safe_exec "Allowing port 5000" ufw allow 5000/tcp  # Flask
        safe_exec "Allowing port 8000" ufw allow 8000/tcp  # Django/FastAPI
        safe_exec "Allowing port 8080" ufw allow 8080/tcp  # Alternative HTTP
        safe_exec "Allowing port 8888" ufw allow 8888/tcp  # Jupyter
    fi
    
    # Enable UFW
    safe_exec "Enabling UFW" bash -c "echo 'y' | ufw enable"
    
    # Show status
    log_info "UFW Status:"
    ufw status verbose
    
    log_success "UFW firewall configured successfully"
}

# Rate limiting for SSH
setup_ufw_rate_limiting() {
    log_info "Setting up rate limiting for SSH..."
    
    if is_dryrun; then
        add_dryrun_operation "FIREWALL" "Enable SSH rate limiting"
        return 0
    fi
    
    # Remove existing SSH rule
    ufw delete allow 22/tcp 2>/dev/null || true
    
    # Add rate-limited SSH rule
    safe_exec "Enabling SSH rate limiting" ufw limit 22/tcp
    
    log_success "SSH rate limiting configured"
}

# Advanced firewall rules
setup_advanced_firewall() {
    log_section "🛡️ Applying Advanced Firewall Rules"
    
    if is_dryrun; then
        add_dryrun_operation "FIREWALL" "Block ping requests (optional)"
        add_dryrun_operation "FIREWALL" "Configure connection tracking"
        return 0
    fi
    
    # Optionally block ping
    if [[ "${BLOCK_PING:-0}" == "1" ]]; then
        log_info "Blocking ICMP ping requests..."
        safe_exec "Blocking ping" bash -c "echo 'net.ipv4.icmp_echo_ignore_all = 1' >> /etc/sysctl.conf"
        safe_exec "Applying sysctl" sysctl -p
    fi
    
    log_success "Advanced firewall rules applied"
}

# Export functions
export -f install_ufw
export -f configure_ufw
export -f setup_ufw_rate_limiting
export -f setup_advanced_firewall
