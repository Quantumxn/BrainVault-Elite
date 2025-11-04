#!/usr/bin/env bash

install_dev_tools() {
    log_info "Installing developer toolchain"
    install_pkg git build-essential python3 python3-pip python3-venv
    log_success "Developer toolchain packages installed"
}

install_container_stack() {
    log_info "Provisioning container runtimes"

    install_pkg docker.io docker-compose podman
    run_cmd "systemctl enable docker" "Enabling Docker service" true || log_warn "Unable to enable Docker service"
    run_cmd "systemctl restart docker" "Starting Docker service" true || log_warn "Unable to start Docker service"
}

install_python_stack() {
    log_info "Installing Python AI packages"

    if ! command -v pip3 >/dev/null 2>&1; then
        log_error "pip3 is not available; ensure python3-pip is installed."
        return 1
    fi

    run_cmd "pip3 install --upgrade pip wheel setuptools" "Upgrading pip tooling"
    run_cmd "pip3 install torch torchvision transformers pandas jupyterlab" "Installing Python AI libraries"
    log_success "Python AI stack installed"
}
