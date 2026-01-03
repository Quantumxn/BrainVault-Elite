#!/usr/bin/env bash

setup_apparmor_profiles() {
    local context="SECURITY:APPARMOR"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get systemctl

    run_apt_install "$context" "Install AppArmor packages" apparmor apparmor-utils
    run_step "$context" "Enable and start AppArmor" sudo systemctl enable --now apparmor
    run_step "$context" "Enforce AppArmor profiles" sudo aa-enforce /etc/apparmor.d/*

    clear_error_handler
    log_success "[$context] AppArmor profiles enforced"
}

export -f setup_apparmor_profiles
