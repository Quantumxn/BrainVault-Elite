#!/bin/bash
# security_main.sh - Main security orchestrator for BrainVault Elite

setup_security_stack() {
    log_section "🔐 SECURITY STACK INSTALLATION"
    
    if [[ "${SKIP_SECURITY:-0}" == "1" ]]; then
        log_warn "Skipping security stack (--skip-security flag)"
        return 0
    fi
    
    # Install and configure firewall
    install_ufw
    
    if [[ "${SECURE_MODE:-0}" == "1" ]]; then
        setup_ufw_rate_limiting
        setup_advanced_firewall
    fi
    
    # Install Fail2Ban
    install_fail2ban
    
    # Install AppArmor
    install_apparmor
    enable_common_profiles
    
    # Apply kernel hardening
    apply_kernel_hardening
    disable_unused_protocols
    
    if [[ "${SECURE_MODE:-0}" == "1" ]]; then
        apply_secure_mode_hardening
    fi
    
    # Telemetry blocking
    if [[ "${DISABLE_TELEMETRY:-0}" == "1" ]]; then
        block_telemetry
        block_ubuntu_motd_ads
        disable_ubuntu_pro_prompts
    fi
    
    # Integrity monitoring
    install_aide
    install_chkrootkit
    install_rkhunter
    
    log_success "Security stack installation completed"
}

# Security audit
run_security_audit() {
    log_section "🔍 SECURITY AUDIT"
    
    log_info "Running security checks..."
    
    # Check firewall
    if command_exists ufw; then
        log_info "Firewall status:"
        ufw status || true
    fi
    
    # Check Fail2Ban
    check_fail2ban_status
    
    # Check AppArmor
    check_apparmor_status
    
    # Check kernel settings
    verify_kernel_settings
    
    # Run integrity check
    if [[ "${RUN_INTEGRITY_CHECK:-0}" == "1" ]]; then
        run_full_integrity_check
    fi
    
    log_success "Security audit completed"
}

# Security status summary
show_security_status() {
    log_section "🛡️ SECURITY STATUS SUMMARY"
    
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║         SECURITY COMPONENT STATUS              ║"
    echo "╠════════════════════════════════════════════════╣"
    
    # UFW
    if systemctl is-active --quiet ufw 2>/dev/null; then
        echo "║ ✓ UFW Firewall              [ACTIVE]          ║"
    else
        echo "║ ✗ UFW Firewall              [INACTIVE]        ║"
    fi
    
    # Fail2Ban
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo "║ ✓ Fail2Ban                  [ACTIVE]          ║"
    else
        echo "║ ✗ Fail2Ban                  [INACTIVE]        ║"
    fi
    
    # AppArmor
    if aa-enabled 2>/dev/null; then
        echo "║ ✓ AppArmor                  [ENABLED]         ║"
    else
        echo "║ ✗ AppArmor                  [DISABLED]        ║"
    fi
    
    # AIDE
    if [[ -f /var/lib/aide/aide.db ]]; then
        echo "║ ✓ AIDE                      [CONFIGURED]      ║"
    else
        echo "║ ✗ AIDE                      [NOT CONFIGURED]  ║"
    fi
    
    # chkrootkit
    if command_exists chkrootkit; then
        echo "║ ✓ chkrootkit                [INSTALLED]       ║"
    else
        echo "║ ✗ chkrootkit                [NOT INSTALLED]   ║"
    fi
    
    echo "╚════════════════════════════════════════════════╝"
    echo ""
}

# Quick security fix
quick_security_fix() {
    log_section "⚡ QUICK SECURITY FIX"
    
    log_info "Applying quick security fixes..."
    
    # Ensure services are running
    if systemctl is-enabled --quiet ufw 2>/dev/null; then
        systemctl start ufw || true
    fi
    
    if systemctl is-enabled --quiet fail2ban 2>/dev/null; then
        systemctl start fail2ban || true
    fi
    
    if systemctl is-enabled --quiet apparmor 2>/dev/null; then
        systemctl start apparmor || true
    fi
    
    # Fix common permission issues
    chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
    chmod 700 /root 2>/dev/null || true
    
    log_success "Quick security fixes applied"
}

# Export functions
export -f setup_security_stack
export -f run_security_audit
export -f show_security_status
export -f quick_security_fix
