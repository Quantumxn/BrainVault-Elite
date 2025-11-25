#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_DEV_MAIN_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_DEV_MAIN_SH=1

run_dev_installation() {
  log_info "Running development stack installation"

  run_functions \
    install_dev_tools \
    install_python_stack \
    install_containers

  log_success "Development stack installation completed"
}

run_dev_configuration() {
  log_info "Applying development stack configuration"

  run_functions \
    setup_dev_tools \
    setup_python_stack \
    setup_containers

  log_success "Development stack configuration completed"
}

