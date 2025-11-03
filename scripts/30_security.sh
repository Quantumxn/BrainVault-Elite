#!/usr/bin/env bash

install_security_stack() {
  log_section "Security Stack"
  install_pkg ufw fail2ban apparmor apparmor-utils apparmor-profiles-extra lynis chkrootkit rkhunter aide-common auditd needrestart debsecan
  setup_firewall
  setup_fail2ban
  setup_apparmor
  setup_kernel_hardening
  setup_integrity_tools
}

setup_firewall() {
  log_section "Firewall Configuration"
  run_cmd "ufw default deny incoming" "Setting default incoming policy to deny"
  run_cmd "ufw default allow outgoing" "Setting default outgoing policy to allow"
  run_cmd "ufw allow OpenSSH" "Allowing SSH access"
  run_cmd "ufw --force enable" "Enabling UFW firewall"
}

setup_fail2ban() {
  log_section "Fail2ban Configuration"
  run_cmd "systemctl enable fail2ban" "Enabling fail2ban service"
  run_cmd "systemctl start fail2ban" "Starting fail2ban service"
}

setup_apparmor() {
  log_section "AppArmor Configuration"
  run_cmd "systemctl enable apparmor" "Enabling AppArmor"
  run_cmd "systemctl start apparmor" "Starting AppArmor"
}

setup_kernel_hardening() {
  log_section "Kernel Hardening"
  local sysctl_file="/etc/sysctl.d/99-brainvault-hardening.conf"
  local sysctl_content
  sysctl_content=$(cat <<'EOC'
kernel.randomize_va_space=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
kernel.kptr_restrict=2
kernel.sysrq=0
kernel.unprivileged_bpf_disabled=1
fs.protected_hardlinks=1
fs.protected_symlinks=1
EOC
)
  write_file "${sysctl_file}" "${sysctl_content}" "Applying kernel hardening parameters"
  run_cmd "sysctl --system" "Reloading kernel parameters"
}

setup_integrity_tools() {
  log_section "Integrity & Audit Tools"
  run_cmd "rkhunter --update" "Updating rkhunter signatures"
  run_cmd "rkhunter --propupd" "Updating rkhunter property database"
  run_cmd "lynis audit system" "Running Lynis system audit"
}

enable_secure_mode() {
  log_section "Secure Mode Enhancements"
  run_cmd "ufw logging on" "Enabling UFW logging"
  run_cmd "systemctl enable auditd" "Ensuring auditd enabled"
  run_cmd "systemctl start auditd" "Starting auditd"
  run_cmd "chsh -s /usr/sbin/nologin root" "Restricting interactive root shell"
  run_cmd "passwd -l root" "Locking root account"
}

setup_telemetry_block() {
  log_section "Telemetry Blocking"
  run_cmd "iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m string --string 'telemetry' --algo bm -j DROP" "Blocking telemetry endpoints"
}
