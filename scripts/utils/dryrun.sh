#!/usr/bin/env bash

: "${DRY_RUN:=false}"

enable_dry_run() {
    DRY_RUN=true
    log_warn "Dry-run mode enabled: no changes will be made"
}

disable_dry_run() {
    DRY_RUN=false
    log_warn "Dry-run mode disabled: commands will be executed"
}

is_dry_run() {
    [[ "${DRY_RUN}" == "true" ]]
}

run_step() {
    local context="$1"
    local description="$2"
    shift 2

    if is_dry_run; then
        log_info "[$context] (dry-run) ${description} :: $*"
        return 0
    fi

    log_info "[$context] ${description}"
    "$@"
}

simulate_file_change() {
    local context="$1"
    local path="$2"
    if is_dry_run; then
        log_debug "[$context] (dry-run) would modify ${path}"
    fi
}

APT_LOCK_FILE="${APT_LOCK_FILE:-/tmp/brainvault-apt.lock}"

run_apt_update() {
    local context="$1"
    local description="${2:-Update apt cache}"
    run_step "$context" "$description" bash -c 'lock="$1"; flock "$lock" sudo apt-get update' _ "$APT_LOCK_FILE"
}

run_apt_install() {
    local context="$1"
    local description="$2"
    shift 2
    if [[ $# -eq 0 ]]; then
        log_warn "[$context] run_apt_install called without packages"
        return 0
    fi
    run_step "$context" "$description" bash -c 'lock="$1"; shift; flock "$lock" sudo apt-get install -y "$@"' _ "$APT_LOCK_FILE" "$@"
}

run_apt_purge() {
    local context="$1"
    local description="$2"
    shift 2
    if [[ $# -eq 0 ]]; then
        log_warn "[$context] run_apt_purge called without packages"
        return 0
    fi
    run_step "$context" "$description" bash -c 'lock="$1"; shift; flock "$lock" sudo apt-get purge -y "$@"' _ "$APT_LOCK_FILE" "$@"
}

export -f enable_dry_run disable_dry_run is_dry_run run_step simulate_file_change run_apt_update run_apt_install run_apt_purge
