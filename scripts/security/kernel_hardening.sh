#!/bin/bash
# ================================================================
# BrainVault Elite - Kernel Hardening
# Sysctl parameters for enhanced security
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Kernel Hardening =============

setup_kernel_hardening() {
    log_section "Applying Kernel Hardening Parameters"
    
    local sysctl_file="/etc/sysctl.d/99-brainvault-hardening.conf"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Configure kernel hardening parameters in $sysctl_file"
        add_to_summary "Security" "Apply sysctl settings"
        return 0
    fi
    
    log_info "Creating kernel hardening configuration: $sysctl_file"
    
    cat > "$sysctl_file" <<'EOF'
# ================================================================
# BrainVault Elite - Kernel Hardening Parameters
# ================================================================

# ============= Kernel Security =============

# Enable Address Space Layout Randomization (ASLR)
kernel.randomize_va_space = 2

# Restrict kernel pointer leaks
kernel.kptr_restrict = 2

# Restrict access to kernel logs
kernel.dmesg_restrict = 1

# Restrict kernel module loading to CAP_SYS_MODULE
kernel.modules_disabled = 0

# Restrict performance events
kernel.perf_event_paranoid = 3

# Restrict BPF JIT compiler
kernel.unprivileged_bpf_disabled = 1

# Enable ExecShield
kernel.exec-shield = 1

# Yama ptrace scope - restrict ptrace to parent processes
kernel.yama.ptrace_scope = 2

# ============= Network Security =============

# IP Forwarding (disable if not a router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Reverse Path Filtering (anti-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Don't send ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Ignore ICMP echo requests (ping)
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP error responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Enable TCP SYN cookies (SYN flood protection)
net.ipv4.tcp_syncookies = 1

# Disable IPv6 Router Advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# Increase TCP SYN backlog
net.ipv4.tcp_max_syn_backlog = 2048

# Enable TCP timestamps
net.ipv4.tcp_timestamps = 1

# Enable selective acknowledgments
net.ipv4.tcp_sack = 1

# ============= File System Security =============

# Restrict core dumps
fs.suid_dumpable = 0

# Increase inotify watches (useful for development)
fs.inotify.max_user_watches = 524288

# Increase file descriptor limits
fs.file-max = 2097152

# Protected hardlinks
fs.protected_hardlinks = 1

# Protected symlinks
fs.protected_symlinks = 1

# Protected fifos
fs.protected_fifos = 2

# Protected regular files
fs.protected_regular = 2

# ============= Memory Management =============

# Restrict vm.overcommit_memory
vm.overcommit_memory = 1

# Increase virtual memory limits
vm.max_map_count = 262144

# Adjust swappiness (lower = less swap usage)
vm.swappiness = 10

# Control how aggressive the kernel will swap memory pages
vm.vfs_cache_pressure = 50
EOF
    
    log_success "Kernel hardening configuration created"
    
    # Apply the settings
    log_info "Applying sysctl parameters..."
    if sysctl --system >>"$LOGFILE" 2>&1; then
        log_success "Kernel hardening parameters applied successfully"
    else
        log_error "Some sysctl parameters failed to apply (see log for details)"
        log_warn "This may be normal on some systems or in containers"
        return 1
    fi
    
    # Verify some critical settings
    log_info "Verifying critical settings..."
    local critical_params=(
        "kernel.randomize_va_space"
        "kernel.kptr_restrict"
        "net.ipv4.conf.all.rp_filter"
        "net.ipv4.tcp_syncookies"
    )
    
    for param in "${critical_params[@]}"; do
        local value
        value=$(sysctl -n "$param" 2>/dev/null || echo "N/A")
        log_info "  $param = $value"
    done
    
    log_success "Kernel hardening complete"
}

# ============= Security Limits =============

setup_security_limits() {
    log_section "Configuring Security Limits"
    
    local limits_file="/etc/security/limits.d/99-brainvault.conf"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Configure security limits in $limits_file"
        return 0
    fi
    
    log_info "Creating security limits configuration: $limits_file"
    
    cat > "$limits_file" <<'EOF'
# BrainVault Elite - Security Limits

# Limit core dumps
* hard core 0

# Increase file descriptor limits
* soft nofile 65536
* hard nofile 65536

# Increase process limits
* soft nproc 32768
* hard nproc 32768
EOF
    
    log_success "Security limits configured"
}

# ============= Disable Unused Protocols =============

disable_unused_protocols() {
    log_section "Disabling Unused Network Protocols"
    
    local modprobe_file="/etc/modprobe.d/brainvault-disabled-protocols.conf"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Security" "Disable unused network protocols (DCCP, SCTP, RDS, TIPC)"
        return 0
    fi
    
    log_info "Creating protocol blacklist: $modprobe_file"
    
    cat > "$modprobe_file" <<'EOF'
# BrainVault Elite - Disabled Network Protocols

# Disable DCCP (Datagram Congestion Control Protocol)
install dccp /bin/true
blacklist dccp

# Disable SCTP (Stream Control Transmission Protocol)
install sctp /bin/true
blacklist sctp

# Disable RDS (Reliable Datagram Sockets)
install rds /bin/true
blacklist rds

# Disable TIPC (Transparent Inter-Process Communication)
install tipc /bin/true
blacklist tipc

# Disable Bluetooth (if not needed)
# install bluetooth /bin/true
# blacklist bluetooth
EOF
    
    log_success "Unused protocols disabled"
    log_info "These changes will take effect after reboot"
}

# Export functions
export -f setup_kernel_hardening setup_security_limits disable_unused_protocols
