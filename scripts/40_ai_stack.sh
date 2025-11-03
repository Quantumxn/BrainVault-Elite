#!/usr/bin/env bash

install_ai_stack() {
  log_section "AI & Development Stack"
  install_dev_tools
  install_container_stack
  install_python_stack
}

install_dev_tools() {
  log_section "Developer Toolchain"
  install_pkg git build-essential python3 python3-pip python3-venv pkg-config
}

install_container_stack() {
  log_section "Container Tooling"
  install_pkg docker.io docker-compose podman
  run_cmd "systemctl enable docker" "Enabling Docker service"
  run_cmd "systemctl start docker" "Starting Docker service"
}

install_python_stack() {
  log_section "Python AI Packages"
  run_cmd "pip3 install --upgrade pip wheel setuptools" "Upgrading pip tooling"
  run_cmd "pip3 install torch torchvision torchaudio transformers pandas jupyterlab" "Installing AI Python libraries"
}
