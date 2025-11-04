#!/usr/bin/env bash

run_dev_stack() {
    local context="DEV:MAIN"

    if [[ "${SKIP_AI:-false}" == "true" ]]; then
        log_warn "[$context] Dev + AI stack skipped per configuration"
        return 0
    fi

    log_section "Developer & AI Enablement"

    install_dev_tools
    install_python_stack
    setup_container_stack

    log_success "[$context] Dev + AI stack completed"
}

export -f run_dev_stack
