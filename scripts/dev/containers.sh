#!/usr/bin/env bash

if [[ -n "${BRAINVAULT_DEV_CONTAINERS_SH:-}" ]]; then
  return 0
fi

export BRAINVAULT_DEV_CONTAINERS_SH=1

install_containers() {
  log_info "Installing container tooling"
  ensure_dependencies sudo apt-get || return 1

  perform_step "Install Docker engine" sudo apt-get install -y docker.io docker-compose-plugin
  perform_step "Enable Docker service" sudo systemctl enable --now docker

  log_success "Container tooling installed"
}

setup_containers() {
  log_info "Configuring container environment"
  ensure_dependencies sudo docker || return 1

  perform_step "Add current user to docker group" sudo usermod -aG docker "$USER"
  perform_step "Verify Docker version" docker --version

  log_success "Container environment configured"
}

