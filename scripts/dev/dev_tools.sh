#!/usr/bin/env bash

install_dev_tools() {
    local context="DEV:TOOLS"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get

    run_apt_install "$context" "Install foundational developer tooling" build-essential git curl wget neovim tmux unzip
    run_step "$context" "Configure git for secure defaults" bash -c 'git config --global pull.rebase false'

    clear_error_handler
    log_success "[$context] Developer tools installed"
}

export -f install_dev_tools
