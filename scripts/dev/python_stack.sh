#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_DEV_PYTHON_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_DEV_PYTHON_SH=1

install_python_stack() {
  log_info "Installing Python stack"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install Python packages" sudo apt-get install -y python3 python3-pip python3-venv
  perform_step "Upgrade pip" sudo -H python3 -m pip install --upgrade pip
  perform_step "Install core Python tooling" sudo -H python3 -m pip install --upgrade wheel setuptools virtualenv

  log_success "Python stack installation completed"
}

setup_python_stack() {
  log_info "Configuring Python environment"
  ensure_dependencies python3 pip3 || return 1

  perform_step "Create default virtualenv directory" mkdir -p "$HOME/.virtualenvs"
  perform_step "Ensure pip uses caching" mkdir -p "$HOME/.cache/pip"

  log_success "Python stack configuration applied"
}

