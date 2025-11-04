#!/bin/bash
# telemetry_block.sh - Block telemetry and tracking endpoints for BrainVault Elite

block_telemetry() {
    log_section "🚫 Blocking Telemetry and Tracking Endpoints"
    
    if is_dryrun; then
        add_dryrun_operation "PRIVACY" "Block telemetry endpoints in /etc/hosts"
        add_dryrun_operation "PRIVACY" "Configure DNS-level blocking"
        return 0
    fi
    
    log_info "Adding telemetry blocking rules..."
    
    # Backup hosts file
    if [[ ! -f /etc/hosts.backup ]]; then
        safe_exec "Backing up /etc/hosts" cp /etc/hosts /etc/hosts.backup
    fi
    
    # Add telemetry blocking entries
    add_telemetry_hosts
    
    # Apply DNS-level blocking if using systemd-resolved
    configure_dns_blocking
    
    log_success "Telemetry blocking configured"
}

add_telemetry_hosts() {
    log_info "Adding telemetry domains to /etc/hosts..."
    
    local hosts_file="/etc/hosts"
    local telemetry_marker="# BrainVault Elite - Telemetry Blocking"
    
    # Check if already added
    if grep -q "$telemetry_marker" "$hosts_file"; then
        log_info "Telemetry blocking entries already present"
        return 0
    fi
    
    # Telemetry and tracking domains
    local telemetry_domains=(
        # Microsoft
        "telemetry.microsoft.com"
        "vortex.data.microsoft.com"
        "settings-win.data.microsoft.com"
        "watson.telemetry.microsoft.com"
        "oca.telemetry.microsoft.com"
        
        # Ubuntu/Canonical
        "daisy.ubuntu.com"
        "metrics.ubuntu.com"
        "popcon.ubuntu.com"
        
        # Google
        "www.google-analytics.com"
        "ssl.google-analytics.com"
        "analytics.google.com"
        
        # Other tracking
        "ads.google.com"
        "doubleclick.net"
        "googleadservices.com"
    )
    
    # Add marker
    echo "" >> "$hosts_file"
    echo "$telemetry_marker" >> "$hosts_file"
    echo "# Added on: $(date)" >> "$hosts_file"
    
    # Add blocking entries
    for domain in "${telemetry_domains[@]}"; do
        echo "0.0.0.0 $domain" >> "$hosts_file"
        log_debug "Blocked: $domain"
    done
    
    log_success "Added ${#telemetry_domains[@]} telemetry domains to /etc/hosts"
}

configure_dns_blocking() {
    log_info "Configuring DNS-level blocking..."
    
    # Check if systemd-resolved is used
    if command_exists systemd-resolve || command_exists resolvectl; then
        log_info "Detected systemd-resolved"
        
        # Create custom resolved.conf
        local resolved_conf="/etc/systemd/resolved.conf.d/brainvault.conf"
        mkdir -p "$(dirname "$resolved_conf")"
        
        cat > "$resolved_conf" <<'EOF'
[Resolve]
DNS=1.1.1.1 9.9.9.9
FallbackDNS=1.0.0.1 8.8.8.8
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
        
        safe_exec "Restarting systemd-resolved" systemctl restart systemd-resolved
        log_success "DNS blocking configured with privacy-focused resolvers"
    else
        log_debug "systemd-resolved not detected, skipping DNS configuration"
    fi
}

# Block Ubuntu motd ads
block_ubuntu_motd_ads() {
    log_info "Disabling Ubuntu MOTD advertisements..."
    
    if is_dryrun; then
        add_dryrun_operation "PRIVACY" "Disable Ubuntu MOTD ads"
        return 0
    fi
    
    # Disable motd-news
    if [[ -f /etc/default/motd-news ]]; then
        safe_exec "Disabling MOTD news" sed -i 's/ENABLED=1/ENABLED=0/' /etc/default/motd-news
    fi
    
    # Remove executable permissions from ad scripts
    local motd_scripts=(
        "/etc/update-motd.d/50-motd-news"
        "/etc/update-motd.d/10-help-text"
        "/etc/update-motd.d/80-livepatch"
        "/etc/update-motd.d/95-hwe-eol"
    )
    
    for script in "${motd_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod -x "$script" 2>/dev/null || true
            log_debug "Disabled: $script"
        fi
    done
    
    log_success "Ubuntu MOTD advertisements disabled"
}

# Disable Ubuntu Pro prompts
disable_ubuntu_pro_prompts() {
    log_info "Disabling Ubuntu Pro prompts..."
    
    if is_dryrun; then
        add_dryrun_operation "PRIVACY" "Disable Ubuntu Pro prompts"
        return 0
    fi
    
    # Create pro config
    local pro_config="/etc/ubuntu-advantage/uaclient.conf"
    if [[ -d /etc/ubuntu-advantage ]]; then
        mkdir -p /etc/ubuntu-advantage
        cat > "$pro_config" <<'EOF'
contract_url: https://contracts.canonical.com
security_url: https://ubuntu.com/security
features:
  disable_auto_attach: true
EOF
        log_success "Ubuntu Pro prompts disabled"
    else
        log_debug "Ubuntu Advantage not found"
    fi
    
    # Disable apt-news
    if [[ -f /etc/apt/apt.conf.d/20apt-esm-hook.conf ]]; then
        rm -f /etc/apt/apt.conf.d/20apt-esm-hook.conf
        log_debug "Removed apt-esm-hook"
    fi
}

# Block telemetry via iptables (additional layer)
block_telemetry_iptables() {
    log_info "Adding iptables rules for telemetry blocking..."
    
    if is_dryrun; then
        add_dryrun_operation "PRIVACY" "Add iptables telemetry blocking rules"
        return 0
    fi
    
    if ! command_exists iptables; then
        log_warn "iptables not available, skipping"
        return 1
    fi
    
    # Block known telemetry IPs (example)
    # Note: These IPs can change, /etc/hosts is more reliable
    local telemetry_ips=(
        "13.107.4.50"   # Microsoft telemetry
        "65.52.108.33"  # Microsoft telemetry
    )
    
    for ip in "${telemetry_ips[@]}"; do
        iptables -A OUTPUT -d "$ip" -j DROP 2>/dev/null || true
        log_debug "Blocked IP: $ip"
    done
    
    log_success "iptables telemetry blocking configured"
}

# Export functions
export -f block_telemetry
export -f add_telemetry_hosts
export -f configure_dns_blocking
export -f block_ubuntu_motd_ads
export -f disable_ubuntu_pro_prompts
export -f block_telemetry_iptables
