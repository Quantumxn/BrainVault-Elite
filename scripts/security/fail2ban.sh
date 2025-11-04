#!/usr/bin/env bash

install_fail2ban() {
    local context="SECURITY:FAIL2BAN"
    local jail_override="/etc/fail2ban/jail.d/brainvault.conf"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get systemctl

    run_apt_install "$context" "Install Fail2Ban" fail2ban
    run_step "$context" "Enable and start Fail2Ban" sudo systemctl enable --now fail2ban

    if is_dry_run; then
        simulate_file_change "$context" "$jail_override"
    else
        run_step "$context" "Deploy hardened Fail2Ban overrides" bash -c "printf '%s\n' '[DEFAULT]' 'bantime = 3600' 'findtime = 600' 'maxretry = 5' '' '[sshd]' 'enabled = true' 'port = ssh' 'logpath = /var/log/auth.log' 'backend = systemd' | sudo tee ${jail_override} >/dev/null"
        run_step "$context" "Restart Fail2Ban" sudo systemctl restart fail2ban
    fi

    clear_error_handler
    log_success "[$context] Fail2Ban installed and hardened"
}

export -f install_fail2ban
