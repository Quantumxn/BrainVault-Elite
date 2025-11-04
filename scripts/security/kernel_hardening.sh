#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Kernel Hardening Module
# ================================================================

setup_kernel_hardening() {
    local desc="Applying kernel hardening parameters"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        track_dry_run_op "Security" "setup_kernel_hardening" "$desc"
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    local sysctl_file="/etc/sysctl.d/99-brainvault-hardening.conf"
    
    # Backup existing sysctl configuration if it exists
    if [ -f "$sysctl_file" ]; then
        run_cmd "cp $sysctl_file ${sysctl_file}.backup.$(date +%F_%H-%M-%S)" \
            "Backing up existing sysctl configuration"
    fi
    
    # Create kernel hardening configuration
    cat > "$sysctl_file" <<'EOF'
# BrainVault Elite Kernel Hardening Parameters

# Address Space Layout Randomization (ASLR)
kernel.randomize_va_space=2

# IP Spoofing protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Ignore ICMP echo broadcasts
net.ipv4.icmp_echo_ignore_broadcasts=1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses=1

# Restrict kernel pointer exposure
kernel.kptr_restrict=2

# Disable IP forwarding
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0

# SYN flood protection
net.ipv4.tcp_syncookies=1

# Disable source routing
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# Disable send redirects
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Log martian packets
net.ipv4.conf.all.log_martians=1

# Ignore ping broadcasts
net.ipv4.icmp_echo_ignore_broadcasts=1

# Ignore ping requests
net.ipv4.icmp_echo_ignore_all=0

# Protect against time-wait assassination
net.ipv4.tcp_rfc1337=1

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies=1

# Disable IPv6 if not needed (comment out if you use IPv6)
# net.ipv6.conf.all.disable_ipv6=1
EOF
    
    log_success "Created kernel hardening configuration: $sysctl_file"
    
    # Apply sysctl settings
    run_cmd "sysctl --system" "Applying kernel hardening parameters"
    
    log_success "Kernel hardening configuration complete"
    mark_module_loaded "kernel_hardening"
    return 0
}
