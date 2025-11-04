#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_MONITORING_CORE_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_MONITORING_CORE_SH=1

install_monitoring() {
  log_info "Installing monitoring stack"
  ensure_dependencies sudo apt-get curl || return 1

  perform_step "Install Netdata" sudo apt-get install -y netdata
  perform_step "Install Prometheus node exporter" sudo apt-get install -y prometheus-node-exporter

  log_success "Monitoring stack installed"
}

setup_monitoring() {
  log_info "Configuring monitoring services"
  ensure_dependencies sudo systemctl || return 1

  perform_step "Enable Netdata service" sudo systemctl enable --now netdata
  perform_step "Enable node exporter service" sudo systemctl enable --now prometheus-node-exporter

  log_success "Monitoring services configured"
}

