#!/bin/bash
# Kernel hardening configuration script

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logging.sh"
source "${SCRIPT_DIR}/../utils/error_handling.sh"
source "${SCRIPT_DIR}/../utils/dryrun.sh"

install_kernel_hardening() {
    log_section "Installing Kernel Hardening Tools"
    
    # Check dependencies
    local packages=("sysctl" "grub-common")
    local missing_packages=()
    
    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "Installing kernel hardening dependencies..."
        for pkg in "${missing_packages[@]}"; do
            dryrun_install "$pkg" "Kernel hardening dependency: $pkg"
        done
        if [[ "$DRY_RUN" != "1" ]]; then
            apt-get update -qq
            apt-get install -y "${missing_packages[@]}"
        fi
    else
        log_success "Kernel hardening dependencies already installed"
    fi
    
    log_success "Kernel hardening tools installation completed"
}

setup_kernel_hardening() {
    log_section "Configuring Kernel Hardening"
    
    # Check if running in secure mode
    local secure_mode="${SECURE_MODE:-0}"
    
    if [[ "$secure_mode" != "1" ]]; then
        log_warn "Kernel hardening requires --secure flag. Skipping..."
        return 0
    fi
    
    log_step "Configuring sysctl parameters"
    local sysctl_conf="/etc/sysctl.d/99-brainvault-hardening.conf"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would create $sysctl_conf"
    else
        cat > "$sysctl_conf" << 'EOF'
# BrainVault Elite Kernel Hardening
# Network security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1

# IPv6 security
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

# Kernel security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 1

# Memory protection
vm.mmap_rnd_bits = 32
vm.mmap_rnd_compat_bits = 16
vm.unprivileged_userfaultfd = 0
EOF
        log_success "Sysctl configuration created"
        
        # Apply sysctl settings
        sysctl -p "$sysctl_conf"
        log_success "Sysctl settings applied"
    fi
    
    log_step "Configuring kernel parameters via GRUB"
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "[DRY-RUN] Would update GRUB with kernel parameters"
    else
        local grub_cmdline="/etc/default/grub"
        if file_exists "$grub_cmdline"; then
            # Backup original
            cp "$grub_cmdline" "${grub_cmdline}.bak"
            
            # Add kernel parameters
            if ! grep -q "slub_debug" "$grub_cmdline"; then
                sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&slub_debug=P page_poison=1 /' "$grub_cmdline"
                update-grub
                log_success "GRUB kernel parameters updated"
            fi
        fi
    fi
    
    log_success "Kernel hardening configuration completed"
}

check_kernel_hardening() {
    log_info "Kernel Hardening Status:"
    if [[ "$DRY_RUN" != "1" ]]; then
        log_step "Checking sysctl parameters"
        sysctl -a 2>/dev/null | grep -E "(kernel.yama|kernel.kptr|net.ipv4.tcp_syncookies)" || true
    else
        log_warn "[DRY-RUN] Would check kernel hardening status"
    fi
}
