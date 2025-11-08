#!/usr/bin/env bash

setup_kernel_hardening() {
    local context="SECURITY:KERNEL"
    local sysctl_file="/etc/sysctl.d/99-brainvault.conf"
    local -a sysctl_entries=(
        'kernel.kptr_restrict=2'
        'kernel.randomize_va_space=2'
        'net.ipv4.conf.all.rp_filter=1'
        'net.ipv4.conf.default.rp_filter=1'
        'net.ipv4.tcp_syncookies=1'
        'net.ipv4.ip_forward=0'
    )

    if [[ "${SECURE_MODE:-false}" == "true" ]]; then
        sysctl_entries+=(
            'net.ipv4.conf.all.accept_source_route=0'
            'net.ipv4.conf.all.accept_redirects=0'
            'net.ipv6.conf.all.disable_ipv6=1'
        )
    fi

    register_error_handler "$context"
    ensure_dependencies "$context" sudo tee sysctl

    if is_dry_run; then
        simulate_file_change "$context" "$sysctl_file"
    else
        local sysctl_payload
        sysctl_payload=$(printf '%s\n' "${sysctl_entries[@]}")
        run_step "$context" "Apply kernel hardening sysctl profile" bash -c 'printf "%s" "$1" | sudo tee "$2" >/dev/null' _ "$sysctl_payload" "$sysctl_file"
    fi

    run_step "$context" "Reload sysctl settings" sudo sysctl -p "$sysctl_file"

    clear_error_handler
    log_success "[$context] Kernel hardening profile applied"
}

export -f setup_kernel_hardening
