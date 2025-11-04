#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_MONITORING_MAIN_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_MONITORING_MAIN_SH=1

run_monitoring_installation() {
  log_info "Running monitoring installation pipeline"

  run_functions \
    install_backup \
    install_monitoring \
    install_cron_jobs

  log_success "Monitoring installation pipeline completed"
}

run_monitoring_configuration() {
  log_info "Configuring monitoring pipelines"

  run_functions \
    setup_backup \
    setup_monitoring \
    setup_cron_jobs

  log_success "Monitoring configuration completed"
}

