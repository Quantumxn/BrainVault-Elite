#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_DEV_TOOLS_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_DEV_TOOLS_SH=1

install_dev_tools() {
  log_info "Installing developer tooling"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install build essentials" sudo apt-get install -y build-essential pkg-config cmake
  perform_step "Install common developer utilities" sudo apt-get install -y git curl wget unzip jq

  log_success "Developer tooling installed"
}

setup_dev_tools() {
  log_info "Configuring developer tooling defaults"
  ensure_dependencies git || return 1

  perform_step "Configure global Git options" git config --global init.defaultBranch main
  perform_step "Enable Git credential helper cache" git config --global credential.helper cache

  log_success "Developer tooling configured"
}

