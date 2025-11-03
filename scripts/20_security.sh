#!/usr/bin/env bash

install_security_packages() {
    log_info "Installing security baseline packages"
    install_pkg ufw fail2ban apparmor apparmor-utils apparmor-profiles-extra lynis chkrootkit rkhunter aide-common auditd needrestart debsecan
    log_success "Security baseline packages installed"
}

setup_firewall() {
    log_info "Configuring UFW firewall"

    run_cmd "ufw --force reset" "Resetting UFW configuration" true || log_warn "Unable to reset existing UFW rules; continuing."
    run_cmd "ufw default deny incoming" "Setting UFW default deny incoming"
    run_cmd "ufw default allow outgoing" "Setting UFW default allow outgoing"
    run_cmd "ufw --force enable" "Enabling UFW firewall"
}

setup_fail2ban() {
    log_info "Configuring Fail2ban"

    run_cmd "systemctl enable fail2ban" "Enabling Fail2ban service"
    run_cmd "systemctl restart fail2ban" "Restarting Fail2ban service"
}

setup_apparmor() {
    log_info "Ensuring AppArmor enforcement"

    run_cmd "systemctl enable apparmor" "Enabling AppArmor service"
    run_cmd "systemctl restart apparmor" "Restarting AppArmor service"
}

setup_telemetry_block() {
    log_info "Deploying telemetry egress blocking rules"

    if ! command -v iptables >/dev/null 2>&1; then
        log_warn "iptables not available; attempting to install prerequisites."
        install_pkg iptables nftables
        if ! command -v iptables >/dev/null 2>&1; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_warn "iptables still unavailable during dry-run; continuing without telemetry rule enforcement."
                return 0
            fi
            log_error "iptables not available after installation attempt; cannot configure telemetry blocking."
            return 1
        fi
    fi

    run_cmd "iptables -C OUTPUT -p tcp -m multiport --dports 80,443 -m string --string 'telemetry' --algo bm -j DROP 2>/dev/null || iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m string --string 'telemetry' --algo bm -j DROP" \
        "Blocking outbound telemetry patterns"
}

setup_kernel_hardening() {
    log_info "Applying kernel hardening parameters"

    local sysctl_file
    sysctl_file="/etc/sysctl.d/99-brainvault-hardening.conf"

    run_cmd "cat <<'EOF' > ${sysctl_file}
kernel.randomize_va_space=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
kernel.kptr_restrict=2
kernel.yama.ptrace_scope=2
kernel.dmesg_restrict=1
EOF" "Writing kernel hardening configuration to ${sysctl_file}"

    run_cmd "sysctl --system" "Reloading sysctl configuration"
}

setup_integrity_tools() {
    log_info "Initializing integrity and audit toolchain"

    run_cmd "rkhunter --update" "Updating rkhunter signatures" true || log_warn "rkhunter signature update failed"
    run_cmd "lynis audit system" "Running Lynis baseline audit" true || log_warn "Lynis audit encountered issues"
}
