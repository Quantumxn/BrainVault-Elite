#!/usr/bin/env bash

final_steps() {
    log_info "Performing final cleanup"

    run_cmd "apt-get autoremove -y" "Removing unused packages" true || log_warn "Failed to remove unused packages"
    run_cmd "apt-get clean" "Cleaning APT cache" true || log_warn "Failed to clean APT cache"

    log_success "BrainVault Elite bootstrap sequence complete. Reboot recommended."
}
