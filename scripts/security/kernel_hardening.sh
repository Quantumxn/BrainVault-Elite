#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_SECURITY_KERNEL_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_SECURITY_KERNEL_SH=1

: "${SECURE_MODE:=false}"

install_kernel_hardening() {
  log_info "Installing kernel hardening prerequisites"
  ensure_dependencies sudo apt-get uname || return 1

  local current_kernel
  current_kernel=$(uname -r)
  log_debug "Current kernel version: ${current_kernel}"

  perform_step "Install kernel hardening packages" sudo apt-get install -y linux-image-generic linux-headers-"${current_kernel}"

  log_success "Kernel hardening packages installed"
}

setup_kernel_hardening() {
  log_info "Applying kernel hardening sysctl policies"
  ensure_dependencies sudo tee sysctl || return 1

  local sysctl_file="/etc/sysctl.d/99-brainvault.conf"

  perform_step "Write BrainVault sysctl overrides" sudo tee "${sysctl_file}" >/dev/null <<'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.randomize_va_space = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
EOF

  if [[ "${SECURE_MODE}" == "true" ]]; then
    perform_step "Apply secure-mode sysctl hardening" sudo tee -a "${sysctl_file}" >/dev/null <<'EOF'
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
kernel.sysrq = 0
EOF
  fi

  perform_step "Reload sysctl settings" sudo sysctl --system

  log_success "Kernel hardening policies applied"
}

