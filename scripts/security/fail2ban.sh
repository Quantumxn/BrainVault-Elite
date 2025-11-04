#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_FAIL2BAN_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_FAIL2BAN_SH=1

install_fail2ban() {
  log_info "Installing Fail2Ban"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install Fail2Ban package" sudo apt-get install -y fail2ban

  log_success "Fail2Ban installation completed"
}

setup_fail2ban() {
  log_info "Configuring Fail2Ban"
  ensure_dependencies sudo systemctl fail2ban-client || return 1

  perform_step "Create local jail overrides" sudo tee /etc/fail2ban/jail.local >/dev/null <<'EOF'
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF

  perform_step "Restart Fail2Ban" sudo systemctl restart fail2ban
  perform_step "Enable Fail2Ban service" sudo systemctl enable fail2ban

  log_success "Fail2Ban configuration applied"
}

