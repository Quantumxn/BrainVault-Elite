#!/bin/bash
# ================================================================
# BrainVault Elite - Firewall Configuration
# UFW (Uncomplicated Firewall) setup and hardening
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Firewall Setup =============

setup_firewall() {
    log_section "Configuring UFW Firewall"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Configure UFW firewall (deny incoming, allow outgoing)"
        add_to_summary "Security" "Enable UFW firewall"
        return 0
    fi
    
    # Check if UFW is installed
    if ! check_command ufw; then
        log_error "UFW not installed. Installing..."
        install_pkg ufw || error_exit "Failed to install UFW"
    fi
    
    log_info "Configuring default firewall policies..."
    
    # Set default policies
    run_cmd "ufw --force default deny incoming" "Set default deny incoming"
    run_cmd "ufw --force default allow outgoing" "Set default allow outgoing"
    run_cmd "ufw --force default deny routed" "Set default deny routed"
    
    # Allow SSH (important to not lock yourself out!)
    log_warn "Allowing SSH (port 22) to prevent lockout"
    run_cmd "ufw --force allow 22/tcp comment 'SSH'" "Allow SSH"
    
    # Enable UFW
    log_info "Enabling UFW firewall..."
    run_cmd "yes | ufw enable" "Enable UFW firewall"
    
    # Show status
    log_info "Firewall status:"
    run_cmd_silent "ufw status verbose"
    
    log_success "UFW firewall configured successfully"
}

# ============= Custom Rules =============

add_firewall_rule() {
    local port="$1"
    local proto="${2:-tcp}"
    local comment="${3:-Custom rule}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Add firewall rule: allow $port/$proto ($comment)"
        return 0
    fi
    
    log_info "Adding firewall rule: $port/$proto - $comment"
    run_cmd "ufw allow $port/$proto comment '$comment'" "Add rule for $port/$proto" false
}

# ============= Common Service Rules =============

allow_http_https() {
    log_info "Allowing HTTP and HTTPS traffic..."
    add_firewall_rule 80 tcp "HTTP"
    add_firewall_rule 443 tcp "HTTPS"
}

allow_dns() {
    log_info "Allowing DNS traffic..."
    add_firewall_rule 53 tcp "DNS"
    add_firewall_rule 53 udp "DNS"
}

# ============= Rate Limiting =============

setup_rate_limiting() {
    log_section "Setting Up Rate Limiting"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Enable rate limiting on SSH (port 22)"
        return 0
    fi
    
    log_info "Enabling rate limiting for SSH..."
    run_cmd "ufw limit 22/tcp comment 'Rate limit SSH'" "Enable SSH rate limiting" false
    
    log_success "Rate limiting configured"
}

# ============= Firewall Status =============

show_firewall_status() {
    log_section "Firewall Status"
    
    if ! check_command ufw; then
        log_warn "UFW not installed"
        return 1
    fi
    
    log_info "Current firewall rules:"
    ufw status numbered | while read -r line; do
        log_info "  $line"
    done
}

# Export functions
export -f setup_firewall add_firewall_rule allow_http_https allow_dns
export -f setup_rate_limiting show_firewall_status
