#!/usr/bin/env bash

install_python_stack() {
    local context="DEV:PYTHON"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get

    run_apt_install "$context" "Install Python build essentials" python3 python3-pip python3-venv python3-dev
    run_step "$context" "Upgrade pip" sudo -H python3 -m pip install --upgrade pip
    run_step "$context" "Install AI/ML Python packages" sudo -H python3 -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu transformers datasets jupyterlab

    clear_error_handler
    log_success "[$context] Python AI stack ready"
}

export -f install_python_stack
