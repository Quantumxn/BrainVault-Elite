#!/usr/bin/env bash

setup_integrity_monitoring() {
    local context="SECURITY:INTEGRITY"
    local aide_cron="/etc/cron.d/brainvault-aide"

    register_error_handler "$context"
    ensure_dependencies "$context" sudo apt-get tee systemctl

    run_apt_install "$context" "Install integrity tooling" aide aide-common rkhunter chkrootkit debsums
    run_step "$context" "Update rkhunter definitions" sudo rkhunter --update || true
    run_step "$context" "Refresh chkrootkit" sudo chkrootkit || true

    if is_dry_run; then
        simulate_file_change "$context" "$aide_cron"
    else
        run_step "$context" "Schedule AIDE daily scan" bash -c "printf '%s\n' '0 3 * * * root /usr/sbin/aide.wrapper --config /etc/aide/aide.conf --check' | sudo tee ${aide_cron} >/dev/null"
    fi

    run_step "$context" "Initialize AIDE database" sudo aideinit
    run_step "$context" "Activate new AIDE database" sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

    clear_error_handler
    log_success "[$context] Integrity monitoring stack ready"
}

export -f setup_integrity_monitoring
